# Next.js Production Stack

A Next.js deployment example using Bun, a multistage Docker image and Nginx. It explores replica scaling, consistent build IDs, health checks and synthetic load testing. CI verifies builds and HTTP behavior; browser/PWA checks remain manual.

## 🚀 Features

- **Next.js 15.5** - With Turbopack and React 19
- **TypeScript** - Full type safety with strict mode
- **Bun Runtime** - Optimized for Bun with fast package management and runtime
- **Docker Optimized** - Multi-stage builds with Alpine, optimized layers, and production-ready configuration
- **Horizontal Scaling** - Configurable Compose replicas; choose a count that fits your host
- **Nginx Load Balancer** - Production-grade reverse proxy
- **PWA Support** - Offline mode, installable, auto-updates
- **Code Quality** - ESLint, Prettier, input validation
- **Error Handling** - Structured logging and error responses
- **Load Testing** - Synthetic load tests with configurable failure thresholds

## 📋 Prerequisites

- **Bun** >= 1.0 (the supplied build/run scripts use Bun)
- **Docker** >= 20.10
- **Docker Compose** v2 plugin (`docker compose`) or newer

## 🏃 Quick Start

### Development

```bash
# Install dependencies
bun install

# Run development server
bun dev
```

Visit <http://localhost:3000>

### Production Deployment

```bash
# Build production image
make build

# Start with 10 instances
make rebuild

# Verify deployment
curl http://localhost:3009/health
```

## 📁 Project Structure

```text
.
├── src/
│   ├── lib/                    # Core utilities
│   │   ├── api-utils.ts       # Error handling, logging, validation
│   │   ├── validation.ts      # Zod schemas
│   │   ├── weather.ts         # Weather API utilities
│   │   └── constants.ts        # App constants
│   ├── pages/                  # Next.js pages
│   │   ├── api/               # API routes
│   │   │   ├── hello.ts      # Health check endpoint
│   │   │   └── weather.ts    # Weather API
│   │   ├── _app.tsx           # App wrapper + PWA
│   │   ├── index.tsx          # Homepage
│   │   └── weather.tsx        # Weather dashboard
│   ├── components/             # React components
│   └── styles/                 # Tailwind CSS
├── scripts/                    # Build & test scripts
├── docs/                       # Detailed documentation
├── Dockerfile.bun              # Production Docker image
├── docker-compose.prod.yml     # Production deployment
├── nginx.conf                  # Load balancer config
└── Makefile                    # Common commands
```

## 🛠️ Commands

### Development Commands

```bash
bun dev              # Start dev server with Turbopack
bun run build         # Build for production
bun run start         # Start production server
bun run lint          # Run ESLint
bun run lint:fix      # Fix linting issues
bun run format        # Format code with Prettier
bun run type-check    # TypeScript type checking
```

### Production (Makefile)

```bash
make build            # Build production image
make up              # Start containers
make down            # Stop containers
make scale N=10      # Scale to N instances
make rebuild         # Rebuild and restart (10 instances)
make logs            # View container logs
make check-build     # Verify build ID consistency
make clean           # Stop and clean up
```

### Testing

```bash
make test-health            # Test health endpoint
make test-stress            # Standard load test (10k requests)
make test-stress-heavy      # Heavy load test (20k requests)
make test-stress-extreme    # Extreme load test (50k requests)
make test-all              # Run all tests
```

## 🏗️ Architecture

### Horizontal Scaling

```text
                    ┌─────────────┐
                    │   Nginx     │  Port 3009
                    │   Alpine    │  Load Balancer
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
       ┌────▼───┐     ┌────▼───┐    ┌────▼───┐
       │ App #1 │     │ App #2 │    │ App #N │
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

### Performance Targets

| Metric | Target |
|--------|--------|
| Throughput | >1000 req/s |
| API Response | <100ms |
| Homepage (SSR) | <500ms |
| Success Rate | >99% |
| Error Rate | <1% |

## 🔧 Configuration

### Docker & Bun Optimization

This project is optimized for Docker and Bun runtime:

- **Docker**: Multi-stage builds with layer caching, Alpine-based images, and standalone Next.js output
- **Bun**: Native Bun runtime support with optimized Dockerfile (`Dockerfile.bun`) for faster builds and smaller images
- **Build Optimization**: Dependency caching, consistent build IDs for scaling, and health checks
- **Production Ready**: Non-root user, resource limits, and structured logging

### Environment Variables

Create `.env.local` (optional):

```bash
# Optional: For external API integrations
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
```

### Build ID (Important for Scaling)

Consistent build IDs prevent version skew across containers:

```bash
# Automatic (uses git hash or timestamp)
make build

# Manual
BUILD_ID="v1.2.3" docker compose -f docker-compose.prod.yml build
```

### Nginx Configuration

Production-grade `nginx.conf` includes:

- `least_conn` load balancing
- Connection pooling (128 keepalive)
- Rate limiting (DDoS protection)
- Gzip compression
- Security headers
- Docker DNS resolver
- Async I/O for performance

## 💻 Code Quality

### Features

- **ESLint** - Code linting with TypeScript support
- **Prettier** - Consistent code formatting
- **Zod Validation** - Type-safe input validation
- **Error Handling** - Structured error responses
- **Logging** - Contextual logging with timestamps

### Usage Examples

**Input Validation:**

```typescript
import { validate } from "../../lib/api-utils";
import { weatherQuerySchema } from "../../lib/validation";

