import requests
import sys
import time


def main():

    methods = {
        "get_address": get_address,
        "get_peer_id": get_peer_id,
        "get_gvr": get_gvr,
        "get_genesis_time": get_genesis_time,
        "get_chain_id": get_chain_id
    }

    method = sys.argv[1]
    
    if method in methods:
        methods[method]()
    else:
        print(f"Method '{method}' not recognized")

def get_address():
    diva_url= sys.argv[2]
    api_key= sys.argv[3]
    max_retries = 60
    attempts = 0

    while attempts < max_retries:
        try:
            response = requests.get(diva_url + "/api/v1/node/info", headers={"Authorization": "Bearer "
            + api_key })
            if response.status_code == 200:
                node_address = response.json()["node_address"]
                if node_address != "":
                    print(node_address, end="")
                    return node_address
            else:
                attempts += 1
                time.sleep(1)
        except requests.RequestException:
            attempts += 1

    if attempts == max_retries:
        sys.exit(1)

def get_peer_id():
    diva_url= sys.argv[2]
    api_key= sys.argv[3]
    max_retries = 30
    attempts = 0
    while attempts < max_retries:
        try:
            response = requests.get(diva_url + "/api/v1/node/info", headers={"Authorization": "Bearer "
            + api_key})
            if response.status_code == 200:
                peer_id = response.json()["peer_id"]
                if peer_id != "":
                    print(peer_id, end="")
                    return peer_id
            else:
                attempts += 1
                time.sleep(1)
        except requests.RequestException:
            attempts += 1

    if attempts == max_retries:
        sys.exit(1)

def get_gvr():
    beacon_url= sys.argv[2]
    max_retries = 50
    attempts = 0
    while attempts < max_retries:
        try:
            response = requests.get(beacon_url + "/eth/v1/beacon/genesis")
            if response.status_code == 200:
                res= (response.json()["data"].get("genesis_validators_root"))
                if res != "":               
                    print(res)                
                    return res
            else:
                attempts += 1
                time.sleep(1)
        except requests.RequestException:
            attempts += 1

    if attempts == max_retries:
        sys.exit(1)    

def get_chain_id():
    beacon_url= sys.argv[2]
    max_retries = 60
    attempts = 0
    while attempts < max_retries:
        try:
            response = requests.get(beacon_url + "/eth/v1/config/spec")
            if response.status_code == 200:
                res= (response.json()["data"].get("DEPOSIT_NETWORK_ID"))
                print(res)
                return res
            else:
                attempts += 1
                time.sleep(1)
        except requests.RequestException:
            attempts += 1
    if attempts == max_retries:
        sys.exit(1)    

def get_genesis_time():
    beacon_url= sys.argv[2]
    max_retries = 50
    attempts = 0
    while attempts < max_retries:
        try:
            response = requests.get(beacon_url + "/eth/v1/beacon/genesis")
            if response.status_code == 200:
                res= (response.json()["data"].get("genesis_time"))
                print(res)
                return res
            else:
                attempts += 1
        except requests.RequestException:
            attempts += 1
    if attempts == max_retries:
        sys.exit(1)    

main()