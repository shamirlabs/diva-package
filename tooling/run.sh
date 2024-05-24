#!/bin/bash

kurtosis enclave rm diva -f
kurtosis run --enclave diva .. --args-file ../params.yaml --production
container_info=$(docker ps | grep -E 'dora|beaconchain-frontend')

host_port=$(echo "$container_info" | awk -F'[ :>-]+' '{for (i=1; i<=NF; i++) if ($i ~ /0.0.0.0/) print $(i+1)}')

bash start_scan.sh "$@"

echo "http:/IP:   $host_port"
