---
sidebar_position: 14
---

# init.sh

Full-stack bootstrap for Amazon Linux 2023 EC2 instances: self-elevates to root, optionally deploys an application from S3, and installs a complete set of bastion and operations tooling.

## What the Script Does

The script in `static/init.sh` runs in two modes depending on the environment:

**On all environments (EC2 and non-CloudShell):**

- Re-executes itself as root via `sudo` in the background, redirecting all output to `/var/log/init.log`, then clears the console
- Detects CPU architecture (`amd64` / `arm64`) and OS variant (Amazon Linux 2023 or Amazon Linux 2)
- Installs prerequisite packages (`tar`, `zip`, `unzip`, `curl`, `wget`, `git`, `jq`)
- Installs bastion tools: Terraform, AWS CLI v2, `kubectl`, `eksctl`, `helm`, `k9s`, `amazon-efs-utils`
- Installs and configures Docker with multi-architecture (QEMU binfmt) support
- Adds `ec2-user` and `ssm-user` to the `docker` group
- Creates a `binfmt-qemu` systemd service to restore QEMU handlers across reboots
- Installs three utility commands into `/usr/local/bin`: `ecr`, `accbp`, `vpc`

**On non-CloudShell environments only:**

- Installs the CloudWatch Agent with CPU, memory, disk metrics and `/var/log/app.log` log collection
- Downloads the application binary from `s3://appbinary-<account-id>/app.zip` or `s3://appbinary-<account-id>/app`
- Extracts the zip to `/opt/app/` and makes all scripts and binaries executable
- Downloads `/opt/app/app.env` from the same bucket
- Creates and starts a `app.service` systemd unit that runs `start.sh` (or `app`) and logs to `/var/log/app.log`
- Creates and starts an `app-watcher.service` that polls S3 every 60 seconds using ETags and automatically restarts `app.service` when the binary or env file changes

## Quick Start

```bash
curl -fsSL https://awsutils.github.io/init.sh | sh -
```

The script will re-execute itself as root if needed. Progress is logged to `/var/log/init.log`.

```bash
tail -f /var/log/init.log
```

## Customization

Pass environment variables before the pipe to override defaults:

```bash
APP_DIR=/opt/myapp APP_LOG=/var/log/myapp.log curl -fsSL https://awsutils.github.io/init.sh | sh -
```

| Variable | Default | Description |
|---|---|---|
| `SCRIPT_URL` | `https://awsutils.github.io/init.sh` | URL used when re-downloading for root re-execution |
| `LOG_FILE` | `/var/log/init.log` | Where all init output is written |
| `APP_DIR` | `/opt/app` | Deployment directory for the application binary |
| `APP_LOG` | `/var/log/app.log` | Application stdout and stderr log |

## Prerequisites

- Amazon Linux 2023 (Amazon Linux 2 is also supported)
- Internet access for package and binary downloads
- An AWS IAM role attached to the instance with permissions to:
  - `s3:GetObject` on `s3://appbinary-<account-id>/` (if deploying an app)
  - `cloudwatch:PutMetricData`, `logs:PutLogEvents` (for CloudWatch Agent)
  - `sts:GetCallerIdentity`

## Application Deployment via S3

The script looks for your application in a bucket named `appbinary-<account-id>`. Upload one of the following before running init:

```
s3://appbinary-<account-id>/app.zip   # preferred: zip with start.sh inside
s3://appbinary-<account-id>/app       # single binary
s3://appbinary-<account-id>/app.env   # environment variables file (optional)
```

When a zip is detected, it is extracted to `APP_DIR` and `start.sh` is used as the service entry point. When a binary named `app` is detected, it is used directly.

The file watcher compares S3 ETags to avoid redundant downloads. A changed binary or env file triggers a `systemctl restart app`.

## Utility Commands Installed

### `ecr`

Build the `Dockerfile` in the current directory and push it to ECR.

```bash
ecr <repository-name> [tag]
```

```bash
ecr my-service latest
ecr my-service v1.2.3
```

Creates the ECR repository if it does not exist, logs in, builds, and pushes.

### `accbp`

Enable the AWS security baseline for the current account (delegates to `accinit.sh`).

```bash
accbp
accbp --dry-run
```

See [accinit.sh](./accinit.sh.md) for the full list of what this enables.

### `vpc`

Enable common VPC endpoints and CloudWatch flow logs for every VPC in the current region.

```bash
vpc
CW_RETENTION=30 vpc
```

Gateway endpoints created: `s3`, `dynamodb`

Interface endpoints created: `ecr.dkr`, `ecr.api`, `ssm`, `ssmmessages`, `ec2messages`, `sqs`, `sns`

Existing endpoints are detected and skipped. Flow logs are written to `/vpc/flowlogs/<vpc-id>` in CloudWatch Logs with a 7-day retention policy (override with `CW_RETENTION=<days>`).

## CloudWatch Agent Configuration

The agent collects:

- CPU (`idle`, `iowait`, `user`, `system`) every 60 seconds
- Memory (`used_percent`) every 60 seconds
- Disk (`used_percent`, all mounts) every 60 seconds
- Application logs from `/var/log/app.log` → CloudWatch log group `/app/output`, 7-day retention

## Verify

```bash
# init completed
tail /var/log/init.log

# tools
terraform version
kubectl version --client
eksctl version
helm version
k9s version
aws --version

# services
systemctl status docker
systemctl status amazon-cloudwatch-agent
systemctl status app
systemctl status app-watcher
```

## Notes

- The script is safe to run via `curl | sh -` even without a pre-downloaded file; it re-downloads itself for the root re-execution step
- CloudWatch Agent and app deployment steps are skipped automatically when `AWS_EXECUTION_ENV=CloudShell` is set
- App deployment is skipped when no binary is found in the S3 bucket; the rest of the script continues normally
- Docker group membership takes effect on next login; existing sessions need `newgrp docker` or a re-login

## Related Scripts

- [accinit.sh](./accinit.sh.md)
- [vpce.sh](./vpce.sh.md)
- [ec2init.sh](./ec2init.sh.md)
- [csinit.sh](./csinit.sh.md)
