#!/bin/bash

# VPC Creation Script
# Creates a complete VPC with public and private subnets, internet gateway, and optional NAT gateway

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

print_step() {
    echo -e "${BLUE}>>> $1${NC}"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Creates a complete VPC with public and private subnets across multiple availability zones.

Run without options for interactive mode (requires gum: https://github.com/charmbracelet/gum)

OPTIONS:
    -n, --name NAME              VPC name (required for non-interactive)
    -c, --cidr CIDR              VPC CIDR block (default: 10.0.0.0/16)
    -r, --region REGION          AWS region (default: from AWS CLI config)
    -z, --azs NUM                Number of availability zones (default: 2, max: 3)
    --nat-gateway TYPE           NAT Gateway type: none, single, per-az (default: single)
    --enable-dns-hostnames       Enable DNS hostnames (default: true)
    --enable-dns-support         Enable DNS support (default: true)
    --enable-flow-logs           Enable VPC Flow Logs to CloudWatch
    --ipv6                       Enable IPv6 support
    --dry-run                    Show what would be created without creating
    --interactive                Force interactive mode
    -h, --help                   Show this help message

NAT GATEWAY OPTIONS:
    none     - No NAT Gateway (private subnets have no internet access)
    single   - One NAT Gateway in first AZ (cost-effective, no HA)
    per-az   - One NAT Gateway per AZ (high availability, higher cost)

EXAMPLES:
    # Interactive mode (with gum installed)
    $0

    # Create basic VPC with default settings
    $0 --name my-vpc

    # Create VPC with custom CIDR and 3 AZs
    $0 --name my-vpc --cidr 172.16.0.0/16 --azs 3

    # Create VPC without NAT Gateway (cost optimization)
    $0 --name my-vpc --nat-gateway none

    # Create highly available VPC with NAT per AZ
    $0 --name my-vpc --nat-gateway per-az --azs 3

INSTALL GUM:
    # macOS
    brew install gum

    # Linux (download from GitHub releases)
    sudo wget https://github.com/charmbracelet/gum/releases/download/v0.13.0/gum_0.13.0_Linux_x86_64.tar.gz
    sudo tar -xzf gum_0.13.0_Linux_x86_64.tar.gz -C /usr/local/bin gum

EOF
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Default values
VPC_NAME=""
VPC_CIDR="10.0.0.0/16"
REGION=""
NUM_AZS=2
NAT_GATEWAY_TYPE="single"
ENABLE_DNS_HOSTNAMES="true"
ENABLE_DNS_SUPPORT="true"
ENABLE_FLOW_LOGS="false"
ENABLE_IPV6="false"
DRY_RUN="false"
INTERACTIVE_MODE="false"

# Check if gum is installed
HAS_GUM=false
if command -v gum &> /dev/null; then
    HAS_GUM=true
fi

# Parse arguments
if [ $# -eq 0 ]; then
    # No arguments provided, try interactive mode
    if [ "$HAS_GUM" = "true" ]; then
        INTERACTIVE_MODE="true"
    else
        print_error "No arguments provided and gum is not installed"
        echo ""
        print_info "Install gum for interactive mode:"
        echo "  https://github.com/charmbracelet/gum"
        echo ""
        print_usage
        exit 1
    fi
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            VPC_NAME="$2"
            shift 2
            ;;
        -c|--cidr)
            VPC_CIDR="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -z|--azs)
            NUM_AZS="$2"
            shift 2
            ;;
        --nat-gateway)
            NAT_GATEWAY_TYPE="$2"
            shift 2
            ;;
        --enable-dns-hostnames)
            ENABLE_DNS_HOSTNAMES="true"
            shift
            ;;
        --enable-dns-support)
            ENABLE_DNS_SUPPORT="true"
            shift
            ;;
        --enable-flow-logs)
            ENABLE_FLOW_LOGS="true"
            shift
            ;;
        --ipv6)
            ENABLE_IPV6="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --interactive)
            if [ "$HAS_GUM" = "true" ]; then
                INTERACTIVE_MODE="true"
            else
                print_error "gum is not installed. Cannot use interactive mode."
                exit 1
            fi
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Interactive mode using gum
if [ "$INTERACTIVE_MODE" = "true" ]; then
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'AWS VPC Creator' 'Interactive Mode'

    echo ""
    gum style --foreground 250 "Let's create your AWS VPC infrastructure!"
    echo ""

    # VPC Name
    VPC_NAME=$(gum input --placeholder "Enter VPC name (e.g., my-app-vpc)" --prompt "VPC Name: ")
    if [ -z "$VPC_NAME" ]; then
        print_error "VPC name is required"
        exit 1
    fi

    # Region selection
    if [ -z "$REGION" ]; then
        REGION=$(aws configure get region)
    fi

    gum style --foreground 250 "Select AWS region:"
    REGION=$(gum choose --selected="$REGION" \
        "us-east-1" "us-east-2" "us-west-1" "us-west-2" \
        "eu-west-1" "eu-west-2" "eu-central-1" \
        "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" \
        "Other (will use: $REGION)")

    if [ "$REGION" = "Other (will use: $REGION)" ]; then
        REGION=$(aws configure get region)
    fi

    # CIDR Block
    gum style --foreground 250 "Select VPC CIDR block:"
    CIDR_CHOICE=$(gum choose \
        "10.0.0.0/16 (65,536 IPs)" \
        "172.16.0.0/16 (65,536 IPs)" \
        "192.168.0.0/16 (65,536 IPs)" \
        "10.0.0.0/20 (4,096 IPs)" \
        "Custom")

    case $CIDR_CHOICE in
        "10.0.0.0/16"*)
            VPC_CIDR="10.0.0.0/16"
            ;;
        "172.16.0.0/16"*)
            VPC_CIDR="172.16.0.0/16"
            ;;
        "192.168.0.0/16"*)
            VPC_CIDR="192.168.0.0/16"
            ;;
        "10.0.0.0/20"*)
            VPC_CIDR="10.0.0.0/20"
            ;;
        "Custom")
            VPC_CIDR=$(gum input --placeholder "Enter CIDR (e.g., 10.0.0.0/16)" --prompt "CIDR: ")
            ;;
    esac

    # Number of AZs
    gum style --foreground 250 "How many Availability Zones?"
    NUM_AZS=$(gum choose "2 (Recommended)" "3 (Maximum HA)" "1 (Testing only)")
    NUM_AZS=$(echo $NUM_AZS | cut -d' ' -f1)

    # NAT Gateway type
    gum style --foreground 250 "Select NAT Gateway strategy:"
    gum style --foreground 243 "NAT Gateway enables internet access for private subnets"
    NAT_CHOICE=$(gum choose \
        "single - One NAT Gateway (~\$32/month, good for dev/staging)" \
        "per-az - NAT per AZ (~\$32/month per AZ, production HA)" \
        "none - No NAT Gateway (\$0, use VPC endpoints instead)")

    NAT_GATEWAY_TYPE=$(echo $NAT_CHOICE | cut -d' ' -f1)

    # Additional features
    gum style --foreground 250 "Select additional features (Space to select, Enter to confirm):"
    FEATURES=$(gum choose --no-limit \
        "Enable VPC Flow Logs (CloudWatch Logs costs apply)" \
        "Enable IPv6 support" \
        "Dry run (preview without creating)")

    if echo "$FEATURES" | grep -q "Flow Logs"; then
        ENABLE_FLOW_LOGS="true"
    fi

    if echo "$FEATURES" | grep -q "IPv6"; then
        ENABLE_IPV6="true"
    fi

    if echo "$FEATURES" | grep -q "Dry run"; then
        DRY_RUN="true"
    fi

    echo ""
    gum style --foreground 212 "Configuration Summary:"
    echo ""
    gum style --foreground 250 "  VPC Name: $VPC_NAME"
    gum style --foreground 250 "  CIDR Block: $VPC_CIDR"
    gum style --foreground 250 "  Region: $REGION"
    gum style --foreground 250 "  Availability Zones: $NUM_AZS"
    gum style --foreground 250 "  NAT Gateway: $NAT_GATEWAY_TYPE"
    gum style --foreground 250 "  Flow Logs: $ENABLE_FLOW_LOGS"
    gum style --foreground 250 "  IPv6: $ENABLE_IPV6"
    echo ""

    if [ "$DRY_RUN" != "true" ]; then
        gum confirm "Create VPC with these settings?" || exit 0
        echo ""
        gum spin --spinner dot --title "Starting VPC creation..." -- sleep 1
    fi
