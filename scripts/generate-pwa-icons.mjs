#!/usr/bin/env node

/**
 * Generate PWA icons from SVG
 * Production-ready icon generator
 */

import sharp from "sharp";
import { writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicDir = join(__dirname, "..", "src", "public");

// Simple Next.js-inspired icon SVG
const iconSVG = `
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" fill="#111827" rx="80"/>
  <g transform="translate(128, 128)">
    <!-- Triangle (Next.js style) -->
    <path d="M 0 0 L 160 128 L 0 256 Z" fill="#3b82f6"/>
    <!-- Circle (Docker style) -->
    <circle cx="220" cy="128" r="40" fill="#10b981"/>
  </g>
</svg>
`.trim();

async function generateIcons() {
  try {
    const svgBuffer = Buffer.from(iconSVG);

    // Generate 192x192 icon
    await sharp(svgBuffer)
      .resize(192, 192)
      .png()
      .toFile(join(publicDir, "icon-192.png"));

    console.log("✓ Generated icon-192.png");

    // Generate 512x512 icon
    await sharp(svgBuffer)
      .resize(512, 512)
      .png()
      .toFile(join(publicDir, "icon-512.png"));

    console.log("✓ Generated icon-512.png");

    // Also save the SVG source
    writeFileSync(join(publicDir, "icon.svg"), iconSVG);
    console.log("✓ Generated icon.svg");

    console.log("\n🎉 PWA icons generated successfully!");
  } catch (error) {
    console.error("Error generating icons:", error);
    console.log("\n⚠️  Install sharp: bun add -d sharp");
    process.exit(1);
  }
}

generateIcons();
