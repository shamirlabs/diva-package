NIMBUS_IMAGE = "statusim/nimbus-validator-client:multiarch-v23.10.1"


def launch(plan, service_name, web3_signer_url, beacon_url):
    plan.add_service(
        service_name=service_name,
        config=ServiceConfig(
            image=NIMBUS_IMAGE,
            cmd=[
                "--doppelganger-detection=false",
                "--non-interactive",
                "--verifying-web3-signer-url={0}".format(web3_signer_url),
                "--web3-signer-url={0}".format(web3_signer_url),
                "--proven-block-property=.execution_payload.fee_recipient",
                "--web3-signer-update-interval=360",
                "--beacon-node={0}".format(beacon_url),
            ],
        ),
    )
