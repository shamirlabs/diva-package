#!/bin/bash

rm -f ./test/*.pcap
rm -f ./test/*.log
ifconfig_output=$(ifconfig)

interface=$(echo "$ifconfig_output" | awk '/inet 172\.16\.0\./ {print iface} {iface=$1}' | sed 's/:$//')


container_node=$(docker ps | grep 'diva-node-1' | awk '{print $1}')
if [ -z "$container_node" ]; then
    echo "Container 'diva-node-1' not found."
    exit 1
fi
container_val=$(docker ps | grep 'diva-validator-1' | awk '{print $1}')
if [ -z "$container_val" ]; then
    echo "Container 'diva-validator-1' not found."
    exit 1
fi
container_beacon=$(docker ps | grep 'cl-1' | awk '{print $1}')
if [ -z "$container_beacon" ]; then
    echo "Container 'cl-1' not found."
    exit 1
fi

ip_node=$(docker inspect $container_node | jq -r '.[0].NetworkSettings.Networks | to_entries[0].value.IPAddress')

ip_val=$(docker inspect $container_val | jq -r '.[0].NetworkSettings.Networks | to_entries[0].value.IPAddress')

ip_beacon=$(docker inspect $container_beacon | jq -r '.[0].NetworkSettings.Networks | to_entries[0].value.IPAddress')

sudo  tcpdump -i $interface -s 0 -nn "(src $ip_val and dst $ip_node) or (src $ip_node and dst $ip_val)" -s0 -w ../test/http_vc_diva.pcap &
sudo tcpdump -i $interface -s 65535 -nn "(src $ip_val and dst $ip_beacon) or (src $ip_beacon and dst $ip_val)" -s0 -w ../test/http_vc_beacon.pcap &
