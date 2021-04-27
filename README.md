# Important Note!

This is not currently used in Metabase CI because it does not seem to run correctly with the limited amount of memory we can give it in Circle. If we switch to a plan that lets us test with larger instance sizes, we can try using this image.

### DockerHub
[`metabase/druid`](https://hub.docker.com/repository/docker/metabase/druid)
[![](https://images.microbadger.com/badges/version/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)

### Build It

```bash
docker build -t metabase/druid:0.20.2 .
```

The build logic ingests the data in `rows.json` by executing the ingestion spec task `task.json`. This is done in the script `ingest.sh`; tweak as needed.

Why ingest data as part of the build process? In some cases ingestion and indexing can take 10 minutes, on top of
using an obnoxious amount of memory. Better to do it during build so we can use the image right out of the box instead
of making CI super slow.

### Use It

```bash
docker run -p 8081:8081 -p 8082:8082 -p 8888:8888 -it metabase/druid:0.20.2
```

#### Env Vars

For running Metabase tests you shouldn't need to change any of these.

*  `CLUSTER_SIZE` -- Druid config to use. Currently one of `nano-quickstart`, `micro-quickstart`, `small`, `medium`, `large`, or `xlarge`. Default: `nano-quickstart`
*  `START_MIDDLE_MANAGER` -- whether to start the middle manager process. Default `false`, because the middle manager is only needed for ingesting rows. Set to `true` if you plan to ingest more data.
*  `ENABLE_JAVASCRIPT` -- whether to enable javascript on the Druid cluster. Metabase requires this, so by default it it `true`. Set it to something besides `true` to disable it.
*  `LOG4J_PROPERTIES_FILE` -- Log4j2 config. By default, `/druid/apache-druid-0.20.2/log4j2.properties`, copied when building the Docker image, but you can mount a directory and supply a different file if you want different logging levels.

### Push It

```bash
docker push metabase/druid:0.20.2
```
