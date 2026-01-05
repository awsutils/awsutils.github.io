---
sidebar_position: 5
---

# Best Practices

This guide outlines best practices for using AWS Utilities effectively, securely, and efficiently.

## Security Best Practices

### 1. Credential Management

**DO:**
- Use IAM roles whenever possible (EC2, ECS, Lambda, EKS)
- Store credentials in `~/.aws/credentials` with proper file permissions
- Use AWS SSO for enterprise environments
- Rotate credentials regularly (every 90 days recommended)
- Enable MFA for privileged accounts

**DON'T:**
- Hardcode credentials in scripts or configuration files
- Commit credentials to version control
- Share credentials between users or services
- Use root account credentials
- Store credentials in plain text files with broad permissions

```bash
# Secure credential files
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
chmod 700 ~/.aws

# Check for exposed credentials
git grep -i 'aws_access_key_id'  # Should return nothing
```

### 2. Principle of Least Privilege

Grant only the minimum permissions required:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:ListBucket"
    ],
    "Resource": [
      "arn:aws:s3:::my-specific-bucket",
      "arn:aws:s3:::my-specific-bucket/*"
    ]
  }]
}
```

**Tips:**
- Start with read-only permissions
- Add write permissions only when needed
- Use condition keys to further restrict access
- Review and audit permissions regularly
- Use AWS Access Analyzer to identify overly permissive policies

### 3. Enable AWS CloudTrail

Always enable CloudTrail for audit logging:

```bash
# Check if CloudTrail is enabled
aws cloudtrail describe-trails

# Create a trail
aws cloudtrail create-trail \
    --name my-trail \
    --s3-bucket-name my-cloudtrail-bucket
```

### 4. Use Resource Tags

Tag all resources for better organization and cost tracking:

```bash
# Tag resources
aws ec2 create-tags \
    --resources i-1234567890abcdef0 \
    --tags Key=Environment,Value=Production Key=Owner,Value=TeamA Key=Project,Value=MyProject
```

**Recommended tag schema:**
- `Environment`: `Production`, `Staging`, `Development`
- `Owner`: Team or individual responsible
- `Project`: Project name
- `CostCenter`: For cost allocation
- `ManagedBy`: `Terraform`, `CloudFormation`, `Manual`

### 5. Secrets Management

Use AWS Secrets Manager or Systems Manager Parameter Store:

```bash
# Store secret
aws secretsmanager create-secret \
    --name MySecret \
    --secret-string '{"username":"admin","password":"password123"}'

# Retrieve secret in script
SECRET=$(aws secretsmanager get-secret-value --secret-id MySecret --query SecretString --output text)
```

## Operational Best Practices

### 1. Always Use Version Control

Track all scripts and configurations:

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit"

# Use .gitignore to exclude sensitive files
cat > .gitignore <<EOF
*.pem
*.key
.env
.aws/credentials
EOF
```

### 2. Implement Dry Run Mode

Always test with `--dry-run` first:

```bash
# Good practice
./script.sh --dry-run  # Review changes
./script.sh            # Execute actual changes

# In your scripts
if [ "$DRY_RUN" = "true" ]; then
    echo "Would execute: aws s3 rm s3://bucket/file"
else
    aws s3 rm s3://bucket/file
fi
```

### 3. Use Idempotent Operations

Design scripts to be safely re-runnable:

```bash
# Check if resource exists before creating
if ! aws s3 ls s3://my-bucket 2>/dev/null; then
    aws s3 mb s3://my-bucket
    echo "Bucket created"
else
    echo "Bucket already exists"
fi
```

### 4. Implement Proper Error Handling

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Function for error handling
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Use trap for cleanup
cleanup() {
    echo "Cleaning up temporary files..."
    rm -f /tmp/temp-file
}
trap cleanup EXIT

# Check AWS CLI is available
command -v aws >/dev/null 2>&1 || error_exit "AWS CLI not found"

# Check credentials are configured
aws sts get-caller-identity >/dev/null 2>&1 || error_exit "AWS credentials not configured"
```

### 5. Log Everything

Implement comprehensive logging:

```bash
# Define logging function
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a /var/log/awsutils.log
}

# Use in script
log INFO "Starting backup process"
log ERROR "Failed to backup bucket"
```

### 6. Use Configuration Files

Externalize configuration:

```bash
# config.conf
REGION=us-east-1
ENVIRONMENT=production
BACKUP_BUCKET=my-backup-bucket
RETENTION_DAYS=30

