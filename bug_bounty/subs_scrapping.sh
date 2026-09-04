#!/bin/bash

if [ "$1" == "" ]; then
    echo "Domain is empty"
    exit 1
fi

if [ -d "subdomains" ]; then
    rm -rf subdomains
fi

mkdir subdomains
cd subdomains

subfinder -d $1 -all -recursive -o subfinder.txt
assetfinder -subs-only $1 > assetfinder.txt
sublist3r -d $1 -o sublist3r.txt

cat subfinder.txt assetfinder.txt sublist3r.txt >> subs.txt
cat subs.txt | sort | uniq | tee -a unique_subs.txt

cd ../

httpx-toolkit -l subdomains/unique_subs.txt -sc -td -title -probe -ip -fhr -location -o subs_status.txt
