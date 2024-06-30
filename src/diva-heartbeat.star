constants = import_module("./constants.star")


def init(
    plan,
    el_url,
    el_ws,
    prover_url
):
    env_vars = {
        "FUNDED_PRIVATE_KEY": "0x39725efee3fb28614de3bacaffe4cc4bd8c436257e2c8bb887c4b5c4be45e76d",
        "EXECUTION_LAYER_RPC": el_url,
        "EXECUTION_LAYER_RPC_WS": el_ws,
        "ACCOUNTING_MANAGER_ADDRESS" : "0xDdD4DC7D559d431F6C497a840AD7E38Cdf7E0364",
        "BALANCE_VERIFIER_ADDRESS" : "0xeC6ffe5Bdd983986AE8217b0D12fD4bb9d1B074E",
        "PROVER_URL": prover_url
    }
          
    plan.add_service(
        name=constants.DIVA_HEARBEAT_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_HEARBEAT_IMAGE,  
            env_vars = env_vars,
            cmd=["npx tsx index.ts"],
        )
    )
