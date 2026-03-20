---
sidebar_position: 2
---

# eksctl.sh

Installs the latest Linux `eksctl` release into `/usr/local/bin/eksctl`.

## What the Script Does

The current script is a small Linux-only installer wrapper in `static/eksctl.sh`.

- Detects `x86_64` or `aarch64`
- Downloads the latest `eksctl` tarball from GitHub Releases
- Extracts it into `~/.tmp`
- Installs the binary to `/usr/local/bin/eksctl` with `install`

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/eksctl.sh | sudo sh
```

## Prerequisites

- Linux host
- `wget`, `tar`, and `install`
- Permission to write to `/usr/local/bin`

## Verify

```bash
eksctl version
eksctl help
```

## Notes

- The script always installs the latest release; it does not accept a version flag
- The script currently assumes `~/.tmp` can be created and reused
- macOS is not handled by the current implementation

## Typical Next Step

Use `eksctl` to create or manage an EKS cluster:

```bash
eksctl create cluster --name my-cluster --region us-east-1
```

## Related Scripts

- [kubectl.sh](./kubectl.sh.md)
- [helm.sh](./helm.sh.md)
- [k9s.sh](./k9s.sh.md)
