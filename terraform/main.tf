import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/",
  plugins: [react()],
  server: {
    port: 8080,
    strictPort: true,
    host: "0.0.0.0",
    allowedHosts: [
      process.env.ALB_DNS || "projekat2-alb-820038387.us-east-1.elb.amazonaws.com",
      "localhost",
      "127.0.0.1",
    ],
  },
});