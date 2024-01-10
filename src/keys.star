constants = import_module("./constants.star")

PYTHON_RUNNER_IMAGE = "python:3.11-alpine"


def generate_configuration_tomls(plan, validator_keystores, diva_urls, diva_addresses, threshold):
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

    plan.exec(
        service_name="python-runner",
        recipe=ExecRecipe(command=["pip", "install", "pyyaml"]),
    )

    # note here all keys from all validator keystores are split over all divas
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
                    "python /tmp/scripts/keys.py /tmp/node-{0}/node-{0}-keystores/teku-keys /tmp/node-{0}/node-{0}-keystores/teku-secrets {1} {2} {3} {4} {5}".format(
                        index,
                        ",".join(diva_urls),
                        ",".join(diva_addresses),
                        threshold,
                        constants.DIVA_API_KEY,
                        "/tmp/configurations/config-{0}".format(index),
                    ),
                ]
            ),
        )

    return plan.store_service_files(
        service_name="python-runner",
        src="/tmp/configurations",
        name="diva-configuration-tomls",
    )
