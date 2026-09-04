#!/bin/bash

cat live_hosts.txt | cut -d' ' -f1 > urls.txt

# ffuf directory brute force per host
while read url; do
  ffuf -u "$url/FUZZ" -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-medium-directories.txt \
    -mc 200,301,302,403 -t 50 -silent -o "ffuf_$(echo $url | md5sum | cut -d' ' -f1).json"

done < urls.txt

# arjun for hidden parameters on discovered endpoints
arjun -i historical_params.txt -oT arjun_params.txt

