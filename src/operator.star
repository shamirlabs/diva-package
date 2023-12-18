OPERATOR_UI_IMAGE = "diva/operator-ui:latest"


def launch(plan):
    plan.add_service(
        name="operator",
        config=ServiceConfig(
            image=OPERATOR_UI_IMAGE,
            ports={
                "http": PortSpec(
                    number=80, transport_protocol="tcp", application_protocol="http"
                )
            },
        ),
    )
