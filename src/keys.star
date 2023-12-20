constants = import_module("./constants.star")

PYTHON_RUNNER_IMAGE = "python:3.11-alpine"


def generate_configuration_tomls(plan, validator_keystores, prefixes):
    script = plan.upload_files("../python_scripts/keys.py")

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
    for index, prefix in enumerate(prefixes):
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
                    "python /tmp/scripts/keys.py /tmp/node-{0}/node-{0}-keystores/teku-keys /tmp/node-{0}/node-{0}-keystores/teku-secrets {1} {2}".format(
                        index,
                        constants.NUMBER_OF_DIVA_NODES_PER_NODE,
                        constants.DIVA_THRESHOLD,
                        constants.DIVA_API_KEY,
                        prefix,
                        "/tmp/configurations/config-{0}".format(index),
                    ),
                ]
            ),
        )

    return plan.store_service_files(service_name="python-runner", src="/tmp/configurations")
