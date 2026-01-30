---
sidebar_position: 6
---

# Troubleshooting

This guide helps you diagnose and resolve common issues when using awsutils.

## General Troubleshooting Steps

1. **Enable verbose/debug mode**

   ```bash
   ./script.sh --verbose
   AWS_DEBUG=1 ./script.sh
   ```

2. **Check AWS CLI version**

   ```bash
   aws --version
   ```

3. **Verify credentials**

   ```bash
   aws sts get-caller-identity
   ```

4. **Check region configuration**

   ```bash
   aws configure get region
   echo $AWS_DEFAULT_REGION
   ```

5. **Review CloudTrail logs**
   ```bash
   aws cloudtrail lookup-events --max-results 10
   ```

## Credential Issues

### Issue: "Unable to locate credentials"

**Symptoms:**

```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Causes:**

- AWS CLI not configured
- Credentials file missing or corrupted
- Environment variables not set
- Wrong AWS profile

**Solutions:**

1. **Configure AWS CLI:**

   ```bash
   aws configure
   ```

2. **Check credentials file:**

   ```bash
   cat ~/.aws/credentials
   ls -la ~/.aws/
   ```

3. **Verify environment variables:**

   ```bash
   echo $AWS_ACCESS_KEY_ID
   echo $AWS_SECRET_ACCESS_KEY
   echo $AWS_PROFILE
   ```

4. **Test with explicit profile:**

   ```bash
   aws sts get-caller-identity --profile default
   ```

5. **Reset credentials:**
   ```bash
   rm ~/.aws/credentials
   aws configure
   ```

### Issue: "The security token included in the request is invalid"

**Symptoms:**

```
An error occurred (InvalidToken) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**Causes:**

- Expired temporary credentials
- Invalid session token
- Credentials from different account

**Solutions:**

1. **Refresh temporary credentials:**

   ```bash
   # If using AWS SSO
   aws sso login --profile your-profile

   # If using assume role
   unset AWS_SESSION_TOKEN
   aws sts assume-role --role-arn YOUR_ROLE_ARN --role-session-name session
   ```

2. **Clear session token:**

   ```bash
   unset AWS_SESSION_TOKEN
   unset AWS_ACCESS_KEY_ID
   unset AWS_SECRET_ACCESS_KEY
   ```

3. **Reconfigure credentials:**
   ```bash
   aws configure
   ```

### Issue: "The security token included in the request is expired"

**Symptoms:**

```
An error occurred (ExpiredToken) when calling the [Operation] operation: The security token included in the request is expired
```

**Solutions:**

1. **For temporary credentials:**

   ```bash
   # Get new temporary credentials
   aws sts get-session-token --duration-seconds 3600
   ```

2. **For AWS SSO:**

   ```bash
   aws sso login --profile your-profile
   ```

3. **Switch to long-term credentials:**
   ```bash
   aws configure set aws_access_key_id YOUR_KEY
   aws configure set aws_secret_access_key YOUR_SECRET
   ```

## Permission Issues

### Issue: "Access Denied" or "UnauthorizedException"

**Symptoms:**

```
An error occurred (AccessDenied) when calling the [Operation] operation: User: arn:aws:iam::123456789012:user/username is not authorized to perform: [action] on resource: [resource]
```

**Causes:**

- Insufficient IAM permissions
- Wrong AWS account
- Resource policy restrictions
- Service Control Policy (SCP) restrictions

**Solutions:**

1. **Check current identity:**

   ```bash
   aws sts get-caller-identity
   ```

2. **Review IAM policies:**

   ```bash
   # List attached policies
   aws iam list-attached-user-policies --user-name YOUR_USERNAME

   # Get policy details
   aws iam get-policy-version \
       --policy-arn arn:aws:iam::aws:policy/PolicyName \
       --version-id v1
   ```

3. **Test specific permission:**

   ```bash
   aws iam simulate-principal-policy \
       --policy-source-arn arn:aws:iam::123456789012:user/username \
       --action-names s3:GetObject \
       --resource-arns arn:aws:s3:::bucket-name/*
   ```

