DIVA_SC_IMAGE = "diva/sc"
DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"


def deploy(el_url, address):
    plan.add_service(
        name=DIVA_SC_SERVICE_NAME,
        config=ServiceConfig(
            image="DIVA_SC_IMAGE",
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
