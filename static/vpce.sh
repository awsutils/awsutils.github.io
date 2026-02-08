#!/bin/bash

# VPC Endpoints Creation Script
# Creates gateway and interface endpoints with proper configurations

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_message "$RED" "Error: AWS CLI is not installed"
        exit 1
    fi
}

# Function to validate VPC ID
validate_vpc() {
    local vpc_id=$1
    if ! aws ec2 describe-vpcs --vpc-ids "$vpc_id" &> /dev/null; then
        print_message "$RED" "Error: VPC $vpc_id not found or invalid"
        exit 1
    fi
    print_message "$GREEN" "VPC $vpc_id validated successfully"
}

# Function to get all route tables in VPC
get_route_tables() {
    local vpc_id=$1
    aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[*].RouteTableId' \
        --output text
}

# Function to check if route table is private (no IGW attachment)
is_private_route_table() {
    local route_table_id=$1
    local igw_count=$(aws ec2 describe-route-tables \
        --route-table-ids "$route_table_id" \
        --query 'RouteTables[0].Routes[?GatewayId!=`local` && starts_with(GatewayId, `igw-`)].GatewayId' \
        --output text | wc -w)
    
    if [ "$igw_count" -eq 0 ]; then
        return 0  # Private route table
    else
        return 1  # Public route table
    fi
}

# Function to get private subnets
get_private_subnets() {
    local vpc_id=$1
    local private_subnets=()
    
    # Get all subnets in VPC
    local all_subnets=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[*].SubnetId' \
        --output text)
    
    # Check each subnet's route table
    for subnet_id in $all_subnets; do
        # Get the route table associated with this subnet
        local route_table_id=$(aws ec2 describe-route-tables \
            --filters "Name=association.subnet-id,Values=$subnet_id" \
            --query 'RouteTables[0].RouteTableId' \
            --output text)
        
        # If no explicit association, use main route table
        if [ "$route_table_id" == "None" ] || [ -z "$route_table_id" ]; then
            route_table_id=$(aws ec2 describe-route-tables \
                --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=true" \
                --query 'RouteTables[0].RouteTableId' \
                --output text)
        fi
        
        # Check if route table is private
        if is_private_route_table "$route_table_id"; then
            private_subnets+=("$subnet_id")
        fi
    done
    
    echo "${private_subnets[@]}"
}

# Function to get VPC CIDR block
get_vpc_cidr() {
    local vpc_id=$1
    aws ec2 describe-vpcs \
        --vpc-ids "$vpc_id" \
        --query 'Vpcs[0].CidrBlock' \
        --output text
}

# Function to create or get security group for interface endpoints
create_endpoint_security_group() {
    local vpc_id=$1
    local vpc_cidr=$2
    local sg_name="vpc-endpoint-sg"
    
    # Check if security group already exists
    local existing_sg=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=group-name,Values=$sg_name" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$existing_sg" ] && [ "$existing_sg" != "None" ]; then
        print_message "$YELLOW" "Using existing security group: $existing_sg"
        echo "$existing_sg"
        return
    fi
    
    # Create new security group
    local sg_id=$(aws ec2 create-security-group \
        --group-name "$sg_name" \
        --description "Security group for VPC endpoints - allows all traffic from VPC CIDR" \
        --vpc-id "$vpc_id" \
        --query 'GroupId' \
        --output text)
    
    print_message "$GREEN" "Created security group: $sg_id"
    
    # Add ingress rule for all traffic from VPC CIDR
    aws ec2 authorize-security-group-ingress \
        --group-id "$sg_id" \
        --protocol all \
        --cidr "$vpc_cidr" \
        --output text &> /dev/null
    
    print_message "$GREEN" "Added ingress rule: Allow all from $vpc_cidr"
    
    echo "$sg_id"
}

# Function to create gateway endpoint
create_gateway_endpoint() {
    local vpc_id=$1
    local service_name=$2
    local route_tables=$3
    
    print_message "$YELLOW" "Creating gateway endpoint for $service_name..."
    
    local endpoint_id=$(aws ec2 create-vpc-endpoint \
        --vpc-id "$vpc_id" \
        --service-name "$service_name" \
        --route-table-ids $route_tables \
        --query 'VpcEndpoint.VpcEndpointId' \
        --output text 2>&1)
    
    if [[ $endpoint_id == vpce-* ]]; then
        print_message "$GREEN" "✓ Created gateway endpoint: $endpoint_id for $service_name"
    else
        print_message "$RED" "✗ Failed to create gateway endpoint for $service_name: $endpoint_id"
    fi
}

