constants = import_module("./constants.star")

genesis = import_module("./genesis.star")


def start_node(plan, start_index_val, stop_index_val):
    cmd = [
        "--http-host-allowlist=*",
        "eth2",
        "--slashing-protection-enabled=false",
        "--network=/tmp/genesis/config.yaml",
        "--keystores-path=/tmp/node-0/teku-keys",
        "--keystores-passwords-path=/tmp/node-0/teku-secrets",
    ]

    files = {}

    files["/tmp/genesis"] = "el_cl_genesis_data"

    files["/tmp/node-0"] = genesis.generate_validator_keystores(
        plan, start_index_val, stop_index_val
    )

    result = plan.add_service(
        name="diva-node-1",
        config=ServiceConfig(
            user=User(uid=0, gid=0),
            image=constants.W3S_CONSENSYS,
            cmd=cmd,
            ports={
                "w3s-port": PortSpec(number=9000, transport_protocol="TCP", wait=None)
            },
            files=files,
        ),
    )

    return "http://{0}:9000".format(result.name)
