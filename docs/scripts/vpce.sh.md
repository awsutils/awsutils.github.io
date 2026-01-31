---
sidebar_position: 12
---

# vpce.sh

Create VPC endpoints for AWS services to enable private connectivity without internet gateways.

## Overview

`vpce.sh` is a comprehensive script that simplifies the creation of VPC endpoints for AWS services. It supports both Gateway endpoints (S3, DynamoDB) and Interface endpoints (EC2, SSM, ECR, and many more), with automatic service type detection and helpful error messages.

VPC endpoints enable private connectivity to AWS services without requiring an internet gateway, NAT device, VPN connection, or AWS Direct Connect. This improves security and can reduce data transfer costs.

## Quick Start

```bash
# Download script
curl -O https://awsutils.github.io/vpce.sh
chmod +x vpce.sh

# List available services
./vpce.sh --list

# Create S3 gateway endpoint
./vpce.sh --vpc-id vpc-12345 --service s3 --route-tables rtb-111,rtb-222

# Create EC2 interface endpoint
./vpce.sh --vpc-id vpc-12345 --service ec2 \
  --subnets subnet-111,subnet-222 --security-groups sg-123
```

## Features

- **Automatic Service Type Detection**: Distinguishes between gateway and interface endpoints
- **Batch Creation**: Create multiple endpoints in a single command
- **Comprehensive Service List**: Includes 30+ common AWS services
- **Smart Defaults**: Enables private DNS by default for interface endpoints
- **Validation**: Checks for required parameters based on endpoint type
- **Colored Output**: Easy-to-read success/error messages
- **Summary Report**: Shows success/failure count after execution

## Prerequisites

- AWS CLI installed and configured
- IAM permissions to create VPC endpoints
- Existing VPC with subnets and security groups
- For gateway endpoints: Route table IDs
- For interface endpoints: Subnet IDs and security group IDs

## Endpoint Types

### Gateway Endpoints (Free)

Gateway endpoints are free and support only S3 and DynamoDB:

| Service    | Description     | Cost |
| ---------- | --------------- | ---- |
| `s3`       | Amazon S3       | Free |
| `dynamodb` | Amazon DynamoDB | Free |

**Requirements:**

- VPC ID
- Route table IDs

**How it works:**

- Adds routes to your route tables pointing to the service
- No ENI (Elastic Network Interface) created
- No data transfer charges

### Interface Endpoints (Paid)

Interface endpoints support most AWS services and cost approximately $0.01/hour per AZ plus data transfer:

**Common services:**

| Service                | Description           | Use Case                      |
| ---------------------- | --------------------- | ----------------------------- |
| `ec2`                  | EC2 API               | Private EC2 API access        |
| `ssm`                  | Systems Manager       | Private SSM access            |
| `ssmmessages`          | SSM Session Manager   | Session Manager sessions      |
| `ec2messages`          | EC2 Messages          | Required for SSM Agent        |
| `ecr.api`              | ECR API               | Private ECR API               |
| `ecr.dkr`              | ECR Docker            | Pull Docker images privately  |
| `logs`                 | CloudWatch Logs       | Private log shipping          |
| `monitoring`           | CloudWatch Monitoring | Private metrics               |
| `sts`                  | AWS STS               | Private token service         |
| `secretsmanager`       | Secrets Manager       | Private secrets access        |
| `kms`                  | AWS KMS               | Private encryption operations |
| `rds`                  | Amazon RDS            | Private RDS API access        |
| `lambda`               | AWS Lambda            | Invoke Lambda privately       |
| `ecs`                  | Amazon ECS            | Private ECS API               |
| `elasticloadbalancing` | ELB                   | Private ELB API               |
| `autoscaling`          | Auto Scaling          | Private Auto Scaling API      |

**Requirements:**

- VPC ID
- Subnet IDs (typically one per AZ)
- Security group IDs

**How it works:**

- Creates ENIs (Elastic Network Interfaces) in your subnets
- Provides private DNS names
- Charges apply: ~$0.01/hour per AZ + data transfer

## Usage

### Basic Syntax

```bash
./vpce.sh [OPTIONS]
```

### Options

```
-v, --vpc-id VPC_ID          VPC ID (required)
-s, --service SERVICE        Service name or comma-separated list (required)
-r, --region REGION          AWS region (default: from AWS CLI config)
-n, --subnets SUBNET_IDS     Comma-separated subnet IDs (required for interface endpoints)
-g, --security-groups SG_IDS Comma-separated security group IDs (required for interface endpoints)
-t, --route-tables RT_IDS    Comma-separated route table IDs (for gateway endpoints)
-p, --private-dns            Enable private DNS (default: true for interface endpoints)
--no-private-dns             Disable private DNS
--list                       List all available services
-h, --help                   Show help message
```

## Examples

### Gateway Endpoints

#### Create S3 Endpoint

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service s3 \
  --route-tables rtb-111,rtb-222,rtb-333
```

#### Create DynamoDB Endpoint

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service dynamodb \
  --route-tables rtb-111,rtb-222
```

