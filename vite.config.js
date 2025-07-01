import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // Environment variables prefixed with VITE_ are automatically exposed
  resolve: {
    dedupe: ['react', 'react-dom'],
  },
});
