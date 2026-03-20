---
sidebar_position: 6
---

# accinit.sh

Applies a non-interactive single-account AWS security baseline with the AWS CLI.

## What the Script Does

The script in `static/accinit.sh` is designed for one AWS account at a time and, by default, it:

- enables account-level S3 Block Public Access
- enables EBS encryption by default in all enabled regions
- creates a dedicated S3 log bucket when CloudTrail or Config need one
- creates a multi-region CloudTrail trail only when one does not already exist
- enables AWS Config in regions where it is not already configured
- enables Security Hub in all enabled regions
- enables GuardDuty in all enabled regions
- enables GuardDuty runtime monitoring by default
- enables Inspector in all enabled regions
- creates one account-level IAM Access Analyzer per region when missing
- enables Detective in the home region by default

It does this without interactive prompts. Configuration is controlled through flags and environment variables.

## Quick Start

```bash
curl -fsSLO https://awsutils.github.io/accinit.sh
chmod +x accinit.sh
./accinit.sh
```

## Safer Preview

```bash
./accinit.sh --dry-run
```

## Prerequisites

- `bash`
- AWS CLI v2 configured with credentials for the target account
- permissions to manage CloudTrail, Config, GuardDuty, Security Hub, Inspector, IAM Access Analyzer, S3, IAM, and regional EBS defaults

## Default Scope

This script is intentionally focused on a single account baseline, not an AWS Organizations landing zone.

It does not automate:

- root MFA setup
- removal of root access keys
- IAM Identity Center rollout
- SCPs or delegated administrator setup across an organization
- budgets, Macie, or backup plans

## Important Behavior

- It is non-interactive and makes real account changes unless you use `--dry-run`
- It creates a dedicated log bucket by default: `awsutils-accinit-<account-id>-<home-region>`
- If an existing multi-region CloudTrail trail is already present, it leaves that trail alone instead of creating a duplicate
- If AWS Config is already configured in a region, it leaves the existing recorder and delivery channel in place
- Detective is enabled in the home region by default and may add additional cost
- GuardDuty runtime monitoring is enabled by default and may add additional cost

## Common Environment Variables

```bash
ENABLE_S3_BLOCK_PUBLIC_ACCESS=true
ENABLE_EBS_ENCRYPTION=true
ENABLE_CLOUDTRAIL=true
ENABLE_CONFIG=true
ENABLE_SECURITY_HUB=true
ENABLE_SECURITY_HUB_AGGREGATION=true
ENABLE_GUARDDUTY=true
ENABLE_GUARDDUTY_RUNTIME_MONITORING=true
ENABLE_INSPECTOR=true
ENABLE_ACCESS_ANALYZER=true
ENABLE_DETECTIVE=true
HOME_REGION=us-east-1
LOG_BUCKET_NAME=my-dedicated-security-log-bucket
```

## Examples

Enable the default baseline:

```bash
./accinit.sh
```

Preview changes only:

```bash
./accinit.sh --dry-run
```

Disable Detective for a lighter baseline:

```bash
ENABLE_DETECTIVE=false ./accinit.sh
```

Disable GuardDuty runtime monitoring:

```bash
ENABLE_GUARDDUTY_RUNTIME_MONITORING=false ./accinit.sh
```

Use a specific home region and bucket name:

```bash
HOME_REGION=us-west-2 LOG_BUCKET_NAME=my-account-security-baseline ./accinit.sh
```

## Notes

- Use a dedicated bucket when overriding `LOG_BUCKET_NAME`; the script applies a dedicated bucket policy for CloudTrail and Config delivery
- Some services are regional and may not be available in every enabled region; the script keeps going and reports warnings
- The script is idempotent for the main baseline actions and is intended to be safe to re-run

## Related Scripts

- [vpce.sh](./vpce.sh.md)
- [ec2init.sh](./ec2init.sh.md)
- [csinit.sh](./csinit.sh.md)
