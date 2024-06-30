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
        "PRIVATE_KEY": "0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31",
        "CONSENSUS_LAYER_RPC": consensus_url,
        "EXECUTION_LAYER_RPC" : execution_url,
        "ACCOUNTING_MANAGER_ADDRESS" : "0xDdD4DC7D559d431F6C497a840AD7E38Cdf7E0364",
        "BALANCE_VERIFIER_ADDRESS" : "0xeC6ffe5Bdd983986AE8217b0D12fD4bb9d1B074E",
        "VALIDATOR_MANAGER_ADDRESS" : "0x5A22381d4522FF06f62764dE5BA1f2679D129Aab"
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
