---
sidebar_position: 11
---

# ec2init.sh

Complete EC2 instance initialization script for AWS, Terraform, Kubernetes, and container development workflows.

## Overview

`ec2init.sh` is a comprehensive initialization script designed for Amazon Linux 2023 EC2 instances. It transforms a fresh EC2 instance into a fully-equipped development environment with AWS CLI, Terraform, Kubernetes tools (kubectl, eksctl, Helm, k9s), database clients, Docker with multi-architecture support, and useful shell aliases.

## Quick Install

```bash
curl https://awsutils.github.io/ec2init.sh | bash
```

## Features

- **Shell Configuration**: Terraform and kubectl aliases for faster workflow
- **AWS Tools**: AWS CLI v2 for AWS service management
- **Kubernetes Tools**: kubectl, eksctl, Helm, k9s for cluster management
- **Database Clients**: MariaDB, PostgreSQL, Redis clients
- **Container Tools**: Docker with multi-architecture build support
- **Development Tools**: jq, curl, wget, git
- **Architecture Support**: Automatic detection for AMD64 and ARM64
- **Persistent Multi-arch**: Systemd service for multi-architecture Docker builds across reboots

## Prerequisites

- Amazon Linux 2023 EC2 instance
- Internet connectivity
- Root or sudo access
- At least 2GB free disk space

## What Gets Installed

### Shell Aliases

The script adds the following aliases to `~/.bashrc`:

**Terraform aliases:**
```bash
alias t="terraform"              # Shortcut for terraform
alias ti="terraform init"         # Initialize terraform
alias taa="terraform apply --auto-approve --parallelism 100"  # Fast apply
alias td="terraform destroy --parallelism 100"                # Fast destroy
```

**Kubernetes aliases:**
```bash
alias k="kubectl"                # Shortcut for kubectl
alias ka="kubectl apply -f"      # Apply manifest
alias kx="kubectl delete -f"     # Delete resources
alias kd="kubectl describe -f"   # Describe resources
alias kg="kubectl get pod -f"    # Get pods from file
```

**Environment variables:**
```bash
export EDITOR="vim"              # Set vim as default editor
```

### Installed Packages

**System utilities:**
- `jq` - JSON processor
- `curl` - Transfer tool
- `wget` - Download tool
- `git` - Version control
- `docker` - Container runtime

**Database clients:**
- `mariadb1011` - MariaDB 10.11 client
- `postgresql17` - PostgreSQL 17 client
- `redis6` - Redis 6 client

**AWS and Kubernetes tools:**
- `awscli` v2 - AWS Command Line Interface
- `kubectl` - Kubernetes CLI
- `eksctl` - EKS cluster management
- `helm` - Kubernetes package manager
- `k9s` - Kubernetes terminal UI

### Docker Configuration

- Docker service enabled and auto-started
- `ec2-user` added to docker group (no sudo needed)
- `ssm-user` added to docker group (for SSM sessions)
- Multi-architecture support via QEMU binfmt
- Systemd service for persistent multi-arch across reboots

## Installation Methods

### Method 1: Direct Installation (Recommended)

```bash
# Run as root or with sudo
curl https://awsutils.github.io/ec2init.sh | bash
```

### Method 2: Download and Review

```bash
# Download script
curl -o ec2init.sh https://awsutils.github.io/ec2init.sh

# Review script
cat ec2init.sh

# Make executable
chmod +x ec2init.sh

# Run installation
./ec2init.sh
```

### Method 3: EC2 User Data

Add to your EC2 instance user data for automatic setup on launch:

```bash
#!/bin/bash
curl https://awsutils.github.io/ec2init.sh | bash
```

### Method 4: CloudFormation

```yaml
Resources:
  MyEC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: t3.medium
      UserData:
        Fn::Base64: |
          #!/bin/bash
          curl https://awsutils.github.io/ec2init.sh | bash
```

### Method 5: Terraform

```hcl
resource "aws_instance" "dev" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.medium"

  user_data = <<-EOF
    #!/bin/bash
    curl https://awsutils.github.io/ec2init.sh | bash
  EOF
}
```

## Post-Installation

### Reload Shell Configuration

Log out and log back in, or reload bashrc:

```bash
# Log out and back in (recommended)
exit

# Or reload bashrc
source ~/.bashrc
```

### Verify Installations