4. **Check resource-based policies:**

   ```bash
   # S3 bucket policy
   aws s3api get-bucket-policy --bucket bucket-name

   # Lambda function policy
   aws lambda get-policy --function-name function-name
   ```

5. **Verify you're in the correct account:**
   ```bash
   aws sts get-caller-identity
   aws organizations describe-account --account-id YOUR_ACCOUNT_ID
   ```

## Region Issues

### Issue: "Could not connect to the endpoint URL"

**Symptoms:**

```
Could not connect to the endpoint URL: "https://service.region.amazonaws.com/"
```

**Causes:**

- Invalid region name
- Service not available in region
- Network connectivity issues
- Proxy configuration problems

**Solutions:**

1. **Check available regions:**

   ```bash
   aws ec2 describe-regions --output table
   ```

2. **Verify region configuration:**

   ```bash
   aws configure get region
   echo $AWS_DEFAULT_REGION
   ```

3. **Set region explicitly:**

   ```bash
   export AWS_DEFAULT_REGION=us-east-1
   aws configure set region us-east-1
   ```

4. **Check service availability:**

   ```bash
   # List regions where service is available
   aws ec2 describe-regions --all-regions \
       --query 'Regions[?OptInStatus!=`not-opted-in`].RegionName'
   ```

5. **Test connectivity:**
   ```bash
   curl -I https://ec2.us-east-1.amazonaws.com
   ```

### Issue: "The resource you requested does not exist"

**Symptoms:**

```
An error occurred (NoSuchEntity) when calling the [Operation] operation: The resource you requested does not exist.
```

**Causes:**

- Resource in different region
- Resource doesn't exist
- Wrong resource identifier

**Solutions:**

1. **Check all regions:**

   ```bash
   for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
       echo "Checking $region..."
       aws ec2 describe-instances --region $region --instance-ids i-1234567890abcdef0 2>/dev/null
   done
   ```

2. **Verify resource exists:**

   ```bash
   # List resources
   aws ec2 describe-instances --region us-east-1
   ```

3. **Check resource name/ID:**
   ```bash
   # Ensure correct identifier format
   aws s3 ls s3://bucket-name
   ```

## Network and Connectivity Issues

### Issue: "Connection timeout" or "Connection refused"

**Symptoms:**

```
Connect timeout on endpoint URL
Connection refused
```

**Causes:**

- Network connectivity issues
- Firewall blocking AWS API calls
- Proxy configuration issues
- VPN interference

**Solutions:**

1. **Test internet connectivity:**

   ```bash
   ping -c 3 aws.amazon.com
   curl -I https://aws.amazon.com
   ```

2. **Check AWS endpoints:**

   ```bash
   nc -zv ec2.us-east-1.amazonaws.com 443
   telnet ec2.us-east-1.amazonaws.com 443
   ```

3. **Verify DNS resolution:**

   ```bash
   nslookup ec2.us-east-1.amazonaws.com
   dig ec2.us-east-1.amazonaws.com
   ```

4. **Check proxy settings:**

   ```bash
   echo $HTTP_PROXY
   echo $HTTPS_PROXY
   echo $NO_PROXY

   # Test without proxy
   unset HTTP_PROXY HTTPS_PROXY
   aws sts get-caller-identity
   ```

5. **Verify SSL/TLS:**
   ```bash
   openssl s_client -connect ec2.us-east-1.amazonaws.com:443
   ```

### Issue: "SSL validation failed"

**Symptoms:**

```
SSL validation failed
certificate verify failed
```

**Causes:**

- Outdated CA certificates
- Corporate proxy intercepting SSL
- System clock skew

**Solutions:**