# In script
source config.conf
aws s3 sync /data s3://${BACKUP_BUCKET}/${ENVIRONMENT}/
```

## Performance Best Practices

### 1. Use Parallel Operations

Leverage parallelism for better performance:

```bash
# Sequential (slow)
for instance in $INSTANCES; do
    aws ec2 describe-instances --instance-ids $instance
done

# Parallel (faster)
echo "$INSTANCES" | xargs -P 10 -I {} aws ec2 describe-instances --instance-ids {}

# Using GNU parallel
parallel -j 10 "aws ec2 describe-instances --instance-ids {}" ::: $INSTANCES
```

### 2. Implement Pagination

Handle large result sets properly:

```bash
# Using --query and --max-items
aws s3api list-objects-v2 \
    --bucket my-bucket \
    --max-items 1000 \
    --query 'Contents[].Key'

# Using pagination tokens
TOKEN=""
while true; do
    if [ -z "$TOKEN" ]; then
        RESULT=$(aws s3api list-objects-v2 --bucket my-bucket --max-keys 1000)
    else
        RESULT=$(aws s3api list-objects-v2 --bucket my-bucket --max-keys 1000 --continuation-token "$TOKEN")
    fi

    # Process results
    echo "$RESULT" | jq -r '.Contents[].Key'

    # Check for more results
    TOKEN=$(echo "$RESULT" | jq -r '.NextContinuationToken // empty')
    [ -z "$TOKEN" ] && break
done
```

### 3. Cache Results

Cache expensive API calls:

```bash
CACHE_FILE="/tmp/aws-cache-instances.json"
CACHE_TTL=300  # 5 minutes

if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE"))) -lt $CACHE_TTL ]; then
    # Use cached data
    cat "$CACHE_FILE"
else
    # Fetch and cache
    aws ec2 describe-instances > "$CACHE_FILE"
    cat "$CACHE_FILE"
fi
```

### 4. Use Efficient Queries

Optimize AWS CLI queries:

```bash
# Inefficient: Returns everything, filter locally
aws ec2 describe-instances | jq '.Reservations[].Instances[] | select(.State.Name=="running")'

