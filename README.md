DockerHub:
`metabase/druid`
[![](https://images.microbadger.com/badges/version/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)
[![](https://images.microbadger.com/badges/image/metabase/druid.svg)](https://microbadger.com/images/metabase/druid)

### Build It

```bash
docker build -t metabase/druid:0.17.0 .
```

### Test It

```bash
docker run -p 8082:8082 -p 8090:8090 -it metabase/druid:0.17.0
```

### Push It

```bash
docker push metabase/druid:0.17.0
```