const { city } = validate(weatherQuerySchema, req.query);
```

**Error Handling:**

```typescript
import { ApiError, withErrorHandler } from "../../lib/api-utils";

async function handler(req, res) {
  throw new ApiError("Not found", 404, "NOT_FOUND");
}

export default withErrorHandler(handler);
```

**Logging:**

```typescript
import { log } from "../../lib/api-utils";

log.info("Request received", { city });
log.error("API failed", error, { endpoint: "/api/weather" });
```

## 📱 Progressive Web App (PWA)

Full PWA support with offline capabilities:

**Features:**

- 📱 Installable (mobile + desktop)
- 🔌 Offline mode
- 🔄 Smart caching strategies
- ⚡ Auto-update prompts
- 💾 Cache management

**Caching Strategies:**

- **APIs** (`/api/*`): Network First (5 min cache)
- **Images/Fonts**: Cache First (30 days)
- **Next.js Static**: Cache First (1 year, immutable)
- **Pages**: Stale While Revalidate

**Testing:**

1. Build production: `bun run build && bun run start`
2. Open Chrome/Edge → Install icon in address bar
3. Test offline: DevTools → Network → Offline
4. Check browser installation criteria; record the actual result

## 🧪 Load Testing

Synthetic load testing helpers (see the [methodology and limits](docs/LOAD-TEST.md)):

```bash
# Standard test
make test-stress              # 10k requests, 100 concurrent, 60s

# Heavy test
make test-stress-heavy        # 20k requests, 200 concurrent, 120s

# Extreme test
make test-stress-extreme      # 50k requests, 500 concurrent, 300s

# Custom test
./scripts/stress-test.sh <instances> <concurrent> <total> <duration>
```

**What gets tested:**

- Concurrent load handling
- API burst capacity
- Sustained load performance
- Container health & distribution
- Response times & throughput

## 🔄 CI/CD

GitHub Actions workflow (`/.github/workflows/ci.yml`) includes:

- **Lint & Type Check** - Runs ESLint, TypeScript checking, and Prettier validation using Bun
- **Docker Build** - Builds optimized Docker image with Bun runtime, uses build cache
- **Docker Compose Test** - Tests full stack with 2 scaled instances, health checks, and API tests

**Optimized for:**

- Bun runtime (fast installs and builds)
- Docker layer caching (faster CI builds)
- Multi-stage builds (smaller images)
- Consistent build IDs (for scaling)

## 📊 Monitoring

### Health Checks

```bash
# Nginx health
curl http://localhost:3009/health

# App API
curl http://localhost:3009/api/hello

# Container status
docker compose -f docker-compose.prod.yml ps
```

### Resource Monitoring

```bash
# Container stats
docker stats

# Nginx status
curl http://localhost:3009/nginx_status

# View logs
make logs
docker compose -f docker-compose.prod.yml logs -f app
```

## 🔍 Troubleshooting

### Containers Not Starting

```bash
# Check resources
docker stats

# Rebuild clean
make clean
make build
make rebuild
```

### High Error Rate

1. Check container health: `docker compose -f docker-compose.prod.yml ps`
2. Check logs: `make logs`
3. Verify nginx config: `docker compose -f docker-compose.prod.yml exec nginx nginx -t`
4. Check resource limits: `docker stats`

### Build ID Mismatch

```bash
# Verify consistency
make check-build

# Rebuild with consistent ID
make rebuild
```

## 📚 Documentation

Detailed guides available in `docs/`:

- **[DOCKER.md](./docs/DOCKER.md)** - Complete deployment guide
- **[BUILD-ID.md](./docs/BUILD-ID.md)** - Scaling and build IDs
- **[LOAD-TEST.md](./docs/LOAD-TEST.md)** - Load testing guide
- **[PWA-NEXT-PWA.md](./docs/PWA-NEXT-PWA.md)** - PWA implementation
- **[GITHUB-DEPLOY.md](./docs/GITHUB-DEPLOY.md)** - GitHub deployment

## 🛡️ Production Best Practices

1. **Consistent Build IDs** - Use `make build` for scaling
2. **Resource Limits** - Set CPU/memory limits per container
3. **Health Checks** - Monitor container health regularly
4. **Horizontal Scaling** - Add more containers, not bigger ones
5. **Load Testing** - Test before deployments
6. **Monitoring** - Watch `docker stats` during load
7. **Logging** - Structured logs for debugging

## 🎯 Tech Stack

- **Runtime:** Bun 1.x (optimized for Docker)
- **Framework:** Next.js 15.5
- **Language:** TypeScript 5.x
- **Styling:** Tailwind CSS v4, daisyUI 5.x
- **Validation:** Zod 4.x
- **Deployment:** Docker + Docker Compose (optimized multi-stage builds)
- **Load Balancer:** Nginx Alpine
- **PWA:** @ducanh2912/next-pwa
- **CI/CD:** GitHub Actions (Docker & Bun optimized)

## 🤝 Contributing

Contributions welcome. Fork, make changes, test, and submit a PR.

**Guidelines:**

- Follow existing code style (ESLint + Prettier)
- Add tests for new features
- Update documentation as needed
- Keep commits focused and meaningful

## 📝 License

The original README declares MIT, but this repository has no standalone license
file. This maintenance pass preserves that declaration without adding new terms.
