constants = import_module("./constants.star")


def init(plan, el_url, sender_priv,coord_url,minimal):
    timeFrameDuration = 12*32
    if minimal:
        timeFrameDuration = 6*8

    plan.add_service(
        name=constants.DIVA_SUBMITTER_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SUBMITTER_IMAGE,
            env_vars={"RPC": el_url, "SENDER_PRIV": sender_priv, "COORD_URL":coord_url,"TIMEFRAME_SEC": str(timeFrameDuration)},
        ),
    )
