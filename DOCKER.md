# Docker Production Setup

Production-ready Docker configuration with Bun runtime.

## Quick Start

```bash
# Development
docker-compose up --build

# Production (single instance)
docker-compose -f docker-compose.yml up -d

# Production (scaled with nginx)
docker-compose -f docker-compose.prod.yml up -d --scale app=3
```

## Architecture

- **Dockerfile.bun**: Multi-stage build optimized for Bun
- **docker-compose.yml**: Single instance setup
- **docker-compose.prod.yml**: Multi-instance with nginx load balancer

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

### Single Instance

```bash
docker-compose up -d --build
```

### Scaled with Load Balancer

```bash
docker-compose -f docker-compose.prod.yml up -d --scale app=3
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
docker-compose ps

# View logs
docker-compose logs -f app

# Resource usage
docker stats nextjs-app
```

## Scaling

```bash
# Scale to 5 instances
docker-compose -f docker-compose.prod.yml up -d --scale app=5

# Scale down to 2
docker-compose -f docker-compose.prod.yml up -d --scale app=2
```

## Resource Limits

**Per Container:**

- CPU: 0.5-2 cores
- Memory: 256MB-1GB
- Logs: 10MB × 3 files

Adjust in `docker-compose.yml` under `deploy.resources`.

## Troubleshooting

```bash
# Rebuild from scratch
docker-compose build --no-cache

# Check container health
docker inspect --format='{{json .State.Health}}' nextjs-app

# Shell into container
docker-compose exec app sh
```

## Clean Up

```bash
# Stop and remove
docker-compose down

# Remove with volumes
docker-compose down -v

# Full cleanup
docker system prune -a
```
