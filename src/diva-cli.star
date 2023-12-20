constants = import_module("./constants.star")

DIVA_CLI_IMAGE = "diva-cli"
DIVA_CLI_NAME = "diva-cli"


def start_cli(plan):
    plan.add_service(
        name=DIVA_CLI_NAME,
        config=ServiceConfig(
            image=DIVA_CLI_IMAGE,
            entrypoint=["tail", "-f", "/dev/null"],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY},
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
                "export DIVA_SERVER_URL={0} && /usr/bin/diva identity generate".format(diva_server_url),
            ]
        ),
    )
