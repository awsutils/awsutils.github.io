#!/bin/bash
set -e

# ── Configurable defaults (override: VAR=value curl ... | sh -) ────────────
SCRIPT_URL="${SCRIPT_URL:-https://awsutils.github.io/init.sh}"
LOG_FILE="${LOG_FILE:-/var/log/init.log}"
APP_DIR="${APP_DIR:-/opt/app}"
APP_LOG="${APP_LOG:-/var/log/app.log}"

# ── Helpers ────────────────────────────────────────────────────────────────
info()  { printf '[INFO] %s\n' "$*"; }
warn()  { printf '[WARN] %s\n' "$*" >&2; }
fatal() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

is_cloudshell() { [ "${AWS_EXECUTION_ENV:-}" = "CloudShell" ]; }

# ── Step 1: Self-elevate as root and background ────────────────────────────
if [ "$(id -u)" != "0" ]; then
    info "Re-executing as root in background (output → $LOG_FILE)..."
    curl -fsSL "$SCRIPT_URL" -o /tmp/_init.sh
    chmod +x /tmp/_init.sh
    nohup sudo bash /tmp/_init.sh > /dev/null 2>&1 &
    disown
    sleep 1
    clear
    printf 'Initialization running in background.\nTail logs: tail -f %s\n' "$LOG_FILE"
    exit 0
fi

# Running as root — redirect all subsequent output to log file
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1
info "=== init.sh started at $(date) ==="

# ── Step 2: Check system requirements ─────────────────────────────────────
detect_arch() {
    case $(uname -m) in
        x86_64)  ARCH="amd64";  ARCH_LARGE="x86_64" ;;
        aarch64) ARCH="arm64"; ARCH_LARGE="aarch64" ;;
        *) fatal "Unsupported architecture: $(uname -m)" ;;
    esac
    info "Architecture: $ARCH"
}

check_os() {
    case $(uname -r) in
        *amzn2023*) OS_VARIANT="al2023" ;;
        *amzn2*)    OS_VARIANT="al2" ;;
        *) warn "Unknown OS; assuming al2023"; OS_VARIANT="al2023" ;;
    esac
    info "OS variant: $OS_VARIANT"
}

install_prereqs() {
    if [ "$OS_VARIANT" = "al2023" ]; then
        dnf install -y tar zip unzip wget git jq
    else
        yum install -y tar zip unzip curl wget git jq
    fi
}

detect_arch
check_os
install_prereqs

# ── Step 3: CloudWatch Agent ───────────────────────────────────────────────
install_cloudwatch_agent() {
    if [ "$OS_VARIANT" = "al2023" ]; then
        dnf install -y amazon-cloudwatch-agent
    else
        yum install -y amazon-cloudwatch-agent
    fi

    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d

    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/config.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app.log",
            "log_group_class": "STANDARD",
            "log_group_name": "/app/output",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  },
  "metrics": {
    "aggregation_dimensions": [["InstanceId"]],
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "ImageId": "${aws:ImageId}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

    systemctl enable --now amazon-cloudwatch-agent
    info "CloudWatch Agent installed and started"
}

# ── Step 4: Download application binary ───────────────────────────────────
APP_DOWNLOADED=false

download_app() {
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
        warn "Could not resolve AWS account ID; skipping app download"
        return 0
    }

    local s3_bucket="s3://appbinary-${account_id}"
    mkdir -p "$APP_DIR"
    touch "$APP_LOG"

    if aws s3 cp "${s3_bucket}/app.zip" /tmp/app.zip 2>/dev/null; then
        info "Downloaded app.zip; extracting to $APP_DIR"
        unzip -o /tmp/app.zip -d "$APP_DIR"
        rm -f /tmp/app.zip
        APP_DOWNLOADED=true
    elif aws s3 cp "${s3_bucket}/app" "${APP_DIR}/app" 2>/dev/null; then
        info "Downloaded app binary"
        APP_DOWNLOADED=true
    else
        warn "No application binary found in ${s3_bucket}; skipping"
        return 0
    fi

    find "$APP_DIR" -name "*.sh" -exec chmod +x {} \;
    find "$APP_DIR" -maxdepth 1 -type f \
        ! -name "*.env" ! -name "*.json" ! -name "*.yaml" ! -name "*.yml" \
        -exec chmod +x {} \;

    if aws s3 cp "${s3_bucket}/app.env" "${APP_DIR}/app.env" 2>/dev/null; then
        info "Downloaded app.env"
    else
        touch "${APP_DIR}/app.env"
    fi

    info "Application downloaded to $APP_DIR"
}

# ── Step 5: Systemd service ────────────────────────────────────────────────
setup_app_service() {
    local exec_start

    if [ -f "${APP_DIR}/start.sh" ]; then
        exec_start="${APP_DIR}/start.sh"
    elif [ -f "${APP_DIR}/app" ]; then
        exec_start="${APP_DIR}/app"
    else
        warn "No start.sh or app binary in $APP_DIR; skipping service setup"
        return 0
    fi

    cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Application
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/app.env
ExecStart=${exec_start}
StandardOutput=append:${APP_LOG}
StandardError=append:${APP_LOG}

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now app
    info "Application service installed and started"
}

# ── Step 6: File watcher ───────────────────────────────────────────────────
setup_app_watcher() {
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || return 0

    cat > /usr/local/bin/app-watcher.sh << EOF
#!/bin/bash
ACCOUNT_ID="${account_id}"
APP_DIR="${APP_DIR}"

check_and_update() {
    local updated=false new_hash current_hash

    if aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app.zip" > /dev/null 2>&1; then
        new_hash=\$(aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app.zip" --query 'ETag' --output text 2>/dev/null || true)
        current_hash=\$(cat /var/run/app-zip-etag 2>/dev/null || true)
        if [ -n "\$new_hash" ] && [ "\$new_hash" != "\$current_hash" ]; then
            aws s3 cp "s3://appbinary-\${ACCOUNT_ID}/app.zip" /tmp/app.zip
            unzip -o /tmp/app.zip -d "\${APP_DIR}"
            find "\${APP_DIR}" -name "*.sh" -exec chmod +x {} \;
            rm -f /tmp/app.zip
            echo "\$new_hash" > /var/run/app-zip-etag
            updated=true
        fi
    elif aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app" > /dev/null 2>&1; then
        new_hash=\$(aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app" --query 'ETag' --output text 2>/dev/null || true)
        current_hash=\$(cat /var/run/app-bin-etag 2>/dev/null || true)
        if [ -n "\$new_hash" ] && [ "\$new_hash" != "\$current_hash" ]; then
            aws s3 cp "s3://appbinary-\${ACCOUNT_ID}/app" "\${APP_DIR}/app"
            chmod +x "\${APP_DIR}/app"
            echo "\$new_hash" > /var/run/app-bin-etag
            updated=true
        fi
    fi

    if aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app.env" > /dev/null 2>&1; then
        new_hash=\$(aws s3api head-object --bucket "appbinary-\${ACCOUNT_ID}" --key "app.env" --query 'ETag' --output text 2>/dev/null || true)
        current_hash=\$(cat /var/run/app-env-etag 2>/dev/null || true)
        if [ -n "\$new_hash" ] && [ "\$new_hash" != "\$current_hash" ]; then
            aws s3 cp "s3://appbinary-\${ACCOUNT_ID}/app.env" "\${APP_DIR}/app.env"
            echo "\$new_hash" > /var/run/app-env-etag
            updated=true
        fi
    fi

    [ "\$updated" = "true" ] && systemctl restart app 2>/dev/null || true
}

while true; do
    sleep 60
    check_and_update
done
EOF
    chmod +x /usr/local/bin/app-watcher.sh

    cat > /etc/systemd/system/app-watcher.service << 'EOF'
[Unit]
Description=Application S3 file watcher
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/app-watcher.sh

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now app-watcher
    info "App watcher service installed and started"
}

# ── Step 7: Bastion tools ─────────────────────────────────────────────────
install_bastion_tools() {
    if [ "$OS_VARIANT" = "al2023" ]; then
        dnf install -y amazon-efs-utils dnf-plugins-core
        dnf install -y --allowerasing curl
        dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        dnf install -y terraform
    else
        yum install -y amazon-efs-utils yum-utils
        yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        yum install -y terraform
    fi

    # AWS CLI v2
    if ! aws --version 2>&1 | grep -q 'aws-cli/2'; then
        curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_LARGE}.zip" -o /tmp/awscliv2.zip
        unzip -o /tmp/awscliv2.zip -d /tmp/awscli
        /tmp/awscli/aws/install --update
        rm -rf /tmp/awscliv2.zip /tmp/awscli
        info "AWS CLI v2 installed"
    fi

    # kubectl
    local k8s_version
    k8s_version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
    curl -fsSL "https://dl.k8s.io/release/${k8s_version}/bin/linux/${ARCH}/kubectl" -o /tmp/kubectl
    install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
    rm -f /tmp/kubectl

    # eksctl
    curl -fsSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_${ARCH}.tar.gz" | tar xz -C /tmp
    install -o root -g root -m 0755 /tmp/eksctl /usr/local/bin/eksctl
    rm -f /tmp/eksctl

    # helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # k9s
    curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz" | tar xz -C /tmp
    install -o root -g root -m 0755 /tmp/k9s /usr/local/bin/k9s
    rm -f /tmp/k9s

    info "Bastion tools installed (terraform, kubectl, eksctl, helm, k9s, awscli v2)"
}

# ── Step 8: Docker ────────────────────────────────────────────────────────
setup_docker() {
    if ! is_cloudshell; then
        if [ "$OS_VARIANT" = "al2023" ]; then
            dnf install -y docker
        else
            amazon-linux-extras install -y docker
        fi
        systemctl enable --now docker
    fi

    # Cross-platform (QEMU binfmt) support
    mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
    docker run --privileged --rm tonistiigi/binfmt --install all

    if ! is_cloudshell; then
        cat > /etc/systemd/system/binfmt-qemu.service << 'EOF'
[Unit]
Description=Register QEMU binfmt handlers for multi-arch builds
After=docker.service proc-sys-fs-binfmt_misc.mount
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --privileged --rm tonistiigi/binfmt --install all

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable binfmt-qemu
        usermod -aG docker ec2-user  2>/dev/null || true
        usermod -aG docker ssm-user  2>/dev/null || true
    fi

    info "Docker configured (cross-platform support)"
}

# ── Step 9: Utility commands ───────────────────────────────────────────────
install_ecr_command() {
    cat > /usr/local/bin/ecr << 'EOF'
#!/bin/bash
# ecr <repository_name> [tag]
# Login to ECR, build Dockerfile in current directory, and push.
set -e
REPO=${1:?Usage: ecr <repository_name> [tag]}
TAG=${2:-latest}
REGION=$(aws configure get region 2>/dev/null || echo "${AWS_DEFAULT_REGION:-us-east-1}")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr create-repository --repository-name "$REPO" --region "$REGION" 2>/dev/null || true
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"
docker build -t "${REGISTRY}/${REPO}:${TAG}" .
docker push "${REGISTRY}/${REPO}:${TAG}"
printf 'Pushed: %s/%s:%s\n' "$REGISTRY" "$REPO" "$TAG"
EOF
    chmod +x /usr/local/bin/ecr
    info "Installed: ecr"
}

install_accbp_command() {
    cat > /usr/local/bin/accbp << 'EOF'
#!/bin/bash
# Enable AWS security baseline: Config, GuardDuty, SecurityHub, CloudTrail, etc.
exec curl -fsSL https://awsutils.github.io/accinit.sh | bash -s -- "$@"
EOF
    chmod +x /usr/local/bin/accbp
    info "Installed: accbp"
}

install_vpc_command() {
    cat > /usr/local/bin/vpc << 'EOF'
#!/bin/bash
# Enable common VPC endpoints and flow logs for every VPC in this region.
# Usage: vpc
# Override: CW_RETENTION=<days> vpc
set -e

export AWS_PAGER=""
REGION=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text)
CW_RETENTION="${CW_RETENTION:-7}"

info()  { printf '[INFO] %s\n' "$*"; }
warn()  { printf '[WARN] %s\n' "$*" >&2; }

GATEWAY_SERVICES=(
    "com.amazonaws.${REGION}.s3"
    "com.amazonaws.${REGION}.dynamodb"
)

INTERFACE_SERVICES=(
    "com.amazonaws.${REGION}.ecr.dkr"
    "com.amazonaws.${REGION}.ecr.api"
    "com.amazonaws.${REGION}.ssm"
    "com.amazonaws.${REGION}.ssmmessages"
    "com.amazonaws.${REGION}.ec2messages"
    "com.amazonaws.${REGION}.sqs"
    "com.amazonaws.${REGION}.sns"
)

FLOWLOG_ROLE_ARN=""

ensure_flowlog_role() {
    local role_name="vpc-flowlog-role"
    local role_arn

    role_arn=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text 2>/dev/null || true)
    if [ -n "$role_arn" ] && [ "$role_arn" != "None" ]; then
        FLOWLOG_ROLE_ARN="$role_arn"
        info "Using existing flow log role: $role_name"
        return 0
    fi

    aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"vpc-flow-logs.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
        > /dev/null

    aws iam put-role-policy \
        --role-name "$role_name" \
        --policy-name "vpc-flowlog-policy" \
        --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Resource":"*"}]}' \
        > /dev/null

    sleep 10  # IAM propagation
    FLOWLOG_ROLE_ARN=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text)
    info "Created flow log IAM role: $role_name"
}

