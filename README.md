### DockerHub
[`metabase/druid`](https://hub.docker.com/repository/docker/metabase/druid)
[![](https://images.microbadger.com/badges/version/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)
[![](https://images.microbadger.com/badges/image/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)

### Build It

```bash
docker build -t metabase/druid:0.17.0 .
```

### Use It

```bash
docker run -p 8081:8081 -p 8082:8082 -p 8888:8888 --memory=4g -it metabase/druid:0.17.0
```

Note that `--memory` doesn't seem to work if Docker was installed via the macOS/Windows GUI; go to `Preferences > Resources`
in the GUI and change the limit that way instead. 4 GB memory should be more than enough to run a `micro-quickstart` cluster
which should be sufficient for our purposes.

If you see the broker/historical nodes constantly being killed and restarted make sure the Docker container memory limit is high enough.

#### Env Vars

*  `CLUSTER_SIZE` -- Druid config to use. Currently one of `nano-quickstart`, `micro-quickstart`, `small`, `medium`, `large`, or `xlarge`. Default: `nano-quickstart`
*  `ENABLE_JAVASCRIPT` -- whether to enable javascript on the Druid cluster. Metabase requires this, so by default it it `true`. Set it to something besides `true` to disable it.
*  `LOG4J_PROPERTIES_FILE` -- Log4j2 config. By default, `/druid/apache-druid-0.17.0/log4j2.properties`, copied when building the Docker image, but you can mount a directory and supply a different file if you want different logging levels.

### Push It

```bash
docker push metabase/druid:0.17.0
```
