/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  // Recommended production settings
  compress: true,
  poweredByHeader: false,
  reactStrictMode: true,
};

export default nextConfig;
