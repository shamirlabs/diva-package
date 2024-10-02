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
        "validator-client",
        "--network=/network-configs/config.yaml",
        "--beacon-node-api-endpoint={0}".format(beacon_url),
        "--validators-proposer-default-fee-recipient={0}".format(fee_recipient),
        "--validators-graffiti={0}".format(service_name),
        #"--eth1-endpoint=http://geth:8545",
        "--validators-external-signer-public-keys=0xa99a...e44c,0xb89b...4a0b",
        "--validators-external-signer-url={0}".format(web3_signer_url),
    ]
    image=constants.TEKU_IMAGE
    
    if minimal:
        image= constants.TEKU_IMAGE_MIN
    

    config=ServiceConfig(
        files=files,
        image=image,
        cmd=cmd,
    )
    return config
