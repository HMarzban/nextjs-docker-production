# Scale Testing Guide

Complete guide to test horizontal scaling with Docker Compose and Nginx load balancing.

## Quick Start

```bash
# Stop any running dev server
pkill -f "bun.*start" || pkill -f "next.*start"

# Build the image
docker compose -f docker-compose.prod.yml build

# Start with 3 replicas
docker compose -f docker-compose.prod.yml up -d --scale app=3

# Check status
docker compose -f docker-compose.prod.yml ps
```

## Step-by-Step Testing

### 1. Build Production Image

```bash
cd /Users/macbook/Desktop/nextdocker/nextjs-docker
docker compose -f docker-compose.prod.yml build --no-cache
```

This builds the optimized production image with PWA support.

### 2. Start Scaled Deployment

```bash
# Start with 3 instances
docker compose -f docker-compose.prod.yml up -d --scale app=3

# Or use Makefile
make prod-scale N=3
```

### 3. Verify Instances

```bash
# Check all containers running
docker compose -f docker-compose.prod.yml ps

# Should see:
# - nginx (1 instance)
# - app (3 instances: app-1, app-2, app-3)
```

### 4. Test Load Balancing

```bash
# Hit the load balancer multiple times
for i in {1..10}; do
  curl -s http://localhost:80 | grep -o "Welcome to" && echo " - Request $i"
done
```

### 5. Check Logs

```bash
# All containers
docker compose -f docker-compose.prod.yml logs -f

# Just app instances
docker compose -f docker-compose.prod.yml logs -f app

# Specific instance
docker logs nextjs-docker-app-1
docker logs nextjs-docker-app-2
docker logs nextjs-docker-app-3
```

### 6. Health Checks

```bash
# Nginx health
curl http://localhost:80/health

# App health (directly)
docker exec nextjs-docker-app-1 bun -e "fetch('http://localhost:3000/api/hello').then(r => console.log(r.status))"
```

### 7. Resource Monitoring

```bash
# Real-time stats for all containers
docker stats

# Specific containers
docker stats nextjs-docker-app-1 nextjs-docker-app-2 nextjs-docker-app-3
```

### 8. Scale Up/Down

```bash
# Scale to 5 instances
docker compose -f docker-compose.prod.yml up -d --scale app=5

# Scale down to 2
docker compose -f docker-compose.prod.yml up -d --scale app=2

# Check it worked
docker compose -f docker-compose.prod.yml ps
```

### 9. Browser Testing

1. Open browser: <http://localhost>
2. Open DevTools → Network tab
3. Refresh multiple times
4. Check `X-Real-IP` headers (if added)
5. Test PWA offline mode
6. Install as PWA

### 10. Load Testing (Optional)

```bash
# Install hey (HTTP load generator)
# macOS: brew install hey
# Linux: go install github.com/rakyll/hey@latest

# Send 1000 requests with 50 concurrent workers
hey -n 1000 -c 50 http://localhost:80

# You'll see:
# - Total requests distributed across instances
# - Response time stats
# - Success rate
```

## Test Scenarios

### Scenario 1: Container Failure

```bash
# Kill one instance
docker kill nextjs-docker-app-2

# App still works (load balancer routes to healthy instances)
curl http://localhost:80

# Check logs
docker compose -f docker-compose.prod.yml logs nginx

# Restart failed instance
docker compose -f docker-compose.prod.yml up -d --scale app=3
```

### Scenario 2: High Load

```bash
# Generate load
for i in {1..100}; do
  curl -s http://localhost:80 > /dev/null &
done

# Monitor resources
docker stats

# Check if all instances handling requests
docker compose -f docker-compose.prod.yml logs app | grep "GET /"
```

### Scenario 3: Rolling Update

```bash
# Make a code change
echo "// Updated at $(date)" >> pages/index.tsx

# Rebuild
docker compose -f docker-compose.prod.yml build

# Rolling update (one at a time)
# Due to Docker Compose limitations, this is manual:

# Update instance 1
docker compose -f docker-compose.prod.yml up -d --no-deps --scale app=2 app
docker compose -f docker-compose.prod.yml up -d --no-deps --scale app=3 app

# Or just restart all
docker compose -f docker-compose.prod.yml up -d --force-recreate --scale app=3
```

## Verification Checklist

- [ ] All 3 app instances running
- [ ] Nginx container running
- [ ] Health checks passing
- [ ] Load balancer distributing requests
- [ ] PWA works (offline mode)
- [ ] Service worker active
- [ ] Can scale up to 5 instances
- [ ] Can scale down to 2 instances
- [ ] Survives container failure
- [ ] Resource limits enforced

## Expected Behavior

### Load Distribution

Nginx uses `least_conn` - routes to instance with fewest active connections:

- Request 1 → app-1
- Request 2 → app-2
- Request 3 → app-3
- Request 4 → app-1 (round robin)

### Resource Usage

Per container (configured limits):

- CPU: 0.5-2 cores
- Memory: 256MB-1GB
- Nginx: 64MB-256MB

### Health Checks

- App: Every 30s, `/api/hello` must return 200
- Nginx: Every 30s, `/health` must return 200
- Unhealthy after 3 failed checks

## Troubleshooting

### Containers not starting?

```bash
# Check logs
docker compose -f docker-compose.prod.yml logs

# Check resources
docker system df

# Clean up
docker compose -f docker-compose.prod.yml down -v
docker system prune -f
```

### Nginx showing 502 Bad Gateway?

```bash
# Check app containers are healthy
docker compose -f docker-compose.prod.yml ps

# Check nginx can reach app
docker exec nextjs-docker-nginx-1 ping -c 3 app

# Check nginx config
docker exec nextjs-docker-nginx-1 nginx -t

# Restart
docker compose -f docker-compose.prod.yml restart nginx
```

### Port already in use?

```bash
# Find what's using port 80
lsof -ti:80

# Kill the dev server
pkill -f "bun.*start" || pkill -f "next"

# Or use different port in docker-compose.prod.yml
# ports: "8080:80"
```

### Scale not working?

```bash
# Docker Compose v2 syntax
docker compose -f docker-compose.prod.yml up -d --scale app=3

# Old docker-compose v1 syntax
docker-compose -f docker-compose.prod.yml up -d --scale app=3
```

## Performance Benchmarks

Expected with 3 instances on M1 Mac:

```
Requests/sec:     ~500-1000
Response time:    ~50-100ms
Success rate:     99.9%
Memory per inst:  ~100-200MB
CPU per inst:     ~5-15%
```

## Cleanup

```bash
# Stop all containers
docker compose -f docker-compose.prod.yml down

# Remove volumes
docker compose -f docker-compose.prod.yml down -v

# Remove images
docker rmi nextjs-app:latest

# Full cleanup
docker system prune -af
```

## Notes

- `deploy.replicas: 3` in docker-compose.prod.yml doesn't work with docker-compose (it's Docker Swarm)
- Use `--scale app=N` flag instead
- Nginx automatically discovers all app instances via Docker DNS
- Each request gets new service worker (PWA works across all instances)
- Session state not shared (use Redis for shared sessions if needed)

## Next Steps

1. Test with real traffic
2. Add monitoring (Prometheus + Grafana)
3. Add logging aggregation (ELK stack)
4. Set up CI/CD pipeline
5. Deploy to production (AWS ECS, GCP Cloud Run, etc.)

Production-ready scaling. Clean, simple, effective.
