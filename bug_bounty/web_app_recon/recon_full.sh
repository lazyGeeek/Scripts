#!/bin/bash

DOMAIN=$1

./recon_subs.sh $DOMAIN
./recon_probe.sh
./recon_ports.sh
./recon_crawl.sh
./recon_history.sh
./recon_params.sh

echo "[+] Recon complete for $DOMAIN"
echo "[+] Live hosts: $(wc -l < live_hosts.txt)"
echo "[+] JS endpoints found: $(wc -l < js_endpoints.txt)"
echo "[+] Historical params: $(wc -l < historical_params.txt)"
echo "[+] Possible secrets: $(wc -l < possible_secrets.txt)"

