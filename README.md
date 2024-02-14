# diva-package

## Install kurtosis 
``
echo "deb [trusted=yes] https://apt.fury.io/kurtosis-tech/ /" | sudo tee /etc/apt/sources.list.d/kurtosis.list
sudo apt update
sudo apt install kurtosis-cli
``

### Upgrade Kurtosis
Sometimes you will find weird errors and that's because approximately once per month kurtosis introduces breaking changes, please update:
``
apt update && apt install --only-upgrade kurtosis-cli
kurtosis engine restart
``




## Parameters

You can define the different options in two files:
    - params.yaml          # Arguments that will define the deployment itself, it contains parameters about ethereum-package and diva-package as well
    - src/constants.star   # Parameters for when you want set different protocol specific information or in case you want to attach one deployment to another


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

Kurtosis can deploy the following services in order:

- ethereum_clients
- deploy smart_contract
- bootnode and coordinator client, reg and fund
- diva-clients, 
- registration and fund of each one of the above diva-clients
- deploy of the keyshares 
- deploy of operator ui
- validator-clients

Each service can be skiped, but most of them need the previous one, so if skipped the pipeline will assume the previous services will be found on the endpoints defined at constants.star



## Use diva-package

```
git clone https://github.com/shamirlabs/diva-package
cd diva-package
```


```
kurtosis run . --enclave enclaveName
```
