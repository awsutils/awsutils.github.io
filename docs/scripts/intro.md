---
sidebar_position: 1
---

# Scripts Overview

The scripts in this repo are published directly from `static/`, so each file is available at `https://awsutils.github.io/<script>.sh`.

## Available Scripts

| Script | What it does | Best fit |
| --- | --- | --- |
| [eksctl.sh](./eksctl.sh.md) | Installs the latest Linux `eksctl` binary into `/usr/local/bin` | Quick EKS CLI setup |
| [kubectl.sh](./kubectl.sh.md) | Installs the latest stable Linux `kubectl` binary into `/usr/local/bin` | Quick Kubernetes CLI setup |
| [k9s.sh](./k9s.sh.md) | Installs the latest Linux `k9s` binary into `/usr/local/bin` | Terminal UI for Kubernetes |
| [helm.sh](./helm.sh.md) | Runs Helm's official install script wrapper | Helm installation via upstream script |
| [accinit.sh](./accinit.sh.md) | Applies a non-interactive single-account AWS security baseline | Account-level baseline bootstrap |
| [csinit.sh](./csinit.sh.md) | Prepares AWS CloudShell for Terraform and Kubernetes work | CloudShell bootstrap |
| [dashboard.sh](./dashboard.sh.md) | Creates or updates the repo's CloudWatch dashboard from the published docs JSON | CloudWatch dashboard bootstrap |
| [ec2init.sh](./ec2init.sh.md) | Prepares Amazon Linux 2023 EC2 instances for AWS, Terraform, Docker, and Kubernetes work | EC2 workstation bootstrap |
| [vpce.sh](./vpce.sh.md) | Interactive VPC endpoint creation helper | Building private-network access to AWS services |

## How These Scripts Are Published

- Script source lives in `static/*.sh`
- Docs live in `docs/scripts/*.md`
- The site serves files from `static/` at the root URL, which is why `static/eksctl.sh` becomes `/eksctl.sh`

## Usage Pattern

Prefer downloading a script first when it will make changes to your machine or AWS account.

```bash
curl -fsSLO https://awsutils.github.io/eksctl.sh
chmod +x eksctl.sh
less eksctl.sh
sudo ./eksctl.sh
```

For very small installer wrappers, you can also pipe directly to a shell when you trust the source:

```bash
curl -fsSL https://awsutils.github.io/kubectl.sh | sudo sh
```

## Important Notes

- These scripts do not share a single option standard; each script has its own behavior
- Most installer scripts target Linux and write to `/usr/local/bin`
- `csinit.sh` and `ec2init.sh` are intended for AWS-managed Linux environments, not generic desktops
- `vpce.sh` is interactive and expects a terminal because it uses `gum`

## Before You Run One

- Review the script contents
- Confirm prerequisites in the matching doc page
- Make sure your AWS CLI profile and region are set correctly for AWS-changing scripts
- Expect root or `sudo` to be required for scripts that install binaries system-wide

## Contributing

When adding a new script, keep the script in `static/` and add its matching doc page in `docs/scripts/` so both stay aligned.
