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

    files["/tmp"] = "el_cl_genesis_data"

    cmd = [
        "--accept-terms-of-use=true",
        "--chain-config-file=/tmp/config.yaml",
        "--suggested-fee-recipient={0}".format(fee_recipient),
        "--disable-monitoring=true",
        "--graffiti={0}".format(service_name),
        "--beacon-rpc-provider={0}".format(beacon_url),
        "--beacon-rest-api-provider={0}".format(beacon_url),
        "--validators-external-signer-public-keys={0}/api/v1/eth2/publicKeys".format(
            web3_signer_url
        ),
        "--validators-external-signer-url={0}".format(web3_signer_url),
        "--enable-beacon-rest-api",
    ]
    image=constants.PRYSM_IMAGE
    if minimal:
        image= constants.PRYSM_IMAGE_MIN
    plan.add_service(
        name=service_name,
        config=ServiceConfig(
            files=files,
            image=image,
            cmd=cmd,
        ),
    )
