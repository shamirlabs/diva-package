ethereum_package = import_module("github.com/kurtosis-tech/ethereum-package/main.star")

DIVA_CLI_IMAGE = "diva/cli"


def run(plan, args):
    ethereum_network = ethereum_package.run(plan, args)
    plan.print("Succesfully launched an Ethereum Network")

    plan.print("Shutting down all validators")
    for participant in ethereum_network.all_participants:
        cl_client_context = participant.cl_client_context
        validator_service_name = cl_client_context.validator_service_name
        plan.remove_service(validator_service_name)
