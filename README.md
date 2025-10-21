# Next.js on Docker with Bun, TypeScript & Tailwind CSS v4

Production-ready Next.js app with TypeScript, Tailwind CSS v4, and optimized Docker setup using Bun.

## Features

- ✅ **Next.js 15.5** - Latest with Turbopack and React 19
- ✅ **TypeScript** - Full type safety and IntelliSense
- ✅ **Tailwind CSS v4** - Latest with CSS-first configuration
- ✅ **daisyUI 5.3** - Beautiful UI components
- ✅ **Turbopack** - Ultra-fast dev server (3x faster than Webpack)
- ✅ **Weather Dashboard** - Real-time weather with SSR
- ✅ **PWA Support** - Offline mode, installable, background updates
- ✅ **Bun** - Fast package manager and runtime
- ✅ **Docker** - Optimized multi-stage build
- ✅ **Production Ready** - Standalone output, proper caching

## Quick Start

### 1. Install Dependencies

```bash
bun install
```

### 2. Setup API Key (Required for Weather Page)

Get your **FREE** OpenWeatherMap API key:

1. Sign up at: <https://openweathermap.org/api>
2. Copy your API key (takes 10-15 mins to activate)
3. Create `.env.local` in project root:

```bash
OPENWEATHER_API_KEY=your_actual_api_key_here
```

### 3. Run Development Server

```bash
bun dev
```

Visit:

- **Home:** <http://localhost:3000>
- **Weather Dashboard:** <http://localhost:3000/weather>

> **Note:** Weather page will show a setup warning if API key is missing

### Docker Deployment

**Quick Start:**

```bash
# Single instance
make up

# Production with scaling
make prod-scale N=3
```

**📚 Full Documentation:**

- [QUICKSTART.md](./QUICKSTART.md) - Quick reference
- [DOCKER.md](./DOCKER.md) - Complete guide
- [PWA.md](./PWA.md) - Progressive Web App setup
- [OFFLINE-TEST.md](./OFFLINE-TEST.md) - Offline mode testing
- [SCALE-TEST.md](./SCALE-TEST.md) - Horizontal scaling guide
- [SCALE-RESULTS.md](./SCALE-RESULTS.md) - Load testing results

**🚀 Load Testing:**

- [TEST-SUITE-README.md](./TEST-SUITE-README.md) - Complete load test overview
- [TESTING-QUICKSTART.md](./TESTING-QUICKSTART.md) - Quick testing guide
- [LOAD-TEST.md](./LOAD-TEST.md) - Detailed testing documentation

**Features:**

- ✅ Multi-stage optimized builds
- ✅ Health checks & auto-restart
- ✅ Resource limits (CPU/Memory)
- ✅ Nginx load balancing
- ✅ Horizontal scaling
- ✅ Production load testing suite
- ✅ Production-ready

## Load Testing

Test your deployment with production-grade load testing:

```bash
# One-command full test (build + deploy + test)
./run-full-test.sh

# Or use Make targets
make test-stress              # 10 instances, 10k requests, 60s
make test-stress-heavy        # 10 instances, 20k requests, 120s
make test-stress-extreme      # 10 instances, 50k requests, 300s
```

**What gets tested:**

- ✅ Homepage concurrent load (100-500 concurrent users)
- ✅ API burst load (10k-50k requests)
- ✅ Sustained load (60-300 seconds)
- ✅ Mixed workload (multiple endpoints)

**Metrics collected:**

- Response time, TTFB, throughput
- Success rate, error rate
- CPU & memory per container
- Container health & distribution
- Connection pooling efficiency

**Reports generated:**

```bash
./generate-report.sh
open ./load-test-results/report.html
```

See [TESTING-QUICKSTART.md](./TESTING-QUICKSTART.md) to get started.

## Project Structure

