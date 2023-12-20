ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator = import_module("./src/operator.star")
diva_cli = import_module("./src/diva-cli.star")

utils = import_module("./src/utils.star")

NUMBER_OF_DIVA_NODES_PER_NODE = 5
DIVA_THRESHOLD = 3


def run(plan, args):
    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

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

    diva_cli.start_cli(plan)
    diva_cli.generate_identity(plan, bootnode_url)

    bootnode_address = utils.get_address(plan, bootnode_url)
    bootnode_peer_id = utils.get_peer_id(plan, bootnode_url)

    diva_sc.fund(plan, bootnode_address)

    plan.print("Shutting down validators, starting diva nodes")
    prefixes = []
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

        cl_client_context = participant.cl_client_context
        validator_service_name = cl_client_context.validator_service_name
        prefixes.append(validator_service_name)
        plan.remove_service(validator_service_name)

        for node in range(0, 5):
            diva_server.start_node(
                plan,
                "{0}-{1}".format(validator_service_name),
                per_node_el_uri,
                per_node_cl_uri,
                smart_contract_address,
                bootnode_peer_id,
                genesis_validators_root,
                final_genesis_timestamp,
                # for now we assume this only connects to nimbus
                is_nimbus=True,
            )

    # start nodes, following the operator registration and funding model
    # shut down validators
    # start web3s validators

    diva_operator.launch(plan)
