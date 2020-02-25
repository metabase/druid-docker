#! /usr/bin/env bash

set -euo pipefail

cd $(dirname "$0")

# When this exits, exit all back ground process also.
trap 'kill -s KILL $(jobs -p)' EXIT

echo -e "\n\n"
echo '********************************************************************************'
echo "               Starting Druid cluster with size $CLUSTER_SIZE"
echo '********************************************************************************'
echo -e "\n\n"

ZK_CONF_DIR=$(pwd)/conf/zk
DRUID_CONF_DIR=$(pwd)/conf/druid/single-server/$CLUSTER_SIZE
DRUID_COMMON_CONF_DIR=$DRUID_CONF_DIR/_common

if [ ! -d "$DRUID_CONF_DIR" ]; then
    echo "Invalid cluster size $CLUSTER_SIZE -- cannot find conf dir $DRUID_CONF_DIR"
    echo "found: $(ls conf/druid/single-server)"
    exit -1
fi

check_health() {
    service=$1
    port=$2

    nc -z localhost $port || {
        echo "service $service port $port is not open"
        return -1
    }

    if [ $service != zookeeper ]; then
        if [ "$(curl -s http://localhost:${port}/status/health)" != "true" ]; then
            echo "Health check for service $service on port $port did not return true"
            return -2
        fi
    fi
}

# These are in seconds
HEALTH_CHECK_INTERVAL=1
MAX_WAIT_FOR_HEALTHY_STATUS=20

wait_for_healthy_loop() {
    service=$1
    port=$2
    max_wait=$3

    if [ $max_wait -le 0 ]; then
        echo "Timed out waiting for service $service to be healthy after $MAX_WAIT_FOR_HEALTHY_STATUS seconds".
        return -1
    fi

    # echo "Waiting for service $service on port $port to be healthy..."
    if check_health $service $port; then
        echo "service $service on port $port is healthy."
    else
        sleep $HEALTH_CHECK_INTERVAL
        wait_for_healthy_loop $service $port `expr $max_wait - $HEALTH_CHECK_INTERVAL`
    fi
}

wait_for_healthy() {
    service=$1
    port=$2

    wait_for_healthy_loop $service $port $MAX_WAIT_FOR_HEALTHY_STATUS
}

start_zookeeper() {
    echo -e "\n\n"
    echo '********************************************************************************'
    echo "                             Starting Zookeeper"
    echo '********************************************************************************'
    echo -e "\n\n"

    mkdir -p var/zk

    nohup java `cat $ZK_CONF_DIR/jvm.config | xargs` \
          -cp "lib/*:$ZK_CONF_DIR" \
          -Dzookeeper.jmx.log4j.disable=true \
          -Dlog4j.configurationFile="$LOG4J_PROPERTIES_FILE" \
          org.apache.zookeeper.server.quorum.QuorumPeerMain \
          "$ZK_CONF_DIR/zoo.cfg" 2>&1 | sed 's/^/[zookeeper] /' &

    wait_for_healthy zookeeper 2181 || start_zookeeper
}

start_zookeeper_if_needed() {
    check_health zookeeper 2181 || start_zookeeper
}

start_druid_service() {
    service=$1
    port=$2
    log_file="logs/$service.log"
    conf_dir="$DRUID_CONF_DIR/$service"

    echo -e "\n\n"
    echo '********************************************************************************'
    echo "               Starting Druid $service service on port $port"
    echo '********************************************************************************'
    echo -e "\n\n"

    mkdir -p var/druid/segments
    mkdir -p var/druid/indexing-logs

    nohup java `cat $conf_dir/jvm.config | xargs` \
          -cp "$DRUID_COMMON_CONF_DIR:$conf_dir:lib/*" \
          -Dlog4j.configurationFile="$LOG4J_PROPERTIES_FILE" \
          `cat $conf_dir/main.config | xargs` \
          2>&1 | sed "s/^/[$service] /" &

    wait_for_healthy $service $port || start_druid_service $service $port
}

start_druid_service_if_needed() {
    service=$1
    port=$2

    check_health $service $port || start_druid_service $service $port
}

start_services_if_needed() {
    start_zookeeper_if_needed
    start_druid_service_if_needed "coordinator-overlord" 8081
    start_druid_service_if_needed "broker" 8082
    start_druid_service_if_needed "historical" 8083
    start_druid_service_if_needed "router" 8888
    start_druid_service_if_needed "middleManager" 8091
}

DRUID_COMMON_PROPERTIES=$DRUID_COMMON_CONF_DIR/common.runtime.properties

if [ "$ENABLE_JAVASCRIPT" = true ]; then
    echo 'Enabling JavaScript.'
    echo -e "\ndruid.javascript.enabled=true" >> $DRUID_COMMON_PROPERTIES
fi

# Disable extensions that we aren't going to be using like HDFS storage and the Kafka indexing service
echo -e "\ndruid.extensions.loadList=[]" >> $DRUID_COMMON_PROPERTIES

start_services_if_needed

echo -e "\n\n"
echo '********************************************************************************'
echo '*                             Druid Cluster Ready.                             *'
echo '********************************************************************************'
echo -e "\n\n"

# Now monitor stuff and restart nodes as needed until we quit
start_loop() {
    while true; do
        sleep 1
        start_services_if_needed
    done
}

start_loop
