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
        num_diva_nodes: the number of diva nodes
        diva_threshold: the diva node threshold; has to be less than num_diva_nodes
        diva_api_key: the DIVA API key
        diva_client_prefix: the prefix for the url of the client; programmatically generates urls; THIS assumes a lot; should not
        destination: the destination folder to write too
    """

    keystore_folder = sys.argv[1]
    secrets_folder = sys.argv[2]
    num_diva_nodes = int(sys.argv[3])
    diva_threshold = int(sys.argv[4])
    diva_api_key = sys.argv[5]
    diva_client_prefix = sys.argv[6]
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

    diva_urls = []
    for index in range(0, num_diva_nodes):
        diva_urls.append(f"http://{diva_client_prefix}-{index}:30000/api")

    configurations = []
    for entry in entries:
        configuration = {
            "keystore": entry.key,
            "keystore_password": entry.secret,
            "threshold": diva_threshold,
            "nodes": [{"api_url": url, "api_key": diva_api_key} for url in diva_urls]
        }
        configurations.append(configuration)

    print(f"writing out {len(configurations)} to {destination}")
    for index in range(0, len(configurations)):
        filepath = f"{destination}/config-{index}.toml"
        with open(filepath, "w") as output_file_handle:
            output_file_handle.write(yaml.dump(configurations[index]))
    

def append(folder, file):
    return folder + "/" + file
        
main()