# Docker Quick Start 🚀

## Initial Setup (one-time)

```bash
./setup.sh
```

## Common Commands

### Development

```bash
# Build and start
make up

# View logs
make logs

# Stop
make down
```

### Production (Single Instance)

```bash
docker-compose up -d --build
```

### Production (Scaled with Load Balancer)

```bash
# Start with 3 instances behind nginx
docker-compose -f docker-compose.prod.yml up -d --scale app=3

# Scale to 5 instances
make prod-scale N=5

# View logs
make prod-logs

# Stop
make prod-down
```

## Health Check

```bash
curl http://localhost:3000/api/hello
# or
make test-health
```

## Monitoring

```bash
# Health status
make health

# Resource usage
make stats

# Docker ps
docker-compose ps
```

## Cleanup

```bash
# Stop and remove
make down

# Full cleanup (removes volumes, images)
make clean
```

## Architecture

**Single Instance:**

```
Browser → Port 3000 → Next.js App
```

**Scaled Production:**

```
Browser → Port 80 → Nginx → Load Balancer
                      ↓
            ┌─────────┼─────────┐
            ↓         ↓         ↓
         App 1     App 2     App 3
         :3000     :3000     :3000
```

## Resource Limits (per container)

- **CPU:** 0.5-2 cores
- **Memory:** 256MB-1GB
- **Logs:** 10MB × 3 files

## Files

- `Dockerfile.bun` - Production-optimized Bun build
- `docker-compose.yml` - Single instance setup
- `docker-compose.prod.yml` - Multi-instance with nginx
- `nginx.conf` - Load balancer config
- `Makefile` - Convenience commands
