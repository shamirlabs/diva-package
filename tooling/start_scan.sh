#!/usr/bin/env bash


get_container() {
    case "$1" in
        diva[1-5] | val[1-5])
            echo "$(docker ps | grep "$1" | awk '{print $1}')"
            ;;
        bc)
            echo "$(docker ps | grep "cl-" | awk '{print $1}')"
            ;;
        *)
            echo "Error: Alias de contenedor desconocido"
            exit 1
            ;;
    esac
}

get_ip(){
    echo "$(docker inspect $1 | jq -r '.[0].NetworkSettings.Networks | to_entries[0].value.IPAddress')"
}

handle_commands() {
    local pairs=()
    if [[ $# -eq 0 ]]; then
        pairs=("diva1-val1")
    else
        for arg in "$@"; do
            if [[ "$arg" == "diva-val" ]]; then
                for i in {1..5}; do
                    pairs+=("diva$i-val$i")
                done
            elif [[ "$arg" == "val-diva" ]]; then
                for i in {1..5}; do
                    pairs+=("val$i-diva$i")
                done
            else
                pairs+=("$arg")
            fi
        done
    fi

    ifconfig_output=$(ifconfig)
    interface=$(echo "$ifconfig_output" | awk '/inet 172\.16\.0\./ {print iface} {iface=$1}' | sed 's/:$//')
    for pair in "${pairs[@]}"; do
        IFS='-' read -ra ADDR <<< "$pair"
        src=$(get_ip "$(get_container "${ADDR[0]}")")
        dst=$(get_ip "$(get_container "${ADDR[1]}")")
        echo "Capturando entre ${ADDR[0]} y ${ADDR[1]}"

        sudo tcpdump -i "$interface" -s 0 -nn "(src $src and dst $dst)" -w "../test/${ADDR[0]}_${ADDR[1]}.pcap" &
    done
}
rm -f ../test/*.pcap
handle_commands "$@"
