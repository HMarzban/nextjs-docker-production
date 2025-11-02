/**
 * Simple, production-ready API utilities
 * Consolidated error handling, validation, and logging
 */

import type { NextApiRequest, NextApiResponse } from "next";
import { z, ZodError } from "zod";

// Simple error class - one class, different status codes
export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public code?: string
  ) {
    super(message);
    this.name = "ApiError";
  }
}

// Simple logging - just functions, no class
const isDev = process.env.NODE_ENV === "development";

export const log = {
  info: (msg: string, data?: Record<string, unknown>) => {
    console.log(`[INFO] ${msg}`, data ? JSON.stringify(data) : "");
  },
  warn: (msg: string, data?: Record<string, unknown>) => {
    console.warn(`[WARN] ${msg}`, data ? JSON.stringify(data) : "");
  },
  error: (msg: string, err?: unknown, data?: Record<string, unknown>) => {
    const errorInfo =
      err instanceof Error
        ? { message: err.message, ...(isDev && { stack: err.stack }) }
        : err;
    console.error(`[ERROR] ${msg}`, {
      ...data,
      error: errorInfo,
    });
  },
};

// Validate with Zod - throws ApiError on failure
export function validate<T extends z.ZodSchema>(
  schema: T,
  data: unknown
): z.infer<T> {
  try {
    return schema.parse(data);
  } catch (err) {
    if (err instanceof ZodError) {
      const firstError = err.issues[0];
      throw new ApiError(
        firstError?.message || "Validation failed",
        400,
        "VALIDATION_ERROR"
      );
    }
    throw err;
  }
}

// Error handler wrapper for API routes
export function withErrorHandler(
  handler: (req: NextApiRequest, res: NextApiResponse) => Promise<void> | void
) {
  return async (req: NextApiRequest, res: NextApiResponse): Promise<void> => {
    try {
      await handler(req, res);
    } catch (error) {
      if (res.headersSent) {
        log.error("Response already sent", error, {
          url: req.url,
          method: req.method,
        });
        return;
      }

      if (error instanceof ApiError) {
        log.warn("API error", {
          statusCode: error.statusCode,
          code: error.code,
          url: req.url,
        });
        res.status(error.statusCode).json({
          error: {
            message: error.message,
            code: error.code,
            statusCode: error.statusCode,
          },
        });
      } else {
        log.error("Unhandled error", error, {
          url: req.url,
          method: req.method,
        });
        res.status(500).json({
          error: {
            message: isDev
              ? error instanceof Error
                ? error.message
                : "Unknown error"
              : "Internal server error",
            statusCode: 500,
            code: "INTERNAL_ERROR",
          },
        });
      }
    }
  };
}
