# Production Deployment Checklist

## Pre-Deployment

### Environment

- [ ] Copy `.env.production.example` to `.env.production`
- [ ] Add all API keys and secrets
- [ ] Set `NEXT_TELEMETRY_DISABLED=1`
- [ ] Never commit `.env.production` to git

### Security

- [ ] Review all exposed ports
- [ ] Set up SSL certificates in `./ssl/` for nginx
- [ ] Update nginx.conf for SSL (if needed)
- [ ] Use secrets management (Docker secrets, AWS SSM, etc.)
- [ ] Limit resource access in docker-compose

### Configuration

- [ ] Adjust resource limits in docker-compose
  - CPU: based on expected load
  - Memory: 256MB minimum, 1GB+ for high traffic
- [ ] Configure log rotation (default: 10MB × 3 files)
- [ ] Set proper restart policies
- [ ] Configure health check intervals

## Deployment

### Initial Deploy

```bash
# 1. Run setup
./setup.sh

# 2. Build and start
make up

# 3. Verify health
make test-health

# 4. Check logs
make logs
```

### Scaled Deploy (Load Balanced)

```bash
# Start with 3 instances behind nginx
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# Verify all containers are healthy
docker-compose ps

# Test nginx load balancer
curl http://localhost/api/hello
```

## Monitoring

### Health Checks

```bash
# Container health
docker inspect --format='{{json .State.Health}}' nextjs-app | jq

# All services
docker-compose ps
```

### Resource Usage

```bash
# Real-time stats
docker stats

# Specific container
docker stats nextjs-app
```

### Logs

```bash
# Follow logs
make logs

# Last 100 lines
docker-compose logs --tail=100 app

# Specific time range
docker-compose logs --since 2h app
```

## Scaling

### Horizontal Scaling

```bash
# Scale up to 5 instances
make prod-scale N=5

# Scale down to 2
make prod-scale N=2

# Check distribution
docker-compose ps
```

### When to Scale

- **CPU > 70%** for sustained periods
- **Memory > 80%** consistently
- **Response time** degrading
- **Traffic** increasing significantly

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs app

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d

# Check image
docker images nextjs-app
```

### Health Check Failing

```bash
# Manual health check
curl http://localhost:3000/api/hello

# Inside container
docker exec -it nextjs-app sh
bun -e "fetch('http://localhost:3000/api/hello')"

# Check network
docker network inspect nextjs-app-network
```

### High Memory Usage

```bash
# Check current usage
docker stats nextjs-app --no-stream

# Restart container
make restart

# Adjust limits in docker-compose.yml
deploy.resources.limits.memory: "2G"
```

### Logs Growing Too Large

```bash
# Check log size
du -sh $(docker inspect --format='{{.LogPath}}' nextjs-app)

# Rotate manually
docker-compose restart app

# Adjust in docker-compose.yml:
logging:
  options:
    max-size: "5m"  # smaller files
    max-file: "5"   # more files
```

## Updates & Rollbacks

### Zero-Downtime Update

```bash
# Build new image
docker-compose build

# Start new containers before stopping old ones
docker-compose up -d --no-deps --build app

# Verify
docker-compose ps
make test-health
```

### Rollback

```bash
# If update fails, revert to previous image
docker tag nextjs-app:latest nextjs-app:rollback
docker-compose up -d
```

### Image Management

```bash
# Tag before deploy
docker tag nextjs-app:latest nextjs-app:v1.0.0

# List images
docker images nextjs-app

# Remove old images
docker image prune -a --filter "until=72h"
```

## Backup & Recovery

### Data Backup

```bash
# No persistent data in base setup
# If you add volumes, backup regularly:
docker run --rm --volumes-from nextjs-app \
  -v $(pwd):/backup alpine \
  tar czf /backup/data.tar.gz /app/data
```

### Configuration Backup

```bash
# Backup all configs
tar czf configs-$(date +%Y%m%d).tar.gz \
  docker-compose*.yml \
  nginx.conf \
  .env.production \
  Dockerfile.bun
```

## Performance Optimization

### Build Optimization

- Use BuildKit: `DOCKER_BUILDKIT=1`
- Cache layers effectively
- Multi-stage builds (already implemented)
- Minimize layer count

### Runtime Optimization

- Use alpine base image (✓ already using)
- Run as non-root user (✓ already implemented)
- Minimize installed packages
- Use health checks (✓ already implemented)

### Network Optimization

- Use nginx for static assets
- Enable gzip compression
- Configure proper caching headers
- Use CDN for static assets

## Security Best Practices

### Container Security

- [x] Non-root user (nextjs:nodejs)
- [x] Minimal base image (alpine)
- [x] No unnecessary packages
- [x] Resource limits set
- [ ] Regular image updates
- [ ] Security scanning (e.g., Trivy)

### Network Security

- [x] Isolated network
- [ ] Firewall rules
- [ ] Rate limiting
- [ ] SSL/TLS termination

### Secrets Management

- Never commit secrets
- Use Docker secrets
- Or: AWS Secrets Manager
- Or: HashiCorp Vault
- Environment variables for non-sensitive config

## Post-Deployment

### Verify

- [ ] All containers running
- [ ] Health checks passing
- [ ] API endpoints responding
- [ ] Static assets loading
- [ ] No errors in logs
- [ ] Weather API working (if configured)

### Set Up Monitoring

- [ ] CPU/Memory alerts
- [ ] Health check monitoring
- [ ] Log aggregation
- [ ] Error tracking (Sentry, etc.)
- [ ] Uptime monitoring

### Documentation

- [ ] Document any custom changes
- [ ] Update team on deployment
- [ ] Record deployment date/version
- [ ] Create runbook for common issues

## Quick Reference

```bash
# Start production
make prod-up

# Scale instances
make prod-scale N=5

# View logs
make prod-logs

# Check health
make health

# Resource usage
make stats

# Stop all
make prod-down

# Emergency restart
docker-compose restart app
```

## Support

For issues or questions:

1. Check logs: `make logs`
2. Verify health: `make health`
3. Review this checklist
4. Check DOCKER.md for detailed info