# Function to create interface endpoint
create_interface_endpoint() {
    local vpc_id=$1
    local service_name=$2
    local subnet_ids=$3
    local security_group_id=$4
    
    print_message "$YELLOW" "Creating interface endpoint for $service_name..."
    
    local endpoint_id=$(aws ec2 create-vpc-endpoint \
        --vpc-id "$vpc_id" \
        --vpc-endpoint-type Interface \
        --service-name "$service_name" \
        --subnet-ids $subnet_ids \
        --security-group-ids "$security_group_id" \
        --private-dns-enabled \
        --query 'VpcEndpoint.VpcEndpointId' \
        --output text 2>&1)
    
    if [[ $endpoint_id == vpce-* ]]; then
        print_message "$GREEN" "✓ Created interface endpoint: $endpoint_id for $service_name"
    else
        print_message "$YELLOW" "✗ Failed to create interface endpoint for $service_name: $endpoint_id"
    fi
}

# Main function
main() {
    print_message "$GREEN" "=== VPC Endpoints Creation Script ==="
    echo
    
    # Check AWS CLI
    check_aws_cli
    
    # Get VPC ID from user
    if [ -z "$1" ]; then
        read -p "Enter VPC ID: " VPC_ID
    else
        VPC_ID=$1
    fi
    
    # Validate VPC
    validate_vpc "$VPC_ID"
    
    # Get AWS region
    AWS_REGION=$(aws configure get region)
    if [ -z "$AWS_REGION" ]; then
        AWS_REGION="us-east-1"
        print_message "$YELLOW" "No region configured, using default: $AWS_REGION"
    fi
    
    print_message "$GREEN" "Using region: $AWS_REGION"
    echo
    
    # Get VPC CIDR
    VPC_CIDR=$(get_vpc_cidr "$VPC_ID")
    print_message "$GREEN" "VPC CIDR: $VPC_CIDR"
    
    # Get all route tables
    print_message "$YELLOW" "Fetching route tables..."
    ROUTE_TABLES=$(get_route_tables "$VPC_ID")
    ROUTE_TABLE_COUNT=$(echo $ROUTE_TABLES | wc -w)
    print_message "$GREEN" "Found $ROUTE_TABLE_COUNT route table(s)"
    
    # Get private subnets
    print_message "$YELLOW" "Identifying private subnets..."
    PRIVATE_SUBNETS=$(get_private_subnets "$VPC_ID")
    PRIVATE_SUBNET_COUNT=$(echo $PRIVATE_SUBNETS | wc -w)
    
    if [ $PRIVATE_SUBNET_COUNT -eq 0 ]; then
        print_message "$RED" "No private subnets found. Interface endpoints require private subnets."
        print_message "$YELLOW" "Only gateway endpoints will be created."
    else
        print_message "$GREEN" "Found $PRIVATE_SUBNET_COUNT private subnet(s)"
        
        # Create security group for interface endpoints
        print_message "$YELLOW" "Creating/Getting security group for interface endpoints..."
        SECURITY_GROUP_ID=$(create_endpoint_security_group "$VPC_ID" "$VPC_CIDR")
    fi
    
    echo
    print_message "$GREEN" "=== Creating Gateway Endpoints ==="
    
    # Create S3 gateway endpoint
    create_gateway_endpoint "$VPC_ID" "com.amazonaws.$AWS_REGION.s3" "$ROUTE_TABLES"
    
    # Create DynamoDB gateway endpoint
    create_gateway_endpoint "$VPC_ID" "com.amazonaws.$AWS_REGION.dynamodb" "$ROUTE_TABLES"
    
    # Create interface endpoints only if private subnets exist
    if [ $PRIVATE_SUBNET_COUNT -gt 0 ]; then
        echo
        print_message "$GREEN" "=== Creating Interface Endpoints ==="
        
        # Common interface endpoints
        INTERFACE_SERVICES=(
            "ec2"
            "ec2messages"
            "ssm"
            "ssmmessages"
            "logs"
            "sts"
            "secretsmanager"
            "kms"
            "ecr.api"
            "ecr.dkr"
        )
        
        for service in "${INTERFACE_SERVICES[@]}"; do
            create_interface_endpoint "$VPC_ID" \
                "com.amazonaws.$AWS_REGION.$service" \
                "$PRIVATE_SUBNETS" \
                "$SECURITY_GROUP_ID"
        done
    fi
    
    echo
    print_message "$GREEN" "=== VPC Endpoints Creation Complete ==="
}

# Run main function
main "$@"
