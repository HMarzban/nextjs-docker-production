import { GetServerSideProps } from "next";
import Head from "next/head";
import { useState } from "react";
import axios from "axios";
import {
  WiDaySunny,
  WiCloudy,
  WiRain,
  WiSnow,
  WiThunderstorm,
  WiFog,
  WiDayHaze,
} from "react-icons/wi";
import { IoAddCircleOutline, IoCloseCircle } from "react-icons/io5";

interface WeatherData {
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
}

interface WeatherPageProps {
  initialCities: WeatherData[];
  error?: string;
}

const getWeatherIcon = (weatherId: number, main: string) => {
  if (weatherId >= 200 && weatherId < 300)
    return <WiThunderstorm className="text-6xl text-yellow-400" />;
  if (weatherId >= 300 && weatherId < 600)
    return <WiRain className="text-6xl text-blue-400" />;
  if (weatherId >= 600 && weatherId < 700)
    return <WiSnow className="text-6xl text-blue-200" />;
  if (weatherId >= 700 && weatherId < 800)
    return <WiFog className="text-6xl text-gray-400" />;
  if (weatherId === 800)
    return <WiDaySunny className="text-6xl text-yellow-500" />;
  if (weatherId > 800) return <WiCloudy className="text-6xl text-gray-500" />;
  return <WiDayHaze className="text-6xl text-gray-400" />;
};

