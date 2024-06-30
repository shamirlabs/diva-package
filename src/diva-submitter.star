constants = import_module("./constants.star")


def init(plan, el_url,coord_dkg_url,minimal,prover):
    timeFrameDuration = 12*32
    if minimal:
        timeFrameDuration = 6*8
    
    plan.add_service(
        name=constants.DIVA_SUBMITTER_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_IMAGE,
            cmd=["node scripts/testnet/submitterDKG.js  {0} {1} {2} {3} {4} {5} {6}".format(
                     (coord_dkg_url+"/api/v1/coordinator/dkgs"),el_url, prover, constants.SUBMITTER_PRIVATE_KEY , timeFrameDuration, constants.DIVA_API_KEY, constants.DEPLOYER_ADDRESS
                )
            ],
        ),
    )