---
sidebar_position: 12
---

# vpce.sh

Automate VPC endpoint creation for gateway and interface endpoints with proper security group and subnet configurations.

## Overview

`vpce.sh` is a VPC endpoint provisioning script that creates both gateway endpoints (S3, DynamoDB) and interface endpoints (EC2, SSM, ECR, CloudWatch Logs, etc.) for a given VPC. It automatically detects private subnets, creates a dedicated security group, and associates endpoints with the correct route tables and subnets.

## Quick Install

```bash
curl -o vpce.sh https://awsutils.github.io/vpce.sh && chmod +x vpce.sh
```

## Features

- **Gateway Endpoints**: Creates S3 and DynamoDB gateway endpoints attached to all route tables
- **Interface Endpoints**: Creates 10 common interface endpoints for private connectivity
- **Private Subnet Detection**: Automatically identifies private subnets (no IGW route)
- **Security Group Management**: Creates or reuses a `vpc-endpoint-sg` security group allowing all VPC CIDR traffic
- **VPC Validation**: Validates the provided VPC ID before proceeding
- **Region Auto-Detection**: Uses the configured AWS CLI region
- **Colored Output**: Clear color-coded status messages for each operation

## Prerequisites

- AWS CLI installed and configured
- IAM permissions for VPC endpoint management (see [IAM Permissions](#iam-permissions))
- A VPC with at least one private subnet (for interface endpoints)
- Internet connectivity (to reach AWS APIs)

## What Gets Created

### Gateway Endpoints

Gateway endpoints are added to all route tables in the VPC:

| Service | Endpoint |
|---------|----------|
| Amazon S3 | `com.amazonaws.<region>.s3` |
| Amazon DynamoDB | `com.amazonaws.<region>.dynamodb` |

### Interface Endpoints

Interface endpoints are created in private subnets with private DNS enabled:

| Service | Endpoint | Purpose |
|---------|----------|---------|
| EC2 | `com.amazonaws.<region>.ec2` | EC2 API calls |
| EC2 Messages | `com.amazonaws.<region>.ec2messages` | SSM agent communication |
| SSM | `com.amazonaws.<region>.ssm` | Systems Manager |
| SSM Messages | `com.amazonaws.<region>.ssmmessages` | Session Manager |
| CloudWatch Logs | `com.amazonaws.<region>.logs` | Log delivery |
| STS | `com.amazonaws.<region>.sts` | Assume role / token |
| Secrets Manager | `com.amazonaws.<region>.secretsmanager` | Secret retrieval |
| KMS | `com.amazonaws.<region>.kms` | Encryption key operations |
| ECR API | `com.amazonaws.<region>.ecr.api` | Container image metadata |
| ECR Docker | `com.amazonaws.<region>.ecr.dkr` | Container image pulls |

### Security Group

A security group named `vpc-endpoint-sg` is created (or reused if it already exists):

- **Inbound**: All traffic from VPC CIDR block
- **Outbound**: Default (all traffic)

## Usage

### Interactive Mode

```bash
./vpce.sh
# Prompts: Enter VPC ID: vpc-0abc123def456789
```

### With VPC ID Argument

```bash
./vpce.sh vpc-0abc123def456789
```

### Download and Run

```bash
curl -o vpce.sh https://awsutils.github.io/vpce.sh
chmod +x vpce.sh
./vpce.sh vpc-0abc123def456789
```

## How It Works

1. **Validates** the provided VPC ID via the AWS API
2. **Detects** the AWS region from CLI configuration (defaults to `us-east-1`)
3. **Retrieves** the VPC CIDR block
4. **Fetches** all route tables in the VPC
5. **Identifies** private subnets by checking route tables for the absence of an internet gateway route
6. **Creates** a security group (`vpc-endpoint-sg`) allowing all traffic from the VPC CIDR
7. **Creates** S3 and DynamoDB gateway endpoints associated with all route tables
8. **Creates** interface endpoints in private subnets with private DNS enabled

## Common Use Cases

### Private EKS Cluster Access

Enable private EKS nodes to pull images and communicate with AWS services without a NAT gateway:

```bash
# Create endpoints for the EKS VPC
./vpce.sh vpc-0abc123def456789
```

This creates ECR, EC2, SSM, STS, and CloudWatch Logs endpoints needed by EKS worker nodes.

### Replacing NAT Gateway

Reduce data transfer costs by routing AWS API traffic through VPC endpoints instead of a NAT gateway:

```bash
# Create all endpoints
./vpce.sh vpc-0abc123def456789

# Verify S3 traffic uses the gateway endpoint
aws s3 ls  # Traffic stays within the AWS network
```

### Systems Manager (SSM) Session Access

Enable SSM Session Manager for EC2 instances in private subnets:

```bash
./vpce.sh vpc-0abc123def456789

# Now connect via SSM without internet access
aws ssm start-session --target i-0abc123def456789
```

### Terraform Integration

Use with Terraform to set up endpoints after VPC creation:

```hcl
resource "null_resource" "vpc_endpoints" {
  provisioner "local-exec" {
    command = "./vpce.sh ${aws_vpc.main.id}"
  }

  depends_on = [aws_vpc.main, aws_subnet.private]
}
```

## IAM Permissions

### Required Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcEndpoints",
        "ec2:CreateVpcEndpoint",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": "*"
    }
  ]
}
```

## Troubleshooting

### Issue: "VPC not found or invalid"

**Solution:** Verify the VPC ID and ensure your AWS CLI is configured for the correct region:

```bash
# Check configured region
aws configure get region

