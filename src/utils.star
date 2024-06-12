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


def get_diva_field(plan, service_name, endpoint, field):
    recipe = GetHttpRequestRecipe(
        port_id="api-port",
        endpoint=endpoint,
        extract={
            field: "." + field,
        },
        headers = {
            "Authorization": "Bearer {0}".format(constants.DIVA_API_KEY) 
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


def get_eth_urls(all_participants, diva_args, index_total):
    # index fixed to 0, todo: distribute url btw diva_eth_nodes
    if index_total != 0:
        index = index_total % diva_args["diva_eth_nodes"]
    else:
        index = 0


    diva_args["diva_eth_start_index"]=0
    el_ip_addr = all_participants[
        0
    ].el_context.ip_addr
    el_ws_port = all_participants[
        0
    ].el_context.ws_port_num
    el_rpc_port = all_participants[
        0
    ].el_context.rpc_port_num
    el_rpc_uri = "http://{0}:{1}".format(el_ip_addr, el_rpc_port)
    el_ws_uri = "ws://{0}:{1}".format(el_ip_addr, el_ws_port)
    cl_ip_addr = all_participants[
        0
    ].cl_context.ip_addr
    cl_http_port_num = all_participants[
        0
    ].cl_context.http_port
    cl_uri = "http://{0}:{1}".format(cl_ip_addr, cl_http_port_num)

    return (cl_uri, el_rpc_uri, el_ws_uri)
