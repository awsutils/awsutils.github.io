---
sidebar_position: 13
---

# vpc.sh

Create a complete, production-ready VPC with public and private subnets across multiple availability zones.

## Overview

`vpc.sh` is a comprehensive script that automates the creation of a complete VPC infrastructure following AWS best practices. It creates a VPC with public and private subnets across multiple availability zones, sets up routing with Internet Gateway and optional NAT Gateways, and provides flexible configuration options for different use cases and budgets.

**✨ Interactive Mode:** The script features a beautiful interactive TUI (Terminal User Interface) powered by [gum](https://github.com/charmbracelet/gum). Simply run the script without arguments to use the interactive mode with guided prompts and selections!

## Quick Start

### Interactive Mode (Recommended)

Install gum and run the script for a guided experience:

```bash
# Install gum (one-time setup)
curl https://awsutils.github.io/install-gum.sh | sh

# Download and run script
curl -O https://awsutils.github.io/vpc.sh
chmod +x vpc.sh

# Run in interactive mode
./vpc.sh
```

### Command-Line Mode

```bash
# Create basic VPC with defaults (2 AZs, single NAT Gateway)
./vpc.sh --name my-vpc

# Create cost-optimized VPC (no NAT Gateway)
./vpc.sh --name my-vpc --nat-gateway none

# Create highly available VPC (NAT per AZ)
./vpc.sh --name my-vpc --nat-gateway per-az --azs 3
```

## Features

### Core Features

- **Multi-AZ Support**: Deploy across 1-3 availability zones for high availability
- **Automatic Subnet Calculation**: Intelligently allocates CIDR blocks for subnets
- **Flexible NAT Gateway Options**: Choose between none, single (cost-effective), or per-AZ (HA)
- **Internet Gateway**: Automatic setup for public subnet internet access
- **Route Tables**: Properly configured public and private routing
- **DNS Support**: Enables DNS hostnames and resolution by default
- **VPC Flow Logs**: Optional CloudWatch Logs integration
- **IPv6 Support**: Optional IPv6 CIDR block allocation
- **Dry Run Mode**: Preview what would be created without actually creating resources
- **Comprehensive Output**: Detailed summary and saved configuration file
- **Colored Output**: Easy-to-read progress indicators and status messages

### Interactive Mode Features

When using [gum](https://github.com/charmbracelet/gum), the script provides:

- **Beautiful TUI**: Styled menus and prompts with colors and borders
- **Guided Workflow**: Step-by-step prompts for all configuration options
- **Region Selection**: Choose from common AWS regions with arrow keys
- **CIDR Presets**: Select from common CIDR blocks or enter custom
- **Multi-Select Options**: Use spacebar to select multiple features
- **Cost Indicators**: See estimated costs for NAT Gateway options
- **Configuration Summary**: Review all settings before creating
- **Confirmation Prompt**: Prevent accidental resource creation
- **Progress Spinners**: Visual feedback for long-running operations
- **Success Banner**: Beautiful completion message

### Installing gum

**One-line installer:**

```bash
curl https://awsutils.github.io/install-gum.sh | sh
```

**Manual installation:**

```bash
# macOS
brew install gum

# Linux (x86_64)
wget https://github.com/charmbracelet/gum/releases/download/v0.14.3/gum_0.14.3_linux_x86_64.tar.gz
tar -xzf gum_0.14.3_linux_x86_64.tar.gz
sudo install gum /usr/local/bin/

# Linux (ARM64)
wget https://github.com/charmbracelet/gum/releases/download/v0.14.3/gum_0.14.3_linux_arm64.tar.gz
tar -xzf gum_0.14.3_linux_arm64.tar.gz
sudo install gum /usr/local/bin/
```

**Note:** gum is automatically installed by [ec2init.sh](./ec2init.sh.md) and [csinit.sh](./csinit.sh.md)!

## Architecture

### Default VPC Layout (2 AZs)

```
VPC: 10.0.0.0/16
│
├── Public Subnets (Internet access via IGW)
│   ├── AZ1: 10.0.0.0/20   (4,096 IPs)
│   └── AZ2: 10.0.16.0/20  (4,096 IPs)
│
└── Private Subnets (Internet access via NAT Gateway)
    ├── AZ1: 10.0.128.0/20 (4,096 IPs)
    └── AZ2: 10.0.144.0/20 (4,096 IPs)

Routing:
- Public Route Table → Internet Gateway (0.0.0.0/0)
- Private Route Table(s) → NAT Gateway(s) (0.0.0.0/0)
```

### High Availability Architecture (NAT per AZ)

```
┌─────────────────────────────────────────────────────┐
│                   VPC: 10.0.0.0/16                  │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │   AZ1            │      │   AZ2            │   │
│  │                  │      │                  │   │
│  │  Public Subnet   │      │  Public Subnet   │   │
│  │  10.0.0.0/20     │      │  10.0.16.0/20    │   │
│  │  ┌────────────┐  │      │  ┌────────────┐  │   │
│  │  │ NAT GW #1  │  │      │  │ NAT GW #2  │  │   │
│  │  └────────────┘  │      │  └────────────┘  │   │
│  │        │         │      │        │         │   │
│  └────────┼─────────┘      └────────┼─────────┘   │
│           │                         │             │
│  ┌────────┼─────────┐      ┌────────┼─────────┐   │
│  │  Private Subnet  │      │  Private Subnet  │   │
│  │  10.0.128.0/20   │      │  10.0.144.0/20   │   │
│  │  (routes to      │      │  (routes to      │   │
│  │   NAT GW #1)     │      │   NAT GW #2)     │   │
│  └──────────────────┘      └──────────────────┘   │
│                                                     │
│           Internet Gateway (IGW)                   │
└─────────────────────────────────────────────────────┘
                        │
                    Internet
```

## Prerequisites

- AWS CLI installed and configured
- IAM permissions to create VPC resources
- Understanding of CIDR notation
- AWS account with available Elastic IPs (for NAT Gateways)

## Usage

### Basic Syntax

```bash
./vpc.sh [OPTIONS]
```

### Options

```
-n, --name NAME              VPC name (required)
-c, --cidr CIDR              VPC CIDR block (default: 10.0.0.0/16)
-r, --region REGION          AWS region (default: from AWS CLI config)
-z, --azs NUM                Number of availability zones (1-3, default: 2)
--nat-gateway TYPE           NAT Gateway type: none, single, per-az (default: single)
--enable-dns-hostnames       Enable DNS hostnames (default: true)
--enable-dns-support         Enable DNS support (default: true)
--enable-flow-logs           Enable VPC Flow Logs to CloudWatch
--ipv6                       Enable IPv6 support
--dry-run                    Preview without creating resources
-h, --help                   Show help message
```

### NAT Gateway Options

| Option   | Description                 | Cost              | High Availability |
| -------- | --------------------------- | ----------------- | ----------------- |
| `none`   | No NAT Gateway              | Free              | N/A               |
| `single` | One NAT Gateway in first AZ | ~$32/month        | ❌ No             |
| `per-az` | One NAT Gateway per AZ      | ~$32/month per AZ | ✅ Yes            |

## Examples

### Basic VPC with Defaults

```bash
./vpc.sh --name my-app-vpc
```

Creates:

- VPC with 10.0.0.0/16 CIDR
- 2 public subnets (one per AZ)
- 2 private subnets (one per AZ)
- 1 NAT Gateway (single)
- Internet Gateway
- Proper routing

### Cost-Optimized VPC (No NAT Gateway)

For applications that don't need outbound internet from private subnets:

```bash
./vpc.sh --name my-app-vpc --nat-gateway none
```

**Use cases:**

- Private database-only VPC
- Use VPC endpoints instead of NAT Gateway
- Development/testing environments
- Cost-sensitive deployments

**Savings:** ~$32/month per NAT Gateway

### Highly Available VPC

Production environment with NAT Gateway per AZ:

```bash
./vpc.sh \
  --name production-vpc \
  --nat-gateway per-az \
  --azs 3 \
  --enable-flow-logs
```

Creates:

- 3 availability zones
- 3 NAT Gateways (one per AZ)
- VPC Flow Logs enabled
- Full redundancy

### Custom CIDR Block

```bash
./vpc.sh \
  --name my-vpc \
  --cidr 172.16.0.0/16
```

Common CIDR blocks:

- `10.0.0.0/16` - Default, 65,536 IPs
- `172.16.0.0/16` - Avoids conflicts with home networks
- `192.168.0.0/16` - Smaller range
- `10.0.0.0/8` - Very large VPC (not recommended)

### VPC with IPv6

```bash
./vpc.sh \
  --name my-vpc \
  --ipv6
```

Enables:

- Amazon-provided IPv6 CIDR block
- Dual-stack networking
- IPv6 routing

### Dry Run (Preview)

See what would be created without actually creating it:

```bash
./vpc.sh \
  --name my-vpc \
  --nat-gateway per-az \
  --azs 3 \
  --dry-run
```

## Subnet Allocation

The script automatically calculates subnet CIDRs based on your VPC CIDR.

### For /16 VPC (Default: 10.0.0.0/16)

Each subnet gets /20 (4,096 IPs):

**2 AZs:**

- Public AZ1: `10.0.0.0/20` (10.0.0.0 - 10.0.15.255)
- Public AZ2: `10.0.16.0/20` (10.0.16.0 - 10.0.31.255)
- Private AZ1: `10.0.128.0/20` (10.0.128.0 - 10.0.143.255)
- Private AZ2: `10.0.144.0/20` (10.0.144.0 - 10.0.159.255)

**3 AZs:**

- Public AZ1: `10.0.0.0/20`
- Public AZ2: `10.0.16.0/20`
- Public AZ3: `10.0.32.0/20`
- Private AZ1: `10.0.128.0/20`
- Private AZ2: `10.0.144.0/20`
- Private AZ3: `10.0.160.0/20`

### Available IPs per Subnet

AWS reserves 5 IPs per subnet:

- `.0` - Network address
- `.1` - VPC router
- `.2` - DNS server
- `.3` - Future use
- `.255` - Broadcast address

For /20 subnet: 4,096 - 5 = **4,091 usable IPs**

## Cost Analysis

### Monthly Cost Breakdown

**Free Components:**

- VPC creation: Free
- Subnets: Free
- Route tables: Free
- Internet Gateway: Free
- DNS queries: Free

**Paid Components:**

| Resource                | Cost        | Notes                                    |
| ----------------------- | ----------- | ---------------------------------------- |
| NAT Gateway             | $0.045/hour | ~$32.40/month per NAT Gateway            |
| NAT Data Transfer       | $0.045/GB   | For data processed                       |
| Elastic IP (unattached) | $0.005/hour | Free when attached to running instance   |
| VPC Flow Logs           | Variable    | CloudWatch Logs data ingestion + storage |

### Cost Scenarios

**Cost-Optimized (--nat-gateway none):**

- Monthly: **$0**
- Use case: Private subnets with VPC endpoints only

**Standard (--nat-gateway single):**

- Monthly: **~$32** + data transfer
- Use case: Dev/test, small production

**High Availability (--nat-gateway per-az, 2 AZs):**

- Monthly: **~$65** + data transfer
- Use case: Production with HA requirements

**High Availability (--nat-gateway per-az, 3 AZs):**

- Monthly: **~$97** + data transfer
- Use case: Mission-critical production

### Cost Optimization Strategies

1. **Use VPC Endpoints Instead of NAT**: For S3, DynamoDB (free gateway endpoints)
2. **Single NAT Gateway**: For non-critical workloads
3. **NAT Instance**: Use EC2 instance instead of NAT Gateway (more management)
4. **Review Data Transfer**: Optimize application to reduce data through NAT
5. **Development VPCs**: Use `--nat-gateway none` for dev environments

## IAM Permissions Required

Minimum permissions needed to create VPC:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:CreateSubnet",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateRouteTable",
        "ec2:CreateRoute",
        "ec2:CreateTags",
        "ec2:AllocateAddress",
        "ec2:AttachInternetGateway",
        "ec2:AssociateRouteTable",
        "ec2:ModifyVpcAttribute",
        "ec2:ModifySubnetAttribute",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeNatGateways",
        "ec2:DescribeRouteTables",
        "ec2:DescribeAvailabilityZones",
        "ec2:AssociateVpcCidrBlock"
      ],
      "Resource": "*"
    }
  ]
}
```

### For VPC Flow Logs

Additional permissions needed if using `--enable-flow-logs`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateFlowLogs",
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:GetRole"
      ],
      "Resource": "*"
    }
  ]
}
```

