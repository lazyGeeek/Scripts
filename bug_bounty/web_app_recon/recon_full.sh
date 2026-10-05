#!/bin/bash

# Stop the script if:
# - A command fails
# - An undefined variable is used
# - A command in a pipeline fails
set -euo pipefail

# -------------------------------------------------------------------
# Usage
# -------------------------------------------------------------------
#
#   ./recon_full.sh example.com /path/to/output-directory
#
# Example:
#
#   ./recon_full.sh example.com ./results
#
# All output files are saved inside the specified output directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 domain /path/to/output-directory"
    exit 1
fi

DOMAIN="$1"
REPORTS_DIR="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$REPORTS_DIR"

# -------------------------------------------------------------------
# Check required scripts
# -------------------------------------------------------------------

REQUIRED_SCRIPTS=(
    "recon_subs.sh"
    "recon_probe.sh"
    "recon_ports.sh"
    "recon_crawl.sh"
    "recon_history.sh"
    "recon_params.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
        echo "Error: Cannot find executable script: $SCRIPT_DIR/$script"
        echo "Make it executable with: chmod +x $SCRIPT_DIR/$script"
        exit 1
    fi
done

# -------------------------------------------------------------------
# Run reconnaissance stages
# -------------------------------------------------------------------

echo "[1/6] Enumerating subdomains"
"$SCRIPT_DIR/recon_subs.sh" "$DOMAIN" "$REPORTS_DIR"

echo "[2/6] Probing live services"
"$SCRIPT_DIR/recon_probe.sh" "$REPORTS_DIR"

echo "[3/6] Scanning ports"
"$SCRIPT_DIR/recon_ports.sh" "$REPORTS_DIR"

echo "[4/6] Crawling live targets"
"$SCRIPT_DIR/recon_crawl.sh" "$REPORTS_DIR"

echo "[5/6] Collecting historical URLs"
"$SCRIPT_DIR/recon_history.sh" "$REPORTS_DIR"

echo "[6/6] Discovering parameters"
"$SCRIPT_DIR/recon_params.sh" "$REPORTS_DIR"

# -------------------------------------------------------------------
# Define summary files
# -------------------------------------------------------------------

LIVE_HOSTS_FILE="$REPORTS_DIR/probe/live_hosts.txt"
JS_ENDPOINTS_FILE="$REPORTS_DIR/crawl/js_endpoints.txt"
HISTORICAL_PARAMS_FILE="$REPORTS_DIR/history/historical_params.txt"
POSSIBLE_SECRETS_FILE="$REPORTS_DIR/crawl/possible_secrets.txt"

# -------------------------------------------------------------------
# Count results safely
# -------------------------------------------------------------------

count_lines() {
    local file="$1"

    if [[ -f "$file" ]]; then
        wc -l < "$file"
    else
        echo "0"
    fi
}

LIVE_HOST_COUNT="$(count_lines "$LIVE_HOSTS_FILE")"
JS_ENDPOINT_COUNT="$(count_lines "$JS_ENDPOINTS_FILE")"
HISTORICAL_PARAM_COUNT="$(count_lines "$HISTORICAL_PARAMS_FILE")"
POSSIBLE_SECRET_COUNT="$(count_lines "$POSSIBLE_SECRETS_FILE")"

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

echo
echo "Recon complete for $DOMAIN"
echo
echo "Results directory: $REPORTS_DIR"
echo "Live hosts: $LIVE_HOST_COUNT"
echo "JS endpoints found: $JS_ENDPOINT_COUNT"
echo "Historical parameters: $HISTORICAL_PARAM_COUNT"
echo "Possible secrets: $POSSIBLE_SECRET_COUNT"

