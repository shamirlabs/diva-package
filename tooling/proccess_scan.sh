#!/usr/bin/env bash

test_dir="../test"


extract_containers() {
    filename="$1"
    container1=$(echo "$filename" | cut -d'_' -f1)
    container2=$(echo "$filename" | cut -d'_' -f2)
    containers["$container1"]=1
    containers["$container2"]=1
}

declare -A containers

for pcap_file in "$test_dir"/*.pcap; do
    filename=$(basename -- "$pcap_file")
    filename_no_ext="${filename%.*}"
    
    extract_containers "$filename_no_ext"
    
    tshark -s 0 -r "$pcap_file" -Y http -T fields -e frame.time -e ip.src -e ip.dst -e tcp.seq -e tcp.ack -e http.request.method -e http.request.uri -e http.response.code -e http.response.phrase -e http.file_data -E header=y -E separator=, -E quote=d -E occurrence=f > "$test_dir/${filename_no_ext}.csv"

    rm "$pcap_file"
done

rm $test_dir/*.log
rm $test_dir/*.csv

for container in "${!containers[@]}"; do
    while IFS= read -r container_info; do
        container_id=$(echo "$container_info" | awk '{print $1}')
        container_name=$(echo "$container_info" | awk '{print $NF}')
        if [[ "$container_name" == *"$container"* ]]; then
            docker logs "$container_id" &> "$test_dir/${container}.log"
            break
        fi
    done < <(docker ps | grep "$container")
done

