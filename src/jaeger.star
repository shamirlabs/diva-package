constants = import_module("./constants.star")


def start(
    plan
):
    public_ports = {}
    public_ports["trace-collector"] = PortSpec(
        number=4318, transport_protocol="TCP", wait=None
    )
    public_ports["trace-front"] = PortSpec(
        number=16686, transport_protocol="TCP", wait=None
    )
    
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
            min_memory=128,
            max_memory=2048,
            public_ports=public_ports
        ),
    )

    return "http://{0}:4318".format(result.name)