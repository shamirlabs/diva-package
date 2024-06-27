constants = import_module("./constants.star")


def start(
    plan,
    el_url,
    el_ws,
):
    env_vars = {
        "FUNDED_PRIVATE_KEY": "0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31",
        "EXECUTION_LAYER_RPC": el_url,
        "EXECUTION_LAYER_RPC_WS": el_ws,
        "ACCOUNTING_MANAGER_ADDRESS" : "0x076eB2080f312DE95b8423AD8fF8b00a8505c895",
        "BALANCE_VERIFIER_ADDRESS" : "0xaEBa55e07C3a3471030b190e7EE8Ee87567e878c",
    }
          
    plan.add_service(
        name=constants.DIVA_HEARBEAT_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_HEARBEAT_IMAGE,  
            env_vars = env_vars,
            cmd=["npx tsx index.ts"],
        )
    )
