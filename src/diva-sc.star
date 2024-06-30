utils = import_module("./utils.star")
constants = import_module("./constants.star")


def init(plan, el_url, sender_priv):
    plan.add_service(
        name=constants.DIVA_SC_SERVICE_NAME,
        config=ServiceConfig(
            image=constants.DIVA_SC_IMAGE,
            env_vars={"CUSTOM_URL": el_url, "CUSTOM_PRIVATE_KEY": sender_priv},
            cmd=["tail", "-f", "/dev/null"],
        ),
    )


def deploy(plan, el_rpc, delay_sc, chainID, sc_verif,genesis_time, minimal):
    plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(command=["sleep", "0"]),
    )
    fund = plan.wait(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast send 0x3fab184622dc19b6109349b94811493bf2a45362 --value \"0.1 ether\" --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --rpc-url {0}".format(el_rpc)
            ]
        ),
        field="code", 
        assertion="==", 
        target_value=0,
        interval = "3s",
        timeout = "3m",
    )
 
    create2factory = plan.wait(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast publish --rpc-url {0} 0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222".format(el_rpc) 
            ]
        ),
        field="code", 
        assertion="==", 
        target_value=0,
        interval = "3s",
        timeout = "3m",         
    )
    if minimal:
        command=[
            "/bin/sh",
            "-c",
            "TEST=false SLOTS_PER_EPOCH=8 SECONDS_PER_SLOT=6 ERA_DURATION_IN_SLOT=10 NETWORK_ID=3151908 MIN_WITHDRAWAL_REQUEST_AMOUNT=\"0.1 ether\" MAX_WITHDRAWAL_REQUEST_AMOUNT=\"100 ether\" MAX_WITHDRAWAL_REQUEST_FULFILLMENT_AMOUNT=10 WITHDRAWAL_FEE=\"0.03 ether\" OPERATORS_FEE=1000 ETH2_DEPOSIT_CONTRACT=0x4242424242424242424242424242424242424242 DEPLOYER_ADDRESS=0x8943545177806ED17B9F23F0a21ee5948eCaa776 DEFAULT_EPOCHS_PER_TIMEFRAME=1 GENESIS_TIME_NETWORK={0} forge script scripts/Deploy.s.sol -vv  --rpc-url={1} --broadcast --private-key={2} --legacy".format(genesis_time, el_rpc,constants.DEPLOYER_PRIVATE_KEY)
        ]    
    else:
        command=[
            "/bin/sh",
            "-c",
            "NETWORK_ID=3151908 MIN_WITHDRAWAL_REQUEST_AMOUNT=\"0.1 ether\" MAX_WITHDRAWAL_REQUEST_AMOUNT=\"100 ether\" MAX_WITHDRAWAL_REQUEST_FULFILLMENT_AMOUNT=10 WITHDRAWAL_FEE=\"0.03 ether\" OPERATORS_FEE=1000 ERA_DURATION_IN_SLOT=225 SECONDS_PER_SLOT=12 ETH2_DEPOSIT_CONTRACT=0x4242424242424242424242424242424242424242 DEPLOYER_ADDRESS=0x8943545177806ED17B9F23F0a21ee5948eCaa776 TEST=true DEFAULT_EPOCHS_PER_TIMEFRAME=1 GENESIS_TIME_NETWORK={0} forge script scripts/Deploy.s.sol -vv  --rpc-url={1} --broadcast --private-key={2} --legacy".format(genesis_time, el_rpc,constants.DEPLOYER_PRIVATE_KEY)
        ]

    deploy = plan.wait(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=command
        ),
        field="code", 
        assertion="==", 
        target_value=0,
        interval = "3s",
        timeout = "3m",        
    )
    validator_manager = plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cat /app/broadcast/Deploy.s.sol/3151908/run-latest.json "
            ]
        ),
    )

def fund(plan, el_rpc, op_addresses, deposit_value_eth):
    commands = []    
    initial_command = "nonce=$(cast nonce 0x8943545177806ED17B9F23F0a21ee5948eCaa776 --rpc-url {0}); ".format(el_rpc)
    for address in op_addresses:
        command = " cast send {0} --value \"{1} ether\" --nonce $nonce --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --rpc-url {2} & nonce=$(($nonce + 1));".format(
            address, deposit_value_eth + 1, el_rpc
        )
        commands.append(command)


    full_command = initial_command + " ".join(commands) + " wait; [ $? -eq 0 ] || exit 1"

    plan.print(full_command)
    res = plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                full_command
            ]
        ),
    )
 
def collateral(plan, el_rpc, priv_keys,value):
    commands = []

    for priv_key in priv_keys:
        command =  "DEPLOYER_ADDRESS={3} COLLATERAL_AMOUNT=\"{0} ether\" forge script scripts/testnet/AddCollateral.s.sol -vvv --rpc-url={1} --broadcast --private-key {2} &".format(value,el_rpc,priv_key,constants.DEPLOYER_ADDRESS)

        commands.append(command)
    
        full_command = " ".join(commands) + " wait; [ $? -eq 0 ] || exit 1"
    
    plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                full_command
            ]
        ),
    )

