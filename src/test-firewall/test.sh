#!/bin/bash

# scriptlet:_common/get_firewall.sh
# scriptlet:ufw/install.sh
# scriptlet:_common/firewall_allow.sh

echo "Firewall: $(get_available_firewall)"
if [ "$(get_available_firewall)" == "none" ]; then
	install_ufw
fi

firewall_allow --port "16261:16262" --udp
firewall_allow --port "1234" --tcp
firewall_allow --port "111,2049" --tcp --zone internal --source 1.2.3.4/32
firewall_allow --zone trusted --source 6.7.8.9/32

# Status print (debugging)
FIREWALL="$(get_available_firewall)"
if [ "$FIREWALL" == "ufw" ]; then
	ufw status verbose
elif [ "$FIREWALL" == "firewalld" ]; then
	firewall-cmd --list-all --zone=public
	firewall-cmd --list-all --zone=internal
	firewall-cmd --list-all --zone=trusted
elif [ "$FIREWALL" == "iptables" ]; then
	iptables -L -v
fi