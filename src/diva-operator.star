constants = import_module("./constants.star")


def launch(plan):
    plan.add_service(
        name="operator",
        config=ServiceConfig(
            image=constants.OPERATOR_UI_IMAGE,
            ports={
                "http": PortSpec(
                    number=80, transport_protocol="TCP", application_protocol="http"
                )
            },
        ),
    )
