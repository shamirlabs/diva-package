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
        recipe=ExecRecipe(
            command=["sh", "-c", "pip install requests > /dev/null 2>&1"]
        ),
    )


def get_diva_field(plan, service_name, field):
    recipe = GetHttpRequestRecipe(
        port_id="api-port",
        endpoint="/api/v1/node/info",
        extract={
            field: "." + field,
        },
    )
    field_n = "extract." + field
    response = plan.wait(
        field=field_n,
        assertion="!=",
        target_value="",
        timeout="5s",
        recipe=recipe,
        service_name=service_name,
    )
    return response[field_n]


def wait(plan, s):
    result = plan.run_python(
        # The Python script to execute as a string
        # This will get executed via '/bin/sh -c "python /tmp/python/main.py"'.
        # Where `/tmp/python/main.py` is path on the temporary container;
        # on which the script is written before it gets run
        # MANDATORY
        run="""
import time
time.sleep(40)
        """,
        image="python:3.11-alpine",
        wait=None,
        description="running python script.. waiting 40s.",
    )


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
