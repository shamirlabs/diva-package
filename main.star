ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")
genesis_constants = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

diva_server = import_module("./src/diva-server.star")
diva_sc = import_module("./src/diva-sc.star")
diva_operator = import_module("./src/operator.star")


def run(plan, args):
    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

    # WE seem to need the validators to deploy smart contracts
    # DO this stop and restart later
    # plan.print("Shutting down all validators")
    # for participant in ethereum_network.all_participants:
    #     cl_client_context = participant.cl_client_context
    #     validator_service_name = cl_client_context.validator_service_name
    #     plan.remove_service(validator_service_name)

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

    diva_server.start_bootnode(plan, el_uri, cl_uri, smart_contract_address)

    diva_operator.launch(plan)