1. **Update CA certificates:**

   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install ca-certificates

   # RHEL/CentOS
   sudo yum update ca-certificates
   ```

2. **Set CA bundle:**

   ```bash
   export AWS_CA_BUNDLE=/path/to/ca-bundle.crt
   aws configure set ca_bundle /path/to/ca-bundle.crt
   ```

3. **Check system time:**

   ```bash
   date
   # Sync time if needed
   sudo ntpdate pool.ntp.org
   ```

4. **Disable SSL verification (NOT RECOMMENDED for production):**
   ```bash
   aws s3 ls --no-verify-ssl
   ```

## Script-Specific Issues

### Issue: "Command not found"

**Symptoms:**

```
bash: script.sh: command not found
bash: aws: command not found
```

**Solutions:**

1. **Make script executable:**

   ```bash
   chmod +x script.sh
   ```

2. **Use correct path:**

   ```bash
   ./script.sh  # Current directory
   /path/to/script.sh  # Absolute path
   ```

3. **Check PATH variable:**

   ```bash
   echo $PATH
   which aws
   ```

4. **Install missing tools:**

   ```bash
   # AWS CLI
   pip install awscli

   # jq
   sudo apt-get install jq  # Debian/Ubuntu
   brew install jq          # macOS
   ```

### Issue: "Permission denied" when executing script

**Symptoms:**

```
bash: ./script.sh: Permission denied
```

**Solutions:**

1. **Add execute permissions:**

   ```bash
   chmod +x script.sh
   ```

2. **Run with bash explicitly:**

   ```bash
   bash script.sh
   ```

3. **Check file ownership:**
   ```bash
   ls -la script.sh
   sudo chown $USER:$USER script.sh
   ```

### Issue: "Syntax error" or "Unexpected token"

**Symptoms:**

```
syntax error near unexpected token
bad interpreter: No such file or directory
```

**Solutions:**

1. **Check shebang:**

   ```bash
   head -1 script.sh
   # Should be: #!/bin/bash or #!/usr/bin/env bash
   ```

2. **Verify bash version:**

   ```bash
   bash --version
   ```

3. **Check line endings:**

   ```bash
   # Convert Windows CRLF to Unix LF
   dos2unix script.sh
   # Or
   sed -i 's/\r$//' script.sh
   ```

4. **Validate script syntax:**
   ```bash
   bash -n script.sh  # Check syntax without executing
   shellcheck script.sh  # Use shellcheck for detailed analysis
   ```

## AWS CLI Issues

### Issue: "AWS CLI command too slow"

**Causes:**

- Large result sets
- Network latency
- Inefficient queries

**Solutions:**

1. **Use pagination:**

   ```bash
   aws s3api list-objects-v2 --bucket my-bucket --max-items 100
   ```

2. **Use filters:**

   ```bash
   aws ec2 describe-instances \
       --filters "Name=instance-state-name,Values=running" \
       --query 'Reservations[].Instances[].InstanceId'
   ```

3. **Increase timeout:**

   ```bash
   aws configure set cli_read_timeout 60
   ```

4. **Use different output format:**
   ```bash
   aws ec2 describe-instances --output text
   ```

### Issue: "Invalid JSON" errors

**Symptoms:**

```
Error parsing parameter: Invalid JSON
```

**Solutions:**

1. **Validate JSON:**

   ```bash
   cat config.json | jq .
   ```

2. **Use file:// prefix:**

   ```bash
   aws iam put-role-policy --policy-document file://policy.json
   ```

3. **Escape JSON in command line:**
   ```bash
   aws iam put-role-policy --policy-document '{"Version":"2012-10-17",...}'
   ```

### Issue: "Rate exceeded" or "Throttling"

**Symptoms:**

```
An error occurred (Throttling) when calling the [Operation] operation: Rate exceeded
```

**Solutions:**

1. **Implement exponential backoff:**

   ```bash
   retry_with_backoff() {
       local max_attempts=5
       local timeout=1
       local attempt=1

       while [ $attempt -le $max_attempts ]; do
           if "$@"; then
               return 0
           fi
           echo "Attempt $attempt failed. Retrying in ${timeout}s..."
           sleep $timeout
           timeout=$((timeout * 2))
           attempt=$((attempt + 1))
       done
       return 1
   }
   ```

2. **Add delays between calls:**

   ```bash
   for item in $items; do
       aws ec2 describe-instances --instance-ids $item
       sleep 1  # Rate limiting
   done
   ```

3. **Request limit increase:**

   ```bash
   # Check current limits
   aws service-quotas get-service-quota \
       --service-code ec2 \
       --quota-code L-1216C47A

   # Request increase
   aws service-quotas request-service-quota-increase \
       --service-code ec2 \
       --quota-code L-1216C47A \
       --desired-value 100
   ```

## Resource-Specific Issues

### S3 Issues

**Issue: "NoSuchBucket"**

```bash
# Verify bucket exists
aws s3 ls s3://bucket-name

