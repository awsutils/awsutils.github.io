#!/bin/bash
set -euo pipefail

export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off

info()  { printf '%s\n' "$*"; }
warn()  { printf 'warn: %s\n' "$*" >&2; }
fatal() { printf 'error: %s\n' "$*" >&2; exit 1; }

record_warning() {
    warn "$*"
    WARNING_COUNT=$((WARNING_COUNT + 1))
}

show_help() {
    cat <<'EOF'
Usage: accinit.sh [--dry-run] [--help]

Applies a non-interactive single-account AWS security baseline in us-east-1.

Actions:
  S3 account-level block public access
  EBS default encryption
  CloudTrail multi-region trail
  AWS Config recorder and delivery channel
  Security Hub with finding aggregation
  GuardDuty with runtime monitoring
  Inspector
  IAM Access Analyzer
  Detective

Environment variables:
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
  LOG_BUCKET_NAME=my-dedicated-bucket
EOF
}

is_true() {
    [[ "${1:-false}" =~ ^([Tt][Rr][Uu][Ee]|1|[Yy][Ee][Ss])$ ]]
}

apply() {
    if [[ "$DRY_RUN" == true ]]; then
        printf 'dry-run:' >&2
        printf ' %q' "$@" >&2
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

    record_warning "$description"
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
        info "account-level S3 block public access already enabled"
        return 0
    fi

    if ! apply aws_home s3control put-public-access-block \
        --account-id "$ACCOUNT_ID" \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true; then
        return 1
    fi

    info "enabled account-level S3 block public access"
}

ensure_log_bucket() {
    local encryption_config

    encryption_config='{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

    if aws_home s3api head-bucket --bucket "$LOG_BUCKET_NAME" >/dev/null 2>&1; then
        info "using existing log bucket $LOG_BUCKET_NAME"
    else
        info "creating log bucket $LOG_BUCKET_NAME"
        apply aws_home s3api create-bucket --bucket "$LOG_BUCKET_NAME" >/dev/null || return 1
    fi

    apply aws_home s3api put-public-access-block \
        --bucket "$LOG_BUCKET_NAME" \
        --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null || return 1

    apply aws_home s3api put-bucket-versioning \
        --bucket "$LOG_BUCKET_NAME" \
        --versioning-configuration Status=Enabled >/dev/null || return 1

    apply aws_home s3api put-bucket-encryption \
        --bucket "$LOG_BUCKET_NAME" \
        --server-side-encryption-configuration "$encryption_config" >/dev/null || return 1

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
        --policy "file://$TMP_DIR/log-bucket-policy.json" >/dev/null || return 1

    info "configured log bucket $LOG_BUCKET_NAME"
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
            --enable-log-file-validation >/dev/null || return 1
        apply aws_region "$named_trail_home_region" cloudtrail start-logging --name "$TRAIL_NAME" >/dev/null || return 1
        info "updated and started CloudTrail trail $TRAIL_NAME"
        return 0
    fi

    existing_multi_region=$(aws_home cloudtrail describe-trails \
        --query 'trailList[?IsMultiRegionTrail==`true`].Name | [0]' \
        --output text 2>/dev/null || true)

    if [[ -n "$existing_multi_region" && "$existing_multi_region" != "None" ]]; then
        info "existing multi-region CloudTrail trail detected: $existing_multi_region — leaving unchanged"
        return 0
    fi

    apply aws_home cloudtrail create-trail \
        --name "$TRAIL_NAME" \
        --s3-bucket-name "$LOG_BUCKET_NAME" \
        --s3-key-prefix "$LOG_PREFIX/cloudtrail" \
        --is-multi-region-trail \
        --include-global-service-events \
        --enable-log-file-validation >/dev/null || return 1

    apply aws_home cloudtrail start-logging --name "$TRAIL_NAME" >/dev/null || return 1
    info "created and started CloudTrail trail $TRAIL_NAME"
}

