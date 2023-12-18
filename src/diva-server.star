constants = import_module("./constants.star")

DIVA_SERVER_IMAGE = "diva-server"
DIVA_BOOT_NODE_NAME = "diva-bootnode-coordinator"
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"


# Starts the BootNode / Coordinator Node
def start_bootnode(plan, el_url, cl_url, contract_address):
    plan.add_service(
        name=DIVA_BOOTNODE_NAME,
        config=ServiceConfig(
            image=DIVA_SERVER_IMAGE,
            cmd=[
                "--db=/tmp/diva.db",
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
                "api": PortSpec(number=30000, transport_protocol="TCP"),
            },
        ),
    )


# Starts a normal DIVA Node
# TODO parallelize this?
def start_node(
    plan,
    diva_node_name,
    el_url,
    cl_url,
    contract_address,
    bootnode_peer_id,
    genesis_validators_root,
    genesis_time,
    is_nimbus=True,
):
    cmd = [
        "--db=/tmp/diva.db",
        "--w3s-address=0.0.0.0",
        "--execution-client-url={0}".format(el_url),
        "--consensus-client-url={0}".format(cl_url),
        # TODO remove this for now if lack of jaeger causes issues
        "--tracing",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--contract={0}".format(contract_address),
        "--bootnode-address=/ip4/{0}/tcp/5050/p2p/{1}".format(
            DIVA_BOOT_NODE_NAME, bootnode_peer_id
        ),
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--fork-info=0x40000038",
        "--verify-fee-recipient",
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id=3151908",
        "--genesis-time={0}".format(genesis_time),
    ]

    if is_nimbus:
        cmd.append("--verify-fee-recipient")

    plan.add_service(
        name=diva_node_name,
        config=ServiceConfig(
            image=DIVA_SERVER_IMAGE,
            cmd=cmd,
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                # TODO fill up jaeger configuration
            },
            ports={
                "p2p": PortSpec(number=5050, transport_protocol="TCP"),
                "metrics": PortSpec(number=9000, transport_protocol="TCP"),
                "api": PortSpec(number=30000, transport_protocol="TCP"),
            },
        ),
    )
