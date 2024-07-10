constants = import_module("./constants.star")

def init(
    plan,
    consensus_url,
    execution_url,
    minimal
):
    preset="mainnet"
    if minimal:
        preset="minimal"
    env_vars = {
        "PRESET": preset,
        "PRIVATE_KEY": constants.PROVER_PRIVATE_KEY,
        "CONSENSUS_LAYER_RPC": consensus_url,
        "EXECUTION_LAYER_RPC" : execution_url,
        "ACCOUNTING_MANAGER_ADDRESS" : constants.ACCOUNTING_MANAGER_ADDRESS,
        "BALANCE_VERIFIER_ADDRESS" : constants.BALANCE_VERIFIER_ADDRESS,
        "VALIDATOR_MANAGER_ADDRESS" : constants.VALIDATOR_MANAGER_ADDRESS
    }
          
    result= plan.add_service(
        name=constants.DIVA_PROOFS_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_PROOFS_IMAGE,  
            env_vars = env_vars,
            ports={
                "prover": PortSpec(number=5000, transport_protocol="TCP", wait=None),
            },
        )
    )
    return "http://{0}:{1}".format(result.name, "5000")
