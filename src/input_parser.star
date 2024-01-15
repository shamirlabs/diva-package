ethereum_input_parser = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/package_io/input_parser.star@d5bf45150dc09432bb84b366d2deda8c6036afea"
)


def default_diva_validator():
    validator = ethereum_input_parser.default_participant()
    validator["el_client_type"] = "geth"
    validator["cl_client_type"] = "nimbus"
    validator["cl_split_mode_enabled"] = True
    return validator


def default_diva_params():
    return {
        "nodes": 5,
        "threshold": 3,
        "validator_count": 20,
        "verify_fee_recipient": True,
    }


def default_input_args():
    network_params = ethereum_input_parser.default_network_params()
    diva = default_diva_params()
    return {
        "network_params": network_params,
        "diva": diva,
    }


def parse_diva_params(plan, input_args):
    result = default_input_args()
    for attr in input_args:
        value = input_args[attr]
        # if its insterted we use the value inserted
        if attr == "network_params":
            for sub_attr in input_args["network_params"]:
                sub_value = input_args["network_params"][sub_attr]
                result["network_params"][sub_attr] = sub_value
        elif attr == "participants":
            participants = [default_diva_validator()]
            for participant in input_args["participants"]:
                new_participant = ethereum_input_parser.default_participant()
                for sub_attr, sub_value in participant.items():
                    new_participant[sub_attr] = sub_value
                for _ in range(0, new_participant["count"]):
                    participant_copy = ethereum_input_parser.deep_copy_participant(
                        new_participant
                    )
                    participants.append(participant_copy)
            result["participants"] = participants

        elif attr == "diva":
            for sub_attr in input_args["diva"]:  # TODO: improve with items
                sub_value = input_args["diva"][sub_attr]
                result["diva"][sub_attr] = sub_value

    plan.print(result["participants"])
    result["participants"][0]["validator_count"] = result["diva"]["validator_count"]

    actual_num_validators = 0
    for index, participant in enumerate(result["participants"]):
        validator_count = participant["validator_count"]
        if validator_count == None:
            default_validator_count = result["network_params"][
                "num_validator_keys_per_node"
            ]
            participant["validator_count"] = default_validator_count

        actual_num_validators += participant["validator_count"]

    if result["diva"]["nodes"] <= 0:
        fail(
            "diva.nodes is invalid: %s. Should be greater than zero"
            % (result["diva"]["nodes"])
        )
    if result["diva"]["threshold"] <= 0:
        fail(
            "diva.threshold is invalid: %s. Should be greater than zero"
            % (result["diva"]["threshold"])
        )
    if result["diva"]["threshold"] > result["diva"]["nodes"]:
        fail(
            "diva.threshold is invalid: %s. Should be between 1 and diva.nodes (%s)"
            % (result["diva"]["threshold"], result["diva"]["nodes"])
        )
    if result["diva"]["validator_count"] <= 0:
        fail(
            "diva.diva_validators is invalid: %s. Should be greater than zero"
            % (result["diva"]["validators_to_import"])
        )

    return result


def input_parser(plan, input_args):
    return parse_diva_params(plan, input_args)
