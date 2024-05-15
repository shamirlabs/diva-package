# Images
DIVA_SC_IMAGE = "diva-sc:4"
DIVA_CLI_IMAGE = "diva-cli:1"
OPERATOR_UI_IMAGE = "diva/operator-ui:latest"
DIVA_SERVER_IMAGE = "diva-server:12"
W3S_CONSENSYS = "consensys/web3signer:23.9.0"
NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-latest"
PRYSM_IMAGE = "gcr.io/prysmaticlabs/prysm/validator:latest"

# Service names
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"

# Diva API endpoints
DIVA_INFO_ENDPOINT ="/api/v1/node/info"
DIVA_ID_ENDPOINT= "/api/v1/keymanager/node-key"

DIVA_API_KEY = "diva"
DIVA_VAULT_PASSWORD = DIVA_API_KEY

# External Network
HOST = "135.181.X.X"
EL_WS_PORT = "32802"
EL_HTTP_PORT = "32803"
CL_PORT = "32811"
EXEC_EXPL_PORT = "2878"
DIVA_SC = "0xDeC3326BE4BaDb9A1fA7Be473Ef8370dA775889a"
BOOTNODE_PORT = "30000"
DIVA_VAL_INDEX_START = 64

# Diva specifics
PREGENESIS_VAL_SEED = "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

DIVA_W3S=9000
DIVA_API=30000
DIVA_P2P=5050

DIVA_VAL_INDEX_START=64 # when deploy divas to existing eth-network
DIVA_SET_SIZE = 5
DIVA_SET_THRESHOLD = 3
DIVA_NODES= 6
DIVA_VALIDATORS= 2 #-1 for all available validators created at pre-genesis
DIVA_DISTRIBUTION="[1]"