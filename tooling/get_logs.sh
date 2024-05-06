#!/bin/bash

rm -f ../test/*.log
# Find container ID for 'diva-node-1'
container_node=$(docker ps | grep 'diva-node-1' | awk '{print $1}')
if [ -z "$container_node" ]; then
    echo "Container 'diva-node-1' not found."
    exit 1
fi

# Find container ID for 'diva-validator-1'
container_val=$(docker ps | grep 'diva-validator-1' | awk '{print $1}')
if [ -z "$container_val" ]; then
    echo "Container 'diva-validator-1' not found."
    exit 1
fi

# Log output and errors from the containers
docker logs $container_node &> ../test/node.log
docker logs $container_val &> ../test/validator.log


tshark -s 0 -r ../test/http_vc_diva.pcap -Y http -T fields -e frame.time -e ip.src -e ip.dst -e tcp.seq -e tcp.ack -e http.request.method -e http.request.uri -e http.response.code -e http.response.phrase -e http.file_data -E header=y -E separator=, -E quote=d -E occurrence=f > ../test/vc_diva.csv

tshark -s 0 -r ../test/http_vc_beacon.pcap -Y http -T fields -e frame.time -e ip.src -e ip.dst -e tcp.seq -e tcp.ack -e http.request.method -e http.request.uri -e http.response.code -e http.response.phrase  -e http.content_type -E header=y -E separator=, -E quote=d -E occurrence=f > ../test/vc_beacon.csv

rm ../test/http_vc_diva.pcap
rm  ../test/http_vc_beacon.pcap