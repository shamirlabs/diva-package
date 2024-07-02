# Images
DIVA_SERVER_IMAGE = "ghcr.io/shamirlabs/diva:v24.6.0-11-g5d797c30"
DIVA_SC_IMAGE = "diva-sc:16"
DIVA_SUBMITTER_IMAGE = "diva-sc:16"
DIVA_PROOFS_IMAGE = "diva-prover:17"
DIVA_HEARBEAT_IMAGE = "diva-hb:5"

DIVA_CLI_IMAGE = "diva-cli:1"
DIVA_ORACLE_IMAGE = "oracle:10"
OPERATOR_UI_IMAGE = "diva/operator-ui:latest"
W3S_CONSENSYS = "consensys/web3signer:23.9.0"
PRYSM_IMAGE = "gcr.io/prysmaticlabs/prysm/validator:latest"
PRYSM_IMAGE_MIN = "ethpandaops/prysm-validator:develop-minimal"
NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-v23.10.1"
NIMBUS_IMAGE_MINIMAL = "ethpandaops/nimbus-validator-client:stable-minimal"
JAEGER_IMAGE = "jaegertracing/all-in-one:1.58.1"


# Service names
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"
DIVA_SUBMITTER_NAME = "diva-submitter"
DIVA_DEPLOYER_CLI_NAME = "diva-cli-deployer"
DIVA_CLI_NAME = "diva-cli"
DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"
DIVA_SC_REGISTER_NAME = "diva-smartcontract-register"
DIVA_HEARBEAT_SERVICE_NAME = "diva-heartbeat"
DIVA_PROOFS_SERVICE_NAME = "diva-proofs"

# Diva API endpoints
DIVA_INFO_ENDPOINT ="/api/v1/node/info"
DIVA_ID_ENDPOINT= "/api/v1/keymanager/node-key"

DIVA_API_KEY = "diva"
DIVA_VAULT_PASSWORD = DIVA_API_KEY

# External Network
HOST = "65.109.109.62"
EL_WS_PORT = "35847"
EL_HTTP_PORT = "35848"
CL_PORT = "35861"
EXEC_EXPL_PORT = "2878"
DIVA_SC = "0xDeC3326BE4BaDb9A1fA7Be473Ef8370dA775889a"
BOOTNODE_PORT = "30000"
DIVA_VAL_INDEX_START = 64 # when deploy divas to existing eth-network
BOOT_PEER_ID= "16Uiu2HAkwXpxB3ypfcpG629vrDEq5rfeVk2eDa1sWZ8chpjLhNyj"
DIVA_PROVER= "http://diva-prover:5000"

# Diva specifics
PREGENESIS_VAL_SEED = "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

DEPLOYER_PRIVATE_KEY= "bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31"
DEPLOYER_ADDRESS= "0x8943545177806ED17B9F23F0a21ee5948eCaa776"
SUBMITTER_PRIVATE_KEY= "53321db7c1e331d93a11a41d16f004d7ff63972ec8ec7c25db329728ceeb1710"

        #"0xE25583099BA105D9ec0A67f5Ae86D90e50036425",
        #"39725efee3fb28614de3bacaffe4cc4bd8c436257e2c8bb887c4b5c4be45e76d",
#Private key: 0x15493cbd7d11e9eda528eae3d7165b5aca837ba5ed362e33944cd2f11574a5c8
#Address:     0xF10f3614ACA520b4e0E2c2681883970Ca0F2120c
#node:
#Address:     0xc1DAe0e33DcC12E2Ed50CeD1e01a06582eA8B1FD
#Private key: 0x2e7653160b11edb68f0c3758f6faafeca21320817201bc34372af2aad03bc306

DIVA_W3S=9000
DIVA_API=30000
DIVA_P2P=5050

DIVA_SET_SIZE = 5
DIVA_SET_THRESHOLD = 3
