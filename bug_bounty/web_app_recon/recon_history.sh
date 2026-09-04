#!/bin/bash

cat hosts_only.txt | while read h; do
  waybackurls "$h"
  gau "$h"

done | sort -u > historical_urls.txt # filter to interesting parameterized URLs

grep '?' historical_urls.txt | grep -viE "\.(png|jpg|jpeg|gif|css|svg|woff)" \
  > historical_params.txt
