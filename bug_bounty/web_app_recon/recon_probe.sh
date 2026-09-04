#!/bin/bash

cat all_subs.txt | dnsx -silent -a -resp-only > resolved.txt
cat resolved.txt | httpx-toolkit -silent -title -status-code -tech-detect -ip \
  -o live_hosts.txt
