/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",

  // Recommended production settings
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,

  // Use src directory for pages and components
  // This keeps the root directory clean
  pageExtensions: ['ts', 'tsx', 'js', 'jsx', 'md', 'mdx'],

  // Consistent build ID for horizontal scaling
  // Ensures all containers serve the same version
  generateBuildId: async () => {
    // Use git hash, timestamp, or version from package.json
    // This ensures the same build ID across all scaled instances
    return process.env.BUILD_ID || process.env.GIT_HASH || "production-build";
  },
};

export default nextConfig;