#### Create Both S3 and DynamoDB

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service s3,dynamodb \
  --route-tables rtb-111,rtb-222
```

### Interface Endpoints

#### Create EC2 Endpoint

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service ec2 \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-abc123
```

#### Systems Manager Access (SSM Session Manager)

For SSM Session Manager, you need three endpoints:

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service ssm,ssmmessages,ec2messages \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-abc123 \
  --region us-east-1
```

#### ECS with ECR (Container Workflows)

For ECS tasks to pull from ECR privately:

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service ecs,ecs-agent,ecs-telemetry,ecr.api,ecr.dkr,logs \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-abc123
```

#### Lambda in Private VPC

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service lambda,logs \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-abc123
```

#### Secrets Manager Access

```bash
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service secretsmanager \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-abc123
```

### Complete Private Subnet Setup

Create all endpoints needed for a fully private subnet:

```bash
# Gateway endpoints (free)
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service s3,dynamodb \
  --route-tables rtb-private-1,rtb-private-2

# Interface endpoints for common services
./vpce.sh \
  --vpc-id vpc-0abc123def456789 \
  --service ec2,ssm,ssmmessages,ec2messages,logs,secretsmanager,kms \
  --subnets subnet-private-1,subnet-private-2 \
  --security-groups sg-vpc-endpoints
```

## Security Group Configuration

Your security group for interface endpoints should allow inbound traffic:

```bash
# Create security group
aws ec2 create-security-group \
  --group-name vpc-endpoints-sg \
  --description "Security group for VPC endpoints" \
  --vpc-id vpc-0abc123def456789

# Allow HTTPS from VPC CIDR
aws ec2 authorize-security-group-ingress \
  --group-id sg-abc123 \
  --protocol tcp \
  --port 443 \
  --cidr 10.0.0.0/16
```

### Terraform Example

```hcl
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}
```

## IAM Permissions Required

Minimum IAM permissions needed to create VPC endpoints:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpcEndpoint",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeRouteTables",
        "ec2:ModifyVpcEndpoint"
      ],
      "Resource": "*"
    }
  ]
}
```

### Full Management Permissions

For full VPC endpoint management including deletion:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:DescribeVpcEndpoints",
        "ec2:DescribeVpcEndpointServices",
        "ec2:ModifyVpcEndpoint",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeRouteTables",
        "ec2:DescribePrefixLists"
      ],
      "Resource": "*"
    }
  ]
}
```

## Common Use Cases

### 1. Private EC2 Instances with SSM Access

Enable SSM Session Manager for EC2 instances in private subnets:

```bash
# Create endpoints
./vpce.sh \
  --vpc-id vpc-12345 \
  --service ssm,ssmmessages,ec2messages \
  --subnets subnet-private-1a,subnet-private-1b \
  --security-groups sg-endpoints

# Now connect to instances without SSH
aws ssm start-session --target i-1234567890abcdef0
```

### 2. ECS Fargate in Private Subnets

Enable Fargate tasks to pull from ECR without NAT Gateway:

```bash
# Create required endpoints
./vpce.sh \
  --vpc-id vpc-12345 \
  --service ecr.api,ecr.dkr,s3 \
  --subnets subnet-private-1a,subnet-private-1b \
  --security-groups sg-endpoints

# S3 gateway endpoint for image layers
./vpce.sh \
  --vpc-id vpc-12345 \
  --service s3 \
  --route-tables rtb-private
```

### 3. Lambda Accessing Secrets Manager

Lambda in VPC accessing Secrets Manager privately:

```bash
./vpce.sh \
  --vpc-id vpc-12345 \
  --service secretsmanager \
  --subnets subnet-private-1a,subnet-private-1b \
  --security-groups sg-endpoints
```

### 4. Cost Optimization

Replace NAT Gateway with VPC endpoints for supported services:

**Before (with NAT Gateway):**

- NAT Gateway: $0.045/hour = $32.40/month
- Data transfer: $0.045/GB

**After (with VPC endpoints):**

- S3 gateway endpoint: Free
- DynamoDB gateway endpoint: Free
- Interface endpoints: $0.01/hour × 2 AZ × 5 services = $0.10/hour = $72/month
- Data transfer: $0.01/GB

**Break-even point:** ~1.6 TB/month of data transfer

### 5. Compliance and Security

Meet compliance requirements by keeping traffic within AWS network:

```bash
# Create endpoints for audit and security services
./vpce.sh \
  --vpc-id vpc-12345 \
  --service logs,cloudtrail,securityhub,guardduty \
  --subnets subnet-private-1a,subnet-private-1b \
  --security-groups sg-endpoints
```

## Verification

### Check Endpoint Status

```bash
# List all endpoints in VPC
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-12345" \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName,State]' \
  --output table

# Check specific endpoint
aws ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids vpce-abc123 \
  --query 'VpcEndpoints[0].[State,ServiceName,DnsEntries[0].DnsName]' \
  --output table
```

### Test Connectivity

```bash
# From EC2 instance, test S3 endpoint
aws s3 ls

# Test SSM connectivity
aws ssm describe-instance-information

