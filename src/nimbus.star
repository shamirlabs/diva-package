NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-v23.10.1"


def launch(plan, service_name, web3_signer_url, beacon_url, fee_recipient, verify_fee_recipient):

    cmd=[
        "--doppelganger-detection=false",
        "--non-interactive",
        "--web3-signer-update-interval=360",
        "--beacon-node={0}".format(beacon_url),
        "--suggested-fee-recipient={0}".format(fee_recipient),
        "--graffiti={0}".format(service_name),        
    ]

    if verify_fee_recipient:
        cmd.append("--verifying-web3-signer-url={0}".format(web3_signer_url))
        cmd.append("--proven-block-property=.execution_payload.fee_recipient")
    else:
        cmd.append("--web3-signer-url={0}".format(web3_signer_url))



    plan.add_service(
        name=service_name,
        config=ServiceConfig(
            image=NIMBUS_IMAGE,
            cmd=cmd,
        )
    )
