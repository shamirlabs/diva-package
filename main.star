ethereum_package_official = import_module("github.com/kurtosis-tech/ethereum-package@/main.star")
ethereum_package_shamir = import_module("../ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/shamirlabs/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator_ui = import_module("./src/diva-operator.star")
diva_cli = import_module("./src/diva-cli.star")
constants = import_module("./src/constants.star")
keys = import_module("./src/keys.star")
nimbus = import_module("./src/nimbus.star")
utils = import_module("./src/utils.star")
input_parser = import_module("./src/input-parser.star")


def run(plan, args):
    diva_args = input_parser.diva_input_parser(plan, args)
    diva_params= args.get(
        "diva_params"
    )

    deploy_eth= False
    deploy_diva = True
    deploy_diva_sc= False
    deploy_diva_coord_boot= True
    deploy_operator_ui=False
    verify_fee_recipient=False
    private_pools_only=True    
    charge_pre_genesis_keys=True
    
    public_ports= False

    delay_sc="0"
    utils.initUtils(plan)

    if deploy_eth:
        if deploy_diva_sc:
            delay_sc="150"
        if public_ports:
            ethereum_package = ethereum_package_shamir
        else:
            ethereum_package = ethereum_package_official

        ethereum_network = ethereum_package.run(plan, diva_args)

        plan.print("Succesfully launched an Ethereum Network")
        
        genesis_validators_root, genesis_time = (
            ethereum_network.genesis_validators_root,
            ethereum_network.final_genesis_timestamp,
        )
        el_ip_addr = ethereum_network.all_participants[0].el_context.ip_addr
        el_ws_port = ethereum_network.all_participants[0].el_context.ws_port_num
        el_rpc_port = ethereum_network.all_participants[0].el_context.rpc_port_num
        el_rpc_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)
        el_ws_uri = "ws://{0}:{1}".format(el_ip_addr, el_ws_port)
        cl_ip_addr = ethereum_network.all_participants[0].cl_context.ip_addr
        cl_http_port_num = ethereum_network.all_participants[0].cl_context.http_port
        cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)
        network_id = 3151908
        sc_verif=ethereum_network.blockscout_sc_verif_url
        start_index_val=constants.PARTICIPANTS_VALIDATORS -1
    else:    
        el_ws_uri = "ws://{0}:{1}".format(constants.HOST, constants.EL_WS_PORT)
        cl_uri = "http://{0}:{1}".format(constants.HOST, constants.CL_PORT)
        el_rpc_uri = "http://{0}:{1}".format(constants.HOST, constants.EL_HTTP_PORT)
        genesis_validators_root = utils.get_gvr(plan,cl_uri)
        genesis_time = utils.get_genesis_time(plan,cl_uri)
        network_id = utils.get_chain_id(plan,cl_uri) 
        sc_verif = "http://{0}:{1}".format(constants.HOST, constants.EXEC_EXPL_PORT)
        start_index_val=constants.DIVA_VAL_INDEX_START
    
    stop_index_val=start_index_val+constants.DIVA_VALIDATORS
    diva_validators=constants.DIVA_VALIDATORS
        
    if deploy_diva_sc or deploy_diva:
        diva_sc.init(plan, el_rpc_uri, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key)
    
    smart_contract_address = constants.DIVA_SC

    plan.print(sc_verif)
    plan.print(delay_sc)
    plan.print(network_id)

    if deploy_diva_sc:
        smart_contract_address = diva_sc.deploy(
            plan, delay_sc, network_id,sc_verif
        )

    if deploy_diva or deploy_diva_coord_boot:
        diva_cli.start_cli(plan)


    if deploy_diva_coord_boot:
        bootnode, bootnode_url = diva_server.start_bootnode(
            plan,
            el_ws_uri,
            cl_uri,
            smart_contract_address,
            genesis_validators_root,
            genesis_time,
            public_ports,
            network_id
        )
        diva_cli.generate_identity(plan, bootnode_url)
        bootnode_address = utils.get_diva_field(plan, constants.DIVA_BOOTNODE_NAME, "node_address")
        plan.print(bootnode_address)
        plan.print("bootnode-address")

        if deploy_diva_sc:        
            diva_sc.fund(plan, bootnode_address)
    
    if deploy_diva:
        bootonde_url= "http://{0}:{1}".format(constants.HOST,constants.BOOTNODE_PORT)
        bootnode_ip= constants.HOST

        if deploy_diva_coord_boot:
            bootnode_ip= bootnode.ip_address

        bootnode_peer_id = utils.get_diva_field(plan,constants.DIVA_BOOTNODE_NAME,"network_settings.peer_id")
        plan.print(bootonde_url)
        plan.print(bootnode_peer_id)
        

        plan.print("Starting DIVA nodes")
        
        diva_urls = []
        validators_to_shutdown = []
        diva_addresses = []
        signer_urls = []
        for index in range(0, constants.DIVA_NODES):
            service_name_node = "diva-node-{0}".format(index + 1)
            node, node_url, signer_url = diva_server.start_node(
                plan,
                service_name_node,
                el_ws_uri,
                cl_uri,
                smart_contract_address,
                bootnode_peer_id,
                genesis_validators_root,
                genesis_time,
                bootnode_ip,
                verify_fee_recipient,
                network_id,
                is_nimbus=True,
            )
            diva_urls.append(node_url)
            signer_urls.append(signer_url)
            node_identity = diva_cli.generate_identity(plan, node_url)
            node_address = utils.get_diva_field(plan,service_name_node,"node_address")
            diva_addresses.append(node_address)
            if not private_pools_only:
                operator_public_key, operator_private_key, operator_address = diva_sc.new_key(plan)
                diva_sc.fund(plan, operator_address)
                diva_sc.register(plan, operator_private_key, smart_contract_address, node_address)

    if deploy_operator_ui:
        diva_operator_ui.launch(plan)

    if deploy_diva and charge_pre_genesis_keys:
        keys.upload_pregenesis_keys(plan,start_index_val,stop_index_val)
        configuration_tomls = keys.proccess_pregenesis_keys(
            plan, diva_urls, diva_addresses,start_index_val,stop_index_val
        )
        diva_cli.start_cli(plan, configuration_tomls)
        diva_cli.deploy(plan, stop_index_val - start_index_val)

    if deploy_diva:
        for index in range(0, constants.DIVA_NODES):
            nimbus.launch(
                plan,
                "diva-validator-{0}".format(index+1),
                signer_urls[index],
                cl_uri,
                smart_contract_address,
                verify_fee_recipient
            )