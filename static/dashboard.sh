#!/bin/bash
set -euo pipefail

export AWS_PAGER=""
export AWS_CLI_AUTO_PROMPT=off

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
    printf '%b[INFO]%b %s\n' "$GREEN" "$NC" "$*"
}

warn() {
    printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*" >&2
}

fatal() {
    printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*" >&2
    exit 1
}

show_help() {
    cat <<'EOF'
Usage: dashboard.sh [--name DASHBOARD_NAME] [--region AWS_REGION] [--source URL_OR_PATH] [--dry-run] [--help]

Creates or updates the CloudWatch dashboard published in this repo.

Options:
  --name DASHBOARD_NAME   Dashboard name to create or update (default: app-observability)
  --region AWS_REGION     Region to apply to the dashboard JSON and AWS CLI call
  --source URL_OR_PATH    Dashboard JSON source. Supports https:// URLs or local files.
                          Default: https://awsutils.github.io/docs/docs/dashboards
  --dry-run               Print what would happen without calling PutDashboard
  -h, --help              Show this help text

Behavior:
  - extracts the JSON dashboard body from the repo's dashboards documentation page
  - replaces the default region placeholder (us-east-1) with the selected region
  - uploads the resulting body with aws cloudwatch put-dashboard

Examples:
  ./dashboard.sh
  ./dashboard.sh --name platform-observability --region us-west-2
  ./dashboard.sh --source ./docs/docs/dashboards.md --dry-run
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fatal "Required command not found: $1"
}

json_escape() {
    python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

extract_dashboard_json() {
    python3 - "$1" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
match = re.search(r"### Apply Dashboard \.json Directly\s*```json\s*(\{.*?\})\s*```", text, re.S)
if not match:
    sys.stderr.write("Unable to find dashboard JSON block in source\n")
    sys.exit(1)
print(match.group(1))
PY
}

fetch_source() {
    local source="$1"
    local output="$2"

    case "$source" in
        http://*|https://*)
            curl -fsSL "$source" -o "$output"
            ;;
        *)
            cp "$source" "$output"
            ;;
    esac
}

DASHBOARD_NAME="app-observability"
AWS_REGION_VALUE="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
SOURCE="https://awsutils.github.io/docs/docs/dashboards"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            [[ $# -ge 2 ]] || fatal "Missing value for --name"
            DASHBOARD_NAME="$2"
            shift 2
            ;;
        --region)
            [[ $# -ge 2 ]] || fatal "Missing value for --region"
            AWS_REGION_VALUE="$2"
            shift 2
            ;;
        --source)
            [[ $# -ge 2 ]] || fatal "Missing value for --source"
            SOURCE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            fatal "Unknown option: $1"
            ;;
    esac
done

require_command aws
require_command python3
require_command curl

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

SOURCE_FILE="$TMP_DIR/source.md"
RAW_JSON_FILE="$TMP_DIR/dashboard-raw.json"
FINAL_JSON_FILE="$TMP_DIR/dashboard.json"

info "Fetching dashboard source from $SOURCE"
fetch_source "$SOURCE" "$SOURCE_FILE"

info "Extracting dashboard JSON"
extract_dashboard_json "$SOURCE_FILE" > "$RAW_JSON_FILE"

python3 - "$RAW_JSON_FILE" "$FINAL_JSON_FILE" "$AWS_REGION_VALUE" <<'PY'
import json
import sys

source_path, output_path, region = sys.argv[1:4]
with open(source_path, encoding="utf-8") as f:
    dashboard = json.load(f)

text = json.dumps(dashboard)
text = text.replace("us-east-1", region)
dashboard = json.loads(text)

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(dashboard, f, separators=(",", ":"))
PY

if [[ "$DRY_RUN" == true ]]; then
    info "Dry run enabled; dashboard body prepared but not uploaded"
    info "Dashboard name: $DASHBOARD_NAME"
    info "Region: $AWS_REGION_VALUE"
    info "Dashboard JSON: $FINAL_JSON_FILE"
    exit 0
fi

info "Uploading dashboard $DASHBOARD_NAME to region $AWS_REGION_VALUE"
if aws --region "$AWS_REGION_VALUE" cloudwatch put-dashboard \
    --dashboard-name "$DASHBOARD_NAME" \
    --dashboard-body "file://$FINAL_JSON_FILE" >/dev/null; then
    info "Dashboard updated successfully"
else
    warn "Dashboard upload failed, likely due to missing CloudWatch permissions. Prepared JSON remains at $FINAL_JSON_FILE"
fi

warn "Review namespace-driven EKS widgets in CloudWatch and select your namespace variable after import"