fi

# Validate required parameters
if [ -z "$VPC_NAME" ]; then
    print_error "VPC name is required"
    print_usage
    exit 1
fi

# Validate NAT Gateway type
if [[ ! "$NAT_GATEWAY_TYPE" =~ ^(none|single|per-az)$ ]]; then
    print_error "Invalid NAT Gateway type: $NAT_GATEWAY_TYPE (must be: none, single, or per-az)"
    exit 1
fi

# Validate number of AZs
if [ "$NUM_AZS" -lt 1 ] || [ "$NUM_AZS" -gt 3 ]; then
    print_error "Number of AZs must be between 1 and 3"
    exit 1
fi

# Get region if not specified
if [ -z "$REGION" ]; then
    REGION=$(aws configure get region)
    if [ -z "$REGION" ]; then
        print_error "Could not determine AWS region. Please specify with --region or configure AWS CLI"
        exit 1
    fi
fi

if [ "$INTERACTIVE_MODE" != "true" ]; then
    print_info "Configuration:"
    echo "  VPC Name: $VPC_NAME"
    echo "  VPC CIDR: $VPC_CIDR"
    echo "  Region: $REGION"
    echo "  Availability Zones: $NUM_AZS"
    echo "  NAT Gateway: $NAT_GATEWAY_TYPE"
    echo "  DNS Hostnames: $ENABLE_DNS_HOSTNAMES"
    echo "  DNS Support: $ENABLE_DNS_SUPPORT"
    echo "  Flow Logs: $ENABLE_FLOW_LOGS"
    echo "  IPv6: $ENABLE_IPV6"
    echo ""