## Common Use Cases

### 1. Web Application with Database

```bash
./vpc.sh \
  --name webapp-vpc \
  --nat-gateway single \
  --azs 2
```

Architecture:

- Public subnets: Load balancers, bastion hosts
- Private subnets: Application servers, databases
- Single NAT: Cost-effective outbound access

### 2. Microservices with ECS/EKS

```bash
./vpc.sh \
  --name k8s-vpc \
  --cidr 10.0.0.0/16 \
  --nat-gateway per-az \
  --azs 3 \
  --enable-flow-logs
```

Architecture:

- Public subnets: Load balancers
- Private subnets: ECS tasks, EKS pods
- NAT per AZ: High availability
- Flow Logs: Network monitoring

### 3. Data Processing (No NAT)

```bash
./vpc.sh \
  --name data-vpc \
  --nat-gateway none \
  --azs 2

# Create VPC endpoints for S3 access
./add-vpc-endpoint.sh \
  --vpc-id $(cat vpc-data-vpc-info.txt | grep VPC_ID | cut -d'=' -f2) \
  --service s3 \
  --route-tables $(cat vpc-data-vpc-info.txt | grep PUBLIC_RT_ID | cut -d'=' -f2)
```

Architecture:

- Private subnets only
- VPC endpoints for AWS services
- No NAT Gateway costs
- Fully private data processing

