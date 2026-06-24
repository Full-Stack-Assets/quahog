import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { execSync } from "node:child_process";

// Build stamp: prefer Vercel's injected commit SHA; fall back to local git so a
// dev build is still identifiable. Surfaced in-game (HUD corner) so it's obvious
// which build is live after a deploy + hard refresh.
function commitSha(): string {
  const env = process.env.VERCEL_GIT_COMMIT_SHA || process.env.GITHUB_SHA;
  if (env) return env.slice(0, 7);
  try {
    return execSync("git rev-parse --short HEAD", { encoding: "utf8" }).trim();
  } catch {
    return "dev";
  }
}

export default defineConfig({
  plugins: [react()],
  base: "./",
  define: {
    __BUILD_SHA__: JSON.stringify(commitSha()),
    __BUILD_DATE__: JSON.stringify(new Date().toISOString().slice(0, 10)),
  },
  build: {
    rollupOptions: {
      input: {
        main: "index.html", // the game slice
        earth: "earth.html", // Google Photorealistic 3D Tiles test
      },
    },
  },
});
