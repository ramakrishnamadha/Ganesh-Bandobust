import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  allowedDevOrigins: [
    "192.168.1.169",
    "192.168.1.167", // Added your current local IP address
  ],
};

export default nextConfig;
