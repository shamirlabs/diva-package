constants = import_module("./constants.star")

DIVA_CLI_IMAGE = "diva-cli"
DIVA_CLI_NAME = "diva-cli"


def start_cli(plan, configuration_tomls):
    plan.add_service(
        name=DIVA_CLI_NAME,
        config=ServiceConfig(
            image=DIVA_CLI_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY},
            files={
                "/configuration": configuration_tomls,
            },
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
                "export DIVA_SERVER_URL={0} && /usr/bin/diva identity generate".format(
                    diva_server_url
                ),
            ]
        ),
    )

def deploy(plan, validator_service_names, number_of_keys_per_node):
    for validator_index in range(0, len(validator_service_names)):
        for key_index in range(0, number_of_keys_per_node):
            configuration_file = "/configuration/config-{0}/config-{1}.toml".format(validator_index, key_index)
            plan.print("deploying {0} for validator {1}".format(configuration_file, validator_index))
            plan.exec(
                service_name=DIVA_CLI_NAME,
                recipe = ExecRecipe(
                    command = ["/bin/sh", "-c", "/usr/bin/diva pools migrate {0} > /tmp/pool.json".format(configuration_file)]
                )
            )
            plan.exec(
                service_name=DIVA_CLI_NAME,
                recipe = ExecRecipe(
                    command = ["/bin/sh", "-c", "/usr/bin/diva pools deploy /tmp/pool.json"]
                )
            )
