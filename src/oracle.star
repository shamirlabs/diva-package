constants = import_module("./constants.star")


def start_oracle(
    plan,
    name,
    el_url,
    cl_url,
    chain_id,
    minimal,
    genesis_time,
    gvr,
    oracle_tools,
    oracle_balance_private_key,
    oracle_prover_private_key
    ):


    env_vars = {
                "CONSENSUS_CLIENT_ADDRESS": cl_url,
                "EXECUTION_CLIENT_ADDRESS": el_url,
                "ACCOUNTING_MANAGER_CONTRACT_ADDRESS": constants.ACCOUNTING_MANAGER_ADDRESS,
                "VALIDATOR_MANAGER_CONTRACT_ADDRESS": constants.VALIDATOR_MANAGER_ADDRESS,
                "PERFORMANCE_PROVER_CONTRACT_ADDRESS": constants.PERFORMANCE_PROVER_ADDRESS,
                "DIVA_ETHER_TOKEN_CONTRACT_ADDRESS": constants.DIVA_ETHER_TOKEN_ADDRESS,
                "BALANCE_VERIFIER_CONTRACT_ADDRESS": constants.BALANCE_VERIFIER_ADDRESS,
                "COLLATERAL_CURVE_CONTRACT_ADDRESS": constants.COLLATERAL_CURVE_ADDRESS,

                "EPOCH_START": "0",
                "EPOCHS_RANGE_LIMIT": "2",  # 225 epochs : 1 day
                "KEY_SHARES_PER_VALIDATOR": "5",
                "RETRY_BACKOFF_TIME": "0",
                "RUN_REWARDS_MERKLETREE_DAY": "1",  # day of the month
                "MAX_CONCURRENT_JOBS_FETCH_AND_STORE_EPOCHS": "2",
                "MAX_RETRIES_FETCH_AND_STORE_EPOCHS": "3",
                "MAX_CONCURRENT_JOB_FETCHING_ATTESTED_EPOCHS": "2",
                "MAX_EPOCHS_PER_QUERY": "5",
                "MAX_RETRIES_FETCHING_ATTESTED_EPOCHS": "3",
                "DB_USER":"example-database",
                "DB_PASSWORD":"example-database-password", 
                "DB_NAME":"example-database",
                "DB_PORT":"5432",
                "DB_HOST":"{0}-db".format(name),
                "NUM_EPOCHS_VOLUNTARY_EXIT":"1575", # 1 week of epochs (225 * 7)
                "API_ADDRESS":"",
                "API_PORT":"4000",
                "DIVA_SCHEDULER_INTERVAL_IN_SEC":"86400", # 24 hours in seconds  = 86400

                # Used in (Dendreth Backup (TVL)) Submit Report
                "ORACLE_BALANCE_VERIFIER_PRIVATE_KEY":  oracle_balance_private_key,
                # Used in Vote Operators Rewards / Vote Voluntary Exit
                "ORACLE_PERF_PROVER_PRIVATE_KEY":oracle_prover_private_key    
            }


    if minimal:
        env_vars.update({
            "SLOTS_PER_EPOCH": "8",
            "SLOT_DURATION": "6",
            "GENESIS_TIME": "{0}".format(genesis_time),
            "FORK_VERSION_HEX": "0x10000038",
            "FORK_VERSION": "0x10000038",
            "GVR":  "{0}".format(gvr),
            "DEPOSIT_CONTRACT_HEX":"0x4242424242424242424242424242424242424242",
            "BEACON_STATE_SPEC":"minimal",
            "CHAIN":"custom",
            "CHAIN_ID": "{0}".format(chain_id),
            })

    else:
        env_vars.update({
            "SLOTS_PER_EPOCH": "32",
            "SLOT_DURATION": "12",
            "GENESIS_TIME": "{0}".format(genesis_time),
            "FORK_VERSION_HEX": "0x10000038",
            "GVR":  "{0}".format(gvr),
            "DEPOSIT_CONTRACT_HEX":"0x4242424242424242424242424242424242424242",
            "BEACON_STATE_SPEC":"mainnet",
            "CHAIN":"custom",
            "CHAIN_ID": "{0}".format(chain_id),
            })        
    plan.add_service(
        name="{0}-db".format(name),
        config=ServiceConfig(
            image="postgres:latest",
            cmd=["-c", "shared_buffers=3GB", "-c", "max_connections=300"],
            env_vars={
                "POSTGRES_DB": "example-database",
                "POSTGRES_USER": "example-database",
                "POSTGRES_PASSWORD": "example-database-password",
            },
            ports={
                "postgres": PortSpec(number=5432, transport_protocol="TCP")
            },
            #files={
            #    "/var/lib/postgresql/data": Directory(persistent_key="pg-data")
            #},
            min_cpu=200,
            max_cpu=1000
        )
    )

    oracle= plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_ORACLE_IMAGE,  
            env_vars = env_vars,
            ports={
                "api": PortSpec(number=4000, transport_protocol="TCP")
            },            
        ),
    )



    if oracle_tools:
        plan.add_service(
            name="{0}-pg-admin".format(name),
            config=ServiceConfig(
                image="dpage/pgadmin4:latest",
                env_vars={
                    "PGADMIN_DEFAULT_EMAIL": "admin@example.com",
                    "PGADMIN_DEFAULT_PASSWORD": "admin_password",
                },
                ports={
                    "admin": PortSpec(number=80, transport_protocol="TCP")
                },
                min_cpu=100,
                max_cpu=500
            )
        )   
        plan.add_service(
            name="{0}-jaeger".format(name),
            config=ServiceConfig(
                image="jaegertracing/all-in-one:latest",
                env_vars={
                    "COLLECTOR_ZIPKIN_HOST_PORT": ":9411",
                },
                ports={
                    "6831": PortSpec(number=6831, transport_protocol="UDP"),
                    "6832": PortSpec(number=6832, transport_protocol="UDP"),
                    "5778": PortSpec(number=5778, transport_protocol="TCP"),
                    "16686": PortSpec(number=16686, transport_protocol="TCP"),
                    "4317": PortSpec(number=4317, transport_protocol="TCP"),
                    "4318": PortSpec(number=4318, transport_protocol="TCP"),
                    "14250": PortSpec(number=14250, transport_protocol="TCP"),
                    "14268": PortSpec(number=14268, transport_protocol="TCP"),
                    "14269": PortSpec(number=14269, transport_protocol="TCP"),
                    "9411": PortSpec(number=9411, transport_protocol="TCP"),
                },
                min_cpu=200,
                max_cpu=1000
            )
        )
        plan.add_service(
            name="{0}-grafana".format(name),
            config=ServiceConfig(
                image="grafana/grafana:10.2.5",
                user="root",
                env_vars={},
                ports={
                    "3000": PortSpec(number=3000, transport_protocol="TCP")
                },
                files={
                    "/var/lib/grafana": Directory(persistent_key="grafana-storage")
                },
                min_cpu=200,
                max_cpu=1000,
                restart_policy="unless-stopped"
            ),
        )
        plan.add_service(
            name="{0}-loki".format(name),
            config=ServiceConfig(
                image="grafana/loki:2.9.2",
                cmd=["-config.file=/etc/loki/local-config.yaml"],
                env_vars={
                    "JAEGER_AGENT_HOST": "jaeger",
                    "JAEGER_AGENT_PORT": "6831",
                    "JAEGER_SAMPLER_TYPE": "const",
                    "JAEGER_SAMPLER_PARAM": "1",
                },
                ports={
                    "3100": PortSpec(number=3100, transport_protocol="TCP")
                },
                min_cpu=200,
                max_cpu=1000
            )
        )  
        
    return oracle