```bash
# Check all tools
aws --version
terraform version
kubectl version --client
eksctl version
helm version
k9s version
docker --version

# Test aliases
t version
k version --client

# Test Docker (no sudo needed after re-login)
docker ps
```

## Common Use Cases

### AWS Management

```bash
# Configure AWS CLI
aws configure

# Or use IAM role (recommended for EC2)
aws sts get-caller-identity

# List S3 buckets
aws s3 ls

# Describe EC2 instances
aws ec2 describe-instances
```

### Terraform Workflows

```bash
# Initialize Terraform project
ti

# Plan changes
t plan

# Apply with auto-approval
taa

# Destroy infrastructure
td
```

### Kubernetes Cluster Management

```bash
# Create EKS cluster
eksctl create cluster --name my-cluster --region us-east-1

# Update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# View cluster with k9s
k9s

# Deploy with kubectl
k apply -f deployment.yaml

# Install chart with Helm
helm install my-app ./my-chart
```

### Database Connections

```bash
# Connect to RDS MySQL/MariaDB
mysql -h my-db.abc123.us-east-1.rds.amazonaws.com -u admin -p

# Connect to RDS PostgreSQL
psql -h my-db.abc123.us-east-1.rds.amazonaws.com -U postgres -d mydb

# Connect to ElastiCache Redis
redis-cli -h my-redis.abc123.0001.use1.cache.amazonaws.com -p 6379
```

### Multi-Architecture Docker Builds

```bash
# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest .

# Build ARM64 image on x86_64 instance
docker build --platform linux/arm64 -t myapp:arm64 .

# Run ARM64 container on x86_64 (via QEMU)
docker run --platform linux/arm64 myapp:arm64

# Push multi-arch image to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker buildx build --platform linux/amd64,linux/arm64 -t 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest --push .
```

## Architecture Support

The script automatically detects your EC2 instance architecture:

| Instance Family | Architecture | Detected As | All Tools Supported |
|-----------------|--------------|-------------|---------------------|
| t3, m5, c5, r5 | x86_64 (Intel) | amd64/x86_64 | ✅ Yes |
| t4g, m6g, c6g, r6g | ARM64 (Graviton) | arm64/aarch64 | ✅ Yes |

## Systemd Services

### Docker Service

Docker is configured to start automatically:

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# View Docker logs
sudo journalctl -u docker -f
```

### Multi-Architecture Support Service

A systemd service ensures multi-arch support persists across reboots:

```bash
# Check binfmt service status
sudo systemctl status binfmt-qemu

# Restart service
sudo systemctl restart binfmt-qemu

# View service logs
sudo journalctl -u binfmt-qemu
```

## IAM Permissions

### Required IAM Role Permissions

For full functionality, attach an IAM role with these permissions to your EC2 instance:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "s3:*",
        "cloudformation:*",
        "iam:PassRole",
        "iam:CreateServiceLinkedRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### Least Privilege Example

For read-only access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "ec2:Describe*",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
```

## Troubleshooting

### Issue: "yum: command not found"

**Solution:** This script is designed for Amazon Linux 2023. Verify your OS:

```bash
cat /etc/os-release

# Should show Amazon Linux 2023
# For Amazon Linux 2, you may need to modify the script
```

### Issue: Docker permission denied

**Solution:** After installation, you need to log out and back in:

```bash
# Log out
exit

# SSH back in
ssh ec2-user@your-instance

# Now test
docker ps
```

Or manually reload groups:

```bash
newgrp docker
docker ps
```

### Issue: Multi-arch builds failing

**Solution:** Verify binfmt service is running:

```bash
# Check service status
sudo systemctl status binfmt-qemu

# Restart service
sudo systemctl restart binfmt-qemu

# Verify multi-arch support
docker run --rm --platform linux/arm64 alpine uname -m
# Should output: aarch64
```

### Issue: AWS CLI not configured

**Solution:** Configure credentials or use IAM role:

```bash
# Method 1: Configure credentials
aws configure

# Method 2: Use IAM instance role (recommended)
# Attach IAM role to EC2 instance in AWS Console

# Verify
aws sts get-caller-identity
```

### Issue: kubectl connection refused

**Solution:** Update kubeconfig for your EKS cluster:

```bash
# For EKS clusters
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Verify connection
kubectl get nodes
```

### Issue: Terraform state locking issues

**Solution:** Use S3 backend with DynamoDB for state locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Updating Tools

To update all tools to their latest versions, re-run the script:

```bash
curl https://awsutils.github.io/ec2init.sh | bash
```

Individual tool updates:

```bash
# Update AWS CLI
cd ~/.tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update

# Update kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Uninstallation

To remove installed tools:

```bash
# Remove packages
sudo yum remove -y jq curl wget git mariadb1011 postgresql17 docker redis6

# Remove AWS CLI
sudo rm -rf /usr/local/aws-cli /usr/local/bin/aws /usr/local/bin/aws_completer

# Remove kubectl, eksctl, helm, k9s
sudo rm /usr/local/bin/kubectl /usr/local/bin/eksctl /usr/local/bin/helm /usr/local/bin/k9s

# Remove systemd service
sudo systemctl disable binfmt-qemu
sudo rm /etc/systemd/system/binfmt-qemu.service

# Remove aliases (edit ~/.bashrc)
nano ~/.bashrc
```

## Security Considerations

- **Script Execution**: Always review scripts before running them
- **IAM Roles**: Use IAM instance roles instead of hardcoded credentials
- **Auto-Approve**: The `taa` alias bypasses Terraform confirmation - use carefully
- **Docker Access**: Users in docker group have root-equivalent permissions
- **Privileged Containers**: Multi-arch setup uses privileged containers
- **Database Clients**: Ensure connections use SSL/TLS in production

## EC2 Instance Recommendations

### Minimum Requirements

- **Instance Type**: t3.small or larger
- **Storage**: 20GB gp3 EBS volume
- **AMI**: Amazon Linux 2023
- **Network**: Public subnet with internet gateway (for downloads)

### Recommended for Development

```hcl
resource "aws_instance" "dev" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.medium"  # 2 vCPU, 4GB RAM

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  iam_instance_profile = aws_iam_instance_profile.dev.name

  vpc_security_group_ids = [aws_security_group.dev.id]
  subnet_id              = aws_subnet.public.id

  user_data = file("${path.module}/ec2init.sh")

  tags = {
    Name = "dev-workstation"
  }
}
```

## Differences from csinit.sh

| Feature | ec2init.sh | csinit.sh |
|---------|-----------|-----------|
| Target Environment | EC2 Instances | AWS CloudShell |
| AWS CLI | Installs AWS CLI v2 | Pre-installed |
| kubectl | Installs kubectl | Uses CloudShell's |
| eksctl | Installs eksctl | Uses CloudShell's |
| Helm | Installs Helm | Uses CloudShell's |
| Database Clients | Included | Not included |
| Docker Setup | Full setup with users | Minimal setup |
| Persistence | Systemd service for multi-arch | Not needed |
| User Data Support | ✅ Yes | ❌ No |

## Best Practices

1. **Use IAM roles** instead of access keys
2. **Tag your resources** for cost tracking
3. **Use version control** for Terraform and Kubernetes manifests
4. **Enable CloudWatch** for monitoring
5. **Regular updates**: Re-run script periodically for latest tools
6. **Test in dev first**: Always test changes in development environment
7. **Backup important data**: Use EBS snapshots or S3
8. **Use Systems Manager**: Connect via SSM instead of SSH when possible
9. **Encrypt EBS volumes**: Enable encryption for security
10. **Monitor costs**: Use AWS Cost Explorer and set billing alarms

## Additional Resources

- [Amazon Linux 2023 Documentation](https://docs.aws.amazon.com/linux/al2023/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

For issues with:

- **EC2 instances**: Contact [AWS Support](https://aws.amazon.com/support/)
- **Installation script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)
- **AWS CLI**: Visit [AWS CLI GitHub](https://github.com/aws/aws-cli/issues)
- **kubectl**: Visit [Kubernetes GitHub](https://github.com/kubernetes/kubectl/issues)
- **eksctl**: Visit [eksctl GitHub](https://github.com/eksctl-io/eksctl/issues)

## Related Scripts

- [csinit.sh](./csinit.sh.md) - CloudShell initialization
- [kubectl.sh](./kubectl.sh.md) - Install kubectl only
- [eksctl.sh](./eksctl.sh.md) - Install eksctl only
- [k9s.sh](./k9s.sh.md) - Install k9s only
- [helm.sh](./helm.sh.md) - Install Helm only

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Best Practices](../docs/best-practices.md)
- [Configuration Guide](../docs/configuration.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)
