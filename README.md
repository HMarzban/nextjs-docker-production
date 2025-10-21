# Next.js Production on Docker

Production-ready Next.js app with TypeScript, Tailwind CSS v4, Bun runtime, Docker scaling, Nginx load balancing, and comprehensive load testing.

## Features

- ✅ **Next.js 15.5** - Latest with Turbopack and React 19
- ✅ **TypeScript** - Full type safety
- ✅ **Tailwind CSS v4 + daisyUI** - Modern styling
- ✅ **Bun Runtime** - Fast package manager and runtime
- ✅ **Docker** - Multi-stage optimized builds
- ✅ **Nginx Load Balancer** - Production-grade reverse proxy
- ✅ **Horizontal Scaling** - Tested with 10+ instances
- ✅ **Load Testing Suite** - Comprehensive performance testing
- ✅ **PWA Support** - Offline mode, installable
- ✅ **Production Ready** - Battle-tested configuration

## Quick Start

### Development

```bash
# Install dependencies
bun install

# Setup environment (optional - for weather page)
cp .env.example .env.local
# Add your OpenWeatherMap API key

# Run dev server
bun dev
```

Visit <http://localhost:3000>

### Production Deployment

```bash
# Build production image
make prod-build
# or: ./scripts/build-production.sh

# Start with 10 instances
docker-compose -f docker-compose.prod.yml up -d --scale app=10

# Verify
curl http://localhost:3009/health
```

## Load Testing

Test your scaled deployment:

```bash
# Run full test suite
./scripts/run-full-test.sh

# Or individual tests
make test-stress              # Standard: 10k requests, 60s
make test-stress-heavy        # Heavy: 20k requests, 120s
make test-stress-extreme      # Extreme: 50k requests, 300s

# Generate HTML report
./scripts/generate-report.sh
open ./load-test-results/report.html
```

**What gets tested:**

- Homepage concurrent load (100-500 concurrent users)
- API burst load (10k-50k requests)
- Sustained load (60-300 seconds)
- Mixed workload (multiple endpoints)

**Metrics collected:**

- Response time, TTFB, throughput
- Success rate, error rate
- CPU & memory per container
- Container health & load distribution

## Project Structure

```
.
├── pages/                      # Next.js pages
│   ├── _app.tsx               # App wrapper + PWA
│   ├── index.tsx              # Homepage
│   ├── weather.tsx            # Weather dashboard
│   └── api/                   # API routes
├── components/                # React components
├── styles/                    # Tailwind CSS
├── public/                    # Static assets
├── worker/                    # Service worker (PWA)
├── types/                     # TypeScript definitions
├── docs/                      # Documentation
│   ├── BUILD-ID.md           # Scaling guide
│   ├── DOCKER.md             # Deployment guide
│   ├── GITHUB-DEPLOY.md      # Git workflow
│   └── LOAD-TEST.md          # Testing guide
├── scripts/                   # Shell scripts
│   ├── build-production.sh   # Build with consistent ID
│   ├── stress-test.sh        # Load testing engine
│   ├── run-full-test.sh      # Full test automation
│   ├── generate-report.sh    # HTML report generator
│   ├── test-load-balancing.sh
│   ├── test-container-distribution.sh
│   └── generate-icons.js     # PWA icon generator
├── Dockerfile.bun             # Production Docker image
├── docker-compose.prod.yml    # Production deployment
├── nginx.conf                 # Load balancer config
├── Makefile                   # Common commands
└── README.md                  # This file
```

## Make Commands

```bash
# Production
make prod-build         # Build with consistent build ID
make prod-up            # Start services
make prod-down          # Stop services
make prod-scale N=10    # Scale to N instances
make prod-logs          # View logs
make prod-rebuild       # Rebuild and restart

# Testing
make test-stress        # Standard load test
make test-stress-heavy  # Heavy load test
make test-stress-extreme # Extreme load test
```

## Architecture

### Horizontal Scaling

```
                    ┌─────────────┐
                    │   Nginx     │  (Port 3009)
                    │   Alpine    │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
       ┌────▼───┐     ┌────▼───┐    ┌────▼───┐
       │ App #1 │     │ App #2 │    │ App #10│
       │  Bun   │     │  Bun   │    │  Bun   │
       └────────┘     └────────┘    └────────┘
            │              │              │
            └──────────────┴──────────────┘
                   Docker Network
```

**Load Balancing:** `least_conn` algorithm  
**Connection Pooling:** 128 keepalive connections  
**Health Checks:** 30s intervals  
**Resource Limits:** 1GB RAM, 2 CPUs per container  

### Performance

Expected with 10 instances:

