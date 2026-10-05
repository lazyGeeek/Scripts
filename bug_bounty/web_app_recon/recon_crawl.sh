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
#   ./recon_crawl.sh /path/to/output-directory
#
# Example:
#
#   ./recon_crawl.sh ./results
#
# All output files are saved in the "crawl" directory.
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Check arguments
# -------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/reports-directory"
    exit 1
fi

REPORTS_DIR="$1"
OUTPUT_DIR="$REPORTS_DIR/crawl"
LIVE_HOSTS_FILE="$REPORTS_DIR/probe/live_hosts.txt"

if [[ ! -f "$LIVE_HOSTS_FILE" ]]; then
    echo "Error: Cannot find $LIVE_HOSTS_FILE"
    exit 1
fi

# -------------------------------------------------------------------
# Define output files
# -------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"

CRAWLED_URLS_FILE="$OUTPUT_DIR/crawled_urls.txt"
JS_URLS_FILE="$OUTPUT_DIR/js_files.txt"
API_ENDPOINTS_FILE="$OUTPUT_DIR/js_endpoints.txt"
ALL_JS_CONTENT_FILE="$OUTPUT_DIR/all_js_content.txt"
POSSIBLE_SECRETS_FILE="$OUTPUT_DIR/possible_secrets.txt"

# -------------------------------------------------------------------
# Prepare the output directory and files
# -------------------------------------------------------------------

# Empty old output files so each run starts fresh.
: > "$CRAWLED_URLS_FILE"
: > "$JS_URLS_FILE"
: > "$API_ENDPOINTS_FILE"
: > "$ALL_JS_CONTENT_FILE"
: > "$POSSIBLE_SECRETS_FILE"

# -------------------------------------------------------------------
# Step 1: Crawl the live hosts
# -------------------------------------------------------------------

echo "[1/4] Crawling live hosts..."

katana \
    -list "$LIVE_HOSTS_FILE" \
    -jc \
    -d 3 \
    -silent \
    -o "$CRAWLED_URLS_FILE"

# -------------------------------------------------------------------
# Step 2: Find JavaScript URLs
# -------------------------------------------------------------------

echo "[2/4] Finding JavaScript files..."

grep -Ei '\.js([?#].*)?$' "$CRAWLED_URLS_FILE" |
    sort -u > "$JS_URLS_FILE" || true

# -------------------------------------------------------------------
# Step 3: Download JavaScript and find API endpoints
# -------------------------------------------------------------------

echo "[3/4] Finding API endpoints..."

while IFS= read -r javascript_url; do

    # Ignore empty lines.
    [[ -z "$javascript_url" ]] && continue

    # Download the JavaScript file and search for /api/ paths.
    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --max-time 30 \
        "$javascript_url" 2>/dev/null |
        grep -oE '/api/[A-Za-z0-9_/-]+' || true

done < "$JS_URLS_FILE" |
    sort -u > "$API_ENDPOINTS_FILE"

# -------------------------------------------------------------------
# Step 4: Save all JavaScript content
# -------------------------------------------------------------------

echo "[4/4] Downloading all JavaScript content..."

while IFS= read -r javascript_url; do

    # Ignore empty lines.
    [[ -z "$javascript_url" ]] && continue

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --max-time 30 \
        "$javascript_url" 2>/dev/null || true

    # Add a blank line between downloaded files.
    printf '\n'

done < "$JS_URLS_FILE" > "$ALL_JS_CONTENT_FILE"

# -------------------------------------------------------------------
# Step 5: Search for possible hard-coded secrets
# -------------------------------------------------------------------

echo "Searching for possible secrets..."

SECRET_PATTERN='(api[_-]?key|secret|token|aws_access_key_id)[[:space:]]*["'\'']?[[:space:]]*[:=][[:space:]]*["'\''][A-Za-z0-9_./+=-]{10,}["'\'']'

grep \
    --extended-regexp \
    --ignore-case \
    --line-number \
    "$SECRET_PATTERN" \
    "$ALL_JS_CONTENT_FILE" \
    > "$POSSIBLE_SECRETS_FILE" || true

# -------------------------------------------------------------------
# Finished
# -------------------------------------------------------------------

echo
echo "Scan complete."
echo
echo "Crawled URLs:     $CRAWLED_URLS_FILE"
echo "JavaScript URLs:  $JS_URLS_FILE"
echo "API endpoints:    $API_ENDPOINTS_FILE"
echo "JavaScript data:  $ALL_JS_CONTENT_FILE"
echo "Possible secrets: $POSSIBLE_SECRETS_FILE"

