#!/bin/bash
set -euo pipefail

export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    printf '%b[INFO]%b %s\n' "$GREEN" "$NC" "$*"
}

warn() {
    printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*" >&2
}

fatal() {
    printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*" >&2
    exit 1
}

show_help() {
    cat <<'EOF'
Usage: accinit.sh [--dry-run] [--help]

Applies a non-interactive single-account AWS security baseline.

Default actions:
  - enables account-level S3 Block Public Access
  - enables EBS encryption by default in all enabled regions
  - creates a dedicated log bucket when needed
  - creates a multi-region CloudTrail trail if one does not already exist
  - enables AWS Config in regions where it is not already configured
  - enables Security Hub in all enabled regions
  - enables GuardDuty in all enabled regions
  - enables GuardDuty runtime monitoring
  - enables Inspector in all enabled regions
  - creates one account-level IAM Access Analyzer per region when missing
  - enables Detective in the home region

Optional actions are controlled with environment variables, not prompts.

Common environment variables:
  ENABLE_S3_BLOCK_PUBLIC_ACCESS=true|false
  ENABLE_EBS_ENCRYPTION=true|false
  ENABLE_CLOUDTRAIL=true|false
  ENABLE_CONFIG=true|false
  ENABLE_SECURITY_HUB=true|false
  ENABLE_SECURITY_HUB_AGGREGATION=true|false
ENABLE_GUARDDUTY=true|false
  ENABLE_GUARDDUTY_RUNTIME_MONITORING=true|false
  ENABLE_INSPECTOR=true|false
  ENABLE_ACCESS_ANALYZER=true|false
  ENABLE_DETECTIVE=true|false
  HOME_REGION=us-east-1
  LOG_BUCKET_NAME=my-dedicated-bucket

Examples:
  ./accinit.sh
  ./accinit.sh --dry-run
  ENABLE_DETECTIVE=true ./accinit.sh
EOF
}

is_true() {
    [[ "${1:-false}" =~ ^([Tt][Rr][Uu][Ee]|1|[Yy][Ee][Ss])$ ]]
}

apply() {
    if [[ "$DRY_RUN" == true ]]; then
        printf '%b[DRY RUN]%b ' "$CYAN" "$NC" >&2
        printf '%q ' "$@" >&2
        printf '\n' >&2
        return 0
    fi

    "$@"
}

run_nonfatal() {
    local description="$1"
    shift

    if "$@"; then
        return 0
    fi

    warn "$description"
    WARNING_COUNT=$((WARNING_COUNT + 1))
    return 0
}

aws_home() {
    aws --no-cli-pager --region "$HOME_REGION" "$@"
}

aws_region() {
    local region="$1"
    shift
    aws --no-cli-pager --region "$region" "$@"
}

ensure_account_public_access_block() {
    local current

    current=$(aws_home s3control get-public-access-block \
        --account-id "$ACCOUNT_ID" \
        --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,IgnorePublicAcls,BlockPublicPolicy,RestrictPublicBuckets]' \
        --output text 2>/dev/null || true)

    if [[ "$current" == $'True\tTrue\tTrue\tTrue' ]]; then
        info "Account-level S3 Block Public Access already enabled"
        return 0
    fi

    if ! apply aws_home s3control put-public-access-block \
        --account-id "$ACCOUNT_ID" \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true; then
        return 1
    fi

    info "Enabled account-level S3 Block Public Access"
}

