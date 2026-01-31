#!/bin/bash

# VPC Endpoint Creation Script
# Creates VPC endpoints for AWS services to enable private connectivity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Creates VPC endpoints for AWS services to enable private connectivity.

OPTIONS:
    -v, --vpc-id VPC_ID          VPC ID (required)
    -s, --service SERVICE        Service name (e.g., s3, ec2, ssm)
    -r, --region REGION          AWS region (default: from AWS CLI config)
    -n, --subnets SUBNET_IDS     Comma-separated subnet IDs (required for interface endpoints)
    -g, --security-groups SG_IDS Comma-separated security group IDs (required for interface endpoints)
    -t, --route-tables RT_IDS    Comma-separated route table IDs (for gateway endpoints)
    -p, --private-dns            Enable private DNS (default: true for interface endpoints)
    --list                       List common service endpoints
    -h, --help                   Show this help message

EXAMPLES:
    # Create S3 gateway endpoint
    $0 --vpc-id vpc-12345 --service s3 --route-tables rtb-111,rtb-222

    # Create EC2 interface endpoint
    $0 --vpc-id vpc-12345 --service ec2 --subnets subnet-111,subnet-222 --security-groups sg-123

    # Create multiple endpoints
    $0 --vpc-id vpc-12345 --service ssm,ssmmessages,ec2messages --subnets subnet-111,subnet-222 --security-groups sg-123

COMMON SERVICES:
    Gateway Endpoints (no additional charges):
        s3          - Amazon S3
        dynamodb    - Amazon DynamoDB

    Interface Endpoints (charges apply):
        ec2         - EC2 API
        ssm         - Systems Manager
        ssmmessages - Systems Manager Session Manager
        ec2messages - EC2 Messages (for SSM)
        ecr.api     - ECR API
        ecr.dkr     - ECR Docker
        logs        - CloudWatch Logs
        monitoring  - CloudWatch Monitoring
        sts         - AWS STS
        secretsmanager - Secrets Manager
        kms         - AWS KMS
        rds         - Amazon RDS
        lambda      - AWS Lambda
        ecs         - Amazon ECS
        elasticloadbalancing - Elastic Load Balancing
        autoscaling - Auto Scaling

EOF
}

list_services() {
    cat << EOF
${GREEN}Gateway Endpoints (No additional charges):${NC}
  s3          - Amazon S3
  dynamodb    - Amazon DynamoDB

${YELLOW}Interface Endpoints (Charges apply - \$0.01/hour per AZ + data transfer):${NC}
  ec2         - EC2 API
  ssm         - Systems Manager
  ssmmessages - Systems Manager Session Manager
  ec2messages - EC2 Messages (required for SSM)
  ecr.api     - Elastic Container Registry API
  ecr.dkr     - Elastic Container Registry Docker
  logs        - CloudWatch Logs
  monitoring  - CloudWatch Monitoring
  sts         - AWS Security Token Service
  secretsmanager - AWS Secrets Manager
  kms         - AWS Key Management Service
  rds         - Amazon RDS
  lambda      - AWS Lambda
  ecs         - Amazon ECS
  ecs-agent   - ECS Agent
  ecs-telemetry - ECS Telemetry
  elasticloadbalancing - Elastic Load Balancing
  autoscaling - Auto Scaling
  sns         - Amazon SNS
  sqs         - Amazon SQS
  kinesis-streams - Amazon Kinesis Data Streams
  kinesis-firehose - Amazon Kinesis Data Firehose
  athena      - Amazon Athena
  glue        - AWS Glue
  sagemaker.runtime - SageMaker Runtime

${YELLOW}Common Combinations:${NC}
  SSM Session Manager: ssm, ssmmessages, ec2messages
  ECS with ECR: ecs, ecs-agent, ecs-telemetry, ecr.api, ecr.dkr, logs
  Private RDS Access: rds
  Lambda in VPC: lambda, logs

EOF
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Parse arguments
VPC_ID=""
SERVICES=""
REGION=""
SUBNETS=""
SECURITY_GROUPS=""
ROUTE_TABLES=""
PRIVATE_DNS="true"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--vpc-id)
            VPC_ID="$2"
            shift 2
            ;;
        -s|--service)
            SERVICES="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -n|--subnets)
            SUBNETS="$2"
            shift 2
            ;;
        -g|--security-groups)
            SECURITY_GROUPS="$2"
            shift 2
            ;;
        -t|--route-tables)
            ROUTE_TABLES="$2"
            shift 2
            ;;
        -p|--private-dns)
            PRIVATE_DNS="true"
            shift
            ;;
        --no-private-dns)
            PRIVATE_DNS="false"
            shift
            ;;
        --list)
            list_services
            exit 0
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

