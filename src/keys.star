constants = import_module("./constants.star")

PYTHON_RUNNER_IMAGE = "python:3.11-alpine"


def generate_configuration_tomls(plan, validator_keystores, diva_node_urls, diva_addresses):
    script = plan.upload_files("../python_scripts/keyshares.py")

    files = {
        "/tmp/scripts": script,
    }

    for index, keystore in enumerate(validator_keystores):
        files["/tmp/node-{0}".format(index)] = keystore

    plan.add_service(
        name="python-runner",
        config=ServiceConfig(
            image=PYTHON_RUNNER_IMAGE,
            files=files,
            cmd=["tail", "-f", "/dev/null"],
        ),
    )

    plan.exec(
        service_name="python-runner",
        recipe=ExecRecipe(command=["pip", "install", "pyyaml"]),
    )
    
    for index in range(0, len(validator_keystores)):    
        plan.exec(
            service_name="python-runner",
            recipe=ExecRecipe(
                command=["mkdir", "-p", "/tmp/configurations/config-{0}".format(index)]
            ),
        )

    plan.exec(
        service_name="python-runner",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/keyshares.py /tmp/node-0/node-0-keystores/teku-keys /node-0/node-0-keystores/teku-secrets {0} {1} {2} {3} {4}".format(
                    diva_node_urls,
                    ",".join(diva_addresses),
                    constants.DIVA_SET_THRESHOLD,
                    constants.DIVA_API_KEY,
                    "/tmp/configurations/config-0",
                    len(validator_keystores),
                    constants.DIVA_SET_SIZE
                    constants.DIVA_DISTRIBUTION
                ),
            ]
        ),
    )

    return plan.store_service_files(
        service_name="python-runner",
        src="/tmp/configurations",
        name="diva-configuration-tomls",
    )