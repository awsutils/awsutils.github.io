#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Check/Install gum ---
if ! command -v gum > /dev/null 2>&1; then
  log "Installing gum..."
  GUM_VERSION="0.17.0"
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;
  esac
  OS=$(uname -s)
  case "$OS" in
    Linux)  OS="Linux" ;;
    Darwin) OS="Darwin" ;;
    *) error "Unsupported OS: $OS" ;;
  esac
  GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${OS}_${ARCH}.tar.gz"
  TMP_DIR=$(mktemp -d)
  curl -fsSL "$GUM_URL" -o "${TMP_DIR}/gum.tar.gz" || error "Failed to download gum"
  tar -xzf "${TMP_DIR}/gum.tar.gz" -C "${TMP_DIR}"
  sudo cp "${TMP_DIR}/gum_${GUM_VERSION}_${OS}_${ARCH}/gum" /usr/local/bin/gum
  sudo chmod +x /usr/local/bin/gum
  rm -rf "${TMP_DIR}"
  command -v gum > /dev/null 2>&1 || error "gum installation failed"
  log "gum installed successfully"
fi

# --- Select VPC ---
VPC_LIST=$(aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId, Tags[?Key==`Name`].Value | [0] || `(no name)`, CidrBlock]' \
  --output text | awk '{printf "%s\t%s\t%s\n", $1, $2, $3}')

[[ -z "$VPC_LIST" ]] && error "No VPCs found"

SELECTED=$(echo "$VPC_LIST" | gum choose --header "Select a VPC:")
VPC_ID=$(echo "$SELECTED" | awk '{print $1}')

REGION=$(aws configure get region)
VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].Tags[?Key==`Name`].Value | [0]' --output text)
[[ "$VPC_NAME" == "None" || -z "$VPC_NAME" ]] && VPC_NAME="$VPC_ID"
log "Region: $REGION"
log "VPC: $VPC_ID ($VPC_NAME)"

# --- Common endpoint services ---
GATEWAY_SERVICES=(
  "com.amazonaws.${REGION}.s3"
  "com.amazonaws.${REGION}.dynamodb"
)

INTERFACE_SERVICES=(
  "com.amazonaws.${REGION}.ec2"
  "com.amazonaws.${REGION}.ec2messages"
  "com.amazonaws.${REGION}.ssm"
  "com.amazonaws.${REGION}.ssmmessages"
  "com.amazonaws.${REGION}.logs"
  "com.amazonaws.${REGION}.monitoring"
  "com.amazonaws.${REGION}.sts"
  "com.amazonaws.${REGION}.kms"
  "com.amazonaws.${REGION}.ecr.api"
  "com.amazonaws.${REGION}.ecr.dkr"
  "com.amazonaws.${REGION}.secretsmanager"
  "com.amazonaws.${REGION}.sqs"
  "com.amazonaws.${REGION}.sns"
  "com.amazonaws.${REGION}.execute-api"
)

# --- Select Gateway Endpoints ---
GW_LABELS=()
for svc in "${GATEWAY_SERVICES[@]}"; do
  GW_LABELS+=("${svc##*.}")
done

echo ""
SELECTED_GW=$(printf '%s\n' "${GW_LABELS[@]}" | gum choose --no-limit --selected="$(IFS=,; echo "${GW_LABELS[*]}")" --header "Select Gateway Endpoints (tab to toggle):")
SELECTED_GW_SERVICES=()
while IFS= read -r label; do
  [[ -z "$label" ]] && continue
  for svc in "${GATEWAY_SERVICES[@]}"; do
    [[ "${svc##*.}" == "$label" ]] && SELECTED_GW_SERVICES+=("$svc") && break
  done
done <<< "$SELECTED_GW"
log "Selected ${#SELECTED_GW_SERVICES[@]} gateway endpoint(s)"

# --- Select Interface Endpoints ---
IF_LABELS=()
for svc in "${INTERFACE_SERVICES[@]}"; do
  IF_LABELS+=("${svc##*.}")
done

SELECTED_IF=$(printf '%s\n' "${IF_LABELS[@]}" | gum choose --no-limit --selected="$(IFS=,; echo "${IF_LABELS[*]}")" --header "Select Interface Endpoints (tab to toggle):")
SELECTED_IF_SERVICES=()
while IFS= read -r label; do
  [[ -z "$label" ]] && continue
  for svc in "${INTERFACE_SERVICES[@]}"; do
    [[ "${svc##*.}" == "$label" ]] && SELECTED_IF_SERVICES+=("$svc") && break
  done
done <<< "$SELECTED_IF"
log "Selected ${#SELECTED_IF_SERVICES[@]} interface endpoint(s)"

