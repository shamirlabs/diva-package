constants = import_module("./constants.star")


def diva_input_parser(plan, input_args):
    total_val = 0
    total_part = 0
    diva_eth_nodes = 0
    diva_eth_start_index = 0
    diva_eth_start_found = 0
    network_params = input_args["network_params"]
    total_val_clients=0
    if "participants" in input_args:
        for participant in input_args["participants"]:
            if "validator_count" in participant:
                nodes_client= participant["count"] if ( "count" in participant) else 1
                total_val_clients += (participant["validator_count"] * nodes_client)
                if participant["validator_count"] == 0:
                    diva_eth_nodes += participant["count"]
                    diva_eth_start_found = 1
            if diva_eth_start_found == 0:
                diva_eth_start_index += 1
            if  "preset" in network_params:
                participant["cl_image"] = ""
                


    input_args["diva_eth_start_index"] = diva_eth_start_index
    input_args["diva_eth_nodes"] = diva_eth_nodes
    

    if "preregistered_validator_count" in network_params :
        if input_args["network_params"]["preregistered_validator_count"] == -1:
            if "network_params" in input_args:
                network_params["preregistered_validator_count"] = (
                    total_val_clients + input_args["diva_params"]["diva_validators"]
                )

    diva_validators = input_args["diva_params"]["diva_validators"]
    diva_nodes = input_args["diva_params"]["diva_nodes"]
    if "genesis_delay" in input_args and ["network_params"]["genesis_delay"] == -1:
        network_params["genesis_delay"] = int(
            12 + total_part * 1.1 + diva_validators * 0.2 * diva_nodes * 0.6
        )

    return input_args
