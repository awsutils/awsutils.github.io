---
sidebar_position: 13
---

# dashboard.sh

Creates or updates the CloudWatch dashboard documented in this repository.

## What the Script Does

The script in `static/dashboard.sh`:

- downloads or reads the dashboard source from this repo
- extracts the JSON dashboard body from `docs/docs/dashboards.md`
- replaces the default region `us-east-1` with your selected region
- creates or updates a CloudWatch dashboard with `aws cloudwatch put-dashboard`

This is a non-interactive helper for applying the same dashboard without manually copying JSON from the docs page.

## Quick Start

```bash
curl -fsSLO https://awsutils.github.io/dashboard.sh
chmod +x dashboard.sh
./dashboard.sh --name app-observability --region us-east-1
```

## Prerequisites

- `bash`
- `aws` CLI configured for the target account
- `python3`
- `curl`
- permission for `cloudwatch:PutDashboard` and `cloudwatch:GetDashboard`

## Options

```bash
./dashboard.sh --help
```

Key flags:

- `--name` sets the CloudWatch dashboard name
- `--region` changes the region placeholders before upload and sets the CLI region
- `--source` lets you use a local copy such as `./docs/docs/dashboards.md`
- `--dry-run` prepares the final JSON without calling AWS

## Examples

Create the default dashboard in `us-east-1`:

```bash
./dashboard.sh
```

Create the dashboard in another region:

```bash
./dashboard.sh --name platform-observability --region us-west-2
```

Use the local repo file instead of the published site:

```bash
./dashboard.sh --source ./docs/docs/dashboards.md --dry-run
```

## Notes

- The current dashboard JSON is sourced from `docs/docs/dashboards.md`
- The script performs a simple global replacement of `us-east-1` in the dashboard body
- EKS widgets that use the `[EKS] Namespace` variable still need the correct namespace selected in CloudWatch after import

## Related Docs

- [How to Use Dashboards](../docs/dashboards)