# --- Add additional endpoints by typing ---
if gum confirm "Add additional interface endpoints manually?"; then
  log "Fetching all available interface services..."
  ALL_IF_SERVICES=$(aws ec2 describe-vpc-endpoint-services \
    --query 'ServiceDetails[?ServiceType[?ServiceType==`Interface`]].ServiceName' \
    --output text | tr '\t' '\n' | sort)

  while true; do
    EXTRA=$(echo "$ALL_IF_SERVICES" | gum filter --placeholder "Type to search service name (ESC to finish)..." --header "Add Interface Endpoint:") || break
    [[ -z "$EXTRA" ]] && break
    # Avoid duplicates
    already=false
    for svc in "${SELECTED_IF_SERVICES[@]}"; do
      [[ "$svc" == "$EXTRA" ]] && already=true && break
    done
    if $already; then
      warn "${EXTRA##*.}: already selected"
    else
      SELECTED_IF_SERVICES+=("$EXTRA")
      log "Added: ${EXTRA##*.}"
    fi
    gum confirm "Add another?" || break
  done
  log "Total interface endpoint(s): ${#SELECTED_IF_SERVICES[@]}"
fi

# --- VPC CIDR ---
VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].CidrBlock' --output text)
log "VPC CIDR: $VPC_CIDR"

# --- Route tables ---
ALL_RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].RouteTableId' --output text)
log "All route tables: $ALL_RT_IDS"

# Public RTs = have igw- route
PUBLIC_RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Routes[?GatewayId!=`null` && starts_with(GatewayId, `igw-`)]].RouteTableId' \
  --output text)

# Private RTs = all minus public
PRIVATE_RT_IDS=""
for rt in $ALL_RT_IDS; do
  is_public=false
  for pub_rt in $PUBLIC_RT_IDS; do
    [[ "$rt" == "$pub_rt" ]] && is_public=true && break
  done
  $is_public || PRIVATE_RT_IDS="$PRIVATE_RT_IDS $rt"
done
PRIVATE_RT_IDS=$(echo "$PRIVATE_RT_IDS" | xargs)
log "Private route tables: ${PRIVATE_RT_IDS:-none}"

# --- Private subnets ---
MAIN_RT=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" \
  --query 'RouteTables[0].RouteTableId' --output text)

MAIN_IS_PRIVATE=false
for rt in $PRIVATE_RT_IDS; do
  [[ "$rt" == "$MAIN_RT" ]] && MAIN_IS_PRIVATE=true && break
done

EXPLICIT_SUBNETS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].Associations[?SubnetId].SubnetId' --output text)

PRIVATE_SUBNET_IDS=""
# Subnets explicitly associated with private RTs
for rt in $PRIVATE_RT_IDS; do
  subs=$(aws ec2 describe-route-tables --route-table-ids "$rt" \
    --query 'RouteTables[0].Associations[?SubnetId].SubnetId' --output text)
  PRIVATE_SUBNET_IDS="$PRIVATE_SUBNET_IDS $subs"
done

# Subnets with no explicit RT use main; if main is private, they're private
if $MAIN_IS_PRIVATE; then
  ALL_SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' --output text)
  for s in $ALL_SUBNETS; do
    echo "$EXPLICIT_SUBNETS" | grep -qw "$s" || PRIVATE_SUBNET_IDS="$PRIVATE_SUBNET_IDS $s"
  done
fi

PRIVATE_SUBNET_IDS=$(echo "$PRIVATE_SUBNET_IDS" | xargs -n1 | sort -u | xargs)
log "Private subnets: ${PRIVATE_SUBNET_IDS:-none}"

[[ -z "$PRIVATE_SUBNET_IDS" ]] && warn "No private subnets found. Interface endpoints will be skipped."

# --- Security Group ---
SG_TAG_NAME="${VPC_NAME}-vpce-sg"
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=${SG_TAG_NAME}" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)

if [[ -n "$SG_ID" && "$SG_ID" != "None" ]]; then
  log "Using existing Security Group: $SG_ID ($SG_TAG_NAME)"
else
  SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_TAG_NAME" \
    --description "VPC Endpoints - allow all from $VPC_CIDR" \
    --vpc-id "$VPC_ID" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${SG_TAG_NAME}}]" \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" --protocol -1 --cidr "$VPC_CIDR" > /dev/null

  log "Created Security Group: $SG_ID ($SG_TAG_NAME)"
fi

# --- Existing endpoints ---
EXISTING=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[?State!=`deleted`].ServiceName' --output text)

# --- Verify service availability ---
AVAILABLE_SERVICES=$(aws ec2 describe-vpc-endpoint-services \
  --query 'ServiceNames' --output text)

