ethereum_package = import_module(
    "github.com/kurtosis-tech/ethereum-package/main.star@1.2.0"
)
ethereum_genesis_constants = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star@1.2.0"
)
ethereum_input_parser = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/package_io/input_parser.star@1.2.0"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator = import_module("./src/operator.star")
diva_cli = import_module("./src/diva-cli.star")
constants = import_module("./src/constants.star")
keys = import_module("./src/keys.star")
nimbus = import_module("./src/nimbus.star")
input_parser = import_module("./src/input_parser.star")
utils = import_module("./src/utils.star")

def run(plan, args):
    args_with_right_defaults = input_parser.input_parser(plan, args)
    network_params = args_with_right_defaults["network_params"]
    diva_params = args_with_right_defaults["diva"]

    num_validator_keys_per_node = network_params["num_validator_keys_per_node"]

    diva_nodes = diva_params["nodes"]
    diva_threshold = diva_params["threshold"]
    diva_validators_to_import = diva_params["validators_to_import"]

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
        plan, el_rpc_uri, ethereum_genesis_constants.PRE_FUNDED_ACCOUNTS[0].private_key
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
    for index in range(0, diva_nodes):
        node, node_url, signer_url = diva_server.start_node(
            plan,
            # TODO improve on this name for diva
            "diva-client-{0}".format(index + 1),
            el_ws_uri,
            cl_uri,
            smart_contract_address,
            bootnode_peer_id,
            genesis_validators_root,
            final_genesis_timestamp,
            bootnode.ip_address,
            # for now we assume this only connects to nimbus
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

    validators_keystore = []
    validators_name = []
    for i in range(diva_validators_to_import):
        validator = ethereum_network.all_participants[i].cl_client_context
        validators_name.append(validator.validator_service_name)
        validators_keystore.append(validator.validator_keystore_files_artifact_uuid)
        # first_node_index = 0

    configuration_tomls = keys.generate_configuration_tomls(
        plan, validators_keystore, diva_urls, diva_addresses, diva_threshold
    )

    diva_cli.start_cli(plan, configuration_tomls)

    for i in range(diva_validators_to_import):
        diva_cli.deploy(plan, i, num_validator_keys_per_node)

    for validator in validators_name:
        plan.print("stopping validator {0}".format(validator))
        plan.stop_service(validator)

    plan.print("starting nimbus with diva configured")
    for index in range(0, diva_nodes):
        nimbus.launch(
            plan,
            "diva-validator-{0}".format(index),
            signer_urls[index],
            cl_uri,
        )
