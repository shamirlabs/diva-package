ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package@1.3.0/main.star")
ethereum_package_shamir = import_module("github.com/shamirlabs/ethereum-package/main.star")
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
    diva_params= diva_args.diva_params
    deploy_eth= diva_params.deploy_eth
    deploy_diva = diva_params.deploy_diva
    deploy_diva_sc= diva_params.deploy_diva_sc
    deploy_diva_coord_boot= diva_params.deploy_diva_coord_boot
    deploy_operator_ui=diva_params.deploy_operator_ui
    verify_fee_recipient=diva_params.verify_fee_recipient
    private_pools_only=diva_params.private_pools_only    
    charge_pre_genesis_keys=diva_params.charge_pre_genesis_keys
    

    public_ports= diva_params.public_ports
    participants = diva_args.participants
    diva_validators = constants.DIVA_VALIDATORS
    start_index_val=diva_params.diva_val_start
    stop_index_val=diva_params.diva_val_stop
    delay_sc="0"
    utils.initUtils(plan)

    if deploy_eth:
        if deploy_diva_sc:
            delay_sc="150"
        if public_ports:
            ethereum_package=ethereum_package_shamir
        ethereum_network = ethereum_package.run(plan, args)

        plan.print("Succesfully launched an Ethereum Network")
        
        genesis_validators_root, genesis_time = (
            ethereum_network.genesis_validators_root,
            ethereum_network.final_genesis_timestamp,
        )
        el_ip_addr = ethereum_network.all_participants[0].el_client_context.ip_addr
        el_ws_port = ethereum_network.all_participants[0].el_client_context.ws_port_num
        el_rpc_port = ethereum_network.all_participants[0].el_client_context.rpc_port_num
        el_rpc_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)
        el_ws_uri = "ws://{0}:{1}".format(el_ip_addr, el_ws_port)
        cl_ip_addr = ethereum_network.all_participants[0].cl_client_context.ip_addr
        cl_http_port_num = ethereum_network.all_participants[0].cl_client_context.http_port_num
        cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)
        network_id = args.get("network_params").get("network_id") if  args.get("network_params").get("network_id") != None else 3151908
        sc_verif=ethereum_network.blockscout_sc_verif_url
    else:
        el_ws_uri = "ws://{0}:{1}".format(constants.HOST, constants.EL_WS_PORT)
        cl_uri = "http://{0}:{1}".format(constants.HOST, constants.CL_PORT)
        el_rpc_uri = "http://{0}:{1}".format(constants.HOST, constants.EL_HTTP_PORT)
        genesis_validators_root = utils.get_gvr(plan,cl_uri)
        genesis_time = utils.get_genesis_time(plan,cl_uri)
        network_id = utils.get_chain_id(plan,cl_uri) 
        sc_verif = "http://{0}:{1}".format(constants.HOST, constants.EXEC_EXPL_PORT)
        
    if deploy_diva_sc or deploy_diva_coord_boot or deploy_diva:
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
        bootnode_address = utils.get_address(plan, bootnode_url)

        diva_sc.fund(plan, bootnode_address)
    
    if deploy_diva:
        bootonde_url= "http://{0}:{1}".format(constants.HOST,constants.BOOTNODE_PORT)
        bootnode_ip= constants.HOST
        if deploy_diva_coord_boot:
            bootnode_ip= bootnode.ip_address            
        plan.print("Starting DIVA nodes")
        bootnode_peer_id = utils.get_peer_id(plan, bootonde_url)
        diva_urls = []
        validators_to_shutdown = []
        diva_addresses = []
        signer_urls = []
        for index in range(0, constants.DIVA_NODES):
            node, node_url, signer_url = diva_server.start_node(
                plan,
                "diva-node-{0}".format(index + 1),
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
            operator_public_key, operator_private_key, operator_address = diva_sc.new_key(plan)
            node_address = utils.get_address(plan, node_url)
            diva_addresses.append(node_address)
            if not private_pools_only:
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
                "diva-validator-{0}".format(index),
                signer_urls[index],
                cl_uri,
                smart_contract_address,
                verify_fee_recipient
            )