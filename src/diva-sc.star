DIVA_SC_IMAGE = "diva-sc"
DIVA_SC_SERVICE_NAME = "diva-smartcontract-deployer"
utils = import_module("./utils.star")


def init(plan, el_url, sender_priv):
    plan.add_service(
        name=DIVA_SC_SERVICE_NAME,
        config=ServiceConfig(
            image=DIVA_SC_IMAGE,
            env_vars={"CUSTOM_URL": el_url, "CUSTOM_PRIVATE_KEY": sender_priv},
            cmd=["tail", "-f", "/dev/null"],
        ),
    )

def deploy(plan, delay_sc):

    plan.exec(service_name=DIVA_SC_SERVICE_NAME, recipe=ExecRecipe(command=["sleep", delay_sc]))

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
    
    return utils.get_sc_address(plan,result["output"])


def fund(plan,address):
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