# --- Pre-cache subnet AZs ---
declare -A SUBNET_AZ_MAP
for subnet in $PRIVATE_SUBNET_IDS; do
  az=$(aws ec2 describe-subnets --subnet-ids "$subnet" \
    --query 'Subnets[0].AvailabilityZone' --output text)
  SUBNET_AZ_MAP[$subnet]="$az"
done

# --- Create endpoints in parallel ---
LOG_DIR=$(mktemp -d)
PIDS=()

# Gateway endpoints
echo ""
log "=== Creating Gateway Endpoints (all route tables) ==="
for svc in "${SELECTED_GW_SERVICES[@]}"; do
  short="${svc##*.}"
  if echo "$EXISTING" | grep -qw "$svc"; then
    warn "$short: already exists, skipping"
    continue
  fi
  if ! echo "$AVAILABLE_SERVICES" | grep -qw "$svc"; then
    warn "$short: not available in $REGION, skipping"
    continue
  fi
  (
    TAG_NAME="${VPC_NAME}-vpce-${short}"
    EPID=$(aws ec2 create-vpc-endpoint \
      --vpc-id "$VPC_ID" \
      --service-name "$svc" \
      --vpc-endpoint-type Gateway \
      --route-table-ids $ALL_RT_IDS \
      --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=${TAG_NAME}}]" \
      --query 'VpcEndpoint.VpcEndpointId' --output text 2>&1) && \
      echo "OK|$short|$EPID|$TAG_NAME" > "${LOG_DIR}/gw_${short}" || \
      echo "FAIL|$short|$EPID" > "${LOG_DIR}/gw_${short}"
  ) &
  PIDS+=($!)
done

# Interface endpoints
echo ""
log "=== Creating Interface Endpoints (private subnets) ==="
if [[ -z "$PRIVATE_SUBNET_IDS" ]]; then
  warn "Skipping all interface endpoints — no private subnets"
else
  for svc in "${SELECTED_IF_SERVICES[@]}"; do
    short="${svc##*.}"
    if echo "$EXISTING" | grep -qw "$svc"; then
      warn "$short: already exists, skipping"
      continue
    fi
    if ! echo "$AVAILABLE_SERVICES" | grep -qw "$svc"; then
      warn "$short: not available in $REGION, skipping"
      continue
    fi

    # Filter subnets by AZ availability
    SVC_AZS=$(aws ec2 describe-vpc-endpoint-services \
      --service-names "$svc" \
      --query 'ServiceDetails[0].AvailabilityZones[]' --output text 2>/dev/null)

    VALID_SUBNETS=""
    for subnet in $PRIVATE_SUBNET_IDS; do
      echo "$SVC_AZS" | grep -qw "${SUBNET_AZ_MAP[$subnet]}" && VALID_SUBNETS="$VALID_SUBNETS $subnet"
    done
    VALID_SUBNETS=$(echo "$VALID_SUBNETS" | xargs)

    if [[ -z "$VALID_SUBNETS" ]]; then
      warn "$short: no subnets in supported AZs, skipping"
      continue
    fi

    (
      TAG_NAME="${VPC_NAME}-vpce-${short}"
      EPID=$(aws ec2 create-vpc-endpoint \
        --vpc-id "$VPC_ID" \
        --service-name "$svc" \
        --vpc-endpoint-type Interface \
        --subnet-ids $VALID_SUBNETS \
        --security-group-ids "$SG_ID" \
        --private-dns-enabled \
        --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=${TAG_NAME}}]" \
        --query 'VpcEndpoint.VpcEndpointId' --output text 2>&1) && \
        echo "OK|$short|$EPID|$TAG_NAME" > "${LOG_DIR}/if_${short}" || \
        echo "FAIL|$short|$EPID" > "${LOG_DIR}/if_${short}"
    ) &
    PIDS+=($!)
  done
fi

# Wait for all background jobs
log "Waiting for ${#PIDS[@]} endpoint(s) to be created..."
for pid in "${PIDS[@]}"; do
  wait "$pid" 2>/dev/null
done

# Print results
echo ""
log "=== Results ==="
for f in "${LOG_DIR}"/*; do
  [[ -f "$f" ]] || continue
  IFS='|' read -r status short detail extra < "$f"
  if [[ "$status" == "OK" ]]; then
    log "$short: $detail ($extra)"
  else
    warn "$short: FAILED - $detail"
  fi
done
rm -rf "${LOG_DIR}"

# --- Summary ---
echo ""
echo -e "${CYAN}========== SUMMARY ==========${NC}"
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[?State!=`deleted`].{ID:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}' \
  --output table

log "Done!"
