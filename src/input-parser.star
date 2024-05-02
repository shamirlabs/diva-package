constants = import_module("./constants.star")

DEFAULT_ADDITIONAL_SERVICES = [
    "tx_spammer",
    "blob_spammer",
    "el_forkmon",
    "beacon_metrics_gazer",
    "dora",
    "prometheus_grafana",
]

ATTR_TO_BE_SKIPPED_AT_ROOT = (
    "network_params",
    "participants",
    "mev_params",
    "assertoor_params",
    "goomy_blob_params",
    "tx_spammer_params",
    "custom_flood_params",
    "xatu_sentry_params",
)


def diva_input_parser(plan, input_args):
    result = parse_network_params(input_args)

    result["mev_type"] = None
    result["mev_params"] = None
    if result["network_params"]["network"] == "kurtosis":
        result["additional_services"] = DEFAULT_ADDITIONAL_SERVICES
    else:
        result["additional_services"] = []
    result["grafana_additional_dashboards"] = []
    result["persistent"] = False
    diva_val_start, diva_val_stop = 0,0
    for attr in input_args:
        value = input_args[attr]
        # if its inserted we use the value inserted
        if attr not in ATTR_TO_BE_SKIPPED_AT_ROOT and attr in input_args:
            result[attr] = value
        plan.print(attr)
    aux= diva_val_index(plan,result)
    if aux != None:
        diva_val_start, diva_val_stop = aux
    else:
        plan.print("diva_val_index returned None")
    diva_params= struct(
                    verify_fee_recipient=result["diva_params"]["protocol_features"]["verify_fee_recipient"],
                    deploy_eth=result["diva_params"]["deployment"]["deploy_eth"],
                    deploy_diva_sc=result["diva_params"]["deployment"]["deploy_diva_sc"],
                    deploy_diva_coord_boot=result["diva_params"]["deployment"]["deploy_diva_coord_boot"],
                    deploy_diva=result["diva_params"]["deployment"]["deploy_diva"],
                    charge_pre_genesis_keys=result["diva_params"]["deployment"]["options"]["charge_pre_genesis_keys"],
                    deploy_operator_ui=result["diva_params"]["deployment"]["deploy_operator_ui"],
                    private_pools_only=result["diva_params"]["protocol_features"]["private_pools_only"],
                    public_ports=result["diva_params"]["deployment"]["options"]["public_ports"],
                    diva_val_start=diva_val_start,
                    diva_val_stop=diva_val_stop
                )

    
    sol =struct(
        participants=[
            struct(
                el_type=participant["el_type"],
                el_image=participant["el_image"],
                el_log_level=participant["el_log_level"],
                el_volume_size=participant["el_volume_size"],
                el_extra_params=participant["el_extra_params"],
                el_extra_env_vars=participant["el_extra_env_vars"],
                el_extra_labels=participant["el_extra_labels"],
                cl_type=participant["cl_type"],
                cl_image=participant["cl_image"],
                cl_log_level=participant["cl_log_level"],
                cl_volume_size=participant["cl_volume_size"],
                cl_split_mode_enabled=participant["cl_split_mode_enabled"],
                cl_extra_params=participant["cl_extra_params"],
                cl_extra_labels=participant["cl_extra_labels"],
                vc_extra_params=participant["vc_extra_params"],
                vc_extra_labels=participant["vc_extra_labels"],
                builder_network_params=participant["builder_network_params"],
                el_min_cpu=participant["el_min_cpu"],
                el_max_cpu=participant["el_max_cpu"],
                el_min_mem=participant["el_min_mem"],
                el_max_mem=participant["el_max_mem"],
                cl_min_cpu=participant["cl_min_cpu"],
                cl_max_cpu=participant["cl_max_cpu"],
                cl_min_mem=participant["cl_min_mem"],
                cl_max_mem=participant["cl_max_mem"],
                vc_min_cpu=participant["vc_min_cpu"],
                vc_max_cpu=participant["vc_max_cpu"],
                vc_min_mem=participant["vc_min_mem"],
                vc_max_mem=participant["vc_max_mem"],
                validator_count=participant["validator_count"],
                snooper_enabled=participant["snooper_enabled"],
                count=participant["count"],
                ethereum_metrics_exporter_enabled=participant[
                    "ethereum_metrics_exporter_enabled"
                ],
                xatu_sentry_enabled=participant["xatu_sentry_enabled"],
                prometheus_config=struct(
                    scrape_interval=participant["prometheus_config"]["scrape_interval"],
                    labels=participant["prometheus_config"]["labels"],
                ),
                blobber_enabled=participant["blobber_enabled"],
                blobber_extra_params=participant["blobber_extra_params"],
            )
            for participant in result["participants"]
        ],
        network_params=struct(
            preregistered_validator_keys_mnemonic=result["network_params"][
                "preregistered_validator_keys_mnemonic"
            ],
            preregistered_validator_count=result["network_params"][
                "preregistered_validator_count"
            ],
            num_validator_keys_per_node=result["network_params"][
                "num_validator_keys_per_node"
            ],
            network_id=result["network_params"]["network_id"],
            deposit_contract_address=result["network_params"][
                "deposit_contract_address"
            ],
            seconds_per_slot=result["network_params"]["seconds_per_slot"],
            genesis_delay=result["network_params"]["genesis_delay"],
            max_churn=result["network_params"]["max_churn"],
            ejection_balance=result["network_params"]["ejection_balance"],
            eth1_follow_distance=result["network_params"]["eth1_follow_distance"],
            capella_fork_epoch=result["network_params"]["capella_fork_epoch"],
            deneb_fork_epoch=result["network_params"]["deneb_fork_epoch"],
            electra_fork_epoch=result["network_params"]["electra_fork_epoch"],
            network=result["network_params"]["network"],
        ),
        additional_services=result["additional_services"],
        wait_for_finalization=result["wait_for_finalization"],
        global_log_level=result["global_log_level"],
        mev_type=result["mev_type"],
        snooper_enabled=result["snooper_enabled"],
        ethereum_metrics_exporter_enabled=result["ethereum_metrics_exporter_enabled"],
        xatu_sentry_enabled=result["xatu_sentry_enabled"],
        parallel_keystore_generation=result["parallel_keystore_generation"],
        grafana_additional_dashboards=result["grafana_additional_dashboards"],
        disable_peer_scoring=result["disable_peer_scoring"],
        persistent=result["persistent"],
        diva_params= diva_params
    )
    return sol


