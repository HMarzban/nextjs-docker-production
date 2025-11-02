import withPWA from "@ducanh2912/next-pwa";

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",

  // Recommended production settings
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,

  // Use src directory for pages and components
  // This keeps the root directory clean
  pageExtensions: ["ts", "tsx", "js", "jsx", "md", "mdx"],

  // Consistent build ID for horizontal scaling
  // Ensures all containers serve the same version
  generateBuildId: async () => {
    // Use git hash, timestamp, or version from package.json
    // This ensures the same build ID across all scaled instances
    return process.env.BUILD_ID || process.env.GIT_HASH || "production-build";
  },

  // PWA: Allow service worker and manifest
  async headers() {
    return [
      {
        source: "/sw.js",
        headers: [
          {
            key: "Cache-Control",
            value: "public, max-age=0, must-revalidate",
          },
          {
            key: "Service-Worker-Allowed",
            value: "/",
          },
        ],
      },
      {
        source: "/manifest.json",
        headers: [
          {
            key: "Content-Type",
            value: "application/manifest+json",
          },
        ],
      },
    ];
  },
};

export default withPWA({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
  register: true,
  skipWaiting: false, // Let user control when to update via UpdatePrompt
  reloadOnOnline: true,

  // Custom caching strategies for scaled Docker deployment
  workboxOptions: {
    disableDevLogs: true,
    clientsClaim: true,

    // Workbox automatically handles SKIP_WAITING messages
    // UpdatePrompt component sends: registration.waiting.postMessage({ type: "SKIP_WAITING" })
    // Workbox receives and calls skipWaiting() automatically

    runtimeCaching: [
      // API Routes - Network First (fresh data priority)
      {
        urlPattern: /^\/api\/.*/,
        handler: "NetworkFirst",
        options: {
          cacheName: "api-cache",
          networkTimeoutSeconds: 10,
          expiration: {
            maxEntries: 50,
            maxAgeSeconds: 5 * 60, // 5 minutes
          },
          networkTimeoutSeconds: 10,
        },
      },

      // Static assets - Cache First (immutable)
      {
        urlPattern: /\.(?:png|jpg|jpeg|svg|gif|webp|ico)$/,
        handler: "CacheFirst",
        options: {
          cacheName: "image-cache",
          expiration: {
            maxEntries: 100,
            maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
          },
        },
      },

      // Fonts - Cache First
      {
        urlPattern: /\.(?:woff|woff2|ttf|otf|eot)$/,
        handler: "CacheFirst",
        options: {
          cacheName: "font-cache",
          expiration: {
            maxEntries: 20,
            maxAgeSeconds: 365 * 24 * 60 * 60, // 1 year
          },
        },
      },

      // Next.js static files - Cache First
      {
        urlPattern: /\/_next\/static\/.*/,
        handler: "CacheFirst",
        options: {
          cacheName: "next-static",
          expiration: {
            maxEntries: 200,
            maxAgeSeconds: 365 * 24 * 60 * 60, // 1 year
          },
        },
      },

      // Pages - Stale While Revalidate (instant load, background update)
      {
        urlPattern: /^\/(?!api).*/,
        handler: "StaleWhileRevalidate",
        options: {
          cacheName: "pages-cache",
          expiration: {
            maxEntries: 50,
            maxAgeSeconds: 24 * 60 * 60, // 24 hours
          },
        },
      },
    ],
  },
})(nextConfig);
