constants = import_module("./constants.star")


def init(plan, el_url, deployer_private_key,coord_dkg_url,minimal, api_key):
    timeFrameDuration = 12*32
    if minimal:
        timeFrameDuration = 6*8
    
    plan.add_service(
        name=constants.DIVA_SUBMITTER_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_IMAGE,
            env_vars={"CUSTOM_URL": el_url, "CUSTOM_PRIVATE_KEY": deployer_private_key},
            cmd=["node scripts/testnet/submitterDKG.js  {0} {1} {2} {3} {4}".format(
                     (coord_dkg_url+"/api/v1/coordinator/dkgs"),el_url, deployer_private_key, timeFrameDuration, api_key
                )
            ],
        ),
    )
    
            