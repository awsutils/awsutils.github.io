---
sidebar_position: 4
---

# Configuration

This guide covers advanced configuration options for AWS Utilities, including credential management, environment setup, and customization options.

## AWS Credentials Configuration

### Method 1: AWS CLI Configuration Files (Recommended)

The most common and secure method is using AWS CLI configuration files:

**Location:**
- Credentials: `~/.aws/credentials`
- Configuration: `~/.aws/config`

**Setup:**
```bash
aws configure
```

**Example `~/.aws/credentials`:**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[production]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

[development]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Example `~/.aws/config`:**
```ini
[default]
region = us-east-1
output = json

[profile production]
region = us-west-2
output = json
role_arn = arn:aws:iam::123456789012:role/ProductionRole
source_profile = default

[profile development]
region = eu-west-1
output = yaml
```

### Method 2: Environment Variables

Set credentials via environment variables (useful for CI/CD):

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=production
```

**Temporary session credentials:**
```bash
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoEXAMPLEH4aoAH0gNCAPy...
```

### Method 3: IAM Roles (Recommended for EC2/ECS/Lambda)

When running on AWS compute services, use IAM roles:

**For EC2:**
1. Create an IAM role with required permissions
2. Attach the role to your EC2 instance
3. Credentials are automatically available

**For ECS:**
1. Define task execution role
2. Specify in task definition
3. Credentials injected automatically

**For Lambda:**
1. Create execution role
2. Attach to Lambda function
3. Credentials available via runtime

### Method 4: AWS SSO

For enterprise environments using AWS SSO:

```bash
# Configure SSO
aws configure sso

# Login
aws sso login --profile my-sso-profile

# Use SSO profile
export AWS_PROFILE=my-sso-profile
```

**Example SSO configuration in `~/.aws/config`:**
```ini
[profile my-sso-profile]
sso_start_url = https://my-sso-portal.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = us-west-2
output = json
```

## Credential Priority Order

AWS SDK and CLI use credentials in this order:

1. Command line options (`--profile`, `--region`)
2. Environment variables (`AWS_ACCESS_KEY_ID`, etc.)
3. Credentials file (`~/.aws/credentials`)
4. Config file (`~/.aws/config`)
5. Container credentials (ECS tasks)
6. Instance profile credentials (EC2)

## Environment Variables Reference

### AWS Service Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | AWS region for API calls | `us-east-1` |
| `AWS_DEFAULT_REGION` | Fallback region | `us-west-2` |
| `AWS_PROFILE` | Named profile to use | `production` |
| `AWS_CONFIG_FILE` | Config file location | `~/.aws/custom-config` |
| `AWS_SHARED_CREDENTIALS_FILE` | Credentials file location | `~/.aws/custom-creds` |

### Authentication

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | Access key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Secret access key | `wJalrXUtnFEMI/...` |
| `AWS_SESSION_TOKEN` | Session token (temp creds) | `AQoEXAMPLEH4...` |
| `AWS_ROLE_ARN` | Role to assume | `arn:aws:iam::123:role/MyRole` |
| `AWS_ROLE_SESSION_NAME` | Session name when assuming role | `my-session` |

### SDK/CLI Behavior

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_DEFAULT_OUTPUT` | Output format | `json`, `yaml`, `text`, `table` |
| `AWS_PAGER` | Pager for output | `less`, `more`, `` (disable) |
| `AWS_MAX_ATTEMPTS` | Max retry attempts | `3` |
| `AWS_RETRY_MODE` | Retry mode | `standard`, `adaptive` |
| `AWS_METADATA_SERVICE_TIMEOUT` | Metadata timeout (seconds) | `5` |
| `AWS_METADATA_SERVICE_NUM_ATTEMPTS` | Metadata retry attempts | `3` |

### Debugging

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_DEBUG` | Enable debug logging | `1` |
| `AWS_SDK_LOAD_CONFIG` | Load config from file | `1` |

## Script-Specific Configuration

### Global Configuration File

Create a global configuration file for AWS Utilities:

**Location:** `~/.awsutils/config`

```bash
# Create config directory
mkdir -p ~/.awsutils

# Create config file
cat > ~/.awsutils/config <<EOF
# AWS Utilities Configuration
DEFAULT_REGION=us-east-1
LOG_LEVEL=INFO
DRY_RUN=false
BACKUP_RETENTION_DAYS=30
EOF
```

### Per-Script Configuration

Scripts can read configuration from:

1. **Global config:** `~/.awsutils/config`
2. **Script-specific config:** `~/.awsutils/[script-name].conf`
3. **Environment variables:** Override config values
4. **Command-line arguments:** Override everything

**Example script-specific config (`~/.awsutils/eksctl.conf`):**
```bash
EKSCTL_VERSION=0.150.0
INSTALL_DIR=/usr/local/bin
AUTO_UPDATE=true
```

## Region Configuration

### Setting Default Region

**Via AWS CLI:**
```bash
aws configure set region us-west-2
```

**Via Environment Variable:**
```bash
export AWS_DEFAULT_REGION=us-west-2
```

**In Configuration File:**
```ini
[default]
region = us-west-2
```

### Using Multiple Regions

**Script with region parameter:**
```bash
./script.sh --region us-east-1
```

**Environment variable per invocation:**
```bash
AWS_REGION=eu-west-1 ./script.sh
```

**Loop through multiple regions:**
```bash
for region in us-east-1 us-west-2 eu-west-1; do
    AWS_REGION=$region ./script.sh
