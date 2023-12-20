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

# TODO not hardcode this
NUM_VALIDATOR_KEYS_PER_NODE = 64

def run(plan, args):
    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

    validator_keystores = []
    prefixes = []
    for index, participant in enumerate(ethereum_network.all_participants):
        cl_client_context = participant.cl_client_context
        validator_keystores.append(
            participant.cl_client_context.validator_keystore_files_artifact_uuid
        )
        validator_service_name = cl_client_context.validator_service_name
        prefixes.append(validator_service_name)

    configuration_tomls = keys.generate_configuration_tomls(
        plan, validator_keystores, prefixes
    )

    genesis_validators_root, final_genesis_timestamp = (
        ethereum_network.genesis_validators_root,
        ethereum_network.final_genesis_timestamp,
    )

    el_ip_addr = ethereum_network.all_participants[0].el_client_context.ip_addr
    el_rpc_port = ethereum_network.all_participants[0].el_client_context.rpc_port_num
    el_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)

    cl_ip_addr = ethereum_network.all_participants[0].cl_client_context.ip_addr
    cl_http_port_num = ethereum_network.all_participants[
        0
    ].cl_client_context.http_port_num
    cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)

    smart_contract_address = diva_sc.deploy(
        plan, el_uri, genesis_constants.PRE_FUNDED_ACCOUNTS[0].private_key
    )

    bootnode, bootnode_url = diva_server.start_bootnode(
        plan,
        el_uri,
        cl_uri,
        smart_contract_address,
        genesis_validators_root,
        final_genesis_timestamp,
    )

    diva_cli.start_cli(plan, configuration_tomls)
    diva_cli.generate_identity(plan, bootnode_url)

    bootnode_address = utils.get_address(plan, bootnode_url)
    bootnode_peer_id = utils.get_peer_id(plan, bootnode_url)

    diva_sc.fund(plan, bootnode_address)

    plan.print("Starting DIVA nodes")
    diva_nodes = []
    validators_to_shutdown = []
    validator_keystores = []
    cl_uris = []
    for index, participant in enumerate(ethereum_network.all_participants):
        per_node_el_ip_addr = ethereum_network.all_participants[
            index
        ].el_client_context.ip_addr
        per_node_el_rpc_port = ethereum_network.all_participants[
            index
        ].el_client_context.rpc_port_num
        per_node_el_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)

        per_node_cl_ip_addr = ethereum_network.all_participants[
            0
        ].cl_client_context.ip_addr
        per_node_cl_http_port_num = ethereum_network.all_participants[
            index
        ].cl_client_context.http_port_num
        per_node_cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)
        cl_uris.append(per_node_cl_uri)

        cl_client_context = participant.cl_client_context
        validator_service_name = cl_client_context.validator_service_name
        validators_to_shutdown.append(validator_service_name)

        for index in range(0, constants.NUMBER_OF_DIVA_NODES_PER_NODE):
            node, node_url = diva_server.start_node(
                plan,
                "{0}-{1}".format(validator_service_name, index),
                per_node_el_uri,
                per_node_cl_uri,
                smart_contract_address,
                bootnode_peer_id,
                genesis_validators_root,
                final_genesis_timestamp,
                # for now we assume this only connects to nimbus
                is_nimbus=True,
            )
            diva_nodes.append(node_url)
            node_identity = diva_cli.generate_identity(plan, node_url)
            public_key, private_key = diva_sc.new_key(plan)
            diva_sc.fund(plan, public_key)
            node_address = utils.get_address(plan, node_url)
            diva_sc.register(plan, private_key, smart_contract_address, node_address)

    diva_operator.launch(plan)
    diva_cli.deploy(plan, prefixes, NUM_VALIDATOR_KEYS_PER_NODE)

    plan.print("stopping existing validators and starting nimbus' with diva configured")
    for index, participant in enumerate(ethereum_network.all_participants):
        validator_service_name = cl_client_context.validator_service_name
        plan.stop_service(validator_service_name)
        nimbus.launch(
            plan,
            validator_service_name + "-diva",
            diva_nodes[index],
            cl_uris[index],
        )
  

    # stop & restart validators
