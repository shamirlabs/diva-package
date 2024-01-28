constants = import_module("./constants.star")
PYTHON_RUNNER_IMAGE = "python:3.11-alpine"


def initUtils(plan):
    script = plan.upload_files("../python_scripts/utils.py")

    files = {
        "/tmp/scripts": script,
    }

    plan.add_service(
        name="diva-utils",
        config=ServiceConfig(
            image=PYTHON_RUNNER_IMAGE,
            files=files,
            cmd=["tail", "-f", "/dev/null"],
        ),
    )

    plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(command=["pip", "install", "requests"]),
    )
    
def get_address(plan, diva_url):
    result = plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/utils.py get_address {0} {1}".format(
                    diva_url, constants.DIVA_API_KEY
                ),
            ]
        ),
    )    
    return result["output"]

def get_peer_id(plan, diva_url):
    result = plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/utils.py get_peer_id {0} {1} | tr -d '\n'".format(
                    diva_url, constants.DIVA_API_KEY
                ),
            ]
        ),
    )    
    return result["output"]

def get_gvr(plan, beacon_url):
    result = plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/utils.py get_gvr {0} | tr -d '\n'".format(
                    beacon_url
                ),
            ]
        ),
    )
    plan.print(result["output"])
    return result["output"]

def get_genesis_time(plan, beacon_url):
    result = plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/utils.py get_genesis_time {0} | tr -d '\n'".format(
                    beacon_url
                ),
            ]
        ),
    )    
    plan.print(result["output"])
    return result["output"]

def get_chain_id(plan, beacon_url):
    result = plan.exec(
        service_name="diva-utils",
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "python /tmp/scripts/utils.py get_chain_id {0} | tr -d '\n'".format(
                    beacon_url
                ),
            ]
        ),
    )    
    return result["output"]