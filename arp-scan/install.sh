#!/bin/sh

# This script assumes it is run from the folder where arp-scan.sh and actions_arp-scan.conf are located.
# You will probably need to add credentials in /usr/local/opnsense/scripts/arp-scan/.env

install_path="/usr/local/opnsense/scripts/arp-scan"

mkdir -p "$install_path"/data

cp ./arp-scan.sh "$install_path"/arp-scan.sh
chmod 755 "$install_path"/arp-scan.sh
chmod +x "$install_path"/arp-scan.sh

cp ./actions_arp-scan.conf /usr/local/opnsense/service/conf/actions.d/actions_arp-scan.conf
chown root:wheel /usr/local/opnsense/service/conf/actions.d/actions_arp-scan.conf
chmod 644 /usr/local/opnsense/service/conf/actions.d/actions_arp-scan.conf

service configd restart