done
```

## MFA Configuration

### Configure MFA

**In `~/.aws/config`:**
```ini
[profile mfa]
region = us-east-1
output = json
mfa_serial = arn:aws:iam::123456789012:mfa/username
```

### Using MFA with Scripts

**Get temporary credentials:**
```bash
aws sts get-session-token \
    --serial-number arn:aws:iam::123456789012:mfa/username \
    --token-code 123456
```

**Set temporary credentials:**
```bash
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/...
export AWS_SESSION_TOKEN=AQoEXAMPLEH4aoAH0gNCAPy...
```

## Assume Role Configuration

### Configure Role Assumption

**In `~/.aws/config`:**
```ini
[profile assume-role]
role_arn = arn:aws:iam::123456789012:role/MyRole
source_profile = default
region = us-east-1
role_session_name = my-session
external_id = optional-external-id
```

### Assume Role Manually

```bash
# Assume role
aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/MyRole \
    --role-session-name my-session

# Extract and export credentials
# (Use jq to parse JSON response)
```

## Logging Configuration

### Enable Logging

**Environment variable:**
```bash
export AWS_DEBUG=1
export AWSUTILS_LOG_LEVEL=DEBUG
```

**Script configuration:**
```bash
# In script or config file
LOG_FILE=~/.awsutils/logs/script.log
LOG_LEVEL=DEBUG  # DEBUG, INFO, WARN, ERROR
```

### Log Rotation

**Using logrotate (`/etc/logrotate.d/awsutils`):**
```
~/.awsutils/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

## Proxy Configuration

### HTTP/HTTPS Proxy

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=169.254.169.254,localhost,127.0.0.1
```

### AWS CLI Proxy

**Via environment variables:**
```bash
export AWS_CA_BUNDLE=/path/to/ca-bundle.crt
```

**In `~/.aws/config`:**
```ini
[default]
ca_bundle = /path/to/ca-bundle.crt
```

## Performance Optimization

### Concurrent Requests

```bash
# Increase max concurrent requests
export AWS_MAX_CONCURRENT_REQUESTS=20
```

### Connection Pooling

```bash
# Configure connection pool size
export AWS_MAX_CONNECTIONS=10
```

### Retry Configuration

```bash
# Configure retry behavior
export AWS_RETRY_MODE=adaptive
export AWS_MAX_ATTEMPTS=5
```

## Security Best Practices

### 1. File Permissions

Protect credential files:
```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
chmod 700 ~/.aws
```

### 2. Credential Rotation

Rotate credentials regularly:
```bash
# Create new access key
aws iam create-access-key --user-name MyUser

# Update configuration
aws configure set aws_access_key_id NEW_KEY_ID
aws configure set aws_secret_access_key NEW_SECRET_KEY

# Delete old access key
aws iam delete-access-key --access-key-id OLD_KEY_ID --user-name MyUser
```

### 3. Use IAM Roles When Possible

Prefer IAM roles over static credentials for:
- EC2 instances
- ECS tasks
- Lambda functions
- EKS pods (IRSA)

### 4. Principle of Least Privilege

Grant only necessary permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:PutObject"
    ],
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```

## Validation and Testing

### Verify Configuration

```bash
# Check current configuration
aws configure list

# Test credentials
aws sts get-caller-identity

# Verify region
aws configure get region

# List all profiles
aws configure list-profiles
```

### Test Script Configuration

```bash
# Dry run mode
./script.sh --dry-run

# Verbose mode
./script.sh --verbose

# Debug mode
AWSUTILS_DEBUG=1 ./script.sh
```

## Troubleshooting Configuration

### Common Issues

**Issue: Credentials not found**
```bash
# Check credential file exists
ls -la ~/.aws/credentials

# Verify environment variables
env | grep AWS
```

**Issue: Wrong region**
```bash
# Check configured region
aws configure get region

# Override region
aws configure set region us-east-1
```

**Issue: Permission denied**
```bash
# Check IAM permissions
aws iam get-user

# Simulate policy
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::123:user/myuser \
    --action-names s3:GetObject
```

## Next Steps

- Review [Best Practices](best-practices.md) for optimization
- Explore [Troubleshooting Guide](troubleshooting.md) for common issues
- Check [How to Use Scripts](howto.md) for usage examples