setup_vpc() {
    local vpc_id="$1"
    local vpc_name vpc_cidr

    vpc_name=$(aws ec2 describe-vpcs --vpc-ids "$vpc_id" \
        --query 'Vpcs[0].Tags[?Key==`Name`].Value | [0]' --output text 2>/dev/null || true)
    [ -z "$vpc_name" ] || [ "$vpc_name" = "None" ] && vpc_name="$vpc_id"
    vpc_cidr=$(aws ec2 describe-vpcs --vpc-ids "$vpc_id" --query 'Vpcs[0].CidrBlock' --output text)

    info "--- $vpc_id ($vpc_name) ---"

    # All route tables
    local all_rt_ids
    all_rt_ids=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[*].RouteTableId' --output text)

    # Private subnets: no IGW route on their effective route table
    local all_subnets private_subnet_ids=""
    all_subnets=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[*].SubnetId' --output text)

    local main_rt_id
    main_rt_id=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=true" \
        --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || true)

    for subnet in $all_subnets; do
        local rt_id
        rt_id=$(aws ec2 describe-route-tables \
            --filters "Name=association.subnet-id,Values=$subnet" \
            --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || true)
        [ -z "$rt_id" ] || [ "$rt_id" = "None" ] && rt_id="$main_rt_id"
        local has_igw
        has_igw=$(aws ec2 describe-route-tables --route-table-ids "$rt_id" \
            --query 'RouteTables[0].Routes[?starts_with(GatewayId,`igw-`)].GatewayId | [0]' \
            --output text 2>/dev/null || true)
        [ -z "$has_igw" ] || [ "$has_igw" = "None" ] && private_subnet_ids="$private_subnet_ids $subnet"
    done
    private_subnet_ids=$(echo "$private_subnet_ids" | xargs)

    # Existing endpoints
    local existing
    existing=$(aws ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'VpcEndpoints[?State!=`deleted`].ServiceName' --output text)

    # Security group for interface endpoints
    local sg_name="${vpc_name}-vpce-sg" sg_id
    sg_id=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=${sg_name}" \
        --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)

    if [ -z "$sg_id" ] || [ "$sg_id" = "None" ]; then
        sg_id=$(aws ec2 create-security-group \
            --group-name "$sg_name" \
            --description "VPC Endpoints" \
            --vpc-id "$vpc_id" \
            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${sg_name}}]" \
            --query 'GroupId' --output text)
        aws ec2 authorize-security-group-ingress \
            --group-id "$sg_id" --protocol -1 --cidr "$vpc_cidr" > /dev/null
        info "Created SG: $sg_id"
    fi

    # Gateway endpoints (attach to all route tables)
    for svc in "${GATEWAY_SERVICES[@]}"; do
        local short="${svc##*.}"
        if echo "$existing" | grep -qw "$svc"; then
            info "$short: already exists"
            continue
        fi
        aws ec2 create-vpc-endpoint \
            --vpc-id "$vpc_id" \
            --service-name "$svc" \
            --vpc-endpoint-type Gateway \
            --route-table-ids $all_rt_ids \
            --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=${vpc_name}-vpce-${short}}]" \
            --query 'VpcEndpoint.VpcEndpointId' --output text > /dev/null
        info "Created gateway endpoint: $short"
    done

    # Interface endpoints (private subnets only)
    if [ -z "$private_subnet_ids" ]; then
        warn "$vpc_id: no private subnets; skipping interface endpoints"
    else
        for svc in "${INTERFACE_SERVICES[@]}"; do
            local short="${svc##*.}"
            if echo "$existing" | grep -qw "$svc"; then
                info "$short: already exists"
                continue
            fi
            aws ec2 create-vpc-endpoint \
                --vpc-id "$vpc_id" \
                --service-name "$svc" \
                --vpc-endpoint-type Interface \
                --subnet-ids $private_subnet_ids \
                --security-group-ids "$sg_id" \
                --private-dns-enabled \
                --tag-specifications "ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=${vpc_name}-vpce-${short}}]" \
                --query 'VpcEndpoint.VpcEndpointId' --output text > /dev/null 2>&1 \
                && info "Created interface endpoint: $short" \
                || warn "Failed to create interface endpoint: $short"
        done
    fi

    # VPC Flow Logs → CloudWatch Logs
    local log_group="/vpc/flowlogs/${vpc_id}"
    local existing_flowlog
    existing_flowlog=$(aws ec2 describe-flow-logs \
        --filter "Name=resource-id,Values=$vpc_id" "Name=log-destination-type,Values=cloud-watch-logs" \
        --query 'FlowLogs[0].FlowLogId' --output text 2>/dev/null || true)

    if [ -n "$existing_flowlog" ] && [ "$existing_flowlog" != "None" ]; then
        info "Flow logs already enabled for $vpc_id"
    else
        aws logs create-log-group --log-group-name "$log_group" 2>/dev/null || true
        aws logs put-retention-policy --log-group-name "$log_group" --retention-in-days "$CW_RETENTION" 2>/dev/null || true
        aws ec2 create-flow-logs \
            --resource-ids "$vpc_id" \
            --resource-type VPC \
            --traffic-type ALL \
            --log-destination-type cloud-watch-logs \
            --log-group-name "$log_group" \
            --deliver-logs-permission-arn "$FLOWLOG_ROLE_ARN" > /dev/null
        info "Flow logs → $log_group (${CW_RETENTION}d retention)"
    fi
}

ensure_flowlog_role

VPC_IDS=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text)
[ -z "$VPC_IDS" ] && { warn "No VPCs found"; exit 0; }

for vpc_id in $VPC_IDS; do
    setup_vpc "$vpc_id"
done
info "Done"
EOF
    chmod +x /usr/local/bin/vpc
    info "Installed: vpc"
}

# ── Main ───────────────────────────────────────────────────────────────────

if ! is_cloudshell; then
    install_cloudwatch_agent
    download_app
    if [ "$APP_DOWNLOADED" = "true" ]; then
        setup_app_service
        setup_app_watcher
    fi
fi

install_bastion_tools
setup_docker
install_ecr_command
install_accbp_command
install_vpc_command

info "=== init.sh complete at $(date) ==="
