#!/bin/bash

katana -list live_hosts.txt -jc -d 3 -silent -o crawled_urls.txt

grep '\.js$' crawled_urls.txt > js_files.txt pull secrets and endpoints out of JS

cat js_files.txt | while read url; do
  curl -s "$url" | grep -oE "(\"|')(\/api\/[a-zA-Z0-9_\/\-]+)(\"|')"
done | sort -u > js_endpoints.txt

# secretfinder or trufflehog style regex sweep
cat js_files.txt | while read url; do
  curl -s "$url"

done > all_js_content.txt grep -oE "(api[_-]?key|secret|token|aws_access_key_id)[\"']?\s*[:=]\s*[\"'][a-zA-Z0-9\-_]{10,}[\"']" all_js_content.txt > possible_secrets.txt

