import { defineConfig } from "@playwright/test";

const basePath = process.env.TRANSITC_DOCS_BASE_URL ?? "/transitc/";
const layout = basePath === "/" ? "root" : "prefix";
export default defineConfig({
  testDir: "./browser",
  outputDir: `../../.cache/handbook-browser-${layout}`,
  reporter: [["list"], ["html", { outputFolder: `../../.cache/handbook-report-${layout}`, open: "never" }]],
  workers: 2,
  use: {
    baseURL: `http://127.0.0.1:4173${basePath}`,
    trace: "retain-on-failure",
    launchOptions: process.env.CHROMIUM_EXECUTABLE
      ? { executablePath: process.env.CHROMIUM_EXECUTABLE }
      : {},
  },
  projects: [
    { name: "desktop-light", use: { viewport: { width: 1440, height: 1000 }, colorScheme: "light" } },
    { name: "desktop-dark", use: { viewport: { width: 1440, height: 1000 }, colorScheme: "dark" } },
    { name: "mobile-light", use: { viewport: { width: 390, height: 844 }, colorScheme: "light" } },
    { name: "mobile-dark", use: { viewport: { width: 390, height: 844 }, colorScheme: "dark" } },
  ],
  webServer: {
    command: "npm run serve -- --host 127.0.0.1 --port 4173 --no-open",
    url: `http://127.0.0.1:4173${basePath}`,
    reuseExistingServer: false,
    timeout: 60000,
  },
});
