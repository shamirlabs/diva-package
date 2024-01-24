constants = import_module("./constants.star")


# this is costly as we are spinning up a temporary container and downloading requests
# we can/should dockerize this
def get_address(plan, diva_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get(\""""
        + diva_url
        + """/api/v1/node/info", headers={"Authorization": "Bearer """
        + constants.DIVA_API_KEY
        + """\"})
if response.status_code != 200:
    sys.exit(1)
node_address = response.json()["node_address"]
print(node_address, end="")
""",
    )
    return result.output


# this is costly as we are spinning up a temporary container and downloading requests
# we can/should dockerize this
def get_peer_id(plan, diva_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get(\""""
        + diva_url
        + """/api/v1/node/info", headers={"Authorization": "Bearer """
        + constants.DIVA_API_KEY
        + """\"})
if response.status_code != 200:
    sys.exit(1)
peer_id = response.json()["peer_id"]
print(peer_id, end="")
""",
    )
    return result.output

def get_gvr(plan, cl_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get(\""""
        + cl_url
        + """/eth/v1/beacon/genesis")
if response.status_code != 200:
    sys.exit(1)
peer_id = response.json()["data"]["genesis_validators_root"]
print(peer_id, end="")
""",
    )
    return (result.output)

def get_genesis_time(plan, cl_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get(\""""
        + cl_url
        + """/eth/v1/beacon/genesis")
if response.status_code != 200:
    sys.exit(1)
peer_id = response.json()["data"]["genesis_time"]
print(peer_id, end="")
""",
    )
    return (result.output)