---
sidebar_position: 5
---

# helm.sh

Runs Helm's official install script from the upstream `helm/helm` repository.

## What the Script Does

The current wrapper in `static/helm.sh` is intentionally minimal:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | sh
```

That means installation behavior, platform support, and most checks come from Helm's upstream installer rather than custom logic in this repo.

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/helm.sh | bash
```

## Prerequisites

- `bash`
- `curl`
- Any requirements imposed by Helm's upstream install script

## Verify

```bash
helm version
helm help
```

## Notes

- This repo does not pin a Helm version
- The wrapper currently delegates entirely to Helm's `get-helm-4` installer
- If upstream changes installation behavior, this wrapper changes with it

## Typical Next Step

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## Related Scripts

- [kubectl.sh](./kubectl.sh.md)
- [eksctl.sh](./eksctl.sh.md)
- [k9s.sh](./k9s.sh.md)
