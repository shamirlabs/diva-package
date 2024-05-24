ethereum_package_official = import_module(
    "github.com/kurtosis-tech/ethereum-package/main.star"
)
ethereum_package_shamir = import_module("../ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/shamirlabs/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-node.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator_ui = import_module("./src/diva-operator.star")
diva_cli = import_module("./src/diva-cli.star")
constants = import_module("./src/constants.star")
keys = import_module("./src/keys.star")
nimbus = import_module("./src/nimbus.star")
prysm = import_module("./src/prysm.star")
utils = import_module("./src/utils.star")
input_parser = import_module("./src/input-parser.star")
w3s = import_module("./src/w3s.star")


def run(plan, args):
    diva_args = input_parser.diva_input_parser(plan, args)
    deploy_eth = diva_args["diva_params"]["options"]["deploy_eth"]

    deploy_diva = diva_args["diva_params"]["options"]["deploy_diva_nodes"]
    deploy_diva_sc = diva_args["diva_params"]["options"]["deploy_diva_sc"]
    deploy_diva_coord_boot = diva_args["diva_params"]["options"][
        "deploy_diva_coord_boot"
    ]
    deploy_operator_ui = diva_args["diva_params"]["options"]["deploy_operator_ui"]
    verify_fee_recipient = diva_args["diva_params"]["options"]["verify_fee_recipient"]
    private_pools_only = diva_args["diva_params"]["options"]["private_pools_only"]
    charge_pre_genesis_keys = diva_args["diva_params"]["options"][
        "charge_pre_genesis_keys"
    ]
    mev = diva_args["mev_type"] != None
    use_w3s = diva_args["diva_params"]["use_w3s"]
    eth_connection_enabled = diva_args["diva_params"]["options"][
        "eth_connection_enabled"
    ]
    start_index_val = int(diva_args["eth_validator_count"]) - 1
    diva_validators = diva_args["diva_params"]["diva_validators"]
    distribution = diva_args["diva_params"]["distribution"]
    public_ports = diva_args["diva_params"]["options"]["public_ports"]
    diva_nodes = diva_args["diva_params"]["diva_nodes"]
    diva_val_type = diva_args["diva_params"]["diva_val_type"]
    delay_sc = "0"
    utils.initUtils(plan)
    if deploy_eth:
        if deploy_diva_sc:
            delay_sc = "15"
        if public_ports:
            ethereum_package = ethereum_package_shamir
        else:
            ethereum_package = ethereum_package_official

        ethereum_network = ethereum_package.run(plan, diva_args)

        plan.print("Succesfully launched an Ethereum Network")
        cl_uri_0, el_rpc_uri_0, el_ws_uri_0 = utils.get_eth_urls(
            ethereum_network.all_participants, diva_args, 0
        )
        network_id = 3151908
        sc_verif = ethereum_network.blockscout_sc_verif_url
        genesis_validators_root = utils.get_gvr(plan, cl_uri_0)
        genesis_time = utils.get_genesis_time(plan, cl_uri_0)

    else:
        el_ws_uri_0 = "ws://{0}:{1}".format(constants.HOST, constants.EL_WS_PORT)
        cl_uri_0 = "http://{0}:{1}".format(constants.HOST, constants.CL_PORT)
        el_rpc_uri_0 = "http://{0}:{1}".format(constants.HOST, constants.EL_HTTP_PORT)
        genesis_validators_root = utils.get_gvr(plan, cl_uri_0)
        genesis_time = utils.get_genesis_time(plan, cl_uri_0)
        network_id = utils.get_chain_id(plan, cl_uri_0)
        sc_verif = "http://{0}:{1}".format(constants.HOST, constants.EXEC_EXPL_PORT)
        start_index_val = constants.DIVA_VAL_INDEX_START

    stop_index_val = start_index_val + diva_validators

    if deploy_diva_sc :
        diva_sc.init(
            plan, el_rpc_uri_0, genesis_constants.PRE_FUNDED_ACCOUNTS[1].private_key
        )

    smart_contract_address = constants.DIVA_SC

    if deploy_diva_sc:
        diva_sc.deploy(plan, el_rpc_uri_0, delay_sc, network_id, sc_verif)

    if deploy_diva or deploy_diva_coord_boot:
        diva_cli.start_cli(plan)

    if deploy_diva_coord_boot:
        cl_uri_0, el_rpc_uri_0, el_ws_uri_0 = utils.get_eth_urls(
            ethereum_network.all_participants, diva_args, 0
        )
        bootnode, bootnode_url = diva_server.start_bootnode(
            plan,
            el_ws_uri_0,
            cl_uri_0,
            smart_contract_address,
            genesis_validators_root,
            genesis_time,
            public_ports,
            network_id,
            eth_connection_enabled,
        )
        diva_cli.generate_identity(plan, bootnode_url)
        bootnode_address = utils.get_diva_field(
            plan, constants.DIVA_BOOTNODE_NAME,constants.DIVA_INFO_ENDPOINT, "node_address"
        )

        if deploy_diva_sc:
            diva_sc.fund(plan, el_rpc_uri_0, bootnode_address)

    if deploy_diva:
        bootonde_url = "http://{0}:{1}".format(constants.HOST, constants.BOOTNODE_PORT)
        bootnode_ip = constants.HOST

        if deploy_diva_coord_boot:
            bootnode_ip = bootnode.ip_address

        bootnode_peer_id = utils.get_diva_field(
            plan, constants.DIVA_BOOTNODE_NAME, constants.DIVA_INFO_ENDPOINT,"network_settings.peer_id"
        )

        plan.print("Starting DIVA nodes")

        diva_urls = []
        validators_to_shutdown = []
        diva_addresses = []
        signer_urls = []
        for index in range(0, diva_nodes):
            cl_uri, el_rpc_uri, el_ws_uri = utils.get_eth_urls(
                ethereum_network.all_participants, diva_args, index
            )
            service_name_node = "diva{0}".format(index + 1)
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
                eth_connection_enabled,
            )
            diva_urls.append(node_url)
            signer_urls.append(signer_url)
            diva_cli.generate_identity(plan, node_url)
            node_address = utils.get_diva_field(plan, service_name_node, constants.DIVA_INFO_ENDPOINT, "node_address")
            diva_addresses.append(node_address)
            if not private_pools_only:
                (
                    operator_address,
                    operator_private_key,
                ) = diva_sc.new_key(plan)
                diva_sc.fund(plan, el_rpc_uri, operator_address)
                node_priv_key = utils.get_diva_field(plan, service_name_node, constants.DIVA_ID_ENDPOINT, "secret_key")
                diva_sc.register(
                    plan, node_address, node_priv_key, el_rpc_uri,operator_private_key
                )
    if deploy_operator_ui:
        diva_operator_ui.launch(plan)

    if charge_pre_genesis_keys:
        if deploy_diva and not use_w3s:
            keys.upload_pregenesis_keys(plan, start_index_val, stop_index_val)
            configuration_tomls = keys.proccess_pregenesis_keys(
                plan,
                diva_urls,
                diva_addresses,
                start_index_val,
                stop_index_val,
                distribution,
            )
            diva_cli.start_cli(plan, configuration_tomls)
            diva_cli.deploy(plan, stop_index_val - start_index_val)

        if use_w3s:
            cl_uri, el_rpc_uri, el_ws_uri = utils.get_eth_urls(
                ethereum_network.all_participants, diva_args, 0
            )        
            w3s_url = w3s.start_node(plan, start_index_val, stop_index_val)
            if diva_val_type == "prysm":
                prysm.launch(
                    plan,
                    "val0",
                    w3s_url,
                    cl_uri,
                    smart_contract_address,
                    verify_fee_recipient,
                    mev,
                )
            else:
                nimbus.launch(
                    plan,
                    "val0",
                    w3s_url,
                    cl_uri,
                    smart_contract_address,
                    verify_fee_recipient,
                    mev,
                )
    if deploy_diva and not use_w3s:
        for index in range(0, diva_nodes):
            cl_uri, el_rpc_uri, el_ws_uri = utils.get_eth_urls(
                ethereum_network.all_participants, diva_args, index
            )
            if diva_val_type == "prysm":
                prysm.launch(
                    plan,
                    "val{0}".format(index + 1),
                    signer_urls[index],
                    cl_uri,
                    smart_contract_address,
                    verify_fee_recipient,
                    mev,
                )
            else:
                nimbus.launch(
                    plan,
                    "val{0}".format(index + 1),
                    signer_urls[index],
                    cl_uri,
                    smart_contract_address,
                    verify_fee_recipient,
                    mev,
                )
