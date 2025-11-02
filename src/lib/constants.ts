/**
 * Application-wide constants
 */

// API Endpoints
export const API_ENDPOINTS = {
  GEOCODING: "https://geocoding-api.open-meteo.com/v1/search",
  WEATHER: "https://api.open-meteo.com/v1/forecast",
  GITHUB_ZEN: "https://api.github.com/zen",
} as const;

// API Configuration
export const API_CONFIG = {
  GEOCODING_COUNT: 1,
  GEOCODING_LANGUAGE: "en",
  GEOCODING_FORMAT: "json",
  EXTERNAL_API_TIMEOUT: 2000, // ms
} as const;

// Weather Code Mapping
export interface WeatherInfo {
  id: number;
  main: string;
  description: string;
  icon: string;
}

export const WEATHER_CODE_MAP: Record<number, WeatherInfo> = {
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

// Default weather info (fallback)
export const DEFAULT_WEATHER_INFO: WeatherInfo = {
  id: 800,
  main: "Clear",
  description: "clear sky",
  icon: "01d",
};

// Default cities for weather page
export const DEFAULT_CITIES = ["Tehran", "London", "New York"] as const;
