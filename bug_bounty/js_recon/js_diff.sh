#!/bin/bash

DOMAIN=$1

mkdir -p js_snapshots/$DOMAIN/$(date +%F)

cat js_files.txt | while read url; do
  curl -s "$url" -o "js_snapshots/$DOMAIN/$(date +%F)/$(basename $url)"
done

YESTERDAY=$(date -d "yesterday" +%F)

TODAY=$(date +%F)

diff -rq "js_snapshots/$DOMAIN/$YESTERDAY" "js_snapshots/$DOMAIN/$TODAY" \
  > "js_snapshots/$DOMAIN/diff_$TODAY.txt"

