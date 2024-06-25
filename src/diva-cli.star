constants = import_module("./constants.star")




def start_cli(plan, configuration_tomls=None):
    files = {}
    name = constants.DIVA_CLI_NAME
    if configuration_tomls:
        files["/configuration"] = configuration_tomls
        name = constants.DIVA_DEPLOYER_CLI_NAME
    plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_CLI_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY},
            files=files,
        ),
    )


def generate_identity(plan, diva_server_urls):
    commands = []
    for diva_server_url in diva_server_urls:
        command = "export DIVA_SERVER_URL={0} && /usr/local/bin/diva identity generate &".format(
                    diva_server_url
                )
        commands.append(command)
    
    full_command = " ".join(commands) + " wait; [ $? -eq 0 ] || exit 1"

    res= plan.exec(
        service_name=constants.DIVA_CLI_NAME,
        acceptable_codes = [0, 1],
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                full_command
            ]
        ),
    )


def deploy2(plan, diva_validators):
    for key_index in range(0, diva_validators):
        configuration_file = "/configuration/config-{0}/config-{1}.toml".format(
            0, key_index
        )

        plan.print(
            "deploying {0} for validator {1}".format(configuration_file, key_index)
        )

        pool_name = plan.exec(
            service_name=constants.DIVA_DEPLOYER_CLI_NAME,
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
        plan.print(
            pool_name
        )

        plan.exec(
            service_name=constants.DIVA_DEPLOYER_CLI_NAME,
            recipe=ExecRecipe(
                command=[
                    "/bin/sh",
                    "-c",
                    "/usr/local/bin/diva pools deploy {0}".format(pool_name["output"]),
                ]
            ),
        )


def deploy(plan, diva_validators):
    commandsMigrate = []
    commandsDeploy = []
    for key_index in range(0, diva_validators):
        configuration_file = "/configuration/config-{0}/config-{1}.toml".format(
            0, key_index
        )
        commandMigrate = "/usr/local/bin/diva pools migrate {0} | grep -o 'saved .*\\.json' &".format(configuration_file)
        commandsMigrate.append(commandMigrate)
        
    full_commandMigrate = " ".join(commandsMigrate) + " wait; [ $? -eq 0 ] || exit 1"
    deployAllCmd = 'for file in *.json; do /usr/local/bin/diva pools deploy "$file"; done'
    plan.exec(
        service_name=constants.DIVA_DEPLOYER_CLI_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                full_commandMigrate
            ]
        ),
    )
    plan.exec(
        service_name=constants.DIVA_DEPLOYER_CLI_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                deployAllCmd
            ]
        ),
    )