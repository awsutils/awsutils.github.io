---
sidebar_position: 10
---

# csinit.sh

Bootstraps an AWS CloudShell session for Terraform and Kubernetes-oriented work.

## What the Script Does

The current script in `static/csinit.sh` is meant for AWS CloudShell and does the following:

- Appends Terraform and `kubectl` aliases to `~/.bashrc`
- Sets `EDITOR=vim`
- Escalates with `sudo su`
- Installs Terraform from HashiCorp's Amazon Linux repo
- Installs `k9s`
- Runs Helm's upstream installer via `get-helm-3`
- Enables Docker `binfmt_misc` support for multi-arch image work

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/csinit.sh | sh
```

## Prerequisites

- AWS CloudShell
- `sudo` access inside the session
- Outbound network access for package and binary downloads

## Aliases Added

```bash
alias t="terraform"
alias ti="terraform init"
alias taa="terraform apply --auto-approve --parallelism 100"
alias td="terraform destroy --parallelism 100"
alias k="kubectl"
alias ka="kubectl apply -f"
alias kx="kubectl delete -f"
alias kd="kubectl describe -f"
alias kg="kubectl get pod -f"
export EDITOR="vim"
```

## Verify

```bash
terraform version
k9s version
helm version
source ~/.bashrc
```

## Notes

- This script assumes CloudShell already provides core AWS tooling such as `aws`, Docker, and `kubectl`
- It appends to `~/.bashrc` every time you run it
- Helm installation currently uses `get-helm-3` here, which differs from the standalone `helm.sh` wrapper

## Related Scripts

- [ec2init.sh](./ec2init.sh.md)
- [k9s.sh](./k9s.sh.md)
- [helm.sh](./helm.sh.md)
