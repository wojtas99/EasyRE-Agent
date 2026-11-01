#!/bin/sh
# net - packet-capture tooling for crackmes that ship a .pcap/.pcapng next to
# the binary (see the code-and-data and formats-forensics skills). tshark reads
# and filters captures from the command line; capinfos summarises them. scapy
# (Python packet parsing/crafting) is installed by the core module.
set -e

# tshark's postinst asks whether non-root users may capture; preseed it so the
# non-interactive build does not hang.
echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
apt-get update
apt-get install -y --no-install-recommends tshark

echo "net tools:"
for t in tshark capinfos; do
  command -v "$t" >/dev/null 2>&1 && printf '  [x] %s\n' "$t" || printf '  [ ] %s\n' "$t"
done
