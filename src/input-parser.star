constants = import_module("./constants.star")

DEFAULT_ADDITIONAL_SERVICES = [
    "tx_spammer",
    "blob_spammer",
    "el_forkmon",
    "beacon_metrics_gazer",
    "dora",
    "prometheus_grafana",
]


def diva_input_parser(plan, input_args):
    total_val = 0
    total_part = 0
    if "participants" in input_args:
        for participant in input_args["participants"]:
            if "validator_count" in participant:
                total_val += participant["validator_count"]
        total_part = total_part + 1

    if "network_params" in input_args:
        network_params = input_args["network_params"]
        if "preregistered_validator_count" in network_params:
            network_params["preregistered_validator_count"] = (
                total_val + input_args["diva_params"]["diva_validators"]
            )

    input_args["eth_validator_count"] = total_val
    diva_validators = input_args["diva_params"]["diva_validators"]
    diva_nodes = input_args["diva_params"]["diva_nodes"]
    if input_args["network_params"]["genesis_delay"] == -1:
        network_params["genesis_delay"] = int(
            12 + total_part * 1.1 + diva_validators * 0.2 * diva_nodes * 0.6
        )

    return input_args
