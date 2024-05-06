#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 keyword"
    exit 1
fi

keyword="$1"

# Mapping keywords to specific container names
case "$keyword" in
    "diva"|"nodo")
        search_name="diva-node-1"
        ;;
    "val"|"validator")
        search_name="diva-validator-1"
        ;;
    "beacon"|"cl")
        search_name="cl-1"
        ;;
    "mev")
        search_name="mev"
        ;;
    *)
        # Use the keyword as the search name if no predefined keyword matches
        search_name="$keyword"
        ;;
esac

echo "Searching for containers containing '$search_name' in their names..."
while IFS= read -r container_info; do
    container_id=$(echo "$container_info" | awk '{print $1}')
    host_port=$(echo "$container_info" | awk -F'[ :>-]+' '{for (i=1; i<=NF; i++) if ($i ~ /0.0.0.0/) print $(i+1)}')
    container_name=$(echo "$container_info" | awk '{print $NF}')
    if [ ! -z "$host_port" ]; then
        echo " Name: $container_name, Container ID: $container_id, Port: $host_port"
    else
        echo "Name: $container_name, Container ID: $container_id, but no mapped host port found"
    fi
done < <(docker ps | grep "$search_name")

if [ -z "$container_info" ]; then
    echo "No containers found containing '$search_name' in their names."
fi
