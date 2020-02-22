#! /usr/bin/env bash

set -euo pipefail

cd $(dirname "$0")

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p)' EXIT

tail_logs() {
    command="$1"
    log_file="var/sv/$command.log"

    echo "Tailing $log_file"

    while [ ! -f $log_file ]; do
        sleep 0.1;
    done

    tail -f $log_file | sed "s/^/[$command] /" &
}

mkdir -p var/sv
./bin/start-nano-quickstart 2>&1 > var/sv/start.log &

tail_logs start
tail_logs zk
tail_logs coordinator-overlord
tail_logs broker
tail_logs router
tail_logs historical
tail_logs middleManager

wait
