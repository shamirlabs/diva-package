constants = import_module("./constants.star")

DIVA_SERVER_IMAGE = "diva-server"
DIVA_BOOT_NODE_NAME = "diva-bootnode-coordinator"
DIVA_BOOTNODE_NAME = "diva-bootnode-coordinator"


# Starts the BootNode / Coordinator Node
def start_bootnode(
    plan, el_url, cl_url, contract_address, genesis_validators_root, genesis_time
):
    result = plan.add_service(
        name=DIVA_BOOTNODE_NAME,
        config=ServiceConfig(
            image=DIVA_SERVER_IMAGE,
            cmd=[
                "--db=/data/diva.db",
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
                "--genesis-fork-version=0x10000038",
                "--current-fork-version=0x40000038",
                "--gvr={0}".format(genesis_validators_root),
                "--deposit-contract=0x4242424242424242424242424242424242424242",
                # TODO this can be parametrized and use `network_params.network_id`
                "--chain-id=3151908",
                "--genesis-time={0}".format(genesis_time),
            ],
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                # TODO fill up jaeger configuration
            },
            ports={
                # TODO figure out why the port check isn't working
                "p2p": PortSpec(number=5050, transport_protocol="TCP", wait=None),
                # TODO figure out why the port check isn't working
                "signer-api": PortSpec(
                    number=9000, transport_protocol="TCP", wait=None
                ),
                "api": PortSpec(number=30000, transport_protocol="TCP"),
            },
            files={
                "/data": Directory(
                    persistent_key="diva-db-{0}".format(DIVA_BOOT_NODE_NAME)
                )
            },
        ),
    )

    return result, "http://{0}:30000".format(result.name)


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
    bootnode_ip_address,
    verify_fee_recipient,
    is_nimbus
):
    cmd = [
        "--db=/data/diva.db",
        "--w3s-address=0.0.0.0",
        "--execution-client-url={0}".format(el_url),
        "--consensus-client-url={0}".format(cl_url),
        # TODO remove this for now if lack of jaeger causes issues
        "--tracing",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--contract={0}".format(contract_address),
        "--bootnode-address=/ip4/{0}/tcp/5050/p2p/{1}".format(
            bootnode_ip_address, bootnode_peer_id
        ),
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--genesis-fork-version=0x10000038",
        "--current-fork-version=0x40000038",
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id=3151908",
        "--genesis-time={0}".format(genesis_time),
    ]

    if is_nimbus and verify_fee_recipient:
        cmd.append("--verify-fee-recipient")

    result = plan.add_service(
        name=diva_node_name,
        config=ServiceConfig(
            image=DIVA_SERVER_IMAGE,
            cmd=cmd,
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                # TODO fill up jaeger configuration
            },
            ports={
                # TODO figure out why the port check isn't working
                "p2p": PortSpec(number=5050, transport_protocol="TCP", wait=None),
                # TODO figure out why the port check isn't working
                "signer-api": PortSpec(
                    number=9000, transport_protocol="TCP", wait=None
                ),
                "api": PortSpec(number=30000, transport_protocol="TCP"),
            },
            files={
                "/data": Directory(persistent_key="diva-db-{0}".format(diva_node_name))
            },
        ),
    )

    return (
        result,
        "http://{0}:30000".format(result.name),
        "http://{0}:9000".format(result.name),
    )