ensure_log_bucket() {
    local encryption_config

    encryption_config='{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

    if aws_home s3api head-bucket --bucket "$LOG_BUCKET_NAME" >/dev/null 2>&1; then
        info "Using existing log bucket $LOG_BUCKET_NAME"
    else
        info "Creating dedicated log bucket $LOG_BUCKET_NAME"
        if [[ "$HOME_REGION" == "us-east-1" ]]; then
            apply aws_home s3api create-bucket --bucket "$LOG_BUCKET_NAME" >/dev/null
        else
            apply aws_home s3api create-bucket \
                --bucket "$LOG_BUCKET_NAME" \
                --create-bucket-configuration "LocationConstraint=$HOME_REGION" >/dev/null
        fi
    fi

    apply aws_home s3api put-public-access-block \
        --bucket "$LOG_BUCKET_NAME" \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null

    apply aws_home s3api put-bucket-versioning \
        --bucket "$LOG_BUCKET_NAME" \
        --versioning-configuration Status=Enabled >/dev/null

    apply aws_home s3api put-bucket-encryption \
        --bucket "$LOG_BUCKET_NAME" \
        --server-side-encryption-configuration "$encryption_config" >/dev/null

    cat > "$TMP_DIR/log-bucket-policy.json" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:${PARTITION}:s3:::${LOG_BUCKET_NAME}"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:${PARTITION}:s3:::${LOG_BUCKET_NAME}/AWSLogs/${ACCOUNT_ID}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketPermissionsCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:ListBucket"
      ],
      "Resource": "arn:${PARTITION}:s3:::${LOG_BUCKET_NAME}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${ACCOUNT_ID}"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:${PARTITION}:s3:::${LOG_BUCKET_NAME}/AWSLogs/${ACCOUNT_ID}/Config/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${ACCOUNT_ID}",
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF

    apply aws_home s3api put-bucket-policy \
        --bucket "$LOG_BUCKET_NAME" \
        --policy "file://$TMP_DIR/log-bucket-policy.json" >/dev/null

    info "Configured bucket policy, encryption, and versioning for $LOG_BUCKET_NAME"
}

ensure_cloudtrail() {
    local named_trail
    local named_trail_home_region
    local existing_multi_region

    named_trail=$(aws_home cloudtrail describe-trails \
        --trail-name-list "$TRAIL_NAME" \
        --query 'trailList[0].Name' \
        --output text 2>/dev/null || true)
    named_trail_home_region=$(aws_home cloudtrail describe-trails \
        --trail-name-list "$TRAIL_NAME" \
        --query 'trailList[0].HomeRegion' \
        --output text 2>/dev/null || true)

    if [[ -n "$named_trail" && "$named_trail" != "None" ]]; then
        named_trail_home_region="${named_trail_home_region:-$HOME_REGION}"
        apply aws_region "$named_trail_home_region" cloudtrail update-trail \
            --name "$TRAIL_NAME" \
            --s3-bucket-name "$LOG_BUCKET_NAME" \
            --s3-key-prefix "$LOG_PREFIX/cloudtrail" \
            --is-multi-region-trail \
            --include-global-service-events \
            --enable-log-file-validation >/dev/null
        apply aws_region "$named_trail_home_region" cloudtrail start-logging --name "$TRAIL_NAME" >/dev/null
        info "Updated and started CloudTrail trail $TRAIL_NAME"
        return 0
    fi

    existing_multi_region=$(aws_home cloudtrail describe-trails \
        --query 'trailList[?IsMultiRegionTrail==`true`].Name | [0]' \
        --output text 2>/dev/null || true)

    if [[ -n "$existing_multi_region" && "$existing_multi_region" != "None" ]]; then
        info "Existing multi-region CloudTrail trail detected: $existing_multi_region"
        info "Leaving existing CloudTrail configuration unchanged"
        return 0
    fi

    apply aws_home cloudtrail create-trail \
        --name "$TRAIL_NAME" \
        --s3-bucket-name "$LOG_BUCKET_NAME" \
        --s3-key-prefix "$LOG_PREFIX/cloudtrail" \
        --is-multi-region-trail \
        --include-global-service-events \
        --enable-log-file-validation >/dev/null

    apply aws_home cloudtrail start-logging --name "$TRAIL_NAME" >/dev/null
    info "Created and started CloudTrail trail $TRAIL_NAME"
}

