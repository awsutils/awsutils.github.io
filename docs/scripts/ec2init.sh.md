---
sidebar_position: 11
---

# ec2init.sh

Bootstraps an Amazon Linux 2023 EC2 instance with AWS, Terraform, Kubernetes, database, and Docker tooling.

## What the Script Does

The current script in `static/ec2init.sh`:

- Appends Terraform and `kubectl` aliases to `~/.bashrc`
- Installs system packages with `yum`
- Installs AWS CLI v2
- Installs `kubectl`, `eksctl`, `helm`, and `k9s`
- Adds `ec2-user` and `ssm-user` to the Docker group
- Enables Docker and registers `binfmt` support for multi-arch containers
- Creates a `binfmt-qemu` systemd service so multi-arch support survives reboot

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/ec2init.sh | bash
```

## Intended Environment

- Amazon Linux 2023
- EC2 instance with root privileges
- Internet access for package and binary downloads

## Major Packages and Tools

- System packages: `jq`, `curl`, `wget`, `git`, `docker`, `mariadb1011`, `postgresql17`, `redis6`
- AWS tooling: AWS CLI v2
- Kubernetes tooling: `kubectl`, `eksctl`, `helm`, `k9s`

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
aws --version
terraform version
kubectl version --client
eksctl version
helm version
k9s version
docker --version
```

## Notes

- This script is tailored to Amazon Linux 2023 package names and service behavior
- It appends to `~/.bashrc` every time you run it
- Docker group membership usually requires a new login before it takes effect

## Related Scripts

- [csinit.sh](./csinit.sh.md)
- [kubectl.sh](./kubectl.sh.md)
- [eksctl.sh](./eksctl.sh.md)
- [helm.sh](./helm.sh.md)
- [k9s.sh](./k9s.sh.md)
