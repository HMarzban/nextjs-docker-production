/**
 * Weather utilities - consolidated
 */

import axios from "axios";
import { ApiError, log } from "@/lib/api-utils";
import {
  WEATHER_CODE_MAP,
  DEFAULT_WEATHER_INFO,
  type WeatherInfo,
} from "@/lib/constants";

export function getWeatherDescription(code: number): WeatherInfo {
  return WEATHER_CODE_MAP[code] || DEFAULT_WEATHER_INFO;
}

export async function fetchWeatherData(city: string) {
  try {
    // Get coordinates
    const geoResponse = await axios.get(
      "https://geocoding-api.open-meteo.com/v1/search",
      {
        params: {
          name: city,
          count: 1,
          language: "en",
          format: "json",
        },
        timeout: 5000,
      }
    );

    if (!geoResponse.data.results?.length) {
      throw new ApiError(`City "${city}" not found`, 404, "NOT_FOUND");
    }

    const geoData = geoResponse.data.results[0];

    // Get weather
    const weatherResponse = await axios.get(
      "https://api.open-meteo.com/v1/forecast",
      {
        params: {
          latitude: geoData.latitude,
          longitude: geoData.longitude,
          current:
            "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m",
          timezone: "auto",
        },
        timeout: 5000,
      }
    );

    if (!weatherResponse.data.current) {
      throw new ApiError("Invalid weather data", 502, "EXTERNAL_API_ERROR");
    }

    const current = weatherResponse.data.current;
    const weather = getWeatherDescription(current.weather_code);

    return {
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
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }
    if (axios.isAxiosError(error)) {
      log.error("Weather API error", error, { city });
      throw new ApiError(
        "Failed to fetch weather data",
        502,
        "EXTERNAL_API_ERROR"
      );
    }
    throw error;
  }
}