ensure_config_role() {
    local role_arn

    role_arn=$(aws_home iam get-role --role-name "$CONFIG_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)

    if [[ -n "$role_arn" && "$role_arn" != "None" ]]; then
        CONFIG_ROLE_ARN="$role_arn"
        info "Using existing Config role $CONFIG_ROLE_NAME"
    else
        cat > "$TMP_DIR/config-role-trust.json" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

        apply aws_home iam create-role \
            --role-name "$CONFIG_ROLE_NAME" \
            --assume-role-policy-document "file://$TMP_DIR/config-role-trust.json" >/dev/null

        if [[ "$DRY_RUN" != true ]]; then
            sleep 10
        fi

        CONFIG_ROLE_ARN="arn:${PARTITION}:iam::${ACCOUNT_ID}:role/${CONFIG_ROLE_NAME}"
        info "Created Config role $CONFIG_ROLE_NAME"
    fi

    apply aws_home iam attach-role-policy \
        --role-name "$CONFIG_ROLE_NAME" \
        --policy-arn "arn:${PARTITION}:iam::aws:policy/service-role/AWS_ConfigRole" >/dev/null

    if [[ "$DRY_RUN" != true ]]; then
        CONFIG_ROLE_ARN=$(aws_home iam get-role --role-name "$CONFIG_ROLE_NAME" --query 'Role.Arn' --output text)
    fi

    info "Attached AWS managed Config policy to $CONFIG_ROLE_NAME"
}

ensure_config_region() {
    local region="$1"
    local recorder_name
    local delivery_channel_name
    local recording

    recorder_name=$(aws_region "$region" configservice describe-configuration-recorders \
        --query 'ConfigurationRecorders[0].name' --output text 2>/dev/null || true)
    delivery_channel_name=$(aws_region "$region" configservice describe-delivery-channels \
        --query 'DeliveryChannels[0].name' --output text 2>/dev/null || true)

    if [[ -z "$delivery_channel_name" || "$delivery_channel_name" == "None" ]]; then
        apply aws_region "$region" configservice put-delivery-channel \
            --delivery-channel "name=${DEFAULT_DELIVERY_CHANNEL_NAME},s3BucketName=${LOG_BUCKET_NAME},s3KeyPrefix=${LOG_PREFIX}/config,configSnapshotDeliveryProperties={deliveryFrequency=${CONFIG_SNAPSHOT_FREQUENCY}}" >/dev/null
        delivery_channel_name="$DEFAULT_DELIVERY_CHANNEL_NAME"
        info "Created AWS Config delivery channel in $region"
    else
        info "AWS Config delivery channel already exists in $region: $delivery_channel_name"
    fi

    if [[ -z "$recorder_name" || "$recorder_name" == "None" ]]; then
        apply aws_region "$region" configservice put-configuration-recorder \
            --configuration-recorder "name=${DEFAULT_RECORDER_NAME},roleARN=${CONFIG_ROLE_ARN}" \
            --recording-group allSupported=true,includeGlobalResourceTypes=false >/dev/null
        recorder_name="$DEFAULT_RECORDER_NAME"
        info "Created AWS Config recorder in $region"
    else
        info "AWS Config recorder already exists in $region: $recorder_name"
    fi

    recording=$(aws_region "$region" configservice describe-configuration-recorder-status \
        --query 'ConfigurationRecordersStatus[0].recording' --output text 2>/dev/null || true)

    if [[ "$recording" == "True" ]]; then
        info "AWS Config recorder already running in $region"
        return 0
    fi

    apply aws_region "$region" configservice start-configuration-recorder \
        --configuration-recorder-name "$recorder_name" >/dev/null
    info "Started AWS Config recorder in $region"
}

ensure_security_hub_region() {
    local region="$1"

    if aws_region "$region" securityhub describe-hub >/dev/null 2>&1; then
        info "Security Hub already enabled in $region"
        return 0
    fi

    apply aws_region "$region" securityhub enable-security-hub \
        --enable-default-standards \
        --control-finding-generator SECURITY_CONTROL >/dev/null
    info "Enabled Security Hub in $region"
}

ensure_security_hub_aggregation() {
    local existing

    existing=$(aws_home securityhub list-finding-aggregators \
        --query 'FindingAggregators[0].FindingAggregatorArn' \
        --output text 2>/dev/null || true)

    if [[ -n "$existing" && "$existing" != "None" ]]; then
        info "Security Hub finding aggregation already configured in $HOME_REGION"
        return 0
    fi

    apply aws_home securityhub create-finding-aggregator \
        --region-linking-mode ALL_REGIONS >/dev/null
    info "Enabled Security Hub finding aggregation in $HOME_REGION"
}

ensure_guardduty_region() {
    local region="$1"
    local detector_id

    detector_id=$(aws_region "$region" guardduty list-detectors --query 'DetectorIds[0]' --output text 2>/dev/null || true)

    if [[ -z "$detector_id" || "$detector_id" == "None" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            info "[dry-run] Would create GuardDuty detector in $region"
            detector_id="DRYRUN"
        else
            detector_id=$(aws_region "$region" guardduty create-detector \
                --enable \
                --finding-publishing-frequency "$GUARDDUTY_FINDING_FREQUENCY" \
                --query 'DetectorId' --output text)
            info "Enabled GuardDuty in $region"
        fi
    else
        apply aws_region "$region" guardduty update-detector \
            --detector-id "$detector_id" \
            --enable \
            --finding-publishing-frequency "$GUARDDUTY_FINDING_FREQUENCY" >/dev/null
        info "Updated GuardDuty detector in $region"
    fi

    if ! is_true "$ENABLE_GUARDDUTY_RUNTIME_MONITORING"; then
        return 0
    fi

    if [[ "$detector_id" == "DRYRUN" ]]; then
        info "[dry-run] Would enable GuardDuty runtime monitoring in $region"
        return 0
    fi

    apply aws_region "$region" guardduty update-detector \
        --detector-id "$detector_id" \
        --features 'Name=RUNTIME_MONITORING,Status=ENABLED,AdditionalConfiguration=[{Name=EC2_AGENT_MANAGEMENT,Status=ENABLED},{Name=ECS_FARGATE_AGENT_MANAGEMENT,Status=ENABLED},{Name=EKS_ADDON_MANAGEMENT,Status=ENABLED}]' >/dev/null
    info "Enabled GuardDuty runtime monitoring in $region"
}

ensure_inspector_region() {
    local region="$1"
    local output
    local -a resource_types

    read -r -a resource_types <<< "$INSPECTOR_RESOURCE_TYPES"

    if [[ "$DRY_RUN" == true ]]; then
        info "[dry-run] Would enable Inspector in $region"
        return 0
    fi

    if output=$(aws_region "$region" inspector2 enable --resource-types "${resource_types[@]}" 2>&1); then
        info "Enabled Inspector in $region"
        return 0
    fi

    if [[ "$output" == *"ALREADY_ENABLED"* || "$output" == *"ENABLE_IN_PROGRESS"* ]]; then
        info "Inspector already enabled or enabling in $region"
        return 0
    fi

    printf '%s\n' "$output" >&2
    return 1
}

ensure_access_analyzer_region() {
    local region="$1"
    local analyzer_name

    analyzer_name=$(aws_region "$region" accessanalyzer list-analyzers \
        --type ACCOUNT \
        --query 'analyzers[0].name' \
        --output text 2>/dev/null || true)

    if [[ -n "$analyzer_name" && "$analyzer_name" != "None" ]]; then
        info "Account-level Access Analyzer already exists in $region: $analyzer_name"
        return 0
    fi

    apply aws_region "$region" accessanalyzer create-analyzer \
        --analyzer-name "$ACCOUNT_ANALYZER_NAME" \
        --type ACCOUNT >/dev/null
    info "Created account-level Access Analyzer in $region"
}

ensure_ebs_encryption_region() {
    local region="$1"
    local enabled

    enabled=$(aws_region "$region" ec2 get-ebs-encryption-by-default \
        --query 'EbsEncryptionByDefault' --output text 2>/dev/null || true)

    if [[ "$enabled" == "True" ]]; then
        info "EBS encryption by default already enabled in $region"
        return 0
    fi

    apply aws_region "$region" ec2 enable-ebs-encryption-by-default >/dev/null
    info "Enabled EBS encryption by default in $region"
}

ensure_detective() {
    local graph_arn

    graph_arn=$(aws_home detective list-graphs --query 'GraphList[0].Arn' --output text 2>/dev/null || true)

    if [[ -n "$graph_arn" && "$graph_arn" != "None" ]]; then
        info "Detective already enabled in $HOME_REGION"
        return 0
    fi

    apply aws_home detective create-graph >/dev/null
    info "Enabled Detective in $HOME_REGION"
}

DRY_RUN=false
WARNING_COUNT=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            fatal "Unknown option: $1"
            ;;
    esac
    shift
done

ENABLE_S3_BLOCK_PUBLIC_ACCESS="${ENABLE_S3_BLOCK_PUBLIC_ACCESS:-true}"
ENABLE_EBS_ENCRYPTION="${ENABLE_EBS_ENCRYPTION:-true}"
ENABLE_CLOUDTRAIL="${ENABLE_CLOUDTRAIL:-true}"
ENABLE_CONFIG="${ENABLE_CONFIG:-true}"
ENABLE_SECURITY_HUB="${ENABLE_SECURITY_HUB:-true}"
ENABLE_SECURITY_HUB_AGGREGATION="${ENABLE_SECURITY_HUB_AGGREGATION:-true}"
ENABLE_GUARDDUTY="${ENABLE_GUARDDUTY:-true}"
ENABLE_GUARDDUTY_RUNTIME_MONITORING="${ENABLE_GUARDDUTY_RUNTIME_MONITORING:-true}"
ENABLE_INSPECTOR="${ENABLE_INSPECTOR:-true}"
ENABLE_ACCESS_ANALYZER="${ENABLE_ACCESS_ANALYZER:-true}"
ENABLE_DETECTIVE="${ENABLE_DETECTIVE:-true}"

HOME_REGION="${HOME_REGION:-${AWS_REGION:-${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null || true)}}}"
HOME_REGION="${HOME_REGION:-us-east-1}"
TRAIL_NAME="${TRAIL_NAME:-awsutils-account-baseline}"
LOG_PREFIX="${LOG_PREFIX:-account-baseline}"
CONFIG_ROLE_NAME="${CONFIG_ROLE_NAME:-awsutils-account-config-role}"
DEFAULT_RECORDER_NAME="${DEFAULT_RECORDER_NAME:-default}"
DEFAULT_DELIVERY_CHANNEL_NAME="${DEFAULT_DELIVERY_CHANNEL_NAME:-default}"
ACCOUNT_ANALYZER_NAME="${ACCOUNT_ANALYZER_NAME:-awsutils-account-analyzer}"
CONFIG_SNAPSHOT_FREQUENCY="${CONFIG_SNAPSHOT_FREQUENCY:-TwentyFour_Hours}"
GUARDDUTY_FINDING_FREQUENCY="${GUARDDUTY_FINDING_FREQUENCY:-FIFTEEN_MINUTES}"
INSPECTOR_RESOURCE_TYPES="${INSPECTOR_RESOURCE_TYPES:-EC2 ECR LAMBDA LAMBDA_CODE}"

ACCOUNT_ID=$(aws --no-cli-pager sts get-caller-identity --query 'Account' --output text) || fatal "Unable to resolve AWS account identity"
CALLER_ARN=$(aws --no-cli-pager sts get-caller-identity --query 'Arn' --output text) || fatal "Unable to resolve caller ARN"
IFS=':' read -r _ PARTITION _ _ _ _ <<< "$CALLER_ARN"
PARTITION="${PARTITION:-aws}"
LOG_BUCKET_NAME="${LOG_BUCKET_NAME:-awsutils-accinit-${ACCOUNT_ID}-${HOME_REGION}}"
CONFIG_ROLE_ARN=""

mapfile -t REGIONS < <(aws_home ec2 describe-regions \
    --all-regions \
    --query "Regions[?OptInStatus=='opt-in-not-required'||OptInStatus=='opted-in'].RegionName" \
    --output text | tr '\t' '\n' | LC_ALL=C sort)

if [[ ${#REGIONS[@]} -eq 0 ]]; then
    fatal "No enabled AWS regions were discovered"
fi

info "Account: $ACCOUNT_ID"
info "Home region: $HOME_REGION"
info "Enabled regions: ${REGIONS[*]}"

if is_true "$ENABLE_S3_BLOCK_PUBLIC_ACCESS"; then
    run_nonfatal "Unable to enforce account-level S3 Block Public Access" ensure_account_public_access_block
fi

if is_true "$ENABLE_CLOUDTRAIL" || is_true "$ENABLE_CONFIG"; then
    ensure_log_bucket
fi

if is_true "$ENABLE_CLOUDTRAIL"; then
    ensure_cloudtrail
fi

if is_true "$ENABLE_CONFIG"; then
    ensure_config_role
    for region in "${REGIONS[@]}"; do
        run_nonfatal "AWS Config setup failed in $region" ensure_config_region "$region"
    done
fi

if is_true "$ENABLE_EBS_ENCRYPTION"; then
    for region in "${REGIONS[@]}"; do
        run_nonfatal "EBS encryption baseline failed in $region" ensure_ebs_encryption_region "$region"
    done
fi

if is_true "$ENABLE_SECURITY_HUB"; then
    for region in "${REGIONS[@]}"; do
        run_nonfatal "Security Hub setup failed in $region" ensure_security_hub_region "$region"
    done

    if is_true "$ENABLE_SECURITY_HUB_AGGREGATION"; then
        run_nonfatal "Security Hub finding aggregation could not be configured" ensure_security_hub_aggregation
    fi
fi

if is_true "$ENABLE_GUARDDUTY"; then
    for region in "${REGIONS[@]}"; do
        run_nonfatal "GuardDuty setup failed in $region" ensure_guardduty_region "$region"
    done
fi

if is_true "$ENABLE_INSPECTOR"; then
    for region in "${REGIONS[@]}"; do
        run_nonfatal "Inspector setup failed in $region" ensure_inspector_region "$region"
    done
fi

if is_true "$ENABLE_ACCESS_ANALYZER"; then
    for region in "${REGIONS[@]}"; do
        run_nonfatal "Access Analyzer setup failed in $region" ensure_access_analyzer_region "$region"
    done
fi

if is_true "$ENABLE_DETECTIVE"; then
    run_nonfatal "Detective setup failed in $HOME_REGION" ensure_detective
fi

printf '%b========== SUMMARY ==========%b\n' "$CYAN" "$NC"
printf 'Account ID: %s\n' "$ACCOUNT_ID"
printf 'Home region: %s\n' "$HOME_REGION"
printf 'Regions: %s\n' "${REGIONS[*]}"

if is_true "$ENABLE_CLOUDTRAIL" || is_true "$ENABLE_CONFIG"; then
    printf 'Log bucket: %s\n' "$LOG_BUCKET_NAME"
fi

if is_true "$ENABLE_CLOUDTRAIL"; then
    printf 'CloudTrail trail: %s\n' "$TRAIL_NAME"
fi

printf 'Warnings: %s\n' "$WARNING_COUNT"

warn "Manual follow-up still required for root MFA, no root access keys, IAM Identity Center/SSO, and Organizations/SCP guardrails"
