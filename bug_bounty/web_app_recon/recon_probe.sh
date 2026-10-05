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
#   ./reckon_probe.sh /path/to/output-directory
#
# Example:
#
#   ./reckon_probe.sh ./results
#
# Input file:
#   subs/all_subs.txt
#
# All output files are saved in the "probe" directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-directory"
    exit 1
fi

REPORTS_DIR="$1"
OUTPUT_DIR="$REPORTS_DIR/probe"
SUBDOMAINS_FILE="$REPORTS_DIR/subs/all_subs.txt"

if [[ ! -f "$SUBDOMAINS_FILE" ]]; then
    echo "Error: Cannot find $SUBDOMAINS_FILE"
    exit 1
fi

# -------------------------------------------------------------------
# Check required tools
# -------------------------------------------------------------------

for tool in dnsx httpx-toolkit; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: Required command not found: $tool"
        exit 1
    fi
done

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

RESOLVED_FILE="$OUTPUT_DIR/resolved.txt"
LIVE_HOSTS_FILE="$OUTPUT_DIR/live_hosts.txt"

# -------------------------------------------------------------------
# Prepare output files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$RESOLVED_FILE"
: > "$LIVE_HOSTS_FILE"

# -------------------------------------------------------------------
# Step 1: Resolve subdomains with dnsx
# -------------------------------------------------------------------

echo "[1/2] Resolving subdomains"

dnsx \
    -silent \
    -a \
    -resp-only \
    -l "$SUBDOMAINS_FILE" \
    > "$RESOLVED_FILE"

# -------------------------------------------------------------------
# Step 2: Probe HTTP services with httpx-toolkit
# -------------------------------------------------------------------

echo "[2/2] Probing live HTTP services"

httpx-toolkit \
    -l "$SUBDOMAINS_FILE" \
    -silent \
    -title \
    -status-code \
    -tech-detect \
    -ip \
    -fhr \
    -location \
    -nc \
    -o "$LIVE_HOSTS_FILE"

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

echo
echo "Probing complete."
echo
echo "Resolved hosts: $RESOLVED_FILE"
echo "Live hosts: $LIVE_HOSTS_FILE"