ensure_config_role() {
    local role_arn

    role_arn=$(aws_home iam get-role --role-name "$CONFIG_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)

    if [[ -n "$role_arn" && "$role_arn" != "None" ]]; then
        CONFIG_ROLE_ARN="$role_arn"
        info "using existing Config role $CONFIG_ROLE_NAME"
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
            --assume-role-policy-document "file://$TMP_DIR/config-role-trust.json" >/dev/null || return 1

        if [[ "$DRY_RUN" != true ]]; then
            sleep 10
        fi

        CONFIG_ROLE_ARN=$(aws_home iam get-role --role-name "$CONFIG_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)
        [[ -n "$CONFIG_ROLE_ARN" && "$CONFIG_ROLE_ARN" != "None" ]] || return 1
        info "created Config role $CONFIG_ROLE_NAME"
    fi

    apply aws_home iam attach-role-policy \
        --role-name "$CONFIG_ROLE_NAME" \
        --policy-arn "arn:${PARTITION}:iam::aws:policy/service-role/AWS_ConfigRole" >/dev/null || return 1

    if [[ "$DRY_RUN" != true ]]; then
        CONFIG_ROLE_ARN=$(aws_home iam get-role --role-name "$CONFIG_ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)
        [[ -n "$CONFIG_ROLE_ARN" && "$CONFIG_ROLE_ARN" != "None" ]] || return 1
    fi

    info "attached AWS managed Config policy to $CONFIG_ROLE_NAME"
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
        delivery_channel_name=$(aws_region "$region" configservice describe-delivery-channels --query 'DeliveryChannels[0].name' --output text 2>/dev/null || true)
        [[ -n "$delivery_channel_name" && "$delivery_channel_name" != "None" ]] || return 1
        info "created AWS Config delivery channel in $region"
    else
        info "AWS Config delivery channel already exists in $region: $delivery_channel_name"
    fi

    if [[ -z "$recorder_name" || "$recorder_name" == "None" ]]; then
        [[ -n "$CONFIG_ROLE_ARN" && "$CONFIG_ROLE_ARN" != "None" ]] || return 1
        apply aws_region "$region" configservice put-configuration-recorder \
            --configuration-recorder "name=${DEFAULT_RECORDER_NAME},roleARN=${CONFIG_ROLE_ARN}" \
            --recording-group allSupported=true,includeGlobalResourceTypes=false >/dev/null || return 1
        recorder_name=$(aws_region "$region" configservice describe-configuration-recorders --query 'ConfigurationRecorders[0].name' --output text 2>/dev/null || true)
        [[ -n "$recorder_name" && "$recorder_name" != "None" ]] || return 1
        info "created AWS Config recorder in $region"
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
        --configuration-recorder-name "$recorder_name" >/dev/null || return 1
    info "started AWS Config recorder in $region"
}

ensure_security_hub_region() {
    local region="$1"

    if aws_region "$region" securityhub describe-hub >/dev/null 2>&1; then
        info "Security Hub already enabled in $region"
        return 0
    fi

    apply aws_region "$region" securityhub enable-security-hub \
        --enable-default-standards \
        --control-finding-generator SECURITY_CONTROL >/dev/null || return 1
    info "enabled Security Hub in $region"
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
        --region-linking-mode ALL_REGIONS >/dev/null || return 1
    info "enabled Security Hub finding aggregation in $HOME_REGION"
}

ensure_guardduty_region() {
    local region="$1"
    local detector_id

    detector_id=$(aws_region "$region" guardduty list-detectors --query 'DetectorIds[0]' --output text 2>/dev/null || true)

    if [[ -z "$detector_id" || "$detector_id" == "None" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            info "dry-run: would create GuardDuty detector in $region"
            detector_id="DRYRUN"
        else
            detector_id=$(apply aws_region "$region" guardduty create-detector \
                --enable \
                --finding-publishing-frequency "$GUARDDUTY_FINDING_FREQUENCY" \
                --query 'DetectorId' --output text) || return 1
            [[ -n "$detector_id" && "$detector_id" != "None" ]] || return 1
            info "enabled GuardDuty in $region"
        fi
    else
        apply aws_region "$region" guardduty update-detector \
            --detector-id "$detector_id" \
            --enable \
            --finding-publishing-frequency "$GUARDDUTY_FINDING_FREQUENCY" >/dev/null || return 1
        info "updated GuardDuty detector in $region"
    fi

    if ! is_true "$ENABLE_GUARDDUTY_RUNTIME_MONITORING"; then
        return 0
    fi

    if [[ "$detector_id" == "DRYRUN" ]]; then
        info "dry-run: would enable GuardDuty runtime monitoring in $region"
        return 0
    fi

    apply aws_region "$region" guardduty update-detector \
        --detector-id "$detector_id" \
        --features 'Name=RUNTIME_MONITORING,Status=ENABLED,AdditionalConfiguration=[{Name=EC2_AGENT_MANAGEMENT,Status=ENABLED},{Name=ECS_FARGATE_AGENT_MANAGEMENT,Status=ENABLED},{Name=EKS_ADDON_MANAGEMENT,Status=ENABLED}]' >/dev/null || return 1
    info "enabled GuardDuty runtime monitoring in $region"
}

ensure_inspector_region() {
    local region="$1"
    local output
    local -a resource_types

    read -r -a resource_types <<< "$INSPECTOR_RESOURCE_TYPES"

    if [[ "$DRY_RUN" == true ]]; then
        info "dry-run: would enable Inspector in $region"
        return 0
    fi

    if output=$(retry aws_region "$region" inspector2 enable --resource-types "${resource_types[@]}" 2>&1); then
        info "enabled Inspector in $region"
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
        info "account-level Access Analyzer already exists in $region: $analyzer_name"
        return 0
    fi

    apply aws_region "$region" accessanalyzer create-analyzer \
        --analyzer-name "$ACCOUNT_ANALYZER_NAME" \
        --type ACCOUNT >/dev/null || return 1
    info "created account-level Access Analyzer in $region"
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

    apply aws_region "$region" ec2 enable-ebs-encryption-by-default >/dev/null || return 1
    info "enabled EBS encryption by default in $region"
}

ensure_detective() {
    local graph_arn

    graph_arn=$(aws_home detective list-graphs --query 'GraphList[0].Arn' --output text 2>/dev/null || true)

    if [[ -n "$graph_arn" && "$graph_arn" != "None" ]]; then
        info "Detective already enabled in $HOME_REGION"
        return 0
    fi

    apply aws_home detective create-graph >/dev/null || return 1
    info "enabled Detective in $HOME_REGION"
}

DRY_RUN=false
WARNING_COUNT=0
LOG_BUCKET_READY=false
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
            fatal "unknown option: $1"
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
HOME_REGION="us-east-1"
TRAIL_NAME="${TRAIL_NAME:-awsutils-account-baseline}"
LOG_PREFIX="${LOG_PREFIX:-account-baseline}"
CONFIG_ROLE_NAME="${CONFIG_ROLE_NAME:-awsutils-account-config-role}"
DEFAULT_RECORDER_NAME="${DEFAULT_RECORDER_NAME:-default}"
DEFAULT_DELIVERY_CHANNEL_NAME="${DEFAULT_DELIVERY_CHANNEL_NAME:-default}"
ACCOUNT_ANALYZER_NAME="${ACCOUNT_ANALYZER_NAME:-awsutils-account-analyzer}"
CONFIG_SNAPSHOT_FREQUENCY="${CONFIG_SNAPSHOT_FREQUENCY:-TwentyFour_Hours}"
GUARDDUTY_FINDING_FREQUENCY="${GUARDDUTY_FINDING_FREQUENCY:-FIFTEEN_MINUTES}"
INSPECTOR_RESOURCE_TYPES="${INSPECTOR_RESOURCE_TYPES:-EC2 ECR LAMBDA LAMBDA_CODE}"

ACCOUNT_ID=$(aws --no-cli-pager sts get-caller-identity --query 'Account' --output text) || fatal "unable to resolve AWS account identity"
CALLER_ARN=$(aws --no-cli-pager sts get-caller-identity --query 'Arn' --output text) || fatal "unable to resolve caller ARN"
IFS=':' read -r _ PARTITION _ _ _ _ <<< "$CALLER_ARN"
PARTITION="${PARTITION:-aws}"
LOG_BUCKET_NAME="${LOG_BUCKET_NAME:-awsutils-accinit-${ACCOUNT_ID}-${HOME_REGION}}"
CONFIG_ROLE_ARN=""

REGIONS=("us-east-1")

info "account: $ACCOUNT_ID  region: $HOME_REGION"

if is_true "$ENABLE_S3_BLOCK_PUBLIC_ACCESS"; then
    run_nonfatal "unable to enforce account-level S3 block public access" ensure_account_public_access_block
fi

if is_true "$ENABLE_CLOUDTRAIL" || is_true "$ENABLE_CONFIG"; then
    if ensure_log_bucket; then
        LOG_BUCKET_READY=true
    else
        record_warning "shared log bucket setup failed; skipping dependent CloudTrail and AWS Config steps"
    fi
fi

if is_true "$ENABLE_CLOUDTRAIL"; then
    if [[ "$LOG_BUCKET_READY" == true ]]; then
        run_nonfatal "CloudTrail setup failed in $HOME_REGION" ensure_cloudtrail
    else
        record_warning "CloudTrail skipped because the shared log bucket is not available"
    fi
fi

if is_true "$ENABLE_CONFIG"; then
    if [[ "$LOG_BUCKET_READY" != true ]]; then
        record_warning "AWS Config skipped because the shared log bucket is not available"
    elif ensure_config_role; then
        for region in "${REGIONS[@]}"; do
            run_nonfatal "AWS Config setup failed in $region" ensure_config_region "$region"
        done
    else
        record_warning "AWS Config role setup failed; skipping regional Config recorder setup"
    fi
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

printf 'account: %s\n' "$ACCOUNT_ID"
printf 'region: %s\n' "$HOME_REGION"

if is_true "$ENABLE_CLOUDTRAIL" || is_true "$ENABLE_CONFIG"; then
    printf 'log bucket: %s\n' "$LOG_BUCKET_NAME"
fi

if is_true "$ENABLE_CLOUDTRAIL"; then
    printf 'CloudTrail trail: %s\n' "$TRAIL_NAME"
fi

printf 'warnings: %d\n' "$WARNING_COUNT"

warn "manual follow-up required: root MFA, no root access keys, IAM Identity Center/SSO, Organizations/SCP guardrails"
