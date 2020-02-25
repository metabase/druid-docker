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
     --data '@/data/task.json' \
     http://localhost:8888/druid/indexer/v1/task

wait_for_datasource() {
    # echo "Task status:"
    # curl -s "http://localhost:88888/druid/indexer/v1/task/$task/status"

    datasources="$(curl -s http://localhost:8888/druid/v2/datasources)"

    echo "Loaded datasources: $datasources"

    if [ "$datasources" != '["checkins"]' ]; then
        sleep 1
        wait_for_datasource
    fi
}

wait_for_all_rows() {
    QUERY='{"query":"SELECT count(*) AS \"count\" FROM \"checkins\""}'
    count=$(curl -s -X POST -H 'Content-Type: application/json' --data "$QUERY" http://localhost:8888/druid/v2/sql)

    echo "Rows loaded: $count"
    if [ "$count" != '[{"count":1000}]' ]; then
        sleep 1
        wait_for_all_rows
    fi
}

echo -e "\nWaiting for ingestion to finish. Please be patient, this may take up to 10 minutes..."
wait_for_datasource
wait_for_all_rows
