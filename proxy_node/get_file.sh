#!/bin/bash

mkdir -p ./data/network-configs

wget -O /tmp/network-configs.tar http://IP_ADDRESS:40000/network-config.tar

tar -xvf /tmp/network-configs.tar -C ./data/network-configs

rm /tmp/network-configs.tar