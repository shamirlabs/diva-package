ethereum_package = import_module("github.com/shamirlabs/ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/shamirlabs/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator_ui = import_module("./src/operator.star")
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

    deploy_diva_sc= diva_params.get(
        "deploy_diva_sc"
    )

    deploy_eth= diva_params.get(
        "deploy_eth"
    )    

    deploy_diva_coord_boot= diva_params.get(
        "deploy_diva_coord_boot"
    )

    participants = args.get(
        "participants"
    )

    diva_validators = participants[0].get(
        "validator_count"
    )
    

    verify_fee_recipient=diva_params.get(
        "verify_fee_recipient"
    )
    
    deploy_operator_ui=diva_params.get(
        "deploy_operator_ui"
    )
    
    genesis_delay = network_params.get(
        "genesis_delay"
    )
    delay_sc="0"


    if deploy_eth:
        if deploy_diva_sc:
            delay_sc="150"
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
    else:
        el_ws_uri = "ws://{0}:{1}".format(constants.HOST, constants.EL_WS_PORT)
        cl_uri = "http://{0}:{1}".format(constants.HOST, constants.CL_PORT)
        el_rpc_uri = "http://{0}:{1}".format(constants.HOST, constants.EL_HTTP_PORT)
        genesis_validators_root = utils.get_gvr(plan,cl_uri)
        genesis_time = utils.get_genesis_time(plan,cl_uri)
 
    if deploy_diva_sc or deploy_diva_coord_boot or deploy_diva:
        diva_sc.init(plan, el_rpc_uri, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key)

    if deploy_diva_sc:

        # SC deployer will change
        smart_contract_address_out = diva_sc.deploy(
            plan, delay_sc
        )

    else:
        smart_contract_address= constants.DIVA_SC

    if deploy_diva or deploy_diva_coord_boot:
        diva_cli.start_cli(plan)

    static_ports=True

    if deploy_diva_coord_boot:
        bootnode, bootnode_url = diva_server.start_bootnode(
            plan,
            el_ws_uri,
            cl_uri,
            smart_contract_address,
            genesis_validators_root,
            genesis_time,
            static_ports
        )
        diva_cli.generate_identity(plan, bootnode_url)
        bootnode_address = utils.get_address(plan, bootnode_url)

        diva_sc.fund(plan, bootnode_address)
    
    if deploy_diva:
        plan.print("Starting DIVA nodes")
        bootonde_url= "http://{0}:{1}".format(constants.HOST,constants.BOOTNODE_PORT)
        bootnode_address = utils.get_address(plan, bootonde_url)
        bootnode_peer_id = utils.get_peer_id(plan, bootonde_url)
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
                constants.HOST,
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

    if deploy_operator_ui:
        diva_operator_ui.launch(plan)
    
    if deploy_eth:
        first_participant = ethereum_network.all_participants[0].cl_client_context
        first_participant_validator_service_name = first_participant.validator_service_name
        first_participant_keystore = (
            first_participant.validator_keystore_files_artifact_uuid
        )

    if deploy_diva and deploy_eth:
        configuration_tomls = keys.generate_configuration_tomls(
            plan, [first_participant_keystore], diva_urls, diva_addresses
        )

        diva_cli.start_cli(plan, configuration_tomls)
        diva_cli.deploy(plan, diva_validators)
 

    if deploy_eth:
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
