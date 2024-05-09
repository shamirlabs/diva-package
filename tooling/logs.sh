#!/bin/bash

save_logs() {
    local container_id=$1
    local container_name=$2
    echo "Saving logs from $container_name..."
    docker logs "$container_id" &> "../logs/${container_name}.log"
}

handle_multiple_containers() {
    local search_pattern=$1
    echo "Multiple containers found for '$search_pattern'. Do you want to save logs from all? (Y/n)"
    read answer
    if [[ "$answer" == "Y" || "$answer" == "y" || "$answer" == "" ]]; then
        echo "Saving logs for all found containers."
        docker ps | grep "$search_pattern" | while read -r line; do
            local cid=$(echo $line | awk '{print $1}')
            local cname=$(echo $line | awk '{print $(NF)}')
            save_logs "$cid" "$cname"
        done
    else
        echo "Aborted by user."
    fi
}

keyword="$1"
if [[ -z "$keyword" ]]; then
    echo "Usage: $0 <keyword>"
    exit 1
fi

case "$keyword" in
    diva|diva\ all)
        search_name="diva-node-"
        ;;
    validator|validator\ all)
        search_name="diva-validator-"
        ;;
    diva*)
        search_name="diva-node-${keyword:4}"
        ;;
    val*|validator*)
        search_name="diva-validator-${keyword:3}"
        ;;
    *)
        search_name="$keyword"
        ;;
esac

# Search and handle logs based on defined patterns
if [[ "$keyword" == "diva" || "$keyword" == "diva all" || "$keyword" == "validator" || "$keyword" == "validator all" ]]; then
    for i in {1..5}; do
        docker ps | grep "$search_name$i" | while read -r line; do
            cid=$(echo $line | awk '{print $1}')
            cname=$(echo $line | awk '{print $(NF)}')
            if [ -z "$cid" ]; then
                echo "No containers found for '$search_name$i'."
            else
                save_logs "$cid" "$cname"
            fi
        done
    done
else
    # Search for containers
    container_ids=$(docker ps | grep "$search_name" | awk '{print $1}')
    container_names=$(docker ps | grep "$search_name" | awk '{print $(NF)}')
    if [ -z "$container_ids" ]; then
        echo "No containers found containing '$search_name' in their names."
        exit 1
    elif [ "$(echo "$container_ids" | wc -l)" -gt 1 ]; then
        handle_multiple_containers "$search_name"
    else
        save_logs "$container_ids" "$container_names"
    fi
fi
