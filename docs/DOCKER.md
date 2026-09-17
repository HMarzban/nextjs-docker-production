# Running the Docker example

From the repository root, with Docker Engine and Compose v2+:

```sh
export BUILD_ID="build-$(git rev-parse --short HEAD)"
export GIT_HASH="$(git rev-parse --short HEAD)"
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d --scale app=2 --wait --wait-timeout 120
BASE_URL=http://localhost:3009 bash scripts/test-api.sh
docker compose -f docker-compose.prod.yml logs --tail 100
docker compose -f docker-compose.prod.yml down
```

`HTTP_PORT` overrides port 3009; `APP_IMAGE` overrides the local image name.
Use `COMPOSE_PROJECT_NAME=<name>` consistently to isolate a second deployment,
including the shell helpers that invoke Compose.
The stack is an HTTP example. Configure and verify TLS before exposing it publicly;
mounting an `ssl` folder alone does not enable HTTPS. `/health` only checks Nginx;
`/api/hello` checks the application and makes an optional external GitHub request.

Each app is limited to 1 GiB / 2 CPUs. Scale to suit available resources.
Nginx resolves the app replicas at startup; reload/restart it after changing replica
membership. This example has no orchestration or zero-downtime rollout guarantee.
