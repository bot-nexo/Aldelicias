import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "*.supabase.co",
        pathname: "/storage/v1/object/public/product-images/**",
      },
      {
        protocol: "http",
        hostname: "localhost",
        port: "54321",
        pathname: "/storage/v1/object/public/product-images/**",
      },
    ],
  },
};

export default nextConfig;
