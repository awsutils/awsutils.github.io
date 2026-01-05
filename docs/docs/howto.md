---
sidebar_position: 2
---

# How to Use Scripts

This guide explains how to use the AWS utilities and scripts provided in this repository.

## Quick Start

### Running Scripts Directly

You can run scripts directly from the hosted repository using curl:

```bash
curl https://awsutils.github.io/[script-name] | sh
```

For example, to install eksctl:

```bash
curl https://awsutils.github.io/eksctl.sh | sh
```

### Downloading Scripts

To download and inspect a script before running it:

```bash
curl -o script.sh https://awsutils.github.io/[script-name]
chmod +x script.sh
./script.sh
```

## Script Categories

### Installation Scripts

These scripts help you install and configure AWS tools and utilities:

- **eksctl.sh** - Install eksctl for managing EKS clusters
- More scripts coming soon...

### Automation Scripts

Scripts for automating common AWS tasks:

- Resource management
- Backup automation
- Cost optimization
- More coming soon...

## Prerequisites

Before running any scripts, ensure you have:

1. **AWS CLI installed and configured**
   ```bash
   aws --version
   aws configure
   ```

2. **Appropriate IAM permissions**
   - Scripts will require different permissions based on their functionality
   - Check individual script documentation for specific requirements

3. **Required dependencies**
   - bash (version 4+)
   - curl or wget
   - jq (for JSON processing)
   - Other dependencies as specified in script documentation

## Best Practices

### Always Review Scripts

Before running any script from the internet, review its contents:

```bash
curl https://awsutils.github.io/[script-name]
```

### Use Dry Run Mode

When available, use dry run mode to see what changes will be made:

```bash
./script.sh --dry-run
```

### Set Environment Variables

Many scripts support configuration via environment variables:

```bash
export AWS_REGION=us-east-1
export AWS_PROFILE=myprofile
./script.sh
```

### Check Exit Codes

Always check if a script executed successfully:

```bash
./script.sh
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Failed"
fi
```

## Common Options

Most scripts support these common options:

- `--help` or `-h` - Display help information
- `--version` or `-v` - Display version information
- `--verbose` - Enable verbose output
- `--dry-run` - Simulate execution without making changes

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](troubleshooting.md) guide
2. Review the script's documentation
3. Open an issue on GitHub
4. Ensure your AWS credentials are properly configured

## Examples

### Example 1: Installing Tools

```bash
# Install eksctl
curl https://awsutils.github.io/eksctl.sh | sh

# Verify installation
eksctl version
```

### Example 2: Using Environment Variables

```bash
# Set AWS region
export AWS_REGION=us-west-2

# Run script with custom region
./aws-backup.sh
```

### Example 3: Chaining Scripts

```bash
# Run multiple scripts in sequence
curl https://awsutils.github.io/setup-env.sh | sh && \
curl https://awsutils.github.io/configure-vpc.sh | sh
```

## Next Steps

- Read the [Configuration Guide](configuration.md) for detailed setup
- Review [Best Practices](best-practices.md) for optimal usage
- Explore available [Scripts](../scripts/intro.md)