### 4. Multi-Tier Application

```bash
./vpc.sh \
  --name app-vpc \
  --cidr 10.100.0.0/16 \
  --nat-gateway per-az \
  --azs 2 \
  --enable-flow-logs
```

Deployment:

- Public subnets: ALB, NAT Gateways
- Private subnets tier 1: Application servers
- Private subnets tier 2: Databases (use additional subnet sets)
- High availability across 2 AZs

### 5. VPN/Hybrid Cloud

```bash
./vpc.sh \
  --name hybrid-vpc \
  --cidr 172.16.0.0/16 \
  --nat-gateway single \
  --azs 2
```

Then add Virtual Private Gateway for VPN:

```bash
aws ec2 create-vpn-gateway --type ipsec.1 --region us-east-1
```

## Verification

### Check VPC Status

```bash
# Get VPC ID from saved file
VPC_ID=$(cat vpc-my-vpc-info.txt | grep VPC_ID | cut -d'=' -f2)

# Describe VPC
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# List all subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# List route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"

# List NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID"
```

### Test Connectivity

**From EC2 in Public Subnet:**

```bash
# Should have internet access directly
curl -I https://www.google.com
```

**From EC2 in Private Subnet:**

```bash
# Should have internet access via NAT Gateway (if enabled)
curl -I https://www.google.com

# Check route
ip route
# Should show route to 0.0.0.0/0 via local gateway
```

### View in AWS Console

```bash
# The script outputs a direct link
https://console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:VpcId=vpc-xxxxx
```

## Troubleshooting

### Issue: "Not enough availability zones available"

**Solution:** Some regions have fewer AZs. Reduce the number:

```bash
# Check available AZs
aws ec2 describe-availability-zones --region us-east-1

# Use fewer AZs
./vpc.sh --name my-vpc --azs 2
```

### Issue: "Could not determine AWS region"

**Solution:** Configure AWS CLI or specify region:

```bash
# Configure default region
aws configure set region us-east-1

# Or specify in command
./vpc.sh --name my-vpc --region us-east-1
```

### Issue: "VPC limit exceeded"

**Solution:** AWS limits VPCs to 5 per region by default:

```bash
# Check current VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]'

# Delete unused VPCs or request limit increase
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE
```

### Issue: "Elastic IP limit exceeded"

**Solution:** NAT Gateways need Elastic IPs. Default limit is 5:

```bash
# Check current EIPs
aws ec2 describe-addresses

# Release unused EIPs
aws ec2 release-address --allocation-id eipalloc-xxxxx

# Or request limit increase
```

### Issue: NAT Gateway not working

**Solution:** Check NAT Gateway status and routes:

```bash
# Check NAT Gateway state
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxxxx

# Check route table
aws ec2 describe-route-tables --route-table-ids rtb-xxxxx

# Verify security groups allow outbound traffic
```

### Issue: DNS resolution not working

**Solution:** Ensure DNS settings are enabled:

```bash
# Check DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-xxxxx --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-xxxxx --attribute enableDnsHostnames

# Enable if needed (script does this by default)
aws ec2 modify-vpc-attribute --vpc-id vpc-xxxxx --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-xxxxx --enable-dns-hostnames
```

### Issue: Script fails partway through

**Solution:** The script is not idempotent. Clean up and retry:

```bash
# List resources created
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-vpc"

# Delete VPC and all dependencies
aws ec2 delete-vpc --vpc-id vpc-xxxxx
# Note: Must delete dependencies first (NAT GW, subnets, IGW, etc.)
```

