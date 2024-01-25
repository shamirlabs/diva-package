import os
import sys
import re
import random
from collections import namedtuple
import yaml

Entry = namedtuple("Entry", ["key", "secret"])
def main():
    keystore_folder = sys.argv[1] 
    secrets_folder = sys.argv[2]
    diva_urls = sys.argv[3]
    diva_addresses = sys.argv[4]
    diva_threshold = int(sys.argv[5])
    diva_api_key = sys.argv[6]
    destination = sys.argv[7]
    num_validators = sys.argv[8]
    diva_set_size = sys.argv[9]
    diva_distribution = sys.argv[10]
    
    result= distribution(diva_set_size, len(diva_urls),num_validators,diva_distribution)

    for index in range(0, num_validators):
        validator_i= result[index]
        keystore_folder_val_i=make_with_index(keystore_folder,index)
        secrets_folder_val_i=make_with_index(secrets_folder,index)
        destination_val_i=make_with_index(destination,index)
        node_urls_val_i = [diva_urls[node_index] for node_index in validator_i]
        diva_addresses_val_i = [diva_addresses[node_index] for node_index in validator_i]
        create_pool(keystore_folder_val_i, secrets_folder_val_i, node_urls_val_i, diva_addresses_val_i, diva_threshold, diva_api_key, destination_val_i)

                     
def distribution(num_keyshares_per_validator,num_total_nodes,num_validators,distribution):

    total_num_keyshares = num_validators * num_keyshares_per_validator

    total_keyshares_distribution = sum(distribution)
    if total_keyshares_distribution > total_num_keyshares:
        raise ValueError("The total number of keyshares in 'distribution' its too hight for the keyshares avaialble")

    if num_total_nodes < num_keyshares_per_validator:
        raise ValueError("There are not enough nodes to uniquely distribute all keyshares per validator")

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


def create_pool(keystore_folder, secrets_folder, diva_urls, diva_addresses, diva_threshold, diva_api_key, destination):
    """
        This script takes in a few arguments and outputs DIVA CLI friendly configuration
        keystore_folder: the folder containing all keystore json files
        secrets_folder: the folder containing all the secrets files
        diva_urls: the url of the diva nodes
        diva_addresses: the addresses of the diva nodes
        threshold: diva threshold
        diva_api_key: the DIVA API key
        destination: the destination folder to write too
    """

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

    diva_urls = diva_urls.split(",")
    diva_addresses = diva_addresses.split(",")

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

def make_with_index(string, index):
    return re.sub(r'\d+', str(index), string)

main()