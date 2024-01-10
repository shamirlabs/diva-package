ethereum_input_parser = import_module(
    "github.com/kurtosis-tech/ethereum-package/src/package_io/input_parser.star@1.2.0"
)


def default_diva_params():
    return {"nodes": 5, "threshold": 3, "validators_to_import": 1}


def default_input_args():
    network_params = ethereum_input_parser.default_network_params()
    participants = [ethereum_input_parser.default_participant()]
    diva = default_diva_params()
    return {
        "participants": participants,
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
            participants = []
            for participant in input_args["participants"]:
                new_participant = ethereum_input_parser.default_participant()
                for sub_attr, sub_value in participant.items():
                    new_participant[sub_attr] = sub_value
                plan.print(new_participant)
                for _ in range(0, new_participant["count"]):
                    participant_copy = ethereum_input_parser.deep_copy_participant(new_participant)
                    participants.append(participant_copy)
            result["participants"] = participants
            
        elif attr == "diva":
            for sub_attr in input_args["diva"]:  # TODO: improve with items
                sub_value = input_args["diva"][sub_attr]
                result["diva"][sub_attr] = sub_value

    total_participant_count = len(result["participants"]) # validator clients
    actual_num_validators = 0
    # validation of the above defaults
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
    if result["diva"]["validators_to_import"] <= 0:
        fail(
            "diva.validators_to_import is invalid: %s. Should be greater than zero"
            % (result["diva"]["validators_to_import"])
        )
    if result["diva"]["validators_to_import"] > total_participant_count:
        fail(
            "diva.validators_to_import is invalid: %s. Should be between 1 and the number of participants (%s)"
            % (result["diva"]["validators_to_import"], total_participant_count)
        )

    return result


def input_parser(plan, input_args):
    return parse_diva_params(plan,input_args)