# Check region
aws s3api get-bucket-location --bucket bucket-name
```

**Issue: "AccessDenied on S3 operation"**

```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket bucket-name

# Check ACL
aws s3api get-bucket-acl --bucket bucket-name

# Check public access block
aws s3api get-public-access-block --bucket bucket-name
```

### EC2 Issues

**Issue: "InvalidInstanceID.NotFound"**

```bash
# List instances in region
aws ec2 describe-instances --region us-east-1

# Check all regions
for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
    aws ec2 describe-instances --region $region --instance-ids i-1234567890abcdef0 2>/dev/null && echo "Found in $region"
done
```

### IAM Issues

**Issue: "EntityAlreadyExists"**

```bash
# Check if user/role exists
aws iam get-user --user-name username
aws iam get-role --role-name rolename

# Delete and recreate if needed
aws iam delete-user --user-name username
```

## Debugging Tips

### Enable Debug Logging

```bash
# AWS CLI debug output
aws s3 ls --debug 2>&1 | tee debug.log

# Bash script debugging
bash -x script.sh

# Set in script
set -x  # Enable debug mode
set +x  # Disable debug mode
```

### Capture API Calls

```bash
# Log all AWS API calls
export AWS_DEBUG=1
aws s3 ls 2>&1 | tee api-calls.log
```

### Check CloudTrail Events

```bash
# Recent API calls
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket \
    --max-results 10

# Failed operations
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=PutObject \
    --query 'Events[?errorCode!=`null`]'
```

## Getting Additional Help

### Documentation

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS Service Documentation](https://docs.aws.amazon.com/)
- [AWS Knowledge Center](https://aws.amazon.com/premiumsupport/knowledge-center/)

### Support Channels

1. **GitHub Issues**: Report bugs or request features
2. **AWS Support**: For account-specific issues
3. **AWS Forums**: Community support
4. **Stack Overflow**: Tag questions with `aws-cli` or `amazon-web-services`

### Useful Commands for Troubleshooting

```bash
# System information
uname -a
aws --version
python --version
jq --version

# AWS configuration
aws configure list
cat ~/.aws/config
cat ~/.aws/credentials  # Be careful not to share this

# Network diagnostics
curl -I https://aws.amazon.com
nslookup ec2.us-east-1.amazonaws.com
traceroute ec2.us-east-1.amazonaws.com

# Check AWS service status
curl -s https://status.aws.amazon.com/ | grep -i "service is operating normally"
```

## Common Error Codes

| Error Code                  | Meaning                           | Common Solution                    |
| --------------------------- | --------------------------------- | ---------------------------------- |
| `InvalidClientTokenId`      | Invalid access key                | Verify credentials                 |
| `SignatureDoesNotMatch`     | Incorrect secret key or time skew | Check secret key, sync time        |
| `AccessDenied`              | Insufficient permissions          | Review IAM policies                |
| `UnauthorizedOperation`     | Action not allowed                | Check IAM permissions              |
| `ResourceNotFoundException` | Resource doesn't exist            | Verify resource ID/name and region |
| `ThrottlingException`       | Too many requests                 | Implement backoff/retry            |
| `ServiceUnavailable`        | AWS service issue                 | Wait and retry                     |
| `InvalidParameterValue`     | Invalid parameter                 | Check parameter format             |

## Next Steps

If you're still experiencing issues:

1. Review [Configuration Guide](configuration.md) for setup details
2. Check [Best Practices](best-practices.md) for recommendations
3. Consult [AWS Documentation](https://docs.aws.amazon.com/)
4. Open an issue on [GitHub](https://github.com/awsutils/awsutils.github.io/issues)