| Metric | Target |
|--------|--------|
| Throughput | >1000 req/s |
| API Response | <100ms |
| Homepage (SSR) | <500ms |
| Success Rate | >99% |
| Error Rate | <1% |

## Configuration

### Environment Variables

Create `.env.local` (optional):

```bash
# OpenWeatherMap API Key (for weather page)
OPENWEATHER_API_KEY=your_api_key_here
```

### Build ID (Important for Scaling)

The app uses consistent build IDs to prevent version skew across containers:

```bash
# Automatic (uses git hash or timestamp)
./build-production.sh

# Manual
BUILD_ID="v1.2.3" docker-compose -f docker-compose.prod.yml build
```

See [BUILD-ID.md](./BUILD-ID.md) for details.

### Nginx Configuration

Production-grade `nginx.conf` includes:

- `least_conn` load balancing
- Connection pooling (128 keepalive)
- Rate limiting (DDoS protection)
- Gzip compression
- Security headers
- Docker DNS resolver
- Async I/O

## Progressive Web App (PWA)

The app is installable and works offline:

**Install:**

- **Desktop:** Chrome/Edge - Click install icon in address bar
- **Mobile:** Add to Home Screen

**Features:**

- 📱 Installable (mobile + desktop)
- 🔌 Offline mode
- 🔄 Background sync
- 💾 Smart caching

**Test offline mode:**

```bash
# 1. Open app in browser
# 2. Open DevTools → Network → Throttling → Offline
# 3. Reload page - should work offline
```

## Documentation

- **[docs/DOCKER.md](./docs/DOCKER.md)** - Complete deployment guide
- **[docs/BUILD-ID.md](./docs/BUILD-ID.md)** - Scaling and build IDs
- **[docs/LOAD-TEST.md](./docs/LOAD-TEST.md)** - Testing documentation
- **[docs/GITHUB-DEPLOY.md](./docs/GITHUB-DEPLOY.md)** - Push to GitHub

## Common Tasks

### Scale Deployment

```bash
# Scale to 5 instances
docker-compose -f docker-compose.prod.yml up -d --scale app=5

# Scale to 20 instances
docker-compose -f docker-compose.prod.yml up -d --scale app=20
```

### Monitor Resources

```bash
# Watch container stats
docker stats

# Check nginx status
curl http://localhost:3009/nginx_status

# View logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### Rebuild After Changes

```bash
# Rebuild with new build ID
make prod-rebuild

# Or manually
docker-compose -f docker-compose.prod.yml down
./scripts/build-production.sh
docker-compose -f docker-compose.prod.yml up -d --scale app=10
```

### Run Load Tests

```bash
# Full automated test
./scripts/run-full-test.sh

# Custom test (instances, concurrent, total, duration)
./scripts/stress-test.sh 15 300 30000 180

# Quick validation
./scripts/test-load-balancing.sh
./scripts/test-container-distribution.sh
```

## Troubleshooting

### Check Health

```bash
# Nginx
curl http://localhost:3009/health

# App API
curl http://localhost:3009/api/hello

# Container status
docker-compose -f docker-compose.prod.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# App only
docker-compose -f docker-compose.prod.yml logs -f app

# Nginx only
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Containers Not Starting

```bash
# Check resources
docker stats

# Rebuild clean
docker-compose -f docker-compose.prod.yml down -v
docker system prune -f
./build-production.sh
docker-compose -f docker-compose.prod.yml up -d --scale app=10
```

### High Error Rate

1. Check container health: `docker-compose ps`
2. Check logs: `docker-compose logs app`
3. Verify nginx config: `docker-compose exec nginx nginx -t`
4. Check resource limits: `docker stats`

## Tech Stack

- **Runtime:** Bun 1.x
- **Framework:** Next.js 15.5
- **Language:** TypeScript 5.x
- **Styling:** Tailwind CSS v4, daisyUI 5.x
- **Deployment:** Docker + Docker Compose
- **Load Balancer:** Nginx Alpine
- **Testing:** Custom bash scripts, curl

## Performance Tips

1. **Use build script** - Ensures consistent build ID
2. **Set resource limits** - Prevents memory issues
3. **Monitor stats** - Watch `docker stats` during load
4. **Scale horizontally** - Add more containers, not bigger ones
5. **Test regularly** - Run load tests before deployments

## License

MIT

## Contributing

Production-ready setup. Fork, test, improve, PR.

---

**Built with senior engineer principles:**

- Clean, maintainable code
- No overengineering
- Production patterns
- Comprehensive testing
- Battle-tested at scale

**Ready to deploy?**

```bash
./scripts/build-production.sh
docker-compose -f docker-compose.prod.yml up -d --scale app=10
./scripts/stress-test.sh
```

🚀 **Production ready!**
