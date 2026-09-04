#!/bin/bash

DOMAIN=$1

mkdir -p recon_results
cd recon_results

subfinder -d $DOMAIN -all -silent > subs_subfinder.txt
assetfinder --subs-only $DOMAIN > subs_assetfinder.txt
amass enum -passive -d $DOMAIN -o subs_amass.txt

cat subs_*.txt | sort -u > all_subs.txt

echo "[+] $(wc -l < all_subs.txt) unique subdomains found"

