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
    if 'network_params' in input_args:
        network_params = input_args['network_params']
        if 'preregistered_validator_count' in network_params:
            network_params['preregistered_validator_count'] = constants.PARTICIPANTS_VALIDATORS + constants.DIVA_VALIDATORS

    total_val = 0
    if 'participants' in input_args:
        for participant in input_args['participants']:
            if 'validator_count' in participant:
                total_val += participant['validator_count']
    
    #if total_val != constants.PARTICIPANTS_VALIDATORS:
        #fail("The %s validators has not been correctly assigned to participants in paramas.yaml" % (constants.PARTICIPANTS_VALIDATORS))
    
    return input_args
