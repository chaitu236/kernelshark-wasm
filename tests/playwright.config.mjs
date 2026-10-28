import { defineConfig } from '@playwright/test';

const baseURL = process.env.KS_TEST_BASE_URL || 'http://127.0.0.1:8090';

export default defineConfig({
  testDir: '.',
  testMatch: '**/*.spec.mjs',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 120_000,
  expect: { timeout: 15_000 },
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL,
    browserName: 'chromium',
    viewport: { width: 1280, height: 900 },
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    launchOptions: {
      args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
    },
  },
  webServer: process.env.KS_TEST_BASE_URL ? undefined : {
    command: 'node server.mjs',
    url: `${baseURL}/healthz`,
    reuseExistingServer: false,
    timeout: 10_000,
  },
});
