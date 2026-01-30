---
sidebar_position: 3
---

# Getting Started

This guide will help you get up and running with awsutils quickly and efficiently.

## Overview

awsutils is a collection of tools and scripts designed to simplify common AWS operations. Whether you're managing infrastructure, automating deployments, or optimizing costs, these utilities can help streamline your workflow.

## Prerequisites

Before you begin, ensure you have the following:

### 1. AWS Account

You'll need an active AWS account. If you don't have one:

- Visit [AWS Console](https://aws.amazon.com/console/)
- Click "Create an AWS Account"
- Follow the registration process

### 2. AWS CLI

Install the AWS Command Line Interface:

**macOS:**

```bash
brew install awscli
```

**Linux:**

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows:**
Download and run the [AWS CLI MSI installer](https://awscli.amazonaws.com/AWSCLIV2.msi)

Verify installation:

```bash
aws --version
```

### 3. IAM User and Credentials

Create an IAM user with appropriate permissions:

1. Go to AWS Console → IAM → Users
2. Click "Add user"
3. Select "Programmatic access"
4. Attach policies based on your needs (e.g., `AdministratorAccess` for testing)
5. Save the Access Key ID and Secret Access Key

## Initial Setup

### Step 1: Configure AWS Credentials

Configure your AWS credentials using the AWS CLI:

```bash
aws configure
```

You'll be prompted to enter:

- **AWS Access Key ID**: Your IAM user access key
- **AWS Secret Access Key**: Your IAM user secret key
- **Default region name**: e.g., `us-east-1`
- **Default output format**: e.g., `json`

### Step 2: Verify Configuration

Test your configuration:

```bash
# Check your identity
aws sts get-caller-identity

# List S3 buckets (if you have any)
aws s3 ls

# List EC2 instances in your region
aws ec2 describe-instances
```

### Step 3: Install Required Tools

Install common dependencies used by the utilities:

**jq (JSON processor):**

```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
sudo apt-get install jq

# Linux (RHEL/CentOS)
sudo yum install jq
```

**curl (if not already installed):**

```bash
# Most systems have curl pre-installed
curl --version
```

## Using Your First Utility

Let's try running your first AWS utility script:

### Example: Install eksctl

```bash
# Review the script first
curl https://awsutils.github.io/eksctl.sh

# Run the installation script
curl https://awsutils.github.io/eksctl.sh | sh

# Verify installation
eksctl version
```

## Directory Structure

When working with awsutils locally:

```
awsutils/
├── docs/               # Documentation
│   ├── docs/          # General documentation
│   └── scripts/       # Script-specific documentation
├── scripts/           # Utility scripts
│   ├── eksctl.sh
│   └── ...
└── README.md
```

## Working with Multiple AWS Accounts

If you work with multiple AWS accounts, use named profiles:

### Create Named Profiles

Edit `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_DEFAULT_KEY
aws_secret_access_key = YOUR_DEFAULT_SECRET

[production]
aws_access_key_id = YOUR_PROD_KEY
aws_secret_access_key = YOUR_PROD_SECRET

[development]
aws_access_key_id = YOUR_DEV_KEY
aws_secret_access_key = YOUR_DEV_SECRET
```

Edit `~/.aws/config`:

```ini
[default]
region = us-east-1
output = json

[profile production]
region = us-west-2
output = json

[profile development]
region = eu-west-1
output = json
```

### Use Profiles

```bash
# Use specific profile
aws s3 ls --profile production

# Set profile as environment variable
export AWS_PROFILE=production
aws s3 ls

# Use profile with scripts
AWS_PROFILE=production ./script.sh
```

## Environment Variables

Common environment variables used by awsutils:

| Variable                | Description                  | Example                     |
| ----------------------- | ---------------------------- | --------------------------- |
| `AWS_REGION`            | AWS region to use            | `us-east-1`                 |
| `AWS_PROFILE`           | Named AWS profile            | `production`                |
| `AWS_DEFAULT_REGION`    | Default region               | `us-west-2`                 |
| `AWS_ACCESS_KEY_ID`     | Access key (not recommended) | `AKIAIOSFODNN7EXAMPLE`      |
| `AWS_SECRET_ACCESS_KEY` | Secret key (not recommended) | `wJalrXUtnFEMI/K7MDENG/...` |

## Security Best Practices

1. **Never hardcode credentials** in scripts or code
2. **Use IAM roles** when running on EC2 instances
3. **Enable MFA** for your AWS account
4. **Use least privilege** - grant only necessary permissions
5. **Rotate credentials** regularly
6. **Use AWS SSO** for enterprise environments

## Common Issues

### Issue: "Unable to locate credentials"

**Solution:**

```bash
# Re-run AWS configure
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_DEFAULT_REGION=us-east-1
```

### Issue: "Access Denied"

**Solution:**

- Check your IAM user permissions
- Verify you're using the correct AWS profile
- Ensure the resource exists in the specified region

### Issue: "Region not specified"

**Solution:**

```bash
# Set default region
aws configure set region us-east-1

# Or use environment variable
export AWS_DEFAULT_REGION=us-east-1
```

## Next Steps

Now that you're set up, explore:

- [How to Use Scripts](howto.md) - Learn script usage patterns
- [Configuration Guide](configuration.md) - Advanced configuration options
- [Best Practices](best-practices.md) - Optimize your workflow
- [Available Scripts](../scripts/intro.md) - Browse available utilities

## Getting Help

If you need assistance:

1. Check the [Troubleshooting Guide](troubleshooting.md)
2. Review the [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
3. Open an issue on [GitHub](https://github.com/awsutils/awsutils.github.io/issues)
4. Consult [AWS Documentation](https://docs.aws.amazon.com/)

## Quick Reference

### Essential AWS CLI Commands

```bash
# Check identity
aws sts get-caller-identity

# List regions
aws ec2 describe-regions --output table

# Check service quotas
aws service-quotas list-service-quotas --service-code ec2

# CloudFormation operations
aws cloudformation list-stacks
aws cloudformation describe-stacks --stack-name MyStack

# S3 operations
aws s3 ls
aws s3 sync ./local-dir s3://my-bucket/

# EC2 operations
aws ec2 describe-instances
aws ec2 describe-vpcs
```

### Useful Aliases

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
alias awswhoami='aws sts get-caller-identity'
alias awsregions='aws ec2 describe-regions --output table'
alias awsprofile='echo $AWS_PROFILE'
```

## Conclusion

You're now ready to use awsutils effectively. Start with simple scripts and gradually explore more advanced features as you become comfortable with the tools.
