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

    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat run --no-compile scripts/deployDiamondAndSetup.js --network custom",
            ]
        ),
    )

    # figure out how to collect this
    smart_contract_address = ""
    return smart_contract_address


def fund(plan, node_address):
    plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "npx hardhat fund --to {0} --amount 10 --network custom".format(
                    node_address
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
                "npx hardhat new-key",
            ]
        ),
        extract={"publicKey": ".publicKey", "privateKey": ".privateKey"},
    )
    return result["extract.publicKey"], result["extract.privateKey"]


def register(plan, custom_private_key, contract_address, node_address):
    result = plan.exec(
        service_name=DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "export CUSTOM_PRIVATE_KEY={0} && npx hardhat registerOperatorAndNode --contract={1} --node={2} --network=custom".format(
                    contract_address, node_address
                ),
            ],
        ),
    )