export default function WeatherPage({
  initialCities,
  error,
}: WeatherPageProps) {
  const [cities, setCities] = useState<WeatherData[]>(initialCities);
  const [newCity, setNewCity] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(error || "");

  const addCity = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCity.trim()) return;

    setLoading(true);
    setErrorMsg("");

    try {
      const response = await axios.get(`/api/weather?city=${newCity}`);
      setCities([...cities, response.data]);
      setNewCity("");
    } catch (err) {
      setErrorMsg(
        `Could not find weather data for "${newCity}". Please try another city.`
      );
    } finally {
      setLoading(false);
    }
  };

  const removeCity = (cityName: string) => {
    setCities(cities.filter((city) => city.name !== cityName));
  };

  return (
    <>
      <Head>
        <title>Weather Dashboard | Next.js</title>
        <meta name="description" content="Real-time weather information" />
      </Head>

      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-blue-100 to-indigo-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
        <div className="container mx-auto px-4 py-8">
          {/* Error Warning */}
          {error && (
            <div className="alert alert-warning shadow-lg mb-8 max-w-4xl mx-auto">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="stroke-current shrink-0 h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              <div>
                <h3 className="font-bold">Connection Issue</h3>
                <div className="text-sm">{error}</div>
              </div>
            </div>
          )}

          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent mb-2">
              Weather Dashboard
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Real-time weather information for cities around the world
            </p>
          </div>

          {/* Add City Form */}
          <div className="max-w-2xl mx-auto mb-8">
            <form onSubmit={addCity} className="flex gap-2">
              <input
                type="text"
                placeholder="Add a new city (e.g., Paris, Tokyo, Sydney)"
                className="input input-bordered w-full bg-white dark:bg-gray-800"
                value={newCity}
                onChange={(e) => setNewCity(e.target.value)}
                disabled={loading}
              />
              <button
                type="submit"
                className="btn btn-primary"
                disabled={loading}
              >
                {loading ? (
                  <span className="loading loading-spinner"></span>
                ) : (
                  <>
                    <IoAddCircleOutline className="text-xl" />
                    Add
                  </>
                )}
              </button>
            </form>

            {errorMsg && (
              <div className="alert alert-error mt-4">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="stroke-current shrink-0 h-6 w-6"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span>{errorMsg}</span>
              </div>
            )}
          </div>

          {/* Weather Cards Grid */}
          {cities.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {cities.map((city) => (
                <div
                  key={city.name}
                  className="card bg-white dark:bg-gray-800 shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1"
                >
                  <div className="card-body">
                    <div className="flex justify-between items-start">
                      <div>
                        <h2 className="card-title text-2xl">
                          {city.name}
                          <span className="text-sm font-normal text-gray-500">
                            {city.sys.country}
                          </span>
                        </h2>
                        <p className="text-sm text-gray-500 capitalize">
                          {city.weather[0].description}
                        </p>
                      </div>
                      <button
                        onClick={() => removeCity(city.name)}
                        className="btn btn-ghost btn-sm btn-circle"
                        aria-label="Remove city"
                      >
                        <IoCloseCircle className="text-xl text-error" />
                      </button>
                    </div>

                    <div className="flex items-center justify-between my-4">
                      <div>
                        <div className="text-5xl font-bold">
                          {Math.round(city.main.temp)}°C
                        </div>
                        <div className="text-sm text-gray-500">
                          Feels like {Math.round(city.main.feels_like)}°C
                        </div>
                      </div>
                      <div>
                        {getWeatherIcon(
                          city.weather[0].id,
                          city.weather[0].main
                        )}
                      </div>
                    </div>

                    <div className="divider my-2"></div>

                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Humidity
                        </div>
                        <div className="text-lg font-semibold">
                          {city.main.humidity}%
                        </div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Wind
                        </div>
                        <div className="text-lg font-semibold">
                          {city.wind.speed} m/s
                        </div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Pressure
                        </div>
                        <div className="text-lg font-semibold">
                          {city.main.pressure} hPa
                        </div>
                      </div>
                      <div>
                        <div className="text-xs text-gray-500 dark:text-gray-400">
                          Updated
                        </div>
                        <div
                          className="text-lg font-semibold"
                          suppressHydrationWarning
                        >
                          {new Date(city.dt * 1000).toLocaleTimeString([], {
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">🌤️</div>
              <h3 className="text-2xl font-bold mb-2">No cities added yet</h3>
              <p className="text-gray-600 dark:text-gray-400">
                Add your first city to get started!
              </p>
            </div>
          )}

          {/* Footer */}
          <div className="text-center mt-12 text-sm text-gray-500">
            <p>
              Weather data provided by{" "}
              <a
                href="https://open-meteo.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="link link-primary"
              >
                Open-Meteo
              </a>
            </p>
          </div>
        </div>
      </div>
    </>
  );
}

export const getServerSideProps: GetServerSideProps = async () => {
  const defaultCities = ["Tehran", "London", "New York"];

  try {
    // Fetch data directly using the API logic (avoid HTTP call to self)
    const weatherPromises = defaultCities.map(async (city) => {
      const geoResponse = await axios.get(
        `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(
          city
        )}&count=1&language=en&format=json`
      );

      if (!geoResponse.data.results || geoResponse.data.results.length === 0) {
        throw new Error(`City ${city} not found`);
      }

      const geoData = geoResponse.data.results[0];
      const weatherResponse = await axios.get(
        `https://api.open-meteo.com/v1/forecast?latitude=${geoData.latitude}&longitude=${geoData.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m&timezone=auto`
      );

      const current = weatherResponse.data.current;
      const weatherMap: Record<
        number,
        { id: number; main: string; description: string }
      > = {
        0: { id: 800, main: "Clear", description: "clear sky" },
        1: { id: 800, main: "Clear", description: "mainly clear" },
        2: { id: 801, main: "Clouds", description: "partly cloudy" },
        3: { id: 803, main: "Clouds", description: "overcast" },
        45: { id: 741, main: "Fog", description: "fog" },
        61: { id: 500, main: "Rain", description: "slight rain" },
        63: { id: 501, main: "Rain", description: "moderate rain" },
        65: { id: 502, main: "Rain", description: "heavy rain" },
        71: { id: 600, main: "Snow", description: "slight snow" },
        95: { id: 200, main: "Thunderstorm", description: "thunderstorm" },
      };

      const weather = weatherMap[current.weather_code] || {
        id: 800,
        main: "Clear",
        description: "clear sky",
      };

      return {
        name: geoData.name,
        sys: { country: geoData.country_code || "N/A" },
        main: {
          temp: current.temperature_2m,
          feels_like: current.apparent_temperature,
          humidity: current.relative_humidity_2m,
          pressure: current.surface_pressure,
        },
        weather: [weather],
        wind: { speed: current.wind_speed_10m },
        dt: Math.floor(new Date(current.time).getTime() / 1000),
      };
    });

    const initialCities = await Promise.all(weatherPromises);

    return {
      props: {
        initialCities,
      },
    };
  } catch (error) {
    console.error("Error fetching weather data:", error);
    return {
      props: {
        initialCities: [],
        error:
          "Failed to fetch initial weather data. Please check your internet connection.",
      },
    };
  }
};