fi

if [ "$DRY_RUN" = "true" ]; then
    print_info "DRY RUN MODE - No resources will be created"
    exit 0
fi

# Get available AZs
print_step "Getting available availability zones..."
AVAILABLE_AZS=($(aws ec2 describe-availability-zones \
    --region "$REGION" \
    --filters "Name=state,Values=available" \
    --query 'AvailabilityZones[0:3].ZoneName' \
    --output text))

if [ ${#AVAILABLE_AZS[@]} -lt "$NUM_AZS" ]; then
    print_error "Not enough availability zones available in $REGION"
    exit 1
fi

# Use only the requested number of AZs
AZS=("${AVAILABLE_AZS[@]:0:$NUM_AZS}")
print_success "Using AZs: ${AZS[*]}"

# Function to calculate subnet CIDR
calculate_subnet_cidr() {
    local vpc_cidr=$1
    local subnet_index=$2
    local base_ip=$(echo $vpc_cidr | cut -d'/' -f1)
    local base_prefix=$(echo $vpc_cidr | cut -d'/' -f2)

    # For /16 VPC, use /20 subnets (4096 IPs each)
    # Public subnets: 10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20
    # Private subnets: 10.0.128.0/20, 10.0.144.0/20, 10.0.160.0/20

    local octets=($(echo $base_ip | tr '.' ' '))
    local third_octet=${octets[2]}

    if [ $subnet_index -ge 10 ]; then
        # Private subnets (index 10+)
        local offset=$((128 + (subnet_index - 10) * 16))
    else
        # Public subnets (index 0-9)
        local offset=$((subnet_index * 16))
    fi

    echo "${octets[0]}.${octets[1]}.$offset.0/20"
}

# Step 1: Create VPC
print_step "Creating VPC..."
VPC_ID=$(aws ec2 vpc \
    --cidr-block "$VPC_CIDR" \
    --region "$REGION" \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" \
    --query 'Vpc.VpcId' \
    --output text)

if [ -z "$VPC_ID" ]; then
    print_error "Failed to create VPC"
    exit 1
fi
print_success "VPC created: $VPC_ID"

# Enable DNS settings
if [ "$ENABLE_DNS_HOSTNAMES" = "true" ]; then
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames --region "$REGION"
    print_success "DNS hostnames enabled"
fi

if [ "$ENABLE_DNS_SUPPORT" = "true" ]; then
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support --region "$REGION"
    print_success "DNS support enabled"
fi

# Enable IPv6 if requested
if [ "$ENABLE_IPV6" = "true" ]; then
    print_step "Enabling IPv6..."
    IPV6_CIDR=$(aws ec2 associate-vpc-cidr-block \
        --vpc-id "$VPC_ID" \
        --amazon-provided-ipv6-cidr-block \
        --region "$REGION" \
        --query 'Ipv6CidrBlock' \
        --output text)
    print_success "IPv6 CIDR associated: $IPV6_CIDR"
fi

# Step 2: Create Internet Gateway
print_step "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --region "$REGION" \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$VPC_NAME-igw}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)
print_success "Internet Gateway created: $IGW_ID"

aws ec2 attach-internet-gateway \
    --vpc-id "$VPC_ID" \
    --internet-gateway-id "$IGW_ID" \
    --region "$REGION"
print_success "Internet Gateway attached to VPC"

# Step 3: Create Subnets
PUBLIC_SUBNET_IDS=()
PRIVATE_SUBNET_IDS=()

for i in "${!AZS[@]}"; do
    AZ="${AZS[$i]}"

    # Create public subnet
    print_step "Creating public subnet in $AZ..."
    PUBLIC_CIDR=$(calculate_subnet_cidr "$VPC_CIDR" $i)
    PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id "$VPC_ID" \
        --cidr-block "$PUBLIC_CIDR" \
        --availability-zone "$AZ" \
        --region "$REGION" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$VPC_NAME-public-$AZ}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    PUBLIC_SUBNET_IDS+=("$PUBLIC_SUBNET_ID")
    print_success "Public subnet created: $PUBLIC_SUBNET_ID ($PUBLIC_CIDR)"

    # Enable auto-assign public IP for public subnets
    aws ec2 modify-subnet-attribute \
        --subnet-id "$PUBLIC_SUBNET_ID" \
        --map-public-ip-on-launch \
        --region "$REGION"

    # Create private subnet
    print_step "Creating private subnet in $AZ..."
    PRIVATE_CIDR=$(calculate_subnet_cidr "$VPC_CIDR" $((i + 10)))
    PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id "$VPC_ID" \
        --cidr-block "$PRIVATE_CIDR" \
        --availability-zone "$AZ" \
        --region "$REGION" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$VPC_NAME-private-$AZ}]" \
        --query 'Subnet.SubnetId' \
        --output text)
    PRIVATE_SUBNET_IDS+=("$PRIVATE_SUBNET_ID")
    print_success "Private subnet created: $PRIVATE_SUBNET_ID ($PRIVATE_CIDR)"
