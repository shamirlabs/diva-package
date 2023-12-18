constants = import_module("./constants.star")

DIVA_SERVER_IMAGE = "diva/server"
DIVA_BOOT_NODE_NAME = "diva-bootnode-coordinator"


def start_bootnode(el_url, cl_url, contract_address):
    plan.add_service(
        service_name="diva-bootnode-coordinator",
        config=ServiceConfig(
            image=DIVA_SERVER_IMAGE,
            cmd=[
                "--db=/opt/diva/data/diva.db",
                "--w3s-address=0.0.0.0",
                "--execution-client-url={0}".format(el_url),
                "--consensus-client-url={0}".format(cl_url),
                "--tracing",
                "--log-level=debug",
                "--bootnode-address=",
                "--enable-coordinator",
                "--swagger-ui-enabled",
                "--contract={0}".format(contract_address),
                "--master-key={0}".format(constants.DIVA_API_KEY),
            ],
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                # TODO fill up jaeger configuration
            },
            ports={
                "p2p": PortSpec(number=5050, transport_protocol="TCP"),
                "metrics": PortSpec(number=9000, transport_protocol="TCP"),
                "swagger": PortSpec(number=30000, transport_protocol="TCP"),
            },
        ),
    )


def start_node():
    pass
