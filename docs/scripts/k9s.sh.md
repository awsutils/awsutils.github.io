---
sidebar_position: 4
---

# k9s.sh

Installs the latest Linux `k9s` binary into `/usr/local/bin/k9s`.

## What the Script Does

The current script in `static/k9s.sh`:

- Detects `x86_64` or `aarch64`
- Downloads the latest Linux `k9s` tarball from GitHub Releases
- Extracts it into `~/.tmp`
- Installs the binary to `/usr/local/bin/k9s`

## Quick Install

```bash
curl -fsSL https://awsutils.github.io/k9s.sh | sudo sh
```

## Prerequisites

- Linux host
- `wget`, `tar`, and `install`
- A working kubeconfig if you plan to launch `k9s` right away
- Permission to write to `/usr/local/bin`

## Verify

```bash
k9s version
```

## Notes

- The script installs the latest release only
- The script only installs the binary; it does not configure Kubernetes access
- macOS and Windows are not handled by the current implementation

## Typical Next Step

```bash
k9s
```

## Related Scripts

- [kubectl.sh](./kubectl.sh.md)
- [eksctl.sh](./eksctl.sh.md)
- [helm.sh](./helm.sh.md)
