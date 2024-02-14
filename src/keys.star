constants = import_module("./constants.star")
genesis = import_module("./genesis.star")

PYTHON_RUNNER_IMAGE = "python:3.11-alpine"

def upload_pregenesis_keys(plan, start_index_val,stop_index_val):

    script = plan.upload_files("../python_scripts/keys.py")
    files = {
        "/tmp/scripts": script,
    }

    files["/tmp/node-0"] = genesis.generate_validator_keystores(plan,start_index_val,stop_index_val)
    plan.add_service(
        name="diva-keys-python",
        config=ServiceConfig(
            image=PYTHON_RUNNER_IMAGE,
            files=files,
            cmd=["tail", "-f", "/dev/null"],
        ),
    )
    plan.exec(
        service_name="diva-keys-python",
        #recipe=ExecRecipe(command=["pip", "install", "pyyaml"]),
        recipe=ExecRecipe(command=["sh", "-c", "pip install pyyaml > /dev/null 2>&1"])
    )
    plan.exec(
        service_name="diva-keys-python",
        recipe=ExecRecipe(
            command=["mkdir", "-p", "/tmp/configurations/config-0"]
        ),
    )

def proccess_pregenesis_keys(plan, diva_node_urls, diva_addresses, start_index_val, stop_index_val):

    plan.exec(
        service_name="diva-keys-python",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/keys.py /tmp/node-0/node-0-keystores/teku-keys /tmp/node-0/node-0-keystores/teku-secrets {0} {1} {2} {3} {4} {5} {6} {7}".format(
                    constants.DIVA_SET_SIZE,
                    ",".join(diva_addresses),
                    constants.DIVA_SET_THRESHOLD,
                    constants.DIVA_API_KEY,
                    start_index_val,
                    stop_index_val,
                    ",".join(diva_node_urls),
                    (constants.DIVA_DISTRIBUTION)
                ),
            ]
        ),
    )
    
    return plan.store_service_files(
        service_name="diva-keys-python",
        src="/tmp/configurations",
        name="diva-configuration-tomls",
    )
