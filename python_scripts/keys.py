import os
import sys
import re
import random
from collections import namedtuple
import yaml

Entry = namedtuple("Entry", ["key", "secret"])
def main():
    keystore_folder= sys.argv[1]
    secrets_folder = sys.argv[2]
    diva_set_size = int(sys.argv[3]) 
    diva_addresses = sys.argv[4]
    diva_threshold = int(sys.argv[5])
    diva_api_key = sys.argv[6]
    start_index = int(sys.argv[7])
    stop_index = int(sys.argv[8])
    diva_urls = sys.argv[9]
    diva_distribution=[]
    if len(sys.argv) > 10:
        diva_distribution = parse_distribution_arg(sys.argv[9])

    diva_urls = diva_urls.split(",")
    diva_addresses = diva_addresses.split(",")

    result= distribution(diva_set_size, len(diva_urls),stop_index - start_index,diva_distribution)

    for index in range(0, stop_index - start_index):
        validator_i= result[index]
        node_urls_val_i = [diva_urls[node_index] for node_index in validator_i]
        diva_addresses_val_i = [diva_addresses[node_index] for node_index in validator_i]
        create_pool(keystore_folder, secrets_folder, node_urls_val_i, diva_addresses_val_i, diva_threshold, diva_api_key)

                     
def distribution(num_keyshares_per_validator,num_total_nodes,num_validators,distribution):

    total_num_keyshares = num_validators * num_keyshares_per_validator

    total_keyshares_distribution = sum(distribution)
    if total_keyshares_distribution > total_num_keyshares or num_total_nodes < num_keyshares_per_validator:
        raise ValueError("Distribution is not possible with that configuration")


    distribution_result = {validator_id: [] for validator_id in range(num_validators)}

    for node_index, keyshares in enumerate(distribution):
        available_validators = [v_id for v_id in range(num_validators) if node_index not in distribution_result[v_id]]
        assigned = 0
        while assigned < keyshares:
            if not available_validators:  
                raise ValueError(f"Unable to distribute {keyshares} keyshares to node {node_index}")

            validator_id = random.choice(available_validators)
            distribution_result[validator_id].append(node_index)
            available_validators.remove(validator_id)
            assigned += 1


    assigned_keyshares = {node: 0 for node in range(num_total_nodes)}
    for validator_nodes in distribution_result.values():
        for node in validator_nodes:
            assigned_keyshares[node] += 1

    remaining_nodes = [node for node in range(num_total_nodes) 
                       if node >= len(distribution) or assigned_keyshares[node] < distribution[node]]


    for validator_id in range(num_validators):
        available_nodes = [node for node in remaining_nodes if node not in distribution_result[validator_id]]
        while len(distribution_result[validator_id]) < num_keyshares_per_validator:
            if not available_nodes: 
                raise ValueError("Unable to distribute remaining keyshares for validator " + str(validator_id)+ " out of "+ str(num_validators))
            node_index = random.choice(available_nodes)
            distribution_result[validator_id].append(node_index)
            available_nodes.remove(node_index) 


    return distribution_result


def create_pool(keystore_folder, secrets_folder, diva_urls, diva_addresses, diva_threshold, diva_api_key):
    entries = []
    for keystore_file in os.listdir(keystore_folder):
        keystore_contents = ""
        with open(append(keystore_folder, keystore_file)) as keystore_file_handle:
            keystore_contents = keystore_file_handle.read()
        secrets_file = keystore_file.replace("json", "txt")
        secrets_file = append(secrets_folder, secrets_file)
        secret = ""
        with open(secrets_file) as secret_file_handle:
            secret = secret_file_handle.read()
        entries.append(Entry(keystore_contents, secret))

    destination="/tmp/configurations/config-0"
    configurations = []
    for entry in entries:
        configuration = {
            "keystore": entry.key,
            "keystore_password": entry.secret,
            "threshold": diva_threshold,
            "key_shares": [{"client_api_url": url, "client_api_key": diva_api_key, "node_address": diva_addresses[index], "index": get_index(index+1)} for index, url in enumerate(diva_urls)]
        }
        configurations.append(configuration)

    print(f"writing out {len(configurations)} configurations to {destination}")
    for index in range(0, len(configurations)):
        filepath = f"{destination}/config-{index}.toml"
        with open(filepath, "w") as output_file_handle:
            output_file_handle.write(yaml.dump(configurations[index]))


# index will change in next release 
def get_index(index):
    return f"0x0{index}00000000000000000000000000000000000000000000000000000000000000"

def append(folder, file):
    return folder + "/" + file

def parse_distribution_arg(diva_distribution):
    diva_distribution=diva_distribution.strip("[] \t\n\r")
    return [int(x.strip()) for x in diva_distribution.split(",") if x.strip()]


main()