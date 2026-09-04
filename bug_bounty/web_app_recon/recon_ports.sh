#!/bin/bash

cat live_hosts.txt | cut -d' ' -f1 | sed 's~https\?://~~' > hosts_only.txt

naabu -list hosts_only.txt -top-ports 1000 -silent -o open_ports.txt

