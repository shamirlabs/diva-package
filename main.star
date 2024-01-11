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
    
    ethereum_params = args.get(
        "ethereum"
    )

    diva_params = args.get(
        "diva_pools"
    )

    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Starting a diva set")

    genesis_validators_root, final_genesis_timestamp = (
        ethereum_params.genesis_validators_root,
        ethereum_params.genesis_timestamp,
    )

    el_rpc_uri = (ethereum_network.execution_http)
    el_ws_uri = (ethereum_network.execution_ws)
    cl_uri = (ethereum_network.consensus_http)

    smart_contract_address = ethereum_network.diva_contract

 
    plan.print("Starting DIVA nodes")
    diva_urls = []
    validators_to_shutdown = []
    diva_addresses = []
    signer_urls = []
    for index in range(0, diva_params.diva_nodes):
        node, node_url, signer_url = diva_server.start_node(
            plan,
            "diva-{0}".format(index + 1),
            el_ws_uri,
            cl_uri,
            smart_contract_address,
            genesis_validators_root,
            final_genesis_timestamp,
            ethereum_params.bootnode_add,
            # TODO: manage other clients than nimbus
            is_nimbus=True,
        )
        diva_urls.append(node_url)
        signer_urls.append(signer_url)
        node_identity = diva_cli.generate_identity(plan, node_url)
        public_key, private_key, operator_address = diva_sc.new_key(plan)
        diva_sc.fund(plan, operator_address)
        node_address = utils.get_address(plan, node_url)
        diva_addresses.append(node_address)
        diva_sc.register(plan, private_key, smart_contract_address, node_address)

    diva_operator.launch(plan)

    # TODO: rescue the priv_key of first validator diva_pools.validator_keys derived from 
    #https://github.com/kurtosis-tech/ethereum-package/blob/main/src/prelaunch_data_generator/validator_keystores/validator_keystore_generator.star
    # then create pools.json an dthen deploy diva_cli.deploy(plan, first_node_index, num_validator_keys_per_node)


    for index in range(0, diva_params.diva_nodes):
        nimbus.launch(
            plan,
            "nimbus-{0}".format(index),
            signer_urls[index],
            cl_uri,
        )
