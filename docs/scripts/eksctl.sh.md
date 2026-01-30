---
sidebar_position: 2
---

# eksctl.sh

Install and configure eksctl, the official CLI for Amazon EKS (Elastic Kubernetes Service).

## Overview

`eksctl` is a simple CLI tool for creating and managing Kubernetes clusters on Amazon EKS. This script automates the installation process for Linux and macOS systems.

## Quick Install

```bash
curl https://awsutils.github.io/eksctl.sh | sh
```

## Features

- Automatic OS detection (Linux/macOS)
- Latest version installation
- Checksum verification
- Automatic PATH configuration
- Permission management

## Prerequisites

- Bash shell (version 4+)
- `curl` or `wget`
- `tar` (for extraction)
- Sudo access (for system-wide installation)

## Installation Methods

### Method 1: Direct Installation

```bash
curl https://awsutils.github.io/eksctl.sh | sh
```

### Method 2: Download and Review

```bash
# Download script
curl -o eksctl.sh https://awsutils.github.io/eksctl.sh

# Review script
cat eksctl.sh

# Make executable
chmod +x eksctl.sh

# Run installation
./eksctl.sh
```

### Method 3: Custom Installation Location

```bash
# Install to custom directory
INSTALL_DIR=$HOME/bin curl https://awsutils.github.io/eksctl.sh | sh
```

## Usage Options

```bash
./eksctl.sh [OPTIONS]
```

### Available Options

| Option              | Description                   |
| ------------------- | ----------------------------- |
| `--version VERSION` | Install specific version      |
| `--install-dir DIR` | Custom installation directory |
| `--help`            | Display help information      |

### Examples

**Install latest version:**

```bash
./eksctl.sh
```

**Install specific version:**

```bash
./eksctl.sh --version 0.150.0
```

**Custom installation directory:**

```bash
./eksctl.sh --install-dir /usr/local/bin
```

## Verification

After installation, verify eksctl is working:

```bash
# Check version
eksctl version

# Check help
eksctl help

# List available commands
eksctl --help
```

## Configuration

### AWS Credentials

Ensure AWS credentials are configured:

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### Required IAM Permissions

The IAM user/role running eksctl needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "cloudformation:*",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:PutRolePolicy",
        "iam:AddRoleToInstanceProfile",
        "iam:PassRole",
        "iam:DetachRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*"
    }
  ]
}
```

## Common Use Cases

### Create EKS Cluster

```bash
# Create a basic cluster
eksctl create cluster --name my-cluster --region us-east-1

# Create cluster with specific node configuration
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4
```

### Manage Node Groups

```bash
# List node groups
eksctl get nodegroup --cluster my-cluster

# Scale node group
eksctl scale nodegroup \
  --cluster my-cluster \
  --name standard-workers \
  --nodes 5

# Delete node group
eksctl delete nodegroup \
  --cluster my-cluster \
  --name standard-workers
```

### Delete Cluster

```bash
# Delete cluster and all resources
eksctl delete cluster --name my-cluster --region us-east-1
```

### Update kubeconfig

```bash
# Update kubeconfig to access cluster
eksctl utils write-kubeconfig --cluster my-cluster
```

## Troubleshooting

### Issue: "eksctl: command not found"

**Solution:**

```bash
# Check if eksctl is in PATH
which eksctl

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin

# Or add to shell profile
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Installation fails

**Check logs and retry:**

```bash
# Enable debug mode
set -x
./eksctl.sh
set +x
```

### Issue: Permission denied

**Solution:**

```bash
# Run with sudo for system-wide installation
sudo ./eksctl.sh

# Or install to user directory
INSTALL_DIR=$HOME/bin ./eksctl.sh
```

## Updating eksctl

To update to the latest version:

```bash
# Re-run the installation script
curl https://awsutils.github.io/eksctl.sh | sh

# Verify new version
eksctl version
```

## Uninstallation

To remove eksctl:

```bash
# Remove binary
sudo rm /usr/local/bin/eksctl

# Or if installed in custom location
rm $HOME/bin/eksctl
```

## Additional Resources

- [eksctl Official Documentation](https://eksctl.io/)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [eksctl GitHub Repository](https://github.com/weaveworks/eksctl)

## Support

For issues with:

- **eksctl tool**: Visit [eksctl GitHub](https://github.com/weaveworks/eksctl/issues)
- **Installation script**: Open issue on [awsutils GitHub](https://github.com/awsutils/awsutils.github.io/issues)

## Related Scripts

- kubectl.sh - Install kubectl
- aws-cli.sh - Install AWS CLI v2
- helm.sh - Install Helm package manager

## See Also

- [Getting Started Guide](../docs/getting-started.md)
- [Configuration Guide](../docs/configuration.md)
- [Best Practices](../docs/best-practices.md)
