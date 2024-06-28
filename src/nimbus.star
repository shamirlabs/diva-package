constants = import_module("./constants.star")

def launch(plan, service_name, web3_signer_url, beacon_url, fee_recipient, verify_fee_recipient, mev, minimal):
    
    image= constants.NIMBUS_IMAGE
    interval="360"
    if minimal:
        image=constants.NIMBUS_IMAGE_MINIMAL
        interval="120"

    cmd=[
        "--doppelganger-detection=false",
        "--non-interactive",
        "--web3-signer-update-interval={0}".format(interval),
        "--beacon-node={0}".format(beacon_url),
        "--suggested-fee-recipient={0}".format(fee_recipient),
        "--graffiti={0}".format(service_name),
    ]

    if verify_fee_recipient:
        cmd.append("--verifying-web3-signer-url={0}".format(web3_signer_url))
        cmd.append("--proven-block-property=.execution_payload.fee_recipient")
    else:
        cmd.append("--web3-signer-url={0}".format(web3_signer_url))


    config=ServiceConfig(
        image=image,
        cmd=cmd,
    )
    return config
