---
sidebar_position: 12
---

# vpce.sh

Interactive helper for creating common VPC endpoints in an existing VPC.

## What the Script Does

The current script in `static/vpce.sh` is an interactive Bash tool that:

- Ensures `gum` is available, installing it if needed
- Prompts you to choose a VPC from your account
- Lets you select common gateway and interface endpoint services
- Detects private route tables and private subnets
- Creates or reuses a security group named `<vpc-name>-vpce-sg`
- Creates gateway endpoints against all route tables
- Creates interface endpoints in private subnets, filtered by supported AZs
- Prints a final summary table of endpoints in the chosen VPC

## Quick Start

```bash
curl -fsSLO https://awsutils.github.io/vpce.sh
chmod +x vpce.sh
./vpce.sh
```

## Prerequisites

- Bash 4+
- AWS CLI configured for the target account and region
- Permission to create VPC endpoints and security groups
- A real terminal session; the script reads from `/dev/tty`
- `sudo` access if `gum` needs to be installed into `/usr/local/bin`

## Default Service Sets

Gateway endpoints offered by default:

- `s3`
- `dynamodb`

Interface endpoints offered by default:

- `ec2`
- `ec2messages`
- `ssm`
- `ssmmessages`
- `logs`
- `monitoring`
- `sts`
- `kms`
- `ecr.api`
- `ecr.dkr`
- `secretsmanager`
- `sqs`
- `sns`
- `execute-api`

You can also search for and add additional interface services interactively.

## Notes

- The current script is interactive only; it does not accept a VPC ID argument
- Interface endpoints are skipped when no private subnets are detected
- Existing endpoints are detected and skipped
- The script creates resources in parallel once selections are made

## Verify

```bash
aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=vpc-xxxxxxxx
```

## Related Scripts

- [ec2init.sh](./ec2init.sh.md)
- [csinit.sh](./csinit.sh.md)
