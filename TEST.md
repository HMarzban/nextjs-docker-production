# Testing Checklist

## ✅ Before Testing

1. **Install dependencies:**

   ```bash
   bun install
   ```

2. **Add API key to `.env.local`:**

   ```bash
   OPENWEATHER_API_KEY=your_key_here
   ```

3. **Start dev server:**

   ```bash
   bun dev
   ```

## 🧪 Test Cases

### 1. Home Page (/)

- [ ] Page loads with dark gradient background
- [ ] Title shows "Welcome to Next.js"
- [ ] Badge components display (TypeScript, etc.)
- [ ] Weather Dashboard card is prominently displayed
- [ ] All links are clickable

**Expected:** Clean, styled homepage with all Tailwind classes working

### 2. Weather Page (/weather)

- [ ] Page loads with light gradient background
- [ ] Default cities load: Tehran, London, New York
- [ ] Weather cards show temperature, icons, humidity
- [ ] Can add new cities via search
- [ ] Can remove cities with X button
- [ ] Weather icons are colorful and large
- [ ] Hover effects work on cards

**Expected:** Functional weather dashboard with real data

### 3. API Routes

- [ ] `/api/hello` returns JSON
- [ ] `/api/weather?city=Paris` returns weather data

### 4. Styles (SCSS + Tailwind)

- [ ] Tailwind utility classes work
- [ ] daisyUI components work (btn, card, badge, alert)
- [ ] SCSS variables are applied
- [ ] Responsive design works

## 🐛 Common Issues

### Issue: "API key not configured"

**Solution:**

1. Create `.env.local` in project root
2. Add: `OPENWEATHER_API_KEY=your_key`
3. Restart dev server

### Issue: Styles not loading

**Solution:**

```bash
rm -rf .next
bun dev
```

### Issue: Weather data not loading

**Solution:**

1. Check API key is valid
2. Check network tab in browser DevTools
3. New API keys take 10-15 mins to activate

### Issue: Turbopack errors

**Solution:**

```bash
# Use webpack instead
bun dev:webpack
```

Add to package.json:

```json
"dev:webpack": "next dev"
```

## 📊 Performance Check

```bash
# Build for production
bun run build

# Check bundle size
# Should see:
# - Home page: ~103KB
# - Weather page: ~129KB
```

## ✅ Success Criteria

- [ ] All pages load without errors
- [ ] Styles are applied correctly
- [ ] Weather data fetches successfully
- [ ] TypeScript compiles without errors
- [ ] Production build succeeds
- [ ] Docker build succeeds
