# Diva Package 

## Install Kurtosis 
To install Kurtosis, you need to add its repository to your system and then install the ``kurtosis-cli`` package. Use the following commands:


``````
echo "deb [trusted=yes] https://apt.fury.io/kurtosis-tech/ /" | sudo tee /etc/apt/sources.list.d/kurtosis.list
sudo apt update
sudo apt install kurtosis-cli
``````

### Upgrade Kurtosis
Kurtosis may introduce breaking changes approximately once per month. If you encounter any issues, it is recommended to update your installation. Use the following commands to upgrade Kurtosis and restart its engine:
``````
apt update && apt install --only-upgrade kurtosis-cli
kurtosis engine restart
``````




## Configuration Parameters


Configuration for the Diva package deployment can be defined in two files:
    - params.yaml          # Contains arguments defining the deployment itself, including parameters for both the Ethereum package and the Diva package services.
    - src/constants.star   # Used to set protocol-specific information or link one deployment to another.


### Params.yaml
``````
network_params:
  network_id: "3151908"
  genesis_delay: -1                     # If -1, it is overwritten by DIVA
  deneb_fork_epoch: 0
  electra_fork_epoch: 999999
  preregistered_validator_count: -1     # If -1, it is overwritten by DIVA

diva_params:
  diva_validators: 2
  diva_nodes: 6
  diva_val_type: prysm 
  distribution: "[2,1]"                 # Array-index is node-index and array value is number of keyshares, if empty will be randomly distributed
  
  options:
    deploy_eth: true
    deploy_diva_nodes: true
    deploy_diva_sc: false
    deploy_diva_coord_boot: true
    deploy_operator_ui: false
    charge_pre_genesis_keys: true
    private_pools_only: true  
    public_ports: false
    verify_fee_recipient: false
    eth_connection_enabled: true
  use_w3s: false

participants:
  - el_type: geth
    cl_type: lighthouse
    validator_count: 128

  - el_type: geth
    cl_type: prysm
    validator_count: 128

# Ethereum nodes for diva connections
# Nodes with 0 validators will be used by diva nodes and connections will be uniformely distributed between them
  - el_type: geth
    cl_type: prysm
    validator_count: 0
    count: 3

additional_services:
  #- tx_spammer
  #- blob_spammer
  #- custom_flood
  #- el_forkmon
  #- beacon_metrics_gazer
  #- dora
  #- prometheus_grafana
  - full_beaconchain_explorer

persistent: false

mev_params:
  launch_custom_flood: true
  mev_relay_image: flashbots/mev-boost-relay:latest

mev_type: null

``````

### Constants.star

````
# Images
DIVA_SC_IMAGE = "diva-sc"
DIVA_CLI_IMAGE = "diva-cli:1"
OPERATOR_UI_IMAGE = "diva/operator-ui:latest"
DIVA_SERVER_IMAGE = "diva-server:12"
W3S_CONSENSYS="consensys/web3signer:23.9.0"
NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-latest"
PRYSM_IMAGE = "gcr.io/prysmaticlabs/prysm/validator:latest"

# Service names
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"

DIVA_API_KEY = "diva"
DIVA_VAULT_PASSWORD = DIVA_API_KEY

# External Network
HOST = "135.181.29.169"
EL_WS_PORT = "35276"
EL_HTTP_PORT = "35277"
CL_PORT = "35285"
EXEC_EXPL_PORT = "2878"
DIVA_SC = "0xDeC3326BE4BaDb9A1fA7Be473Ef8370dA775889a"
BOOTNODE_PORT = "30000"
DIVA_VAL_INDEX_START = 64

# Diva specifics
PREGENESIS_VAL_SEED = "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

DIVA_W3S = 9000
DIVA_API = 30000
DIVA_P2P = 5050

DIVA_SET_SIZE = 5
DIVA_SET_THRESHOLD = 3

````


## Pipeline

Kurtosis can sequentially deploy the following services for a Diva package setup:

- ethereum_clients
- deploy smart_contract
- bootnode and coordinator client, funding and registration
- diva-nodes, 
- fund and registration of each one of the above diva-clients
- deploy of the keyshares
- deploy of operator-ui
- validator-clients

You can select the services you want to deploy by setting the file `./params.yaml`

If you want to deploy a service that requires a dependency, for expample, you want to deploy DIVA_SC and you dont want to raise a new devnet but just deploy it on an existing one, you must set the required dependency addresses (Eth clients addresses) on `src/constants.star`.


## Using the Diva Package

```
git clone https://github.com/shamirlabs/diva-package
cd diva-package
```

In `/src/constants.star` You need to set the following docker images. If they are privates make sure you have them in your local docker registry or you are logged in in the remote one:
```
DIVA_SERVER_IMAGE = "diva-server:min"
DIVA_SC_IMAGE = "diva-sc:min"
DIVA_CLI_IMAGE = "diva-cli:1"
```

To run your settings:
```
kurtosis run . --enclave enclaveName --args-file params.yaml --production
```


If you want to kill your enclave:

```
kurtosis rm enclaveName -f
```

### Prefunded accounts
For your convenience, some of the prefunded accounts -pub/priv keys- in the eth-package can be found bellow:

    new_prefunded_account(
        "0x741bFE4802cE1C4b5b00F9Df2F5f179A1C89171A",
        "3a91003acaf4c21b3953d94fa4a6db694fa69e5242b2e37be05dd82761058899",
    ),
    new_prefunded_account(
        "0xc3913d4D8bAb4914328651C2EAE817C8b78E1f4c",
        "bb1d0f125b4fb2bb173c318cdead45468474ca71474e2247776b2b4c0fa2d3f5",
    ),
    new_prefunded_account(
        "0x65D08a056c17Ae13370565B04cF77D2AfA1cB9FA",
        "850643a0224065ecce3882673c21f56bcf6eef86274cc21cadff15930b59fc8c",
    ),
    new_prefunded_account(
        "0x3e95dFbBaF6B348396E6674C7871546dCC568e56",
        "94eb3102993b41ec55c241060f47daa0f6372e2e3ad7e91612ae36c364042e44",


### Issues?

To remove the enclave
```
kurtosis enclave rm enclaveName -f
```

To restart everything
```
systemctl restart kurtosis
systemctl restart docker
```

Do you still have issues, pls check the above Upgrade Kurtosis section
