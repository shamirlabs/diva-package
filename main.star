ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")
nimbus = import_module("./src/nimbus.star")


def run(plan, args):
    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

    plan.print("Shutting down all validators")
    for participant in ethereum_network.all_participants:
        cl_client_context = participant.cl_client_context
        validator_service_name = cl_client_context.validator_service_name
        plan.remove_service(validator_service_name)

    genesis_validators_root, final_genesis_timestamp = (
        ethereum_network.genesis_validators_root,
        ethereum_network.final_genesis_timestamp,
    )
