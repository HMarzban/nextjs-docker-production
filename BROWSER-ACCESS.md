# Browser Access Guide

## Quick Fix

**The app IS working** - you just need to refresh your browser properly.

### Method 1: Hard Refresh (Recommended)

1. Open: **<http://localhost>** (not https, just http)
2. Press: **Cmd + Shift + R** (Mac) or **Ctrl + Shift + F5** (Windows)
3. Should load immediately

### Method 2: Clear Cache

1. Open: **<http://localhost>**
2. Open DevTools: F12 or Cmd+Option+I
3. Right-click on refresh button
4. Select: **"Empty Cache and Hard Reload"**

### Method 3: Incognito Mode

1. Open Incognito/Private window
2. Go to: **<http://localhost>**
3. Should work immediately (no cache)

## URLs to Try

```bash
# Main app
http://localhost

# Health check
http://localhost/health

# Weather page
http://localhost/weather

# PWA manifest
http://localhost/manifest.json
```

## Verify It's Working

```bash
# Terminal test
curl http://localhost

# Should return HTML with "Welcome to Next.js"
```

## Common Issues

### Issue: "This site can't be reached"

**Solution**: Make sure you're using `http://` not `https://`

- ❌ Wrong: <https://localhost>
- ✅ Right: <http://localhost>

### Issue: Blank white page

**Solution**: Hard refresh or clear cache (see methods above)

### Issue: Old version showing

**Solution**: Service worker caching - clear application cache:

1. DevTools → Application → Storage → Clear site data
2. Refresh

### Issue: Still not working

**Check containers are running:**

```bash
docker compose -f docker-compose.prod.yml ps

# Should show:
# - app-1 (healthy)
# - app-2 (healthy)  
# - nginx (running)
```

## What You Should See

### Homepage

- Dark background (gradient from gray-900 to black)
- "Welcome to Next.js" heading
- "Production-ready app with TypeScript, Tailwind v4 & daisyUI"
- 4 cards (Weather Dashboard, Documentation, daisyUI, Examples)
- Badges at bottom (TypeScript, Tailwind v4, daisyUI, Docker)

### Weather Page

- Navigate to: <http://localhost/weather>
- Shows weather for Tehran, London, New York
- Can add/remove cities

## Browser DevTools Check

1. Open DevTools (F12)
2. **Console tab**: Should have no major errors
3. **Network tab**: All requests should be 200 OK (green)
4. **Application tab → Service Workers**: Should see `sw.js` registered

## Test Offline Mode

Once loaded:

1. DevTools → Application → Service Workers
2. Check "Offline" checkbox
3. Refresh page
4. **Should still work** ✅
5. Red "Offline mode" indicator top-right

## Multiple Browsers

Test in different browsers if one isn't working:

- ✅ Chrome/Edge: <http://localhost>
- ✅ Firefox: <http://localhost>  
- ✅ Safari: <http://localhost>

## Port Conflicts

If port 80 is busy:

```bash
# Check what's on port 80
lsof -i :80

# Stop conflicting service
sudo lsof -ti:80 | xargs kill
```

## Restart Everything

If still having issues:

```bash
# Stop containers
docker compose -f docker-compose.prod.yml down

# Start fresh
docker compose -f docker-compose.prod.yml up -d --scale app=2

# Wait 10 seconds
sleep 10

# Test
curl http://localhost
```

## Screenshots

What it should look like:

- **Dark theme** with gradient background
- **Blue accents** on cards
- **Clean modern UI** with Tailwind CSS
- **Responsive** layout

## Still Not Working?

1. **Check terminal**:

   ```bash
   curl http://localhost
   # If this works, it's a browser issue
   ```

2. **Check logs**:

   ```bash
   docker compose -f docker-compose.prod.yml logs nginx
   docker compose -f docker-compose.prod.yml logs app
   ```

3. **Try different port**:
   Edit `docker-compose.prod.yml`:

   ```yaml
   nginx:
     ports:
       - "8080:80"  # Use 8080 instead
   ```

   Then access: <http://localhost:8080>

## Success Indicators

✅ Terminal curl works
✅ Browser shows dark homepage  
✅ Service worker registered (DevTools → Application)
✅ Can navigate to /weather
✅ Works offline after initial load

**The app is running. Just need proper browser refresh!**
