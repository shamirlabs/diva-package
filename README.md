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
  genesis_delay: 60
  deneb_fork_epoch: 900
  electra_fork_epoch: null
  preregistered_validator_count: 66 # Those not assigned in participats will be available for diva, in this example 66-32-32= 2 validators available for diva. This 2 must be set on the constants.star file

additional_services: 
  - dora             # Consensus light explorer
  - blockscout       # Explorer full explorer with SC verif

mev_type: none

participants:
  # first pair must be geth & nimbus to expose public ports if you enable "public_ports" and "deploy_eth"
  - el_client_type: geth
    cl_client_type: nimbus
    validator_count: 32

  - el_client_type: geth
    cl_client_type: nimbus
    validator_count: 32

diva_params:
  deployment:
    deploy_eth: false                  # will deploy the eth_clients on the above participants section 
    deploy_diva_sc: true               # will deploy the diva_sc on the set eth_network 
    deploy_diva_coord_boot: true       # will deploy a diva client which is a coordinator and bootnode on the set eth_network with set_sc
    deploy_diva: false                 # will deploy the specified on constant.star diva clients on the set eth_network with set sc and set bootnode
    deploy_operator_ui: false          # will deploy the operator_ui 
    options:
      charge_pre_genesis_keys: false   # will deploy the pregenesis keys as specified in constant.star, must have diva-available keys as indicated in the above 'network_params.preregistered_validator_count'
      public_ports: true               # for deploy_eth will use the shamir-package with the by-default ports instead of ephimery 

  protocol_features:
    verify_fee_recipient: false        # will set the verify_w3s on validator client and diva nodes 
    private_pools_only: true           # will skip all the SC tx to speed up process but disables dkgs   
  
persistent: false                       # will make diva and eth-package persistent, db will be kept on hd 

``````

### Constants.star

````

# Those are the docker image tags that kurtosis will try to fetch, if private and images are not locally, auth need to be set
DIVA_SC_IMAGE = "sc"
DIVA_CLI_IMAGE = "diva-cli"
OPERATOR_UI_IMAGE = "diva/operator-ui:latest"
DIVA_SERVER_IMAGE = "diva-server"


DIVA_API_KEY="diva"
DIVA_VAULT_PASSWORD=DIVA_API_KEY

# when deploy_eth is disabled the program assumes the bellow endpoint will have the desired services avaialble
HOST="95.216.20.186"   
EL_WS_PORT="8546"
EL_HTTP_PORT="8545"
CL_PORT="4000"
EXEC_EXPL_PORT="80"
DIVA_SC="0xDeC3326BE4BaDb9A1fA7Be473Ef8370dA775889a"
BOOTNODE_PORT="30000"
PREGENESIS_VAL_SEED="giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"


DIVA_W3S=9000
DIVA_API=30000
DIVA_P2P=5050



# validator index start should start with the sum of the participants on eth_network
DIVA_VAL_INDEX_START=64 # when deploy divas to existing eth-network
DIVA_VALIDATORS= 2 #-1 for all available validators created at pre-genesis


# diva-protocol specific options
DIVA_SET_SIZE = 5
DIVA_SET_THRESHOLD = 3
DIVA_NODES= 6


# distribution of keyshares, an array where the index specify the node and the value the number of keyshares, if not in the array the number of keyshares for that node will be random. Empty array is allowed.
DIVA_DISTRIBUTION="[1]"
````


## Pipeline

Kurtosis can sequentially deploy the following services for a Diva package setup:

- ethereum_clients
- deploy smart_contract
- bootnode and coordinator client, reg and fund
- diva-clients, 
- registration and fund of each one of the above diva-clients
- deploy of the keyshares 
- deploy of operator ui
- validator-clients

Services can be skipped as needed, but dependencies between them mean that skipping a service assumes its functionality is provided by another means, as configured in constants.star.



## Using the Diva Package

```
git clone https://github.com/shamirlabs/diva-package
cd diva-package
```


```
kurtosis run . --enclave enclaveName
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
