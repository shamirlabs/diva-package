constants = import_module("./constants.star")


# this is costly as we are spinning up a temporary container and downloading requests
# we can/should dockerize this
def get_address(diva_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get("{0}/api/v1/node/info", headers={"Authorization": "Bearer: {1}", "accept": "application/json"})
if response.status_code != 200
    sys.exit(1)
node_address = response.json()["node_address"],
print(node_address)
""".format(
            diva_url, constants.DIVA_API_KEY
        ),
    )
    return reuslt.output


# this is costly as we are spinning up a temporary container and downloading requests
# we can/should dockerize this
def get_peer_id(diva_url):
    result = plan.run_python(
        packages=["requests"],
        run="""
import requests
import sys
response = requests.get("{0}/api/v1/node/info", headers={"Authorization": "Bearer: {1}", "accept": "application/json"})
if response.status_code != 200
    sys.exit(1)
peer_id = response.json()["peer_id"],
print(peer_id)
""".format(
            diva_url, constants.DIVA_API_KEY
        ),
    )
    return reuslt.output
