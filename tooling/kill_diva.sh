#!/bin/bash
 


container_val2=$(docker ps | grep 'diva-node-2' | awk '{print $1}')
container_val3=$(docker ps | grep 'diva-node-3' | awk '{print $1}')
container_val4=$(docker ps | grep 'diva-node-4' | awk '{print $1}')
container_val5=$(docker ps | grep 'diva-node-5' | awk '{print $1}')




docker stop $container_val2 $container_val3 $container_val4 $container_val5

echo "4 divas killed"