# List VPCs in current region
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Issue: "No private subnets found"

**Solution:** The script identifies private subnets by checking for the absence of an internet gateway route. Only gateway endpoints (S3, DynamoDB) will be created if no private subnets are found.

```bash
# Verify subnet routing
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=vpc-0abc123def456789" \
  --query 'RouteTables[*].{ID:RouteTableId,Routes:Routes[*].GatewayId}' \
  --output table
```

### Issue: Interface endpoint creation fails

**Solution:** Common causes include:

- **Duplicate endpoint**: An endpoint for that service already exists in the VPC
- **Service not available**: The service may not be available in your region
- **Subnet AZ mismatch**: The endpoint service may not support all availability zones

```bash
# Check existing endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-0abc123def456789" \
  --query 'VpcEndpoints[*].[ServiceName,State]' \
  --output table

# Check available services in region
aws ec2 describe-vpc-endpoint-services \
  --query 'ServiceNames[?contains(@, `ssm`)]'
```

### Issue: Security group already exists

**Solution:** The script reuses an existing `vpc-endpoint-sg` security group. If you need to recreate it:

```bash
# Find existing security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=vpc-endpoint-sg" "Name=vpc-id,Values=vpc-0abc123def456789" \
  --query 'SecurityGroups[*].GroupId' --output text

# Delete if needed (detach from endpoints first)
aws ec2 delete-security-group --group-id sg-0abc123def456789
```

## Cleanup

To remove created endpoints and the security group:

```bash
# List endpoints in VPC
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-0abc123def456789" \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName]' \
  --output table

# Delete endpoints
aws ec2 delete-vpc-endpoints \
  --vpc-endpoint-ids vpce-0abc123 vpce-0def456

# Delete security group (after endpoints are removed)
aws ec2 delete-security-group --group-id sg-0abc123def456789
```

## Security Considerations

- **Script Review**: Always review scripts before running them
- **Security Group Scope**: The created security group allows all traffic from the VPC CIDR; restrict further if needed
- **Private DNS**: Interface endpoints enable private DNS, which overrides public DNS resolution for the service within the VPC
- **IAM Policies**: Endpoint policies default to full access; consider adding restrictive endpoint policies for production
- **Least Privilege**: Use the minimal IAM permissions listed above

## Best Practices

1. **Review before running**: Always inspect the script before execution
2. **Test in non-production**: Run in a dev/staging VPC first
3. **Add endpoint policies**: Restrict endpoint access with resource-based policies for production
4. **Monitor costs**: Interface endpoints incur hourly charges and data processing fees
5. **Tag endpoints**: Add tags after creation for cost allocation and organization
6. **Use with private subnets**: Interface endpoints are most valuable in private subnets without NAT gateways

## Additional Resources

- [AWS VPC Endpoints Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [Interface Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html)
- [VPC Endpoint Pricing](https://aws.amazon.com/privatelink/pricing/)

## Support

For issues with:

- **VPC Endpoints**: Contact [AWS Support](https://aws.amazon.com/support/)
- **Installation script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)
- **AWS CLI**: Visit [AWS CLI GitHub](https://github.com/aws/aws-cli/issues)

## Related Scripts

- [csinit.sh](./csinit.sh.md) - CloudShell initialization
- [ec2init.sh](./ec2init.sh.md) - EC2 instance initialization

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Best Practices](../docs/best-practices.md)
- [Configuration Guide](../docs/configuration.md)
