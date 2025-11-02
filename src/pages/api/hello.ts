import type { NextApiRequest, NextApiResponse } from "next";
import { withErrorHandler, log } from "@/lib/api-utils";
import { API_ENDPOINTS, API_CONFIG } from "@/lib/constants";

interface ResponseData {
  message: string;
  container: string;
  timestamp: string;
  externalAPI?: string;
}

async function handler(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
): Promise<void> {
  if (req.method !== "GET") {
    res.status(405).json({
      error: { message: "Method not allowed", statusCode: 405 },
    } as never);
    return;
  }

  const containerId = process.env.HOSTNAME || "unknown";
  log.info("Hello endpoint", { container: containerId });

  let externalAPIData: string | undefined;
  try {
    const response = await fetch(API_ENDPOINTS.GITHUB_ZEN, {
      signal: AbortSignal.timeout(API_CONFIG.EXTERNAL_API_TIMEOUT),
    });
    if (response.ok) {
      externalAPIData = await response.text();
    }
  } catch (error) {
    log.warn("External API failed", { error });
  }

  res.status(200).json({
    message: "Hello from Next.js",
    container: containerId,
    timestamp: new Date().toISOString(),
    ...(externalAPIData && { externalAPI: externalAPIData }),
  });
}

export default withErrorHandler(handler);
