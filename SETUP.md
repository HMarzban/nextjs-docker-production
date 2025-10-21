# Quick Setup Guide

## 1. Get Your FREE Weather API Key

The weather page requires an API key from OpenWeatherMap.

### Steps

1. Go to: <https://openweathermap.org/api>
2. Click "Sign Up" (it's FREE)
3. Verify your email
4. Go to your account → API keys
5. Copy your API key

## 2. Configure Environment Variable

Open `.env.local` and add your key:

```bash
OPENWEATHER_API_KEY=your_actual_api_key_here
```

**Example:**

```bash
OPENWEATHER_API_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

## 3. Start Development Server

```bash
bun dev
```

Visit:

- Home: <http://localhost:3000>
- Weather: <http://localhost:3000/weather>

## Troubleshooting

### Weather page shows "API key not configured"

- Make sure `.env.local` exists
- Make sure your API key is valid
- Restart the dev server after adding the key

### Styles not loading

- Clear `.next` folder: `rm -rf .next`
- Restart dev server: `bun dev`

### OpenWeatherMap API not working

- Free tier has 1000 calls/day limit
- New API keys take 10-15 minutes to activate
- Check your API key status at: <https://home.openweathermap.org/api_keys>
