import type { NextApiRequest, NextApiResponse } from "next";

type ResponseData = {
  message: string;
  container: string;
  timestamp: string;
  externalAPI?: string;
  error?: string;
};

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<ResponseData>
) {
  // Test external API call (no nginx config needed!)
  try {
    const externalCall = await fetch("https://api.github.com/zen", {
      signal: AbortSignal.timeout(2000),
    });
    const externalData = await externalCall.text();

    res.status(200).json({
      message: "Hello from Next.js",
      container: process.env.HOSTNAME || "unknown",
      timestamp: new Date().toISOString(),
      externalAPI: externalData,
    });
  } catch (error: any) {
    res.status(200).json({
      message: "Hello from Next.js",
      container: process.env.HOSTNAME || "unknown",
      timestamp: new Date().toISOString(),
      error: "External API failed (but nginx not needed!)",
    });
  }
}
