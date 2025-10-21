import type { NextApiRequest, NextApiResponse } from "next";
import axios from "axios";

type WeatherResponse = {
  name: string;
  sys: {
    country: string;
  };
  main: {
    temp: number;
    feels_like: number;
    humidity: number;
    pressure: number;
  };
  weather: Array<{
    id: number;
    main: string;
    description: string;
    icon: string;
  }>;
  wind: {
    speed: number;
  };
  dt: number;
};

type ErrorResponse = {
  error: string;
};

// Geocoding to get coordinates from city name
async function getCityCoordinates(city: string) {
  const geoResponse = await axios.get(
    `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(
      city
    )}&count=1&language=en&format=json`
  );

  if (!geoResponse.data.results || geoResponse.data.results.length === 0) {
    throw new Error("City not found");
  }

  return geoResponse.data.results[0];
}

// Weather code to description mapping
function getWeatherDescription(code: number): {
  id: number;
  main: string;
  description: string;
  icon: string;
} {
  const weatherMap: Record<
    number,
    { id: number; main: string; description: string; icon: string }
  > = {
    0: { id: 800, main: "Clear", description: "clear sky", icon: "01d" },
    1: { id: 800, main: "Clear", description: "mainly clear", icon: "01d" },
    2: { id: 801, main: "Clouds", description: "partly cloudy", icon: "02d" },
    3: { id: 803, main: "Clouds", description: "overcast", icon: "04d" },
    45: { id: 741, main: "Fog", description: "fog", icon: "50d" },
    48: {
      id: 741,
      main: "Fog",
      description: "depositing rime fog",
      icon: "50d",
    },
    51: { id: 300, main: "Drizzle", description: "light drizzle", icon: "09d" },
    53: {
      id: 301,
      main: "Drizzle",
      description: "moderate drizzle",
      icon: "09d",
    },
    55: { id: 302, main: "Drizzle", description: "dense drizzle", icon: "09d" },
    61: { id: 500, main: "Rain", description: "slight rain", icon: "10d" },
    63: { id: 501, main: "Rain", description: "moderate rain", icon: "10d" },
    65: { id: 502, main: "Rain", description: "heavy rain", icon: "10d" },
    71: { id: 600, main: "Snow", description: "slight snow", icon: "13d" },
    73: { id: 601, main: "Snow", description: "moderate snow", icon: "13d" },
    75: { id: 602, main: "Snow", description: "heavy snow", icon: "13d" },
    80: {
      id: 520,
      main: "Rain",
      description: "slight rain showers",
      icon: "09d",
    },
    81: {
      id: 521,
      main: "Rain",
      description: "moderate rain showers",
      icon: "09d",
    },
    82: {
      id: 522,
      main: "Rain",
      description: "violent rain showers",
      icon: "09d",
    },
    95: {
      id: 200,
      main: "Thunderstorm",
      description: "thunderstorm",
      icon: "11d",
    },
    96: {
      id: 201,
      main: "Thunderstorm",
      description: "thunderstorm with slight hail",
      icon: "11d",
    },
    99: {
      id: 202,
      main: "Thunderstorm",
      description: "thunderstorm with heavy hail",
      icon: "11d",
    },
  };

  return (
    weatherMap[code] || {
      id: 800,
      main: "Clear",
      description: "clear sky",
      icon: "01d",
    }
  );
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<WeatherResponse | ErrorResponse>
) {
  const { city } = req.query;

  if (!city || typeof city !== "string") {
    return res.status(400).json({ error: "City parameter is required" });
  }

  try {
    // Get city coordinates
    const geoData = await getCityCoordinates(city);

    // Get weather data from Open-Meteo (completely free, no API key)
    const weatherResponse = await axios.get(
      `https://api.open-meteo.com/v1/forecast?latitude=${geoData.latitude}&longitude=${geoData.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m&timezone=auto`
    );

    const current = weatherResponse.data.current;
    const weather = getWeatherDescription(current.weather_code);

    // Transform to match our existing format
    const response: WeatherResponse = {
      name: geoData.name,
      sys: {
        country: geoData.country_code || geoData.country || "N/A",
      },
      main: {
        temp: current.temperature_2m,
        feels_like: current.apparent_temperature,
        humidity: current.relative_humidity_2m,
        pressure: current.surface_pressure,
      },
      weather: [weather],
      wind: {
        speed: current.wind_speed_10m,
      },
      dt: Math.floor(new Date(current.time).getTime() / 1000),
    };

    res.status(200).json(response);
  } catch (error) {
    if (axios.isAxiosError(error)) {
      return res.status(404).json({ error: "City not found" });
    }
    res.status(500).json({ error: "Failed to fetch weather data" });
  }
}
