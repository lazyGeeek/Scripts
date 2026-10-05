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
#   ./recon_ports.sh /path/to/output-directory
#
# Example:
#
#   ./recon_ports.sh ./results
#
# Input file:
#   probe/live_hosts.txt
#
# All output files are saved in the "ports" directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-directory"
    exit 1
fi

REPORTS_DIR="$1"
OUTPUT_DIR="$REPORTS_DIR/ports"
LIVE_HOSTS_FILE="$REPORTS_DIR/probe/live_hosts.txt"

if [[ ! -f "$LIVE_HOSTS_FILE" ]]; then
    echo "Error: Cannot find $LIVE_HOSTS_FILE"
    exit 1
fi

# -------------------------------------------------------------------
# Check required tools
# -------------------------------------------------------------------

if ! command -v naabu >/dev/null 2>&1; then
    echo "Error: Required command not found: naabu"
    exit 1
fi

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

HOSTS_FILE="$OUTPUT_DIR/hosts_only.txt"
OPEN_PORTS_FILE="$OUTPUT_DIR/open_ports.txt"

# -------------------------------------------------------------------
# Prepare output files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$HOSTS_FILE"
: > "$OPEN_PORTS_FILE"

# -------------------------------------------------------------------
# Step 1: Extract hostnames from live HTTP services
# -------------------------------------------------------------------

echo "[1/2] Preparing hosts for port scanning"

# Extract the first field, remove the URL scheme, and remove any path.
awk 'NF { print $1 }' "$LIVE_HOSTS_FILE" \
    | sed -E 's~^https?://~~; s~/.*$~~' \
    | sort -u \
    > "$HOSTS_FILE"

# -------------------------------------------------------------------
# Step 2: Scan the top 1,000 ports with naabu
# -------------------------------------------------------------------

echo "[2/2] Scanning open ports"

naabu \
    -list "$HOSTS_FILE" \
    -top-ports 1000 \
    -silent \
    -o "$OPEN_PORTS_FILE" \
    > /dev/null

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

PORT_COUNT="$(wc -l < "$OPEN_PORTS_FILE")"

echo
echo "Port scanning complete."
echo
echo "Hosts scanned: $HOSTS_FILE"
echo "Open ports found: $OPEN_PORTS_FILE"
echo "Total open ports: $PORT_COUNT"

