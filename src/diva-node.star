constants = import_module("./constants.star")


# Starts the BootNode / Coordinator Node
def start_bootnode(
    plan,
    el_url,
    cl_url,
    contract_address,
    genesis_validators_root,
    genesis_time,
    expose_public,
    chain_id,
    clients_enabled,
    debug_mode,
    minimal,
    jaeger
):
    public_ports = {}
    if expose_public:
        public_ports["diva_w3s"] = PortSpec(
            number=1234, transport_protocol="TCP", wait=None
        )
        public_ports["diva_api"] = PortSpec(
            number=constants.DIVA_API, transport_protocol="TCP", wait=None
        )
        public_ports["diva_p2p"] = PortSpec(
            number=constants.DIVA_P2P, transport_protocol="TCP", wait=None
        )
    contracts = plan.upload_files("./config/contracts.toml")

    cmd = [
        "--db=/var/diva/config/diva.db",
        "--w3s-address=0.0.0.0",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--tracing=true",
        "--bootnode-address=",
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--genesis-fork-version=0x10000038",
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id={0}".format(chain_id),
        "--genesis-time={0}".format(genesis_time),
        "--enable-coordinator",
    ]
    if minimal:
        cmd.append("--slot-duration=6")
        cmd.append("--slots-per-epoch=8")

    if clients_enabled:
        cmd.append("--execution-client-url={0}".format(el_url))
        cmd.append("--consensus-client-url={0}".format(cl_url))
        cmd.append("--deployment-contracts-config-file=/var/diva/params/contracts.toml")

    result = plan.add_service(
        name=constants.DIVA_BOOTNODE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SERVER_IMAGE,
            cmd=cmd,
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                "OTEL_EXPORTER_OTLP_ENDPOINT": jaeger,
            },
            ports={
                "p2p-port": PortSpec(number=5050, transport_protocol="TCP", wait=None),
                "w3s-port": PortSpec(number=9000, transport_protocol="TCP", wait=None),
                "api-port": PortSpec(number=30000, transport_protocol="TCP"),
            },
            min_cpu=200,
            max_cpu=1000,
            files={
                "/var/diva": Directory(
                    persistent_key="diva-db-{0}".format(constants.DIVA_BOOTNODE_NAME)
                ),
                "/var/diva/params": contracts
            },
            public_ports=public_ports,
        ),
    )

    return result, "http://{0}:{1}".format(result.name, constants.DIVA_API)


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
    chain_id,
    clients_enabled,
    debug_mode,
    minimal,
    jaeger,
):

    ports={
            "p2p-port": PortSpec(number=5050, transport_protocol="TCP", wait=None),
            "w3s-port": PortSpec(number=9000, transport_protocol="TCP", wait=None),
            "api-port": PortSpec(number=30000, transport_protocol="TCP"),
            }



    cmd = [
        "--db=/var/diva/config/diva.db",
        "--w3s-address=0.0.0.0",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--tracing=true",
        "--bootnode-address=/ip4/{0}/tcp/5050/p2p/{1}".format(
            bootnode_ip_address, bootnode_peer_id
        ),
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--genesis-fork-version=0x10000038",
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id={0}".format(chain_id),
        "--genesis-time={0}".format(genesis_time),
    ]
    if clients_enabled:
        cmd.append("--execution-client-url={0}".format(el_url))
        cmd.append("--consensus-client-url={0}".format(cl_url))
        cmd.append("--deployment-contracts-config-file=/var/diva/params/contracts.toml")

    if minimal:
        cmd.append("--slot-duration=6")
        cmd.append("--slots-per-epoch=8")


    if verify_fee_recipient:
        cmd.append("--verify-fee-recipient")

    contracts = plan.upload_files("./config/contracts.toml")
    result = plan.add_service(
        name=diva_node_name,
        config=ServiceConfig(
            image=constants.DIVA_SERVER_IMAGE,
            cmd=cmd,
            node_selectors={"diva_node": diva_node_name},
            env_vars={
                "DIVA_VAULT_PASSWORD": constants.DIVA_VAULT_PASSWORD,
                "OTEL_EXPORTER_OTLP_ENDPOINT": jaeger,
            },
            ports={
                "p2p-port": PortSpec(number=5050, transport_protocol="TCP", wait=None),
                "w3s-port": PortSpec(number=9000, transport_protocol="TCP", wait=None),
                "api-port": PortSpec(number=30000, transport_protocol="TCP"),
                #"debugger": PortSpec(number=40000, transport_protocol="TCP"),
            },
            files={
                "/var/diva": Directory(
                    persistent_key="diva-db-{0}".format(diva_node_name)
                ),
                "/var/diva/params": contracts
            },
        ),
    )

    return (
        result,
        "http://{0}:30000".format(result.name),
        "http://{0}:9000".format(result.name),
    )