def new_key(plan):
    result = plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "cast wallet new | awk '/Address:/{addr=$2} /Private key:/{key=$3} END{printf \"[\\\"%s\\\",\\\"%s\\\"]\\n\", addr, key}'",
            ],
            extract = {
                "address" : "fromjson | .[0]",
                "private_key" : "fromjson | .[1]",
            },
        ),
 
    )
    address= result["extract.address"]
    private_key= result["extract.private_key"]
    return address, private_key

def register(plan, node_addresses, node_private_keys, el_rpc, operator_private_keys):
    commands = []
    if len(node_addresses)>0 and len(node_addresses)==len(node_private_keys) and len(node_private_keys) == len(operator_private_keys):
        for i in range(len(node_addresses)):
            node_address = node_addresses[i]
            node_private_key = node_private_keys[i]
            operator_private_key = operator_private_keys[i]
            command = "NODE_ADDRESS={0} NODE_PRIVATE_KEY={1} DEPLOYER_ADDRESS={4} forge script scripts/testnet/RegisterNode.s.sol -vvvv --rpc-url={2} --broadcast --private-key {3} &".format(
                node_address, node_private_key, el_rpc, operator_private_key,constants.DEPLOYER_ADDRESS
            )
            commands.append(command)

            full_command = " ".join(commands) + " wait; [ $? -eq 0 ] || exit 1"

        plan.exec(
            service_name=constants.DIVA_SC_SERVICE_NAME,
            recipe=ExecRecipe(
                command=[
                    "/bin/sh",
                    "-c",
                    full_command
                ]
            )
        )


def get_coord_dkg(plan, coord_dkg_url, el_rpc, minimal, operators_priv):
    deployer_private_key= "bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31"

    timeFrameDuration = 12*32
    if minimal:
        timeFrameDuration = 6*8
    
    result = plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "node scripts/testnet/submitterDKG.js {1} {0} {2} {3} {4}".format(
                    el_rpc, (coord_dkg_url+"/api/v1/coordinator/dkgs"),deployer_private_key, timeFrameDuration, constants.DIVA_API_KEY
                )
            ],
        ),
    )

def init_accounting(plan, el_rpc):
    deployer_private_key= "bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31"

    submitReport = plan.exec(
        service_name=constants.DIVA_SC_SERVICE_NAME,
        recipe=ExecRecipe(
            command=[
                "/bin/sh",
                "-c",
                "forge script scripts/SubmitReport.s.sol -vvvv --rpc-url={0} --broadcast --private-key {1}".format(
                el_rpc,deployer_private_key
                )
            ],
        ),
    )
    

    #DKG 
    #node scripts/testnet/getCoordDKG.js http://diva-bootnode-coordinator:30000/api/v1/coordinator/dkgs
    #pending - 2 timeframe after
    #DEPLOYER_ADDRESS=0x8943545177806ED17B9F23F0a21ee5948eCaa776 forge script scripts/testnet/ProposeAggregationSet.s.sol -vvv --rpc-url=http://el-2-geth-nimbus:8545/ --broadcast --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --legacy
    #register  after propse 1 timeframe
    #DEPLOYER_ADDRESS=0x8943545177806ED17B9F23F0a21ee5948eCaa776 forge script scripts/testnet/RegisterValidator.s.sol -vvv --rpc-url=http://el-2-geth-nimbus:8545/ --broadcast --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --legacy  
    # activate val no importa
    #DEPLOYER_ADDRESS=0x8943545177806ED17B9F23F0a21ee5948eCaa776 DEPLOYER_PRIVATE_KEY=bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 forge script scripts/testnet/ActivateValidator.s.sol -vvv --rpc-url=http://el-2-geth-nimbus:8545/ --broadcast --private-key bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 --legacy  

    #node scripts/testnet/submitterDKG.js http://diva-bootnode-coordinator:30000/api/v1/coordinator/dkgs http://el-2-geth-prysm:8545/ bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31 48
    
    #./eth2-val-tools deposit-data --fork-version="0x10000038" --withdrawals-mnemonic="giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete" --validators-mnemonic="giant issue aisle success illegal bike spike question tent bar rely arctic volcano long crawl hungry vocal artwork sniff fantasy very lucky have athlete" --source-max=1 --source-min=0
    #{"account":"m/12381/3600/0/0/0","deposit_data_root":"e4c2ebc78b8bfd3e5f1f6224a029ee37c24bc7ff7c8ebcd8156c9d4446461939","pubkey":"aaf6c1251e73fb600624937760fef218aace5b253bf068ed45398aeb29d821e4d2899343ddcbbe37cb3f6cf500dff26c","signature":"a001e41c00714481850760321da53091e4b14cba89857b53a06daa2696ffaa4ea3a4270ec791c1320d801e40bdf98365114d36cf88cb650110a5fb5e5d56cf9b6b2d13eb4f168c210ac1c33a9917d41f0682fff53bf780f525c819e914debae6","value":32000000000,"version":1,"withdrawal_credentials":"0048281f02e108ec495e48a25d2adb4732df75bf5750c060ff31c864c053d28d"}0xF10f3614ACA520b4e0E2c2681883970Ca0F2120c
