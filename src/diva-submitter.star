constants = import_module("./constants.star")


def init(plan, el_url,coord_dkg_url,minimal,prover):
    timeFrameDuration = 12*32*constants.DEFAULT_EPOCHS_PER_TIMEFRAME
    if minimal:
        timeFrameDuration = 6*8*constants.DEFAULT_EPOCHS_PER_TIMEFRAME
    
    plan.add_service(
        name=constants.DIVA_SUBMITTER_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_IMAGE,
            cmd=["node scripts/testnet/submitterDKG_new.js  {0} {1} {2} {3} {4} {5} {6}".format(
                     (coord_dkg_url+"/api/v1/coordinator/dkgs"),el_url, prover, constants.SUBMITTER_PRIVATE_KEY , timeFrameDuration, constants.DIVA_API_KEY, constants.DEPLOYER_ADDRESS
                )
            ],
        ),
    )

def propose(plan, diva_url, ec_rpc):
    name = "proposer"
    script = plan.upload_files("./config/submitter_keystore_prop_1.json")
    files = {
        "/usr/local/bin/": script,
    }

    plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_CLI,
            entrypoint=["/bin/sh", "-c", "while true; do submitter propose --contract {0} --execution-client-url {1} --keystore {2} --keystore-password {3}; sleep 3600; done & tail -f /dev/null".format(constants.VALIDATOR_MANAGER_ADDRESS, diva_url, "keystore.json", "diva")],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY,"DIVA_SERVER_URL": diva_url},
            files=files
        ),
    )
    plan.print(constants.VALIDATOR_MANAGER_ADDRESS)
    plan.print(ec_rpc)
    plan.print(diva_url)
    plan.print(constants.DIVA_API_KEY)

def register(plan, diva_url, ec_rpc):
    name = "proposer"
    script = plan.upload_files("./config/submitter_keystore_register_1")
    files = {
        "/usr/local/bin/": script,
    }

    plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_CLI,
            entrypoint=["/bin/sh", "-c", "while true; do submitter propose --contract {0} --execution-client-url {1} --keystore {2} --keystore-password {3}; sleep 3600; done & tail -f /dev/null".format(constants.VALIDATOR_MANAGER_ADDRESS, diva_url, "keystore.json", "diva")],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY,"DIVA_SERVER_URL": diva_url},
            files=files
        ),
    )

def activate(plan, diva_url, ec_rpc):
    name = "proposer"
    script = plan.upload_files("./config/submitter_activate_1")
    files = {
        "/usr/local/bin/": script,
    }

    plan.add_service(
        name=name,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_CLI,
            entrypoint=["/bin/sh", "-c", "while true; do submitter propose --contract {0} --execution-client-url {1} --keystore {2} --keystore-password {3}; sleep 3600; done & tail -f /dev/null".format(constants.VALIDATOR_MANAGER_ADDRESS, diva_url, "keystore.json", "diva")],
            env_vars={"DIVA_API_KEY": constants.DIVA_API_KEY,"DIVA_SERVER_URL": diva_url},
            files=files
        ),
    )        
