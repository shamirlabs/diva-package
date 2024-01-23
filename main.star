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



def run(plan, args):

    network_params = args.get(
        "network_params"
    )

    diva_params = args.get(
        "diva_params"
    )

    deploy_eth = diva_params.get(
        "deploy_eth"
    )

    deploy_diva = diva_params.get(
        "deploy_diva"
    )

    deploy_diva_sc= deploy_eth.get(
        "deploy_diva_sc"
    )

    deploy_eth_clients= deploy_eth.get(
        "deploy_eth_clients"
    )    

    deploy_diva_coord_boot= deploy_eth.get(
        "deploy_diva_coord_boot"
    )

    participants = args.get(
        "participants"
    )

    diva_validators = participants[0].get(
        "validator_count"
    )
    diva_validators=2
    verify_fee_recipient=diva_params.get(
        "verify_fee_recipient"
    )

    genesis_delay = network_params.get(
        "genesis_delay"
    )

    ethereum_network = ethereum_package.run(plan, args)

    plan.print("Succesfully launched an Ethereum Network")

    genesis_validators_root, genesis_time = (
        ethereum_network.genesis_validators_root,
        ethereum_network.final_genesis_timestamp,
    )

    el_ip_addr = ethereum_network.all_participants[1].el_client_context.ip_addr
    el_ws_port = ethereum_network.all_participants[1].el_client_context.ws_port_num
    el_rpc_port = ethereum_network.all_participants[1].el_client_context.rpc_port_num
    el_rpc_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)
    el_ws_uri = "ws://{0}:{1}".format(el_ip_addr, el_ws_port)

    cl_ip_addr = ethereum_network.all_participants[1].cl_client_context.ip_addr
    cl_http_port_num = ethereum_network.all_participants[1].cl_client_context.http_port_num
    cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)

    if deploy_diva_sc:
        smart_contract_address = diva_sc.deploy(
            plan, el_rpc_uri, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key
        )
        plan.print(
        "DIVA SC address: {0}".format(smart_contract_address)
        )

    diva_cli.start_cli(plan)

    if deploy_diva_coord_boot:
        bootnode, bootnode_url = diva_server.start_bootnode(
            plan,
            el_ws_uri,
            cl_uri,
            smart_contract_address,
            genesis_validators_root,
            genesis_time,
            ephemeral_ports=False
        )
        diva_cli.generate_identity(plan, bootnode_url)
        bootnode_address = utils.get_address(plan, bootnode_url)
        bootnode_peer_id = utils.get_peer_id(plan, bootnode_url)

        diva_sc.fund(plan, bootnode_address)
    
    if deploy_diva:
        plan.print("Starting DIVA nodes")
        diva_urls = []
        validators_to_shutdown = []
        diva_addresses = []
        signer_urls = []
        for index in range(0, constants.NUMBER_OF_DIVA_NODES):
            node, node_url, signer_url = diva_server.start_node(
                plan,
                # TODO improve on this name for diva
                "diva-client-{0}".format(index + 1),
                el_ws_uri,
                cl_uri,
                smart_contract_address,
                bootnode_peer_id,
                genesis_validators_root,
                genesis_time,
                bootnode.ip_address,
                verify_fee_recipient,
                # for now we assume this only connects to nimbus
                is_nimbus=True
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
    

    first_participant = ethereum_network.all_participants[0].cl_client_context
    first_participant_validator_service_name = first_participant.validator_service_name
    first_participant_keystore = (
        first_participant.validator_keystore_files_artifact_uuid
    )
    first_node_index = 0
    
    if deploy_diva and deploy_eth_clients:
        configuration_tomls = keys.generate_configuration_tomls(
            plan, [first_participant_keystore], diva_urls, diva_addresses
        )

        diva_cli.start_cli(plan, configuration_tomls)
        diva_cli.deploy(plan, diva_validators)
 

    if deploy_eth_clients:
        plan.stop_service(first_participant_validator_service_name)

    if deploy_diva:
        for index in range(0, constants.NUMBER_OF_DIVA_NODES):
            nimbus.launch(
                plan,
                "diva-validator-{0}".format(index),
                signer_urls[index],
                cl_uri,
                smart_contract_address,
                verify_fee_recipient
            )
