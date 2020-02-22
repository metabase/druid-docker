### DockerHub
[`metabase/druid`](https://hub.docker.com/repository/docker/metabase/druid)
[![](https://images.microbadger.com/badges/version/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)
[![](https://images.microbadger.com/badges/image/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)

### Build It

```bash
docker build -t metabase/druid:0.17.0 .
```

### Test It

```bash
docker run -p 8081:8081 -p 8082:8082 -p 8083:8083 -p 8888:8888 -p 8091:8091 -it metabase/druid:0.17.0
```

### Push It

```bash
docker push metabase/druid:0.17.0
```
