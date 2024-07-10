constants = import_module("./constants.star")


def init(
    plan,
    el_url,
    el_ws,
    prover_url,
    chain_id,
):
    env_vars = {
        "FUNDED_PRIVATE_KEY": constants.HEARTBEAT_PRIV_KEY,
        "EXECUTION_LAYER_RPC": el_url,
        "EXECUTION_LAYER_RPC_WS": el_ws,
        "ACCOUNTING_MANAGER_ADDRESS" : constants.ACCOUNTING_MANAGER_ADDRESS,
        "BALANCE_VERIFIER_ADDRESS" : constants.BALANCE_VERIFIER_ADDRESS,
        "PROVER_URL": prover_url,
        "CHAIN_ID": chain_id,
    }
          
    plan.add_service(
        name=constants.DIVA_HEARBEAT_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_HEARBEAT_IMAGE,  
            env_vars = env_vars,
            cmd=["npx tsx index.ts"],
        )
    )
