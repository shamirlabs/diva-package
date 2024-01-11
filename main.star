ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator = import_module("./src/operator.star")
diva_cli = import_module("./src/diva-cli.star")
constants = import_module("./src/constants.star")
keys = import_module("./src/keys.star")
nimbus = import_module("./src/nimbus.star")

utils = import_module("./src/utils.star")

DEFAULT_NUM_VALIDATOR_KEYS_PER_NODE = 64


def run(plan, args):
    network_params = args.get(
        "network_params",
        {"num_validator_keys_per_node": DEFAULT_NUM_VALIDATOR_KEYS_PER_NODE},
    )
    num_validator_keys_per_node = network_params.get(
        "num_validator_keys_per_node", DEFAULT_NUM_VALIDATOR_KEYS_PER_NODE
    )
    plan.print(
        "{0} is the value of num_validator_keys_per_node ".format(
            num_validator_keys_per_node
        )
    )

    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

    genesis_validators_root, final_genesis_timestamp = (
        ethereum_network.genesis_validators_root,
        ethereum_network.final_genesis_timestamp,
    )

    el_ip_addr = ethereum_network.all_participants[0].el_client_context.ip_addr
    el_ws_port = ethereum_network.all_participants[0].el_client_context.ws_port_num
    el_rpc_port = ethereum_network.all_participants[0].el_client_context.rpc_port_num
    el_rpc_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)
    el_ws_uri = "ws://{0}:{1}".format(el_ip_addr, el_ws_port)

    cl_ip_addr = ethereum_network.all_participants[0].cl_client_context.ip_addr
    cl_http_port_num = ethereum_network.all_participants[
        0
    ].cl_client_context.http_port_num
    cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)

    smart_contract_address = diva_sc.deploy(
        plan, el_rpc_uri, genesis_constants.PRE_FUNDED_ACCOUNTS[0].private_key
    )

    bootnode, bootnode_url = diva_server.start_bootnode(
        plan,
        el_ws_uri,
        cl_uri,
        smart_contract_address,
        genesis_validators_root,
        final_genesis_timestamp,
    )

    diva_cli.start_cli(plan)
    diva_cli.generate_identity(plan, bootnode_url)

    bootnode_address = utils.get_address(plan, bootnode_url)
    bootnode_peer_id = utils.get_peer_id(plan, bootnode_url)

    diva_sc.fund(plan, bootnode_address)

    plan.print("Starting DIVA nodes")
    diva_urls = []
    validators_to_shutdown = []
    diva_addresses = []
    signer_urls = []


    diva_operator.launch(plan)

    first_participant = ethereum_network.all_participants[0].cl_client_context
    first_participant_validator_service_name = first_participant.validator_service_name
 
   
    plan.print(
        "stopping validator {0}".format(first_participant_validator_service_name)
    )
    plan.stop_service(first_participant_validator_service_name)

