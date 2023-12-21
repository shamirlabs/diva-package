DIVA_SC_IMAGE = "diva-sc"
DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"


def deploy(plan, el_url, address):
    plan.add_service(
        name=DIVA_SC_SERVICE_NAME,
        config=ServiceConfig(
            image=DIVA_SC_IMAGE,
            env_vars={"CUSTOM_URL": el_url, "CUSTOM_PRIVATE_KEY": address},
            cmd=["tail", "-f", "/dev/null"],
        ),
    )

    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat run --no-compile scripts/deployDiamondAndSetup.js --network custom",
            ]
        ),
    )

    # TODO un hardcode this
    return "0x17435ccE3d1B4fA2e5f8A08eD921D57C6762A180".lower()


def fund(plan, address):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat fund --to {0} --amount 100 --network custom".format(
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
                "npx hardhat new-key | tr -d '\n' > key.txt",
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
                "export CUSTOM_OPERATOR_PRIVATE_KEY={0} && npx hardhat registerOperatorAndNode --contract {1} --node {2} --network custom".format(
                    custom_private_key, contract_address, node_address
                ),
            ],
        ),
    )