# Validate required parameters
if [ -z "$VPC_ID" ]; then
    print_error "VPC ID is required"
    print_usage
    exit 1
fi

if [ -z "$SERVICES" ]; then
    print_error "Service name is required"
    print_usage
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

print_info "Using region: $REGION"
print_info "Using VPC: $VPC_ID"

# Define gateway endpoint services
GATEWAY_SERVICES="s3 dynamodb"

# Function to check if service is gateway endpoint
is_gateway_service() {
    local service=$1
    echo "$GATEWAY_SERVICES" | grep -wq "$service"
}

# Function to create gateway endpoint
create_gateway_endpoint() {
    local service=$1
    local service_name="com.amazonaws.${REGION}.${service}"

    print_info "Creating gateway endpoint for $service..."

    if [ -z "$ROUTE_TABLES" ]; then
        print_error "Route table IDs are required for gateway endpoints. Use --route-tables"
        return 1
    fi

    # Convert comma-separated list to space-separated
    local rt_ids=$(echo "$ROUTE_TABLES" | tr ',' ' ')

    ENDPOINT_ID=$(aws ec2 vpc-endpoint \
        --vpc-id "$VPC_ID" \
        --service-name "$service_name" \
        --route-table-ids $rt_ids \
        --region "$REGION" \
        --query 'VpcEndpoint.VpcEndpointId' \
        --output text)

    if [ $? -eq 0 ]; then
        print_success "Gateway endpoint created: $ENDPOINT_ID for $service"
        return 0
    else
        print_error "Failed to create gateway endpoint for $service"
        return 1
    fi
}

# Function to create interface endpoint
create_interface_endpoint() {
    local service=$1
    local service_name="com.amazonaws.${REGION}.${service}"

    print_info "Creating interface endpoint for $service..."

    if [ -z "$SUBNETS" ]; then
        print_error "Subnet IDs are required for interface endpoints. Use --subnets"
        return 1
    fi

    if [ -z "$SECURITY_GROUPS" ]; then
        print_error "Security group IDs are required for interface endpoints. Use --security-groups"
        return 1
    fi

    # Convert comma-separated list to space-separated
    local subnet_ids=$(echo "$SUBNETS" | tr ',' ' ')
    local sg_ids=$(echo "$SECURITY_GROUPS" | tr ',' ' ')

    ENDPOINT_ID=$(aws ec2 vpc-endpoint \
        --vpc-id "$VPC_ID" \
        --vpc-endpoint-type Interface \
        --service-name "$service_name" \
        --subnet-ids $subnet_ids \
        --security-group-ids $sg_ids \
        --private-dns-enabled "$PRIVATE_DNS" \
        --region "$REGION" \
        --query 'VpcEndpoint.VpcEndpointId' \
        --output text)

    if [ $? -eq 0 ]; then
        print_success "Interface endpoint created: $ENDPOINT_ID for $service"
        return 0
    else
        print_error "Failed to create interface endpoint for $service"
        return 1
    fi
}

# Process each service
IFS=',' read -ra SERVICE_ARRAY <<< "$SERVICES"
SUCCESS_COUNT=0
FAILED_COUNT=0

for service in "${SERVICE_ARRAY[@]}"; do
    # Trim whitespace
    service=$(echo "$service" | xargs)

    if is_gateway_service "$service"; then
        if create_gateway_endpoint "$service"; then
            ((SUCCESS_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    else
        if create_interface_endpoint "$service"; then
            ((SUCCESS_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    fi

    echo ""
done

# Summary
echo "========================================"
print_info "Summary:"
print_success "Successfully created: $SUCCESS_COUNT endpoint(s)"
if [ $FAILED_COUNT -gt 0 ]; then
    print_error "Failed to create: $FAILED_COUNT endpoint(s)"
fi
echo "========================================"

# Show how to verify
echo ""
print_info "To verify your endpoints, run:"
echo "  aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$VPC_ID --region $REGION"

exit 0
