constants = import_module("./constants.star")


def start(
    plan
):
    result = plan.add_service(
        name="jaeger",
        config=ServiceConfig(
            image=constants.JAEGER_IMAGE,
            ports={
                "trace-collector": PortSpec(number=4318, transport_protocol="TCP", wait=None),
                "trace-front": PortSpec(number=16686, transport_protocol="TCP", wait=None),
            },
            min_cpu=200,
            max_cpu=1000,
        ),
    )

    return "http://{0}:4318".format(result.name)