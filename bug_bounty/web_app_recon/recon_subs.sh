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
#   ./recon_subs.sh example.com /path/to/output-directory
#
# Example:
#
#   ./recon_subs.sh example.com ./results
#
# All output files are saved in the "subs" directory.
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
OUTPUT_DIR="$REPORTS_DIR/subs"

# -------------------------------------------------------------------
# Check required tools
# -------------------------------------------------------------------

for tool in subfinder assetfinder amass; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: Required command not found: $tool"
        exit 1
    fi
done

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

SUBFINDER_FILE="$OUTPUT_DIR/subfinder.txt"
ASSETFINDER_FILE="$OUTPUT_DIR/assetfinder.txt"
AMASS_FILE="$OUTPUT_DIR/amass.txt"
ALL_SUBS_FILE="$OUTPUT_DIR/all_subs.txt"

# -------------------------------------------------------------------
# Prepare output files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$SUBFINDER_FILE"
: > "$ASSETFINDER_FILE"
: > "$AMASS_FILE"
: > "$ALL_SUBS_FILE"

# -------------------------------------------------------------------
# Step 1: Collect subdomains with subfinder
# -------------------------------------------------------------------

echo "[1/4] Collecting subdomains with subfinder"

subfinder \
    -d "$DOMAIN" \
    -all \
    -silent \
    > "$SUBFINDER_FILE"

# -------------------------------------------------------------------
# Step 2: Collect subdomains with assetfinder
# -------------------------------------------------------------------

echo "[2/4] Collecting subdomains with assetfinder"

assetfinder \
    --subs-only "$DOMAIN" \
    > "$ASSETFINDER_FILE"

# -------------------------------------------------------------------
# Step 3: Collect subdomains with amass
# -------------------------------------------------------------------

echo "[3/4] Collecting subdomains with amass"

amass enum \
    -nocolor \
    -d "$DOMAIN" \
    > "$AMASS_FILE"

# -------------------------------------------------------------------
# Step 4: Combine and deduplicate results
# -------------------------------------------------------------------

echo "[4/4] Combining subdomain results"

cat \
    "$SUBFINDER_FILE" \
    "$ASSETFINDER_FILE" \
    "$AMASS_FILE" \
    | sed '/^[[:space:]]*$/d' \
    | sort -u \
    > "$ALL_SUBS_FILE"

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

SUBDOMAIN_COUNT="$(wc -l < "$ALL_SUBS_FILE")"

echo
echo "Subdomain enumeration complete."
echo
echo "Unique subdomains found: $SUBDOMAIN_COUNT"
echo
echo "subfinder results: $SUBFINDER_FILE"
echo "assetfinder results: $ASSETFINDER_FILE"
echo "amass results: $AMASS_FILE"
echo "Combined results: $ALL_SUBS_FILE"