# Efficient: Filter on server side
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text
```

## Cost Optimization

### 1. Right-Size Resources

Monitor and adjust resource sizes:

```bash
# Check instance utilization
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average
```

### 2. Implement Lifecycle Policies

Automate resource cleanup:

```bash
# S3 lifecycle policy
cat > lifecycle-policy.json <<EOF
{
  "Rules": [{
    "Id": "DeleteOldBackups",
    "Status": "Enabled",
    "Prefix": "backups/",
    "Expiration": {
      "Days": 30
    }
  }]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket my-bucket \
    --lifecycle-configuration file://lifecycle-policy.json
```

### 3. Use Spot Instances

For fault-tolerant workloads:

```bash
# Request spot instance
aws ec2 request-spot-instances \
    --spot-price "0.05" \
    --instance-count 1 \
    --type "one-time" \
    --launch-specification file://specification.json
```

### 4. Enable Cost Allocation Tags

Track costs by project/team:

```bash
# Activate cost allocation tags
aws ce update-cost-allocation-tags-status \
    --cost-allocation-tags-status TagKey=Project,Status=Active
```

### 5. Set Up Billing Alerts

Monitor spending:

```bash
# Create billing alarm
aws cloudwatch put-metric-alarm \
    --alarm-name BillingAlarm \
    --alarm-description "Alert when charges exceed $100" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 21600 \
    --evaluation-periods 1 \
    --threshold 100 \
    --comparison-operator GreaterThanThreshold
```

## Reliability Best Practices

### 1. Implement Retry Logic

Handle transient failures:

```bash
# Retry function
retry() {
    local max_attempts=$1
    local delay=$2
    local attempt=1
    shift 2

    until "$@"; do
        if [ $attempt -ge $max_attempts ]; then
            echo "Command failed after $max_attempts attempts"
            return 1
        fi
        echo "Attempt $attempt failed. Retrying in ${delay}s..."
        sleep $delay
        attempt=$((attempt + 1))
    done
}

# Usage
retry 3 5 aws s3 cp file.txt s3://my-bucket/
```

### 2. Use Multiple Regions

Design for regional failures:

```bash
# Replicate across regions
REGIONS=("us-east-1" "us-west-2" "eu-west-1")

for region in "${REGIONS[@]}"; do
    aws s3 sync s3://source-bucket s3://backup-bucket-$region --region $region
done
```

### 3. Implement Health Checks

Monitor service health:

```bash
# Check endpoint health
health_check() {
    local url=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" $url)

    if [ $response -eq 200 ]; then
        echo "Service is healthy"
        return 0
    else
        echo "Service is unhealthy: HTTP $response"
        return 1
    fi
}
```

### 4. Backup Critical Data

Regular backups are essential:

```bash
#!/bin/bash
# Backup script with retention

BACKUP_BUCKET="my-backup-bucket"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Create backup
aws s3 sync /data s3://${BACKUP_BUCKET}/backups/${TIMESTAMP}/

# Delete old backups
aws s3 ls s3://${BACKUP_BUCKET}/backups/ | while read -r line; do
    backup_date=$(echo $line | awk '{print $2}')
    backup_epoch=$(date -d "$backup_date" +%s)
    current_epoch=$(date +%s)
    days_old=$(( (current_epoch - backup_epoch) / 86400 ))

    if [ $days_old -gt $RETENTION_DAYS ]; then
        backup_path=$(echo $line | awk '{print $2}')
        echo "Deleting old backup: $backup_path"
        aws s3 rm s3://${BACKUP_BUCKET}/backups/${backup_path} --recursive
    fi
done
```

## Testing Best Practices

### 1. Test in Non-Production First

Always test in development/staging:

```bash
# Use environment-specific profiles
if [ "$ENVIRONMENT" = "production" ]; then
    read -p "Are you sure you want to run in PRODUCTION? (yes/no) " confirm
    [ "$confirm" != "yes" ] && exit 1
fi

export AWS_PROFILE=${ENVIRONMENT}
./script.sh
```

### 2. Use Sandbox Accounts

Test in isolated AWS accounts:

```bash
# Switch to sandbox account
export AWS_PROFILE=sandbox

# Run destructive tests safely
./test-disaster-recovery.sh
```

### 3. Validate Inputs

Always validate user inputs:

```bash
# Validate bucket name
validate_bucket_name() {
    local bucket=$1
    if [[ ! $bucket =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]]; then
        echo "Invalid bucket name: $bucket"
        return 1
    fi
}

# Validate region
validate_region() {
    local region=$1
    aws ec2 describe-regions --region-names $region >/dev/null 2>&1
}
```

## Documentation Best Practices

### 1. Document Everything

```bash
#!/bin/bash
# Script: backup-s3-bucket.sh
# Description: Backs up S3 bucket to another bucket
# Usage: ./backup-s3-bucket.sh SOURCE_BUCKET DEST_BUCKET
# Requirements: AWS CLI, jq
# Author: Your Name
# Date: 2024-01-01
```

### 2. Provide Examples

Include usage examples in documentation:

```bash
# Display help
show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] SOURCE DESTINATION

Options:
    -r, --region REGION    AWS region (default: us-east-1)
    -p, --profile PROFILE  AWS profile to use
    -d, --dry-run          Simulate execution
    -h, --help            Show this help message

Examples:
    # Backup bucket
    $0 source-bucket destination-bucket

    # Backup with specific region
    $0 -r us-west-2 source-bucket destination-bucket

    # Dry run
    $0 --dry-run source-bucket destination-bucket
EOF
}
```

### 3. Maintain a CHANGELOG

Track changes to scripts:

```markdown
# Changelog

## [1.2.0] - 2024-01-15
### Added
- Support for multiple regions
- Retry logic for transient failures

### Changed
- Improved error messages
- Updated AWS CLI commands to v2 syntax

### Fixed
- Fixed issue with special characters in bucket names
```

## Monitoring and Alerting

### 1. Log to CloudWatch

```bash
# Send logs to CloudWatch
aws logs put-log-events \
    --log-group-name /aws/scripts/backup \
    --log-stream-name $(date +%Y%m%d) \
    --log-events timestamp=$(date +%s000),message="Backup completed successfully"
```

### 2. Set Up Alerts

```bash
# Create SNS topic for alerts
aws sns create-topic --name script-alerts

# Subscribe to topic
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789012:script-alerts \
    --protocol email \
    --notification-endpoint admin@example.com

# Send alert
aws sns publish \
    --topic-arn arn:aws:sns:us-east-1:123456789012:script-alerts \
    --subject "Backup Failed" \
    --message "Backup of bucket failed at $(date)"
```

### 3. Use AWS Systems Manager

Track script execution with SSM:

```bash
# Run command via SSM
aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["./backup.sh"]' \
    --targets "Key=tag:Environment,Values=Production"
```

## Next Steps

- Review [Troubleshooting Guide](troubleshooting.md) for common issues
- Check [Configuration Guide](configuration.md) for advanced setup
- Explore [Available Scripts](../scripts/intro.md)
