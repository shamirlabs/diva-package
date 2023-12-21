import os
import sys

from collections import namedtuple
import yaml

Entry = namedtuple("Entry", ["key", "secret"])

def main():
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

    keystore_folder = sys.argv[1]
    secrets_folder = sys.argv[2]
    diva_urls = sys.argv[3]
    diva_addresses = sys.argv[4]
    diva_threshold = int(sys.argv[5])
    diva_api_key = sys.argv[6]
    destination = sys.argv[7]

    assert(diva_threshold <= num_diva_nodes)
    
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

# Replace with better implementation
def get_index(index):
    return f"0x0{index}00000000000000000000000000000000000000000000000000000000000000"


def append(folder, file):
    return folder + "/" + file
        
main()