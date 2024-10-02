constants = import_module("./constants.star")


def launch(
    plan,
    service_name,
    web3_signer_url,
    beacon_url,
    fee_recipient,
    verify_fee_recipient,
    mev,
    minimal
):
    files = {}

    files["/network-configs"] = "el_cl_genesis_data"

    cmd = [
        "validator",
        "--logLevel=info",
        "--paramsFile=/network-configs/config.yaml",
        "--beaconNodes={0}".format(beacon_url),
        "--suggestedFeeRecipient={0}".format(fee_recipient),
        "--graffiti={0}".format(service_name),
        "--useProduceBlockV3",
        "--externalSigner.url={0}".format(web3_signer_url),
        "--externalSigner.fetch",

    ]
    extra_env_vars={}
    if minimal:
        extra_env_vars["LODESTAR_PRESET"] = "minimal"

    config=ServiceConfig(
        files=files,
        image="chainsafe/lodestar:latest",
        cmd=cmd,
        env_vars=extra_env_vars
    )
    return config
