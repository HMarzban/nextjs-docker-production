# PWA Setup

Progressive Web App implementation with offline support, background updates, and network status indicator.

## Features

✅ **Offline Mode**: Entire app cached for offline use  
✅ **Background Updates**: Service worker auto-updates in background  
✅ **Network Indicator**: Shows online/offline status  
✅ **Installable**: Add to home screen on mobile/desktop  
✅ **Production Ready**: Zero config, industry standard tooling

## Stack

- `@ducanh2912/next-pwa`: Maintained fork for Next.js 13+ (supports Next.js 15)
- Auto-generated service worker with Workbox
- Smart caching strategies (NetworkFirst, CacheFirst, StaleWhileRevalidate)

## Installation

```bash
npm install
# or
bun install
```

## Testing

### Development

PWA is **disabled** in dev mode (check `next.config.mjs`)

### Production

```bash
bun install
bun run build
bun start
# visit http://localhost:3000
```

### Offline Testing

1. Visit <http://localhost:3000>
2. Open DevTools (F12) → Application → Service Workers
3. Wait for "activated and is running" status
4. Check "Offline" checkbox
5. Refresh page (Cmd+R)
6. **App still works perfectly**
7. Navigate to `/weather` - still works
8. See offline indicator (red badge top-right)

### Install Testing

1. Chrome: Look for install icon in address bar
2. Mobile: "Add to Home Screen" prompt
3. Edge: Settings → Apps → Install

### Detailed Testing

See [OFFLINE-TEST.md](./OFFLINE-TEST.md) for comprehensive testing guide

## Caching Strategy

- **Pages/HTML**: NetworkFirst (10s timeout) → Cache
- **API calls**: NetworkFirst (10s timeout) → Cache  
- **JS/CSS/Images**: StaleWhileRevalidate (show cache, update in background)
- **Fonts**: CacheFirst (7 days)
- **Video/Audio**: CacheFirst with range requests
- **Updates**: Background sync, no interruption

## Background Updates

Service worker checks for updates on:

- Page load
- Manual refresh
- Navigation

User gets prompt: "A new version is available! Click OK to update and refresh."

## Customization

### manifest.json

```json
{
  "name": "Your App Name",
  "theme_color": "#yourcolor"
}
```

### Icons

Replace `public/icon-192.svg` and `public/icon-512.svg`

### Caching

Check `next.config.mjs` → PWA options

## How It Works

1. **Build**: `@ducanh2912/next-pwa` generates `sw.js` in `public/`
2. **Runtime**: Browser registers SW, caches assets
3. **Offline**: SW serves cached content
4. **Updates**: SW checks for new version, installs in background
5. **Indicator**: React component monitors `navigator.onLine`

## Docker Build

Service worker files are excluded from Docker image (see `.dockerignore`):

```
public/sw.js
public/sw.js.map
public/workbox-*.js
```

They're generated during build, served from `public/`

## No Bullshit

- No manual SW coding
- No complex Workbox config
- No cache invalidation headaches
- Just works™
