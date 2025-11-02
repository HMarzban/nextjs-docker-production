import type { NextApiRequest, NextApiResponse } from "next";
import { withErrorHandler, validate, log } from "@/lib/api-utils";
import { weatherQuerySchema } from "@/lib/validation";
import { fetchWeatherData } from "@/lib/weather";

type WeatherResponse = Awaited<ReturnType<typeof fetchWeatherData>>;

async function handler(
  req: NextApiRequest,
  res: NextApiResponse<WeatherResponse>
): Promise<void> {
  if (req.method !== "GET") {
    res.status(405).json({
      error: { message: "Method not allowed", statusCode: 405 },
    } as never);
    return;
  }

  const { city } = validate(weatherQuerySchema, req.query);
  log.info("Weather request", { city });

  const response = await fetchWeatherData(city);
  log.info("Weather fetched", { city: response.name });

  res.status(200).json(response);
}

export default withErrorHandler(handler);
