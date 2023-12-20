constants = import_module("./src/constants.star")

DIVA_CLI_IMAGE = "diva-cli"
DIVA_CLI_NAME = "diva-cli"


def start_cli(plan):
    plan.add_service(
        name=DIVA_CLI_NAME,
        config=ServiceConfig(
            image=DIVA_CLI_IMAGE,
            cmd=["tail", "-f", "/dev/null"],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY},
        ),
    )


def generate_identity(diva_server_url):
    plan.exec(
        service_name=DIVA_CLI_NAME,
        recipe=ExecRecipe(
            cmd=[
                "/bin/sh",
                "-c",
                "DIVA_SERVER_URL={0} ./diva identity generate".format(diva_server_url),
            ]
        ),
    )