# Test private DNS resolution
nslookup ec2.us-east-1.amazonaws.com
```

### Verify Private DNS

```bash
# Should resolve to private IP
dig +short ec2.us-east-1.amazonaws.com

# Example output (private IPs):
# 10.0.1.123
# 10.0.2.234
```

## Troubleshooting

### Issue: "Could not determine AWS region"

**Solution:** Configure AWS CLI or specify region:

```bash
# Configure AWS CLI
aws configure

# Or specify region in command
./vpce.sh --vpc-id vpc-12345 --service s3 --region us-east-1
```

### Issue: "Route table IDs are required for gateway endpoints"

**Solution:** Gateway endpoints (S3, DynamoDB) need route tables:

```bash
# Find your route table IDs
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-12345" \
  --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Use in command
./vpce.sh --vpc-id vpc-12345 --service s3 --route-tables rtb-111,rtb-222
```

### Issue: "Subnet IDs are required for interface endpoints"

**Solution:** Interface endpoints need subnets (typically one per AZ):

```bash
# Find your subnet IDs
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-12345" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Use in command
./vpce.sh \
  --vpc-id vpc-12345 \
  --service ec2 \
  --subnets subnet-111,subnet-222 \
  --security-groups sg-123
```

### Issue: Connection timeouts after creating interface endpoint

**Solution:** Check security group allows HTTPS (port 443):

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-123

# Add rule if missing
aws ec2 authorize-security-group-ingress \
  --group-id sg-123 \
  --protocol tcp \
  --port 443 \
  --cidr 10.0.0.0/16
```

### Issue: "An error occurred (InvalidParameter)"

**Solution:** Verify VPC, subnets, and security groups exist:

```bash
# Verify VPC exists
aws ec2 describe-vpcs --vpc-ids vpc-12345

# Verify subnets
aws ec2 describe-subnets --subnet-ids subnet-111,subnet-222

# Verify security groups
aws ec2 describe-security-groups --group-ids sg-123
```

### Issue: Private DNS not resolving

**Solution:** Ensure private DNS is enabled and DNS resolution is enabled for VPC:

```bash
# Check VPC DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-12345 --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-12345 --attribute enableDnsHostnames

# Enable if necessary
aws ec2 modify-vpc-attribute --vpc-id vpc-12345 --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-12345 --enable-dns-hostnames
```

## Cost Optimization Tips

1. **Use Gateway Endpoints When Possible**: S3 and DynamoDB gateway endpoints are free
2. **Consolidate Subnets**: Use fewer AZs if high availability isn't critical (each AZ costs $0.01/hour per endpoint)
3. **Evaluate NAT Gateway Replacement**: Calculate if replacing NAT Gateway saves money based on traffic
4. **Remove Unused Endpoints**: Delete endpoints that aren't being used

### Cost Calculation

```bash
# Interface endpoint cost per month (2 AZs)
# Per endpoint: $0.01/hour × 24 hours × 30 days × 2 AZs = $14.40/month
# 5 endpoints: $72/month
# 10 endpoints: $144/month

# Plus data transfer: $0.01/GB
```

## Automation with Terraform

```hcl
# Gateway endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [
    aws_route_table.private_1.id,
    aws_route_table.private_2.id
  ]

  tags = {
    Name = "s3-endpoint"
  }
}

# Interface endpoint for EC2
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "ec2-endpoint"
  }
}

# SSM endpoints for Session Manager
locals {
  ssm_services = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset(local.ssm_services)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${each.value}-endpoint"
  }
}
```

## Best Practices

1. **Enable Private DNS**: Keep private DNS enabled for interface endpoints (default)
2. **Use Multiple AZs**: Deploy interface endpoints in multiple AZs for high availability
3. **Dedicated Security Group**: Create a dedicated security group for VPC endpoints
4. **Minimal Ingress**: Only allow port 443 from your VPC CIDR
5. **Tag Resources**: Tag endpoints for cost allocation and management
6. **Monitor Usage**: Use VPC Flow Logs to monitor endpoint traffic
7. **Document Endpoints**: Maintain documentation of which services use which endpoints
8. **Test Before Production**: Test endpoints in dev/staging before production deployment

## Cleanup

To remove VPC endpoints:

```bash
# List all endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-12345" \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName]' \
  --output table

# Delete specific endpoint
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-abc123

# Delete multiple endpoints
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-abc123 vpce-def456 vpce-ghi789
```

## Additional Resources

- [AWS VPC Endpoints Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [AWS PrivateLink Pricing](https://aws.amazon.com/privatelink/pricing/)
- [Gateway Endpoints Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [Interface Endpoints Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html)
- [VPC Endpoint Services List](https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html)

## Support

For issues with:

- **AWS VPC Endpoints**: Contact [AWS Support](https://aws.amazon.com/support/)
- **This script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Documentation

- [Getting Started Guide](../docs/getting-started.md)
- [Best Practices](../docs/best-practices.md)
- [Configuration Guide](../docs/configuration.md)
- [ec2init.sh](./ec2init.sh.md) - EC2 instance initialization
- [csinit.sh](./csinit.sh.md) - CloudShell initialization
