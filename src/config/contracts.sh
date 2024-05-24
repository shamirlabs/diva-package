#!/bin/bash

validator_manager=$(jq -r '.returns.deployed.value | split(", ")[7]' salida.json)

cat <<EOF > contracts.toml
[[contracts]]
proxy = true
contract_name = "validator_manager"
address = "$validator_manager"
initial_implementation = "0x72ae2643518179cF01bcA3278a37ceAD408DE8b2"

[contracts.implementations]
"0x72ae2643518179cF01bcA3278a37ceAD408DE8b2" = "d7f4bb8d559f75cd14262b738dcfe9ec1dd48da3aa61747101211cc53eaddbf2"

[[contracts]]
proxy = true
contract_name = "collateral_curve"
address = "0xc917992A9c9a21De13e79dAed01F9A69c6fE582E"
initial_implementation = "0x9fCF7D13d10dEdF17d0f24C62f0cf4ED462f65b7"

[contracts.implementations]
"0x9fCF7D13d10dEdF17d0f24C62f0cf4ED462f65b7" = "4f62f636d2a3340df96ef591544387bb3b37906dc78c6a3192a47f1a80e39740"
EOF
