---
sidebar_position: 1
---

# Scripts Overview

Welcome to the awsutils Scripts documentation. This section contains detailed information about all available scripts and tools.

## Available Scripts

### Installation Tools

Scripts to help you install and configure AWS tools and utilities.

#### eksctl.sh

Install eksctl, a CLI tool for creating and managing Kubernetes clusters on Amazon EKS.

**Quick Install:**

```bash
curl https://awsutils.github.io/eksctl.sh | sh
```

[View detailed documentation →](./eksctl.sh.md)

### Coming Soon

More scripts are being added regularly. Check back soon for:

- **AWS CLI v2 Installer** - Automated AWS CLI installation and configuration
- **kubectl Installer** - Install and configure kubectl for Kubernetes management
- **Terraform Installer** - Install specific Terraform versions
- **Session Manager Plugin** - Install AWS Systems Manager Session Manager plugin

## Script Categories

### Infrastructure Management

Scripts for managing AWS infrastructure:

- EC2 instance management
- VPC configuration and setup
- Security group automation
- Load balancer configuration

### Container Tools

Tools for container and Kubernetes management:

- EKS cluster operations
- ECR repository management
- Container image utilities
- Kubernetes deployment helpers

### Backup and Recovery

Automated backup solutions:

- S3 bucket backup and sync
- EBS snapshot automation
- RDS backup management
- Cross-region replication

### Cost Optimization

Scripts to help reduce AWS costs:

- Unused resource identification
- Instance rightsizing recommendations
- S3 storage class optimization
- Reserved Instance utilization

### Security and Compliance

Security automation tools:

- IAM policy auditing
- Security group analysis
- Encryption verification
- Compliance reporting

### Monitoring and Logging

Observability utilities:

- CloudWatch log analysis
- Metric collection and reporting
- Alert configuration
- Performance monitoring

## How to Use Scripts

### Method 1: Direct Execution

Run scripts directly from the hosted repository:

```bash
curl https://awsutils.github.io/[script-name] | sh
```

**Example:**

```bash
curl https://awsutils.github.io/eksctl.sh | sh
```

### Method 2: Download and Execute

Download the script first, review it, then execute:

```bash
# Download
curl -o script.sh https://awsutils.github.io/[script-name]

# Review
cat script.sh

# Make executable
chmod +x script.sh

# Execute
./script.sh
```

### Method 3: Clone Repository

Clone the entire repository for local use:

```bash
# Clone repository
git clone https://github.com/awsutils/awsutils.github.io.git
cd awsutils.github.io

# Navigate to scripts
cd scripts

# Run script
./script.sh
```

## Common Script Options

Most scripts support these standard options:

| Option              | Description                               |
| ------------------- | ----------------------------------------- |
| `--help`, `-h`      | Display help information                  |
| `--version`, `-v`   | Show version information                  |
| `--dry-run`, `-d`   | Simulate execution without making changes |
| `--verbose`         | Enable detailed output                    |
| `--region REGION`   | Specify AWS region                        |
| `--profile PROFILE` | Use specific AWS profile                  |
| `--force`, `-f`     | Skip confirmation prompts                 |
| `--quiet`, `-q`     | Suppress non-error output                 |

**Examples:**

```bash
# Show help
./script.sh --help

# Dry run mode
./script.sh --dry-run

# Verbose output
./script.sh --verbose

# Specific region
./script.sh --region us-west-2

# Use AWS profile
./script.sh --profile production

# Combine options
./script.sh --region eu-west-1 --profile staging --verbose
```

## Prerequisites

Before running any script, ensure you have:

### 1. AWS CLI

```bash
# Check if installed
aws --version

# Install if needed (macOS)
brew install awscli

# Install if needed (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. AWS Credentials

```bash
# Configure credentials
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 3. Required Tools

Common dependencies:

- **bash** (version 4+)
- **curl** or **wget**
- **jq** (JSON processor)
- **git** (for cloning repository)

```bash
# Install jq (macOS)
brew install jq

# Install jq (Ubuntu/Debian)
sudo apt-get install jq

# Install jq (RHEL/CentOS)
sudo yum install jq
```

### 4. IAM Permissions

Scripts require different permissions based on functionality. Check individual script documentation for specific requirements.

**Basic permissions most scripts need:**

- `sts:GetCallerIdentity` - Verify credentials
- Service-specific read/write permissions

## Best Practices

### 1. Review Before Running

Always review scripts before execution:

```bash
# View script content
curl https://awsutils.github.io/script.sh

# Or
wget -O - https://awsutils.github.io/script.sh | less
```

### 2. Use Dry Run Mode

Test with dry run when available:

```bash
./script.sh --dry-run
```

### 3. Start with Non-Production

Test in development/staging environments first:

```bash
# Use development profile
./script.sh --profile development

# Or set environment variable
export AWS_PROFILE=development
./script.sh
```

### 4. Backup Important Data

Before running scripts that modify resources:

```bash
# Backup example
aws s3 sync s3://my-bucket s3://my-bucket-backup
```

### 5. Use Version Control

Track your configurations:

```bash
git init
git add config.conf
git commit -m "Initial configuration"
```

## Environment Variables

Scripts respect these common environment variables:

| Variable             | Description        | Example         |
| -------------------- | ------------------ | --------------- |
| `AWS_REGION`         | Default AWS region | `us-east-1`     |
| `AWS_PROFILE`        | AWS profile to use | `production`    |
| `AWS_DEFAULT_REGION` | Fallback region    | `us-west-2`     |
| `AWSUTILS_DEBUG`     | Enable debug mode  | `true`          |
| `AWSUTILS_DRY_RUN`   | Enable dry run     | `true`          |
| `AWSUTILS_LOG_LEVEL` | Logging level      | `INFO`, `DEBUG` |

**Usage:**

```bash
# Set region
export AWS_REGION=eu-west-1

# Enable debug mode
export AWSUTILS_DEBUG=true

# Run script
./script.sh
```

## Configuration Files

Scripts can read configuration from:

### 1. Global Configuration

**Location:** `~/.awsutils/config`

```bash
# Create global config
mkdir -p ~/.awsutils
cat > ~/.awsutils/config <<EOF
DEFAULT_REGION=us-east-1
LOG_LEVEL=INFO
DRY_RUN=false
EOF
```

### 2. Script-Specific Configuration

**Location:** `~/.awsutils/[script-name].conf`

```bash
# Example: eksctl configuration
cat > ~/.awsutils/eksctl.conf <<EOF
EKSCTL_VERSION=0.150.0
INSTALL_DIR=/usr/local/bin
AUTO_UPDATE=true
EOF
```

### 3. Local Configuration

**Location:** `./config.conf` (in script directory)

```bash
# Local project configuration
cat > config.conf <<EOF
ENVIRONMENT=production
BACKUP_RETENTION=30
NOTIFICATION_EMAIL=admin@example.com
EOF
```

## Security Considerations

### 1. Script Verification

Verify script authenticity:

```bash
# Check script hash (if provided)
curl -sL https://awsutils.github.io/script.sh | sha256sum

# Compare with published hash
```

### 2. Least Privilege

Use IAM roles/policies with minimum required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:DescribeInstances", "ec2:DescribeRegions"],
      "Resource": "*"
    }
  ]
}
```

### 3. Credential Management

- Never hardcode credentials in scripts
- Use IAM roles when running on EC2/ECS/Lambda
- Rotate credentials regularly
- Enable MFA for sensitive operations

### 4. Audit Logging

Enable CloudTrail to track script actions:

```bash
# Check CloudTrail status
aws cloudtrail describe-trails

# View recent events
aws cloudtrail lookup-events --max-results 10
```

## Troubleshooting

### Common Issues

**Script not found:**

```bash
# Ensure script is executable
chmod +x script.sh

# Use full path
/path/to/script.sh
```

**Permission denied:**

```bash
# Check IAM permissions
aws iam get-user

# Verify credentials
aws sts get-caller-identity
```

**Command not found:**

```bash
# Check if tool is installed
which aws
which jq

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin
```

For more troubleshooting help, see the [Troubleshooting Guide](../docs/troubleshooting.md).

## Getting Help

### Script-Level Help

```bash
# Display help for any script
./script.sh --help
```

### Documentation

- [Getting Started Guide](../docs/getting-started.md)
- [Configuration Guide](../docs/configuration.md)
- [Best Practices](../docs/best-practices.md)
- [Troubleshooting](../docs/troubleshooting.md)

### Support

- **Issues**: [GitHub Issues](https://github.com/awsutils/awsutils.github.io/issues)
- **Questions**: GitHub Discussions
- **Contributions**: See [Contributing Guide](../docs/contributing.md)

## Contributing Scripts

Want to add your own script? We welcome contributions!

1. Review the [Contributing Guide](../docs/contributing.md)
2. Follow the script template
3. Include comprehensive documentation
4. Submit a pull request

**Script must include:**

- Clear description and usage
- Help text (`--help`)
- Error handling
- Input validation
- Logging
- Documentation

## Script Index

Browse all available scripts:

- [eksctl.sh](./eksctl.sh.md) - Install eksctl for EKS management

More scripts coming soon!

## Updates and Releases

Scripts are regularly updated with:

- New features
- Bug fixes
- Security patches
- Performance improvements

**Stay updated:**

```bash
# Clone repository
git clone https://github.com/awsutils/awsutils.github.io.git

# Pull latest changes
cd awsutils.github.io
git pull
```

**Release notifications:**

- Watch the repository on GitHub
- Subscribe to release notifications
- Check the changelog

## Feedback

We value your feedback:

- Report bugs or issues
- Suggest new scripts
- Request features
- Share your use cases

Visit our [GitHub repository](https://github.com/awsutils/awsutils.github.io) to get involved!