def diva_val_index(plan,result):
    deploy_eth=True
    deploy_diva=True
    charge_pre_genesis_keys=True
    running_total_validator_count=0
    stop=0
    if charge_pre_genesis_keys and deploy_diva:
        if deploy_eth :
            for participant in result["participants"]:
                plan.print(participant)
                if participant["validator_count"] == 0:
                    continue
                running_total_validator_count += participant["validator_count"]
            available= result["network_params"]["preregistered_validator_count"] - int(running_total_validator_count)
            if available < constants.DIVA_VALIDATORS:
                fail("Not enough validators", available)
            if constants.DIVA_VALIDATORS== -1:
                stop= int(result["network_params"]["preregistered_validator_count"])-1
            else:
                stop= running_total_validator_count + constants.DIVA_VALIDATORS
        else:
            if constants.DIVA_VALIDATORS== -1:
                return (constants.DIVA_VAL_INDEX_START, constants.DIVA_VAL_INDEX_START+10)
            else:
                return (constants.DIVA_VAL_INDEX_START, constants.DIVA_VAL_INDEX_START+constants.DIVA_VALIDATORS)
    return (running_total_validator_count, stop)

def parse_network_params(input_args):
    result = default_input_args()
    for attr in input_args:
        value = input_args[attr]
        # if its insterted we use the value inserted
        if attr not in ATTR_TO_BE_SKIPPED_AT_ROOT and attr in input_args:
            result[attr] = value
        elif attr == "network_params":
            for sub_attr in input_args["network_params"]:
                sub_value = input_args["network_params"][sub_attr]
                result["network_params"][sub_attr] = sub_value
        elif attr == "participants":
            participants = []
            for participant in input_args["participants"]:
                new_participant = default_participant()
                for sub_attr, sub_value in participant.items():
                    # if the value is set in input we set it in participant
                    new_participant[sub_attr] = sub_value
                for _ in range(0, new_participant["count"]):
                    participant_copy = deep_copy_participant(new_participant)
                    participants.append(participant_copy)
            result["participants"] = participants

    total_participant_count = 0
    actual_num_validators = 0
    return result




def default_input_args():
    network_params = default_network_params()
    participants = [default_participant()]
    return {
        "participants": participants,
        "network_params": network_params,
        "wait_for_finalization": False,
        "global_log_level": "info",
        "snooper_enabled": False,
        "ethereum_metrics_exporter_enabled": False,
        "xatu_sentry_enabled": False,
        "parallel_keystore_generation": False,
        "disable_peer_scoring": False,
    }


def default_network_params():
    # this is temporary till we get params working
    return {
        "preregistered_validator_keys_mnemonic": "giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete",
        "preregistered_validator_count": 0,
        "num_validator_keys_per_node": 64,
        "network_id": "3151908",
        "deposit_contract_address": "0x4242424242424242424242424242424242424242",
        "seconds_per_slot": 12,
        "genesis_delay": 20,
        "max_churn": 8,
        "ejection_balance": 16000000000,
        "eth1_follow_distance": 2048,
        "capella_fork_epoch": 0,
        "deneb_fork_epoch": 500,
        "electra_fork_epoch": None,
        "network": "kurtosis",
    }


def default_participant():
    return {
        "el_type": "geth",
        "el_image": "",
        "el_log_level": "",
        "el_volume_size": 0,
        "el_extra_params": [],
        "el_extra_env_vars": {},
        "el_extra_labels": {},
        "cl_type": "lighthouse",
        "cl_image": "",
        "cl_log_level": "",
        "cl_volume_size": 0,
        "cl_split_mode_enabled": False,
        "cl_extra_params": [],
        "cl_extra_labels": {},
        "vc_extra_params": [],
        "vc_extra_labels": {},
        "builder_network_params": None,
        "el_min_cpu": 0,
        "el_max_cpu": 0,
        "el_min_mem": 0,
        "el_max_mem": 0,
        "cl_min_cpu": 0,
        "cl_max_cpu": 0,
        "cl_min_mem": 0,
        "cl_max_mem": 0,
        "vc_min_cpu": 0,
        "vc_max_cpu": 0,
        "vc_min_mem": 0,
        "vc_max_mem": 0,
        "validator_count": None,
        "snooper_enabled": False,
        "ethereum_metrics_exporter_enabled": False,
        "xatu_sentry_enabled": False,
        "count": 1,
        "prometheus_config": {
            "scrape_interval": "15s",
            "labels": None,
        },
        "blobber_enabled": False,
        "blobber_extra_params": [],
    }



def deep_copy_participant(participant):
    part = {}
    for k, v in participant.items():
        if type(v) == type([]):
            part[k] = list(v)
        else:
            part[k] = v
    return part