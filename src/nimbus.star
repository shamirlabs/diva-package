NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-v23.10.1"


def launch(plan, service_name, web3_signer_url, beacon_url, fee_recipient):
    # TODO make this persistent
    plan.add_service(
        name=service_name,
        config=ServiceConfig(
            image=NIMBUS_IMAGE,
            cmd=[
                "--doppelganger-detection=false",
                "--non-interactive",
                "--verifying-web3-signer-url={0}".format(web3_signer_url),
                #"--web3-signer-url={0}".format(web3_signer_url),
                "--proven-block-property=.execution_payload.fee_recipient",
                "--web3-signer-update-interval=360",
                "--beacon-node={0}".format(beacon_url),
                "--suggested-fee-recipient={0}".format(fee_recipient),
            ],
        ),
    )