## Cleanup

To delete the VPC and all associated resources:

```bash
# Source the VPC info file
source vpc-my-vpc-info.txt

# Delete NAT Gateways first (takes a few minutes)
for nat_id in $NAT_GATEWAY_IDS; do
  aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION
done

# Wait for NAT Gateways to be deleted
sleep 120

# Release Elastic IPs
aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=my-vpc*" \
  --query 'Addresses[*].AllocationId' \
  --output text | xargs -n1 aws ec2 release-address --allocation-id

# Detach and delete Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION

# Delete subnets
for subnet_id in $PUBLIC_SUBNET_IDS $PRIVATE_SUBNET_IDS; do
  aws ec2 delete-subnet --subnet-id $subnet_id --region $REGION
done

# Delete route tables (excluding main)
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[0].Main != `true`].RouteTableId' \
  --output text --region $REGION | xargs -n1 aws ec2 delete-route-table --route-table-id

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

echo "VPC $VPC_ID deleted"
```

### Quick Cleanup Script

```bash
#!/bin/bash
VPC_ID="vpc-xxxxx"  # Replace with your VPC ID
REGION="us-east-1"

# Delete all NAT Gateways
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text --region $REGION | xargs -n1 aws ec2 delete-nat-gateway --nat-gateway-id

sleep 120  # Wait for NAT GW deletion

# Delete VPC (AWS will reject if dependencies exist)
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
```

## Automation with Terraform

Alternative Infrastructure as Code approach:

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20"]
  private_subnets = ["10.0.128.0/20", "10.0.144.0/20"]

  enable_nat_gateway   = true
  single_nat_gateway   = true  # Set to false for NAT per AZ
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                      = true
  flow_log_destination_type            = "cloud-watch-logs"
  create_flow_log_cloudwatch_log_group = true

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## Best Practices

1. **Use Multiple AZs**: Deploy across at least 2 AZs for high availability
2. **Right-size CIDR**: Choose CIDR block that allows for growth but isn't wastefully large
3. **Tag Everything**: Use consistent tagging for cost allocation and management
4. **Enable Flow Logs**: For security monitoring and troubleshooting
5. **NAT per AZ for Production**: Use `per-az` NAT Gateway for production workloads
6. **Use VPC Endpoints**: Reduce NAT Gateway costs by using VPC endpoints for AWS services
7. **Document Architecture**: Keep network diagrams and documentation updated
8. **Separate VPCs**: Use separate VPCs for different environments (dev, staging, prod)
9. **Plan IP Addressing**: Avoid overlapping CIDR blocks with on-premises networks
10. **Security Groups**: Plan security group strategy before deploying instances

## Advanced Configurations

### Peering with Existing VPC

After creating VPC, peer with another VPC:

```bash
# Create peering connection
aws ec2 vpc-peering-connection \
  --vpc-id vpc-xxxxx \
  --peer-vpc-id vpc-yyyyy \
  --region us-east-1
```

### Transit Gateway Attachment

Connect to Transit Gateway for hub-and-spoke topology:

```bash
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxxxx \
  --vpc-id vpc-xxxxx \
  --subnet-ids subnet-xxxxx subnet-yyyyy
```

### VPN Configuration

Add VPN access:

```bash
# Create customer gateway
aws ec2 create-customer-gateway \
  --type ipsec.1 \
  --public-ip 203.0.113.12 \
  --bgp-asn 65000

# Create virtual private gateway
aws ec2 create-vpn-gateway --type ipsec.1

# Attach to VPC
aws ec2 attach-vpn-gateway \
  --vpn-gateway-id vgw-xxxxx \
  --vpc-id vpc-xxxxx
```

## Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [VPC Pricing](https://aws.amazon.com/vpc/pricing/)
- [NAT Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [CIDR Calculator](https://www.ipaddressguide.com/cidr)

## Support

For issues with:

- **AWS VPC**: Contact [AWS Support](https://aws.amazon.com/support/)
- **This script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Scripts

- [add-vpc-endpoint.sh](./add-vpc-endpoint.sh.md) - Add VPC endpoints to your VPC
- [ec2init.sh](./ec2init.sh.md) - Initialize EC2 instances in your VPC
- [csinit.sh](./csinit.sh.md) - CloudShell initialization

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Best Practices](../docs/best-practices.md)
- [Configuration Guide](../docs/configuration.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)