done

# Step 4: Create Public Route Table
print_step "Creating public route table..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-public}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)
print_success "Public route table created: $PUBLIC_RT_ID"

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id "$PUBLIC_RT_ID" \
    --destination-cidr-block "0.0.0.0/0" \
    --gateway-id "$IGW_ID" \
    --region "$REGION" > /dev/null
print_success "Route to Internet Gateway added"

# Associate public subnets with public route table
for subnet_id in "${PUBLIC_SUBNET_IDS[@]}"; do
    aws ec2 associate-route-table \
        --route-table-id "$PUBLIC_RT_ID" \
        --subnet-id "$subnet_id" \
        --region "$REGION" > /dev/null
    print_success "Public subnet $subnet_id associated with public route table"
done

# Step 5: Create NAT Gateway(s) and Private Route Tables
NAT_GATEWAY_IDS=()

if [ "$NAT_GATEWAY_TYPE" != "none" ]; then
    if [ "$NAT_GATEWAY_TYPE" = "single" ]; then
        # Create single NAT Gateway in first public subnet
        print_step "Creating NAT Gateway (single)..."

        # Allocate Elastic IP
        EIP_ALLOC_ID=$(aws ec2 allocate-address \
            --domain vpc \
            --region "$REGION" \
            --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$VPC_NAME-nat-eip}]" \
            --query 'AllocationId' \
            --output text)
        print_success "Elastic IP allocated: $EIP_ALLOC_ID"

        # Create NAT Gateway
        NAT_GW_ID=$(aws ec2 create-nat-gateway \
            --subnet-id "${PUBLIC_SUBNET_IDS[0]}" \
            --allocation-id "$EIP_ALLOC_ID" \
            --region "$REGION" \
            --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$VPC_NAME-nat}]" \
            --query 'NatGateway.NatGatewayId' \
            --output text)
        NAT_GATEWAY_IDS+=("$NAT_GW_ID")
        print_success "NAT Gateway created: $NAT_GW_ID"

        # Wait for NAT Gateway to become available
        print_info "Waiting for NAT Gateway to become available (this may take 1-2 minutes)..."
        if [ "$HAS_GUM" = "true" ]; then
            gum spin --spinner dot --title "Waiting for NAT Gateway..." -- \
                aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID" --region "$REGION"
        else
            aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GW_ID" --region "$REGION"
        fi
        print_success "NAT Gateway is available"

        # Create single private route table
        print_step "Creating private route table..."
        PRIVATE_RT_ID=$(aws ec2 create-route-table \
            --vpc-id "$VPC_ID" \
            --region "$REGION" \
            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-private}]" \
            --query 'RouteTable.RouteTableId' \
            --output text)
        print_success "Private route table created: $PRIVATE_RT_ID"

        # Add route to NAT Gateway
        aws ec2 create-route \
            --route-table-id "$PRIVATE_RT_ID" \
            --destination-cidr-block "0.0.0.0/0" \
            --nat-gateway-id "$NAT_GW_ID" \
            --region "$REGION" > /dev/null
        print_success "Route to NAT Gateway added"

        # Associate all private subnets with this route table
        for subnet_id in "${PRIVATE_SUBNET_IDS[@]}"; do
            aws ec2 associate-route-table \
                --route-table-id "$PRIVATE_RT_ID" \
                --subnet-id "$subnet_id" \
                --region "$REGION" > /dev/null
            print_success "Private subnet $subnet_id associated with private route table"
        done

    elif [ "$NAT_GATEWAY_TYPE" = "per-az" ]; then
        # Create NAT Gateway per AZ
        for i in "${!AZS[@]}"; do
            AZ="${AZS[$i]}"
            PUBLIC_SUBNET_ID="${PUBLIC_SUBNET_IDS[$i]}"
            PRIVATE_SUBNET_ID="${PRIVATE_SUBNET_IDS[$i]}"

            print_step "Creating NAT Gateway in $AZ..."

            # Allocate Elastic IP
            EIP_ALLOC_ID=$(aws ec2 allocate-address \
                --domain vpc \
                --region "$REGION" \
                --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$VPC_NAME-nat-eip-$AZ}]" \
                --query 'AllocationId' \
                --output text)
            print_success "Elastic IP allocated: $EIP_ALLOC_ID"

            # Create NAT Gateway
            NAT_GW_ID=$(aws ec2 create-nat-gateway \
                --subnet-id "$PUBLIC_SUBNET_ID" \
                --allocation-id "$EIP_ALLOC_ID" \
                --region "$REGION" \
                --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$VPC_NAME-nat-$AZ}]" \
                --query 'NatGateway.NatGatewayId' \
                --output text)
            NAT_GATEWAY_IDS+=("$NAT_GW_ID")
            print_success "NAT Gateway created: $NAT_GW_ID"
        done

        # Wait for all NAT Gateways to become available
        print_info "Waiting for NAT Gateways to become available (this may take 1-2 minutes)..."
        for nat_gw_id in "${NAT_GATEWAY_IDS[@]}"; do
            if [ "$HAS_GUM" = "true" ]; then
                gum spin --spinner dot --title "Waiting for NAT Gateway $nat_gw_id..." -- \
                    aws ec2 wait nat-gateway-available --nat-gateway-ids "$nat_gw_id" --region "$REGION"
            else
                aws ec2 wait nat-gateway-available --nat-gateway-ids "$nat_gw_id" --region "$REGION"
            fi
        done
        print_success "All NAT Gateways are available"

        # Create private route table per AZ
        for i in "${!AZS[@]}"; do
            AZ="${AZS[$i]}"
            NAT_GW_ID="${NAT_GATEWAY_IDS[$i]}"
            PRIVATE_SUBNET_ID="${PRIVATE_SUBNET_IDS[$i]}"

            print_step "Creating private route table for $AZ..."
            PRIVATE_RT_ID=$(aws ec2 create-route-table \
                --vpc-id "$VPC_ID" \
                --region "$REGION" \
                --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-private-$AZ}]" \
                --query 'RouteTable.RouteTableId' \
                --output text)
            print_success "Private route table created: $PRIVATE_RT_ID"

            # Add route to NAT Gateway
            aws ec2 create-route \
                --route-table-id "$PRIVATE_RT_ID" \
                --destination-cidr-block "0.0.0.0/0" \
                --nat-gateway-id "$NAT_GW_ID" \
                --region "$REGION" > /dev/null
            print_success "Route to NAT Gateway added"

            # Associate private subnet with this route table
            aws ec2 associate-route-table \
                --route-table-id "$PRIVATE_RT_ID" \
                --subnet-id "$PRIVATE_SUBNET_ID" \
                --region "$REGION" > /dev/null
            print_success "Private subnet $PRIVATE_SUBNET_ID associated with private route table"
        done
    fi
