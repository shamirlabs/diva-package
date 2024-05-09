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


def deploy(plan, delay_sc, chainID, sc_verif):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(command=["sleep", delay_sc]),
    )

    diamond = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat run --no-compile scripts/deployDiamondAndSetup.js --network custom  2>/dev/null | tail -n 1 | awk '{print $1, $2, $3}' | tr -d '\n' ",
            ]
        ),
    )

    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "CHAINID=3151908 VERIF_API={1}/api VERIF_URL={1} npx hardhat verify --network custom {2}  | tr -d '\n' ".format(
                    chainID, sc_verif, diamond["output"]
                ),
            ]
        ),
    )
    return diamond["output"].split(" ")[0]


def fund(plan, address):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat fund --to {0} --amount 100 --network custom 2>/dev/null".format(
                    address
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
                "npx hardhat new-key 2>/dev/null | tr -d '\n' > key.txt",
            ],
        ),
    )

    publicKey = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                """cat key.txt | awk -F'"publicKey": "' '{print $2}' | awk -F'"' '{print $1}' | tr -d '\n'""",
            ],
        ),
    )

    privateKey = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                """cat key.txt | awk -F'"privateKey": "' '{print $2}' | awk -F'"' '{print $1}' | tr -d '\n'""",
            ],
        ),
    )

    address = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                """cat key.txt | awk -F'"address": "' '{print $2}' | awk -F'"' '{print $1}' | tr -d '\n'""",
            ],
        ),
    )

    return publicKey["output"], privateKey["output"], address["output"]


def register(plan, custom_private_key, contract_address, node_address):
    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "export CUSTOM_OPERATOR_PRIVATE_KEY={0} && npx hardhat registerOperatorAndNode --contract {1} --node {2} --network custom  2>/dev/null".format(
                    custom_private_key, contract_address, node_address
                ),
            ],
        ),
    )
