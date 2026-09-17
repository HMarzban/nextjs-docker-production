# One build, several replicas

`next.config.mjs` uses `BUILD_ID`, then `GIT_HASH`, then `production-build`.
Use the same built image for every replica in a rollout:

```sh
BUILD_ID="build-$(git rev-parse --short HEAD)" GIT_HASH="$(git rev-parse --short HEAD)" docker compose -f docker-compose.prod.yml build
```

`make build` performs this through `scripts/build-production.sh`. A shared build ID
prevents replicas from advertising different asset versions; it does not make
separately built images identical or coordinate client service-worker updates.
Do not reuse a fixed ID for unrelated production releases.
