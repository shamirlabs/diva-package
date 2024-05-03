constants = import_module("./constants.star")

DIVA_DEPLOYER_CLI_NAME = "diva-cli-deployer"
DIVA_CLI_NAME = "diva-cli"


def start_cli(plan, configuration_tomls=None):
    files = {}
    name = DIVA_CLI_NAME
    if configuration_tomls:
        files["/configuration"] = configuration_tomls
        name = DIVA_DEPLOYER_CLI_NAME
    plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_CLI_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY},
            files=files,
        ),
    )


def generate_identity(plan, diva_server_url):
    plan.print("Generating identity for {0}".format(diva_server_url))
    plan.exec(
        service_name=DIVA_CLI_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "export DIVA_SERVER_URL={0} && /usr/local/bin/diva identity generate".format(
                    diva_server_url
                ),
            ]
        ),
    )
    #plan.exec(service_name=DIVA_CLI_NAME, recipe=ExecRecipe(command=["sleep", "10"]))


# TODO parallelize this; this is currently being called in Kurtosis but
# we can write a python script that creates a thread pool and runs migrate + deploy
def deploy(plan, diva_validators):
    for key_index in range(0, diva_validators):
        plan.print("index {0}".format(key_index))


        configuration_file = (
            "/configuration/config-{0}/config-{1}.toml".format(
                0, key_index
            )
        )
        plan.print(
            "deploying {0} for validator {1}".format(
                configuration_file, key_index
            )
        )
        
        pool_name = plan.exec(
            service_name=DIVA_DEPLOYER_CLI_NAME,
            recipe=ExecRecipe(
                command=[
                    "/bin/sh",
                    "-c",
                    "/usr/local/bin/diva pools migrate {0} | grep -o 'saved .*\\.json' | sed 's/saved //' | tr -d '\n' ".format(
                        configuration_file
                    ),
                ]
            ),
        )
        plan.exec(
            service_name=DIVA_DEPLOYER_CLI_NAME,
            recipe=ExecRecipe(
                command=[
                    "/bin/sh",
                    "-c",
                    "/usr/local/bin/diva pools deploy {0}".format(
                        pool_name["output"]
                    ),
                ]
            ),
        )
