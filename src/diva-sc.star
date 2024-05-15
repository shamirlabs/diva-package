DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"
DIVA_SC_REGISTER_NAME = "diva-smartcontract-register"
utils = import_module("./utils.star")
constants = import_module("./constants.star")


def init(plan, el_url, sender_priv):
    plan.add_service(
        name=DIVA_SC_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SC_IMAGE,
            env_vars={"CUSTOM_URL": el_url, "CUSTOM_PRIVATE_KEY": sender_priv},
            cmd=["tail", "-f", "/dev/null"],
        ),
    )


def deploy(plan, el_rpc, delay_sc, chainID, sc_verif):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(command=["sleep", "0"]),
    )

    fund = plan.wait(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast send 0x3fab184622dc19b6109349b94811493bf2a45362 --value \"0.1 ether\" --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --rpc-url {0}".format(el_rpc)
            ]
        ),
        field="code", 
        assertion="==", 
        target_value=0,
        interval = "3s",
        timeout = "3m",
    )

    create2factory = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast publish --rpc-url {0} 0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222".format(el_rpc) 
            ]
        ),
    )

    deploy = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "forge script scripts/Deploy.s.sol -vv  --rpc-url={0} --broadcast --private-key=bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31".format(el_rpc)
            ]
        ),
    )    
    return deploy["output"]


def fund(plan, el_rpc, address):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast send {0} --value \"0.1 ether\" --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --rpc-url {1}".format(
                    address,el_rpc
                ),
            ]
        ),
    )


def new_key(plan):
    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast wallet new | awk '/Address:/{addr=$2} /Private key:/{key=$3} END{printf \"[\\\"%s\\\",\\\"%s\\\"]\\n\", addr, key}'",
            ],
            extract = {
                "address" : "fromjson | .[0]",
                "private_key" : "fromjson | .[1]",
            },
        ),
 
    )
    address= result["extract.address"]
    private_key= result["extract.private_key"]
    return address, private_key

def register(plan, node_address, node_private_key, el_rpc, operator_private_key):
    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "NODE_ADDRESS={0} NODE_PRIVATE_KEY={1} forge script ./scripts/testnet/RegisterNode.s.sol -vvv --rpc-url={2} --broadcast --private-key {3}".format(
                    node_address, node_private_key, el_rpc,operator_private_key
                )
            ],
        ),
    )