else
    print_info "No NAT Gateway created (private subnets will not have internet access)"

    # Create private route table without NAT Gateway
    print_step "Creating private route table (no internet access)..."
    PRIVATE_RT_ID=$(aws ec2 create-route-table \
        --vpc-id "$VPC_ID" \
        --region "$REGION" \
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$VPC_NAME-private}]" \
        --query 'RouteTable.RouteTableId' \
        --output text)
    print_success "Private route table created: $PRIVATE_RT_ID"

    # Associate all private subnets with this route table
    for subnet_id in "${PRIVATE_SUBNET_IDS[@]}"; do
        aws ec2 associate-route-table \
            --route-table-id "$PRIVATE_RT_ID" \
            --subnet-id "$subnet_id" \
            --region "$REGION" > /dev/null
        print_success "Private subnet $subnet_id associated with private route table"
    done
fi

# Step 6: Enable VPC Flow Logs (optional)
if [ "$ENABLE_FLOW_LOGS" = "true" ]; then
    print_step "Enabling VPC Flow Logs..."

    # Create CloudWatch Log Group
    LOG_GROUP_NAME="/aws/vpc/$VPC_NAME"
    aws logs create-log-group --log-group-name "$LOG_GROUP_NAME" --region "$REGION" 2>/dev/null || true
    print_success "Log group created: $LOG_GROUP_NAME"

    # Create IAM role for Flow Logs
    ROLE_NAME="$VPC_NAME-flow-logs-role"

    # Create trust policy
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

    ROLE_ARN=$(aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --query 'Role.Arn' \
        --output text 2>/dev/null || aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

    # Attach policy to role
    POLICY_DOC=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

    aws iam put-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-name "flow-logs-policy" \
        --policy-document "$POLICY_DOC" 2>/dev/null || true

    # Wait a bit for IAM role to propagate
    sleep 5

    # Create Flow Logs
    aws ec2 create-flow-logs \
        --resource-type VPC \
        --resource-ids "$VPC_ID" \
        --traffic-type ALL \
        --log-destination-type cloud-watch-logs \
        --log-group-name "$LOG_GROUP_NAME" \
        --deliver-logs-permission-arn "$ROLE_ARN" \
        --region "$REGION" > /dev/null
    print_success "VPC Flow Logs enabled"
fi

# Final Summary
echo ""
echo "========================================"
print_success "VPC Infrastructure Created Successfully!"
echo "========================================"
echo ""
echo "VPC Details:"
echo "  VPC ID: $VPC_ID"
echo "  VPC CIDR: $VPC_CIDR"
echo "  Region: $REGION"
echo "  Internet Gateway: $IGW_ID"
echo ""
echo "Public Subnets:"
for i in "${!PUBLIC_SUBNET_IDS[@]}"; do
    echo "  ${AZS[$i]}: ${PUBLIC_SUBNET_IDS[$i]}"
done
echo ""
echo "Private Subnets:"
for i in "${!PRIVATE_SUBNET_IDS[@]}"; do
    echo "  ${AZS[$i]}: ${PRIVATE_SUBNET_IDS[$i]}"
done
echo ""
if [ ${#NAT_GATEWAY_IDS[@]} -gt 0 ]; then
    echo "NAT Gateways:"
    for nat_gw_id in "${NAT_GATEWAY_IDS[@]}"; do
        echo "  $nat_gw_id"
    done
    echo ""
fi
echo "Route Tables:"
echo "  Public: $PUBLIC_RT_ID"
if [ "$NAT_GATEWAY_TYPE" = "per-az" ]; then
    echo "  Private: (one per AZ)"
elif [ "$NAT_GATEWAY_TYPE" != "none" ]; then
    echo "  Private: $PRIVATE_RT_ID"
else
    echo "  Private: $PRIVATE_RT_ID (no internet access)"
fi
echo ""
echo "Next Steps:"
echo "  1. View your VPC in the AWS Console:"
echo "     https://console.aws.amazon.com/vpc/home?region=$REGION#vpcs:VpcId=$VPC_ID"
echo "  2. Launch EC2 instances in your subnets"
echo "  3. Create security groups for your applications"
echo "  4. Consider creating VPC endpoints for AWS services"
echo ""

# Output IDs for scripting
cat > "vpc-${VPC_NAME}-info.txt" << EOF
VPC_ID=$VPC_ID
VPC_CIDR=$VPC_CIDR
REGION=$REGION
IGW_ID=$IGW_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
PUBLIC_SUBNET_IDS=${PUBLIC_SUBNET_IDS[*]}
PRIVATE_SUBNET_IDS=${PRIVATE_SUBNET_IDS[*]}
NAT_GATEWAY_IDS=${NAT_GATEWAY_IDS[*]}
EOF

print_success "VPC information saved to: vpc-${VPC_NAME}-info.txt"
echo ""

if [ "$HAS_GUM" = "true" ]; then
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "✓ VPC Created Successfully!" \
        "VPC ID: $VPC_ID"
fi
