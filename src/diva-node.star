constants = import_module("./constants.star")

diva_min_cpu=300
diva_max_cpu=4000 #4 cores
diva_min_mem=512
diva_max_mem=16384


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
    jaeger,
    public_bootnodes
):
    public_ports = {}
    if expose_public:
        public_ports["w3s-port"] = PortSpec(
            number=constants.DIVA_W3S, transport_protocol="TCP", wait=None
        )
        public_ports["api-port"] = PortSpec(
            number=constants.DIVA_API, transport_protocol="TCP", wait=None
        )
        public_ports["p2p-port"] = PortSpec(
            number=constants.DIVA_P2P, transport_protocol="TCP", wait=None
        )
    contracts = plan.upload_files("./config/contracts.toml")

    cmd = [
        "--db=/var/diva/config/diva.db",
        "--w3s-address=0.0.0.0",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--genesis-fork-version={0}".format(constants.GENESIS_FORK_VERSION),
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id={0}".format(chain_id),
        "--genesis-time={0}".format(genesis_time),
        "--enable-coordinator",
        "--capella-fork-version={0}".format(constants.CAPELLA_FORK_VERSION)
    ]
    if public_bootnodes:
        cmd.append("--bootnode-address=/ip4/3.64.13.227/tcp/5050/p2p/16Uiu2HAkvgZRujNTJ6aHT5uvMNac8iyESxu2uRP8f5jrtKfHiRVU,/ip4/3.79.182.51/tcp/5050/p2p/16Uiu2HAm3tzgHMneLBWKy1BM3r6UYXzR5NZP2FmQdmx8XA29KkKS,/ip4/95.217.218.85/tcp/5050/p2p/16Uiu2HAm1bPsRd7oKqEc1xuYQsqpECZGVW7qothpvSesV38yRkXW,/ip4/37.27.10.207/tcp/5050/p2p/16Uiu2HAmEKRQyRHJwLvaWnnt4jsDDzim3X9wBDixqGYZLJQvfojt")
    else:
        cmd.append("--bootnode-address=")

    if jaeger:
        cmd.append("--tracing=true")

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
            files={
                "/var/diva": Directory(
                    persistent_key="diva-db-{0}".format(constants.DIVA_BOOTNODE_NAME)
                ),
                "/var/diva/params": contracts
            },
            public_ports=public_ports,
            min_cpu=diva_min_cpu,
            max_cpu=diva_max_cpu,
            min_memory=diva_min_mem,
            max_memory=diva_max_mem,
            node_selectors={"diva_node": "bootnode"},
        ),
    )

    return result, "http://{0}:{1}".format(result.name, constants.DIVA_API)


def start_node_config(
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
    public_bootnodes,
    index
):
    w3s=constants.DIVA_W3S+index+1
    api=constants.DIVA_API+index+1
    p2p=constants.DIVA_P2P+index+1
    
    public_ports={
        "p2p-port": PortSpec(number=p2p, transport_protocol="TCP", wait=None),
        "w3s-port": PortSpec(number=w3s, transport_protocol="TCP", wait=None),
        "api-port": PortSpec(number=api, transport_protocol="TCP",wait=None),
    }

    cmd = [
        "--db=/var/diva/config/diva.db",
        "--w3s-address=0.0.0.0",
        "--log-level=debug",
        "--swagger-ui-enabled",
        "--master-key={0}".format(constants.DIVA_API_KEY),
        "--genesis-fork-version={0}".format(constants.GENESIS_FORK_VERSION),
        "--gvr={0}".format(genesis_validators_root),
        "--deposit-contract=0x4242424242424242424242424242424242424242",
        "--chain-id={0}".format(chain_id),
        "--genesis-time={0}".format(genesis_time),
        "--capella-fork-version={0}".format(constants.CAPELLA_FORK_VERSION)
    ]

    if public_bootnodes:
        cmd.append("--bootnode-address=/ip4/{0}/tcp/5050/p2p/{1}{2}".format(
            bootnode_ip_address, bootnode_peer_id,",/ip4/3.64.13.227/tcp/5050/p2p/16Uiu2HAkvgZRujNTJ6aHT5uvMNac8iyESxu2uRP8f5jrtKfHiRVU,/ip4/3.79.182.51/tcp/5050/p2p/16Uiu2HAm3tzgHMneLBWKy1BM3r6UYXzR5NZP2FmQdmx8XA29KkKS,/ip4/95.217.218.85/tcp/5050/p2p/16Uiu2HAm1bPsRd7oKqEc1xuYQsqpECZGVW7qothpvSesV38yRkXW,/ip4/37.27.10.207/tcp/5050/p2p/16Uiu2HAmEKRQyRHJwLvaWnnt4jsDDzim3X9wBDixqGYZLJQvfojt"
        ))
    else:
        cmd.append("--bootnode-address=/ip4/{0}/tcp/5050/p2p/{1}".format(
            bootnode_ip_address, bootnode_peer_id))

    if clients_enabled:
        cmd.append("--execution-client-url={0}".format(el_url))
        cmd.append("--consensus-client-url={0}".format(cl_url))
        cmd.append("--deployment-contracts-config-file=/var/diva/params/contracts.toml")

    if minimal:
        cmd.append("--slot-duration=6")
        cmd.append("--slots-per-epoch=8")

    if jaeger:
        cmd.append("--tracing=true")

    if verify_fee_recipient:
        cmd.append("--verify-fee-recipient")

    contracts = plan.upload_files("./config/contracts.toml")
  
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
        public_ports=public_ports,
        files={
            "/var/diva": Directory(
                persistent_key="diva-db-{0}".format(diva_node_name)
            ),
            "/var/diva/params": contracts
        },
        min_cpu=diva_min_cpu,
        max_cpu=diva_max_cpu,
        min_memory=diva_min_mem,
        max_memory=diva_max_mem,
    )
    
    return (
        config
    )


def start_nodes(plan, nodes_config):
    all_services = plan.add_services(
        nodes_config,
        description = "adding diva-nodes in pararell"
    )
    return (
        all_services
    )

