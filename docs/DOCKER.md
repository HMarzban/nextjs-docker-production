# Docker Production Setup

Production-ready Docker configuration with Bun runtime and Nginx load balancer.

## Quick Start

```bash
# Build with consistent build ID
make build

# Start production (10 instances)
make rebuild

# Scale to custom number
make scale N=5
```

## Architecture

- **Dockerfile.bun**: Multi-stage build optimized for Bun runtime
- **docker-compose.prod.yml**: Production setup with Nginx load balancer
- **nginx.conf**: Load balancer configuration with health checks

## Features

✅ Multi-stage builds (deps → builder → runner)
✅ Health checks (30s interval)
✅ Resource limits (CPU/Memory)
✅ Logging rotation (10MB max, 3 files)
✅ Network isolation
✅ Non-root user (nextjs:nodejs)
✅ Automatic restarts
✅ Alpine base (minimal size)

## Production Deployment

### Build and Deploy

```bash
# Build with consistent build ID
make build

# Deploy with 10 instances
make rebuild

# Or start without rebuilding
make up
```

### Scaling

```bash
# Scale to specific number
make scale N=5

# Scale to 10 instances
make scale N=10
```

### Environment Variables

Copy `.env.production.example` to `.env.production` and configure:

```env
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
# Add API keys here
```

## Monitoring

```bash
# Check health
docker-compose -f docker-compose.prod.yml ps

# View logs
make logs

# Resource usage
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Check build ID consistency
make check-build
```

## Resource Limits

**Per App Container:**
- CPU: 0.5-2 cores
- Memory: 256MB-1GB
- Logs: 10MB × 3 files

**Nginx Container:**
- CPU: 0.25-1 core
- Memory: 128MB-256MB

Adjust in `docker-compose.prod.yml` under `deploy.resources`.

## Troubleshooting

```bash
# Rebuild from scratch
make build

# Check container health
docker-compose -f docker-compose.prod.yml ps

# Check build ID consistency
make check-build

# Shell into container
docker-compose -f docker-compose.prod.yml exec app sh

# Test load balancing
make test-balancing
```

## Clean Up

```bash
# Stop containers
make down

# Stop and remove volumes
make clean

# Full cleanup
docker system prune -a
```

## Load Testing

```bash
# Standard load test
make test-stress

# Heavy load test
make test-stress-heavy

# Extreme load test
make test-stress-extreme
```

See [LOAD-TEST.md](./LOAD-TEST.md) for details.
