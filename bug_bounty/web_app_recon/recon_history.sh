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
#   ./recon_history.sh /path/to/output-directory
#
# Example:
#
#   ./recon_history.sh ./results
#
# All output files are saved in the "history" directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-directory"
    exit 1
fi

REPORTS_DIR="$1"
OUTPUT_DIR="$REPORTS_DIR/history"
HOSTS_FILE="$REPORTS_DIR/ports/hosts_only.txt"

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: Cannot find $HOSTS_FILE"
    exit 1
fi

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

ALL_URLS_FILE="$OUTPUT_DIR/historical_urls.txt"
PARAMETER_URLS_FILE="$OUTPUT_DIR/historical_params.txt"

# -------------------------------------------------------------------
# Prepare the output directory and files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$ALL_URLS_FILE"
: > "$PARAMETER_URLS_FILE"

# -------------------------------------------------------------------
# Step 1: Collect URLs from Wayback Machine and gau
# -------------------------------------------------------------------

echo "[1/2] Collecting URLs"

# Each non-empty line in hosts_only.txt is treated as a host.
# The results are combined, sorted, and deduplicated.
while IFS= read -r host || [[ -n "$host" ]]; do

    # Ignore blank lines.
    [[ -z "$host" ]] && continue

    echo "Collecting URLs for: $host" >&2

    waybackurls "$host"
    gau "$host"

done < "$HOSTS_FILE" \
    | sort -u \
    > "$ALL_URLS_FILE"

# -------------------------------------------------------------------
# Step 2: Collect URLs from Wayback Machine and gau
# -------------------------------------------------------------------

echo "[2/2] Parsing collected URLs"

# Keep only URLs that:
# - Contain a query string
# - Do not point to common static files such as images, CSS, or fonts
grep -F '?' "$ALL_URLS_FILE" \
    | grep -viE '\.(png|jpg|jpeg|gif|css|svg|woff)([?#]|$)' \
    > "$PARAMETER_URLS_FILE" || true

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

# Display a summary when the script finishes.
echo
echo "Scan complete."
echo
echo "All historical URLs: $ALL_URLS_FILE"
echo "Historical URLs with parameters: $PARAMETER_URLS_FILE"

