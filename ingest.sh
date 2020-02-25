#! /usr/bin/env bash

set -eou pipefail

cd $(dirname "$0")

echo 'Starting Druid cluster...'
./run.sh &

check_health() {
    nc -z localhost 8091|| {
        echo "Port 8091 is not open."
        return -1
    }

    if [ "$(curl -s http://localhost:8091/status/health)" != "true" ]; then
        echo "Health check for router did not return true"
        return -1
    fi
}

while ! check_health; do
    sleep 5;
done

echo 'Ingesting data...'
curl -s -X POST \
     -H 'Content-Type: application/json' \
     --data '@/data/ingestion.json' \
     http://localhost:8888/druid/indexer/v1/task

wait_for_ingestion() {
    datasources="$(curl -s http://localhost:8888/druid/v2/datasources)"

    echo "Loaded datasources: $datasources"

    if [ "$datasources" != '["checkins"]' ]; then
        sleep 1
        wait_for_ingestion
    fi
}

echo 'Waiting for ingestion to finish...'
wait_for_ingestion

echo "Sleeping for 2 minutes so ingestion can actually finish..."
sleep 120
