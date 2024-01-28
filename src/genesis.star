constants = import_module("./constants.star")

NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR = "/node-0-keystores"
KEYSTORES_GENERATION_TOOL_NAME = "/app/eth2-val-tools"
ETH_VAL_TOOLS_IMAGE = "protolambda/eth2-val-tools:latest"

SUCCESSFUL_EXEC_CMD_EXIT_CODE = 0

RAW_KEYS_DIRNAME = "keys"
RAW_SECRETS_DIRNAME = "secrets"

TEKU_KEYS_DIRNAME = "teku-keys"
TEKU_SECRETS_DIRNAME = "teku-secrets"
ENTRYPOINT_ARGS = [
    "sleep",
    "99999",
]


def generate_validator_keystores(plan, start_index, stop_index):
    service_name = launch_prelaunch_data_generator(plan, {}, "diva-pre-val-keys")

    all_sub_command_strs = []

    output_dirpath = NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR.format(0)
    generate_keystores_cmd = '{0} keystores --insecure --prysm-pass {1} --out-loc {2} --source-mnemonic "{3}" --source-min {4} --source-max {5}'.format(
        KEYSTORES_GENERATION_TOOL_NAME,
        "PRYSM_PASSWORD",
        output_dirpath,
        constants.PREGENESIS_VAL_SEED,
        start_index + 1,
        stop_index + 1,
    )
    teku_permissions_cmd = (
        "chmod 0777 -R " + output_dirpath + "/" + TEKU_KEYS_DIRNAME
    )
    raw_secret_permissions_cmd = (
        "chmod 0600 -R " + output_dirpath + "/" + RAW_SECRETS_DIRNAME
    )
    all_sub_command_strs.append(generate_keystores_cmd)
    all_sub_command_strs.append(teku_permissions_cmd)
    all_sub_command_strs.append(raw_secret_permissions_cmd)

    command_str = " && ".join(all_sub_command_strs)

    command_result = plan.exec(
        recipe=ExecRecipe(command=["sh", "-c", command_str]), service_name=service_name
    )

    #return command_result
    # Store outputs into files artifacts
    keystore_files = []
    idx=0
    padded_idx = 1
    keystore_start_index = start_index
    keystore_stop_index = (stop_index) - 1
    artifact_name = "diva-artefact-pre-val"
    artifact_name = plan.store_service_files(
        service_name, output_dirpath, name=artifact_name
    )
    return artifact_name
    # This is necessary because the way Kurtosis currently implements artifact-storing is
    base_dirname_in_artifact = path_base(output_dirpath)
    to_add = new_keystore_files(
        artifact_name,
            path_join(base_dirname_in_artifact),
            path_join(base_dirname_in_artifact, RAW_KEYS_DIRNAME),
            path_join(base_dirname_in_artifact, RAW_SECRETS_DIRNAME),
            path_join(base_dirname_in_artifact, "NIMBUS_KEYS_DIRNAME"),
            path_join(base_dirname_in_artifact, "PRYSM_DIRNAME"),
            path_join(base_dirname_in_artifact, TEKU_KEYS_DIRNAME),
            path_join(base_dirname_in_artifact, TEKU_SECRETS_DIRNAME),
    )

    keystore_files.append(to_add)

    
    result = new_generate_keystores_result(
        "prysm_password_artifact_name",
        path_base("PRYSM_PASSWORD_FILEPATH_ON_GENERATOR"),
        keystore_files,
    )

    return result


def new_keystore_files(
    files_artifact_uuid,
    raw_root_dirpath,
    raw_keys_relative_dirpath,
    raw_secrets_relative_dirpath,
    nimbus_keys_relative_dirpath,
    prysm_relative_dirpath,
    teku_keys_relative_dirpath,
    teku_secrets_relative_dirpath,
):
    return struct(
        files_artifact_uuid=files_artifact_uuid,
        # ------------ All directories below are relative to the root of the files artifact ----------------
        raw_root_dirpath=raw_root_dirpath,
        raw_keys_relative_dirpath=raw_keys_relative_dirpath,
        raw_secrets_relative_dirpath=raw_secrets_relative_dirpath,
        nimbus_keys_relative_dirpath=nimbus_keys_relative_dirpath,
        prysm_relative_dirpath=prysm_relative_dirpath,
        teku_keys_relative_dirpath=teku_keys_relative_dirpath,
        teku_secrets_relative_dirpath=teku_secrets_relative_dirpath,
    )
def new_generate_keystores_result(
    prysm_password_artifact_uuid, prysm_password_relative_filepath, per_node_keystores
):
    return struct(
        # Files artifact UUID where the Prysm password is stored
        prysm_password_artifact_uuid=prysm_password_artifact_uuid,
        # Relative to root of files artifact
        prysm_password_relative_filepath=prysm_password_relative_filepath,
        # Contains keystores-per-client-type for each node in the network
        per_node_keystores=per_node_keystores,
    )

def path_join(*args):
    joined_path = "/".join(args)
    return joined_path.replace("//", "/")
def path_base(path):
    split_path = path.split("/")
    return split_path[-1]
def get_config(files_artifact_mountpoints):
    return ServiceConfig(
        image=ETH_VAL_TOOLS_IMAGE,
        entrypoint=ENTRYPOINT_ARGS,
        files=files_artifact_mountpoints,
    )

def launch_prelaunch_data_generator(
    plan,
    files_artifact_mountpoints,
    service_name,
):
    config = get_config(files_artifact_mountpoints)
    plan.add_service(service_name, config)
    return service_name
