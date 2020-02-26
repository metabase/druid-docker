FROM adoptopenjdk/openjdk8:alpine-jre

MAINTAINER Cam Saul <cam@metabase.com>

WORKDIR /druid

ENV DRUID_VERSION 0.17.0
ENV DRUID_ARCHIVE apache-druid-$DRUID_VERSION-bin.tar.gz

# Download Druid
RUN wget http://apache.spinellicreations.com/druid/$DRUID_VERSION/$DRUID_ARCHIVE
RUN tar -xzf $DRUID_ARCHIVE
RUN rm $DRUID_ARCHIVE

# Install deps
RUN apk add bash
RUN apk add curl

# Remove unneeded files
RUN rm -rf $DRUID_DIR/extensions
RUN rm -rf $DRUID_DIR/hadoop-dependencies
RUN rm -rf $DRUID_DIR/quickstart

# Create new unprivileged user & switch to it
RUN addgroup -S druid
RUN adduser -S druid -G druid

# Change owner of /druid to unprivileged user
ENV DRUID_DIR /druid/apache-druid-${DRUID_VERSION}
RUN chown -R druid $DRUID_DIR

RUN mkdir /data
RUN chown -R druid /data

# Switch to Druid user
USER druid

COPY ["./run.sh", "$DRUID_DIR/run.sh"]
COPY ["./log4j2.properties", "$DRUID_DIR/log4j2.properties"]
COPY ["./rows.json", "/data/rows.json"]
COPY ["./task.json", "/data/task.json"]
COPY ["./ingest.sh", "$DRUID_DIR/ingest.sh"]

# Create temp dir
RUN mkdir -p $DRUID_DIR/var/tmp

ENV CLUSTER_SIZE micro-quickstart
ENV LOG4J_PROPERTIES_FILE ${DRUID_DIR}/log4j2.properties
ENV ENABLE_JAVASCRIPT true

ENV START_MIDDLE_MANAGER true

# Ingest the rows.
RUN $DRUID_DIR/ingest.sh

ENV CLUSTER_SIZE nano-quickstart
ENV START_MIDDLE_MANAGER false

# coordinator/overlord
EXPOSE 8081
# broker
EXPOSE 8082
# historical
EXPOSE 8083
# router
EXPOSE 8888
# middle manager
EXPOSE 8091

ENTRYPOINT $DRUID_DIR/run.sh
