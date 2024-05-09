NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-latest"


def launch(
    plan,
    service_name,
    web3_signer_url,
    beacon_url,
    fee_recipient,
    verify_fee_recipient,
    mev,
):
    cmd = [
        "--doppelganger-detection=false",
        "--non-interactive",
        "--web3-signer-update-interval=3",
        "--beacon-node={0}".format(beacon_url),
        "--suggested-fee-recipient={0}".format(fee_recipient),
        "--graffiti={0}".format(service_name),
        # "--log-level=TRACE"
    ]

    if verify_fee_recipient:
        cmd.append("--verifying-web3-signer-url={0}".format(web3_signer_url))
        cmd.append("--proven-block-property=.execution_payload.fee_recipient")
    else:
        cmd.append("--web3-signer-url={0}".format(web3_signer_url))

    if mev:
        cmd.append("--payload-builder=true")

    plan.add_service(
        name=service_name,
        config=ServiceConfig(
            image=NIMBUS_IMAGE,
            cmd=cmd,
        ),
    )
