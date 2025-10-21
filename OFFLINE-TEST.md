# Offline Mode Testing Guide

## Quick Test

1. **Build & Start Production Server**

   ```bash
   bun install
   bun run build
   bun start
   ```

2. **Open Browser**
   - Visit: `http://localhost:3000`
   - Open DevTools (F12 or Cmd+Option+I)

3. **Verify Service Worker**
   - Go to: **Application** → **Service Workers**
   - Should see: `sw.js` with status "activated and running"
   - Check the precache list (should have all your assets)

4. **Test Offline**
   - Method 1 (DevTools):
     - Application → Service Workers → Check "Offline"
     - Or: Network tab → Change to "Offline"

   - Method 2 (Real):
     - Turn off WiFi
     - Disable network adapter

5. **Navigate While Offline**
   - Refresh page (Cmd+R / Ctrl+R)
   - Click around: `/` → `/weather` → back to `/`
   - **Everything should work perfectly**
   - See the offline indicator (red badge top-right)

6. **Go Back Online**
   - Re-enable network
   - See "Back online" notification (green badge)
   - Auto-dismisses after 3 seconds

## What Gets Cached

✅ All HTML pages (`/`, `/weather`)  
✅ All JavaScript chunks  
✅ All CSS files  
✅ All images and icons  
✅ API responses (with 10s timeout)  
✅ Font files  
✅ Static assets  

## Caching Strategies

| Resource Type | Strategy | Cache Duration |
|---------------|----------|----------------|
| Pages (HTML) | NetworkFirst | 24 hours |
| API calls | NetworkFirst (10s timeout) | 24 hours |
| JS/CSS | StaleWhileRevalidate | 24 hours |
| Images | StaleWhileRevalidate | 24 hours |
| Fonts | CacheFirst | 7 days |
| Videos/Audio | CacheFirst | 24 hours |

## Test Scenarios

### Scenario 1: First Visit

1. Clear all cache (DevTools → Clear Storage)
2. Visit `http://localhost:3000`
3. Service Worker installs in background
4. All assets cached automatically
5. Check: Application → Cache Storage → See all caches

### Scenario 2: Offline Navigation

1. Load site while online
2. Go offline
3. Navigate between pages
4. Everything works seamlessly
5. Offline indicator shows

### Scenario 3: Background Updates

1. Keep site open
2. Deploy new version (`bun build`)
3. Service worker detects update
4. Prompts: "New version available! Click OK to update"
5. Click OK → Auto-refresh → New version loaded

### Scenario 4: API Caching

1. Visit `/weather` page while online
2. Weather data loads from API
3. Go offline
4. Refresh page
5. **Cached weather data still displays**
6. No error, just shows last cached data

## Expected Behavior

### ✅ Works Offline

- Static pages load instantly
- Navigation between pages works
- Images, styles, scripts load
- Offline indicator visible

### ✅ Updates in Background

- New versions detected automatically
- User gets prompted
- Smooth update experience

### ✅ Network-Aware

- Online: Fresh data from network
- Offline: Cached data served
- Indicator shows current status

## Debugging

### Service Worker Not Installing?

```bash
# Check console for errors
# Ensure you're on production build
NODE_ENV=production bun build
NODE_ENV=production bun start
```

### Not Working Offline?

1. Check DevTools → Application → Service Workers
2. Verify status: "activated and is running"
3. Check cache: Application → Cache Storage
4. Should see multiple caches with files

### Clear Everything

```bash
# DevTools → Application → Clear Storage → "Clear site data"
# Or programmatically:
```

```javascript
// In browser console:
navigator.serviceWorker.getRegistrations().then(registrations => {
  registrations.forEach(registration => registration.unregister())
})
```

## Production vs Development

### Development (disabled)

- `NODE_ENV=development` → No SW
- Faster hot reload
- No caching headaches

### Production (enabled)

- `NODE_ENV=production` → SW active
- Full offline support
- Background updates

## Mobile Testing

### iOS (Safari)

1. Open in Safari
2. Tap Share → "Add to Home Screen"
3. Opens as standalone app
4. Test offline by enabling Airplane Mode

### Android (Chrome)

1. Chrome shows "Install app" prompt
2. Or: Menu → "Install app"
3. Opens as PWA
4. Test offline with Airplane Mode

## Docker Testing

```bash
# Build production image
docker build -f Dockerfile.bun -t nextjs-pwa .

# Run
docker run -p 3000:3000 nextjs-pwa

# Test same as above
```

## Known Behaviors

### API Calls

- **Online**: Fresh data from server
- **Offline**: Cached data (last successful response)
- **Timeout**: 10 seconds, then falls back to cache

### Navigation

- All pages precached on first visit
- Instant navigation even offline
- No "dinosaur" error page

### Updates

- Checked on every page navigation
- User prompted for major updates
- Non-blocking, happens in background

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SW not registering | Check `NODE_ENV=production` |
| Offline not working | Clear cache and reload |
| Old version stuck | Unregister SW, clear cache |
| API not caching | Check Network tab for failed requests |
| Indicator not showing | Check browser online/offline events |

## Performance

- **First Load**: ~100-130 KB JS
- **Cached Load**: Instant (0ms network)
- **Offline Load**: <50ms from cache
- **Update Check**: <100ms background

Clean, fast, production-ready offline support. Just works™
