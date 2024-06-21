# Images
DIVA_SERVER_IMAGE = "ghcr.io/shamirlabs/diva:v24.5.0-16-g4fdfb5f0"
DIVA_SC_IMAGE = "diva-sc:holesky-with-trusted-balance-verifier-diego-21junio3"
DIVA_CLI_IMAGE = "diva-cli:1"
DIVA_ORACLE_IMAGE = "oracle:10"
OPERATOR_UI_IMAGE = "diva/operator-ui:latest"
W3S_CONSENSYS = "consensys/web3signer:23.9.0"
NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-latest"
PRYSM_IMAGE = "gcr.io/prysmaticlabs/prysm/validator:latest"

# Service names
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"
DIVA_DEPLOYER_CLI_NAME = "diva-cli-deployer"
DIVA_CLI_NAME = "diva-cli"
DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"
DIVA_SC_REGISTER_NAME = "diva-smartcontract-register"

# Diva API endpoints
DIVA_INFO_ENDPOINT ="/api/v1/node/info"
DIVA_ID_ENDPOINT= "/api/v1/keymanager/node-key"

DIVA_API_KEY = "diva"
DIVA_VAULT_PASSWORD = DIVA_API_KEY

# External Network
HOST = "65.109.109.62"
EL_WS_PORT = "32895"
EL_HTTP_PORT = "32896"
CL_PORT = "32904"
EXEC_EXPL_PORT = "2878"
DIVA_SC = "0xDeC3326BE4BaDb9A1fA7Be473Ef8370dA775889a"
BOOTNODE_PORT = "30000"
DIVA_VAL_INDEX_START = 64 # when deploy divas to existing eth-network
BOOT_PEER_ID= "16Uiu2HAkwXpxB3ypfcpG629vrDEq5rfeVk2eDa1sWZ8chpjLhNyj"

# Diva specifics
PREGENESIS_VAL_SEED = "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete"

DIVA_W3S=9000
DIVA_API=30000
DIVA_P2P=5050

DIVA_SET_SIZE = 5
DIVA_SET_THRESHOLD = 3
