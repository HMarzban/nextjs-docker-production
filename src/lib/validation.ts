/**
 * Validation schemas using Zod
 */

import { z } from "zod";

export const citySchema = z
  .string()
  .min(1, "City name is required")
  .max(100, "City name must be less than 100 characters")
  .regex(
    /^[a-zA-Z\s-']+$/,
    "City name can only contain letters, spaces, hyphens, and apostrophes"
  )
  .transform((val) => val.trim());

export const weatherQuerySchema = z.object({
  city: citySchema,
});
