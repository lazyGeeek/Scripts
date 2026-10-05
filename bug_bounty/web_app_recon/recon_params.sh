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
#   ./recon_params.sh /path/to/output-directory
#
# Example:
#
#   ./recon_params.sh ./results
#
# Input files:
#   probe/live_hosts.txt
#   history/historical_params.txt
#
# All output files are saved in the "params" directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/output-directory"
    exit 1
fi

REPORTS_DIR="$1"
OUTPUT_DIR="$REPORTS_DIR/params"

LIVE_HOSTS_FILE="$REPORTS_DIR/probe/live_hosts.txt"
HISTORICAL_PARAMS_FILE="$REPORTS_DIR/history/historical_params.txt"

if [[ ! -f "$LIVE_HOSTS_FILE" ]]; then
    echo "Error: Cannot find $LIVE_HOSTS_FILE"
    exit 1
fi

if [[ ! -f "$HISTORICAL_PARAMS_FILE" ]]; then
    echo "Error: Cannot find $HISTORICAL_PARAMS_FILE"
    exit 1
fi

# -------------------------------------------------------------------
# Check required tools
# -------------------------------------------------------------------

for tool in ffuf arjun md5sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: Required command not found: $tool"
        exit 1
    fi
done

WORDLIST="/usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt"

if [[ ! -f "$WORDLIST" ]]; then
    echo "Error: Cannot find wordlist: $WORDLIST"
    exit 1
fi

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

URLS_FILE="$OUTPUT_DIR/urls.txt"
ARJUN_PARAMS_FILE="$OUTPUT_DIR/arjun_params.txt"

# -------------------------------------------------------------------
# Prepare output files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$URLS_FILE"
: > "$ARJUN_PARAMS_FILE"

# Remove old ffuf result files from previous runs.
find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'ffuf_*.json' -delete

# -------------------------------------------------------------------
# Step 1: Extract live hosts
# -------------------------------------------------------------------

echo "[1/3] Preparing live hosts"

# Extract the first whitespace-separated field from live_hosts.txt.
# Empty lines are ignored, then results are sorted and deduplicated.
awk 'NF { print $1 }' "$LIVE_HOSTS_FILE" \
    | sort -u \
    > "$URLS_FILE"

# -------------------------------------------------------------------
# Step 2: Brute-force directories with ffuf
# -------------------------------------------------------------------

echo "[2/3] Running directory discovery"

while IFS= read -r url || [[ -n "$url" ]]; do

    # Ignore blank lines.
    [[ -z "$url" ]] && continue

    # Remove trailing slashes to avoid URLs such as https://example.com//FUZZ.
    url="${url%/}"

    HASH="$(
        printf '%s' "$url" \
            | md5sum \
            | cut -d' ' -f1
    )"

    OUTPUT_FILE="$OUTPUT_DIR/ffuf_${HASH}.json"

    echo "Scanning: $url" >&2

    ffuf \
        -u "$url/FUZZ" \
        -w "$WORDLIST" \
        -mc 200,301,302,403 \
        -t 50 \
        -s \
        -o "$OUTPUT_FILE" \
        > /dev/null

done < "$URLS_FILE"

# -------------------------------------------------------------------
# Step 3: Find hidden parameters with arjun
# -------------------------------------------------------------------

echo "[3/3] Discovering hidden parameters"

arjun \
    -i "$HISTORICAL_PARAMS_FILE" \
    -oT "$ARJUN_PARAMS_FILE"

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

echo
echo "Parameter reconnaissance complete."
echo
echo "Prepared URLs: $URLS_FILE"
echo "ffuf results: $OUTPUT_DIR/ffuf_<md5>.json"
echo "Arjun results: $ARJUN_PARAMS_FILE"