```
├── pages/           # Next.js pages (TypeScript)
│   ├── _app.tsx    # App wrapper + PWA setup
│   ├── index.tsx   # Home page with daisyUI
│   ├── weather.tsx # Weather dashboard with SSR
│   └── api/
│       ├── hello.ts   # Example API route
│       └── weather.ts # Weather API proxy
├── components/     # React components
│   └── OfflineIndicator.tsx # Network status indicator
├── styles/         # Styling (Tailwind)
│   └── globals.css # Main styles + Tailwind + daisyUI
├── public/         # Static assets
│   ├── manifest.json  # PWA manifest
│   ├── icon-*.svg     # PWA icons
│   └── favicon.ico
├── next.config.mjs # Next.js + PWA config
├── tsconfig.json   # TypeScript configuration
├── Dockerfile.bun  # Optimized Docker build
└── package.json
```

## Scripts

```bash
bun dev         # Development server with Turbopack (⚡ 3x faster)
bun build       # Production build (Webpack - optimized)
bun start       # Production server
bun type-check  # TypeScript type checking
```

**Note:** Turbopack is used for dev only (Next.js 15 doesn't support Turbopack for production builds yet)

## Weather Dashboard

Visit `/weather` to see the real-time weather dashboard:

**Features:**

- 🌍 Pre-loaded with Tehran, London, and New York weather
- ➕ Add any city in the world
- ❌ Remove cities you don't need
- 🎨 Beautiful UI with weather icons
- ⚡ Server-Side Rendering for instant load
- 📱 Fully responsive design

**Tech Stack:**

- OpenWeatherMap API for weather data
- React Icons (weather icons)
- daisyUI components
- SSR with `getServerSideProps`
- Axios for API calls

## Styling

### Tailwind CSS v4 + daisyUI

Clean and simple - just Tailwind + daisyUI:

```scss
// styles/globals.scss
@import "tailwindcss";
@plugin "daisyui";
```

Use Tailwind utility classes and daisyUI components:

```jsx
<button className="btn btn-primary">Click me</button>
<div className="card shadow-xl bg-base-100">
  <div className="card-body">
    <h2 className="card-title">Card Title</h2>
    <p>Card content</p>
  </div>
</div>
```

> **Browser Cache:**
> If styles don't load, hard refresh: **Cmd+Shift+R** (Mac) or **Ctrl+Shift+R** (Windows)

> **Sass Warning:**
> The single `@import "tailwindcss"` deprecation warning is expected and harmless.

> **Turbopack Errors:**
> If you see cache errors: `pkill -9 -f "next dev" && rm -rf .next && bun dev`

Browse components: [daisyUI Documentation](https://daisyui.com/components/)

## Environment Variables

Create `.env.local` for local development:

```bash
# OpenWeatherMap API Key (required for weather page)
# Get your free API key from https://openweathermap.org/api
OPENWEATHER_API_KEY=your_openweather_api_key_here
```

**Important Notes:**

- Free tier includes 1,000 API calls/day
- New API keys take 10-15 minutes to activate
- Check key status: <https://home.openweathermap.org/api_keys>
- Detailed setup instructions in `SETUP.md`

## Production Deployment

The Docker image is optimized:

- Multi-stage build
- Standalone output (minimal size)
- Non-root user
- Layer caching
- Health checks & auto-restart
- Horizontal scaling support

## Browser Support

Modern browsers with full ES6+ support:

- Chrome/Edge (latest)
- Safari (latest)
- Firefox (latest)

## PWA Features

Full Progressive Web App support:

- 📱 **Installable** - Add to home screen (mobile + desktop)
- 🔌 **Offline Mode** - Works without internet
- 🔄 **Background Updates** - Auto-sync new versions
- 📊 **Network Indicator** - Shows online/offline status
- 💾 **Smart Caching** - Entire app cached locally

See [PWA.md](./PWA.md) for details.

## Notes

- Uses Turbopack for faster dev builds
- Tailwind CSS v4 with daisyUI components
- Optimized Docker setup with Bun runtime
- Production-ready with scaling capabilities
- PWA enabled in production only

Clean, simple, production-ready. No overengineering.
