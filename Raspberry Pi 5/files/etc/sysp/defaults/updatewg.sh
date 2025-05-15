#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <profilename>"
  exit 1
fi

profilename=$1

# Delete existing WireGuard network configuration
uci delete network.wggb;
uci delete network.@wireguard_wggb[0];
uci commit network;

# Append specific sections from the wireguard config to the network config
awk -v profilename="$profilename" '
  BEGIN {flag=0}
  $0 ~ "config interface \x27" profilename "\x27$" {flag=1; print; next}
  /^config / && flag {flag=0}
  flag {print}
' /etc/config/wireguard >> /etc/config/network;

awk -v profilename="$profilename" '
  BEGIN {flag=0}
  $0 ~ "config wireguard_" profilename "$" {flag=1; print; next}
  /^config / && flag {flag=0}
  flag {print}
' /etc/config/wireguard >> /etc/config/network;

uci commit network;

# Replace profilename with wggb in the network config
sed -i "s/config interface '$profilename'/config interface 'wggb'/" /etc/config/network;
sed -i "s/config wireguard_$profilename/config wireguard_wggb/" /etc/config/network;

uci commit network

echo "Configuration updated successfully for profile: $profilename"
