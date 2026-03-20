---
sidebar_position: 3
---

# kubectl.sh

Installs the latest stable Linux `kubectl` binary into `/usr/local/bin/kubectl`.

## What the Script Does

The current script in `static/kubectl.sh`:

- Detects `x86_64` or `aarch64`
- Reads the current stable Kubernetes release from `https://dl.k8s.io/release/stable.txt`
- Downloads the matching Linux binary
- Installs it to `/usr/local/bin/kubectl`

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/kubectl.sh | sudo sh
```

## Prerequisites

- Linux host
- `wget`, `curl`, and `install`
- Permission to write to `/usr/local/bin`

## Verify

```bash
kubectl version --client
kubectl help
```

## Notes

- The script installs the current stable release only
- The script does not manage kubeconfig for you
- macOS and Windows are not handled by the current implementation

## Typical Next Step

For EKS, update your kubeconfig after install:

```bash
aws eks update-kubeconfig --name my-cluster --region us-east-1
kubectl get nodes
```

## Related Scripts

- [eksctl.sh](./eksctl.sh.md)
- [k9s.sh](./k9s.sh.md)
- [helm.sh](./helm.sh.md)
