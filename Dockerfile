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
RUN apk add perl

# Create new unprivileged user & switch to it
RUN addgroup -S druid
RUN adduser -S druid -G druid

# Change owner of /druid to unprivileged user
ENV DRUID_DIR /druid/apache-druid-${DRUID_VERSION}
RUN chown -R druid $DRUID_DIR

# Switch to Druid user
USER druid

# Copy ./run.sh script from the building dir
COPY ["./run.sh", "$DRUID_DIR/run.sh"]

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
