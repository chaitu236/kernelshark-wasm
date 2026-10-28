# Browser tests

Build the application with `./build.sh` before running tests. Tests use headless
Chromium and start a local server automatically.

## Run with Docker

From the repository root:

```bash
docker run --rm --init --ipc=host \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace/tests \
  mcr.microsoft.com/playwright:v1.64.1-noble \
  sh -c 'npm ci --no-audit --no-fund && npm test'
```

Keep the image version matched to the Playwright dependency in `package.json`.

## Run with host tools

Requires Node.js 20+ and npm:

```bash
cd tests
npm ci
npx playwright install --with-deps chromium
npm test
```

Installing browser system libraries may require administrator privileges.

## Coverage

Startup, file-picker and drag-and-drop loading, append guards, appending, and
replacement cleanup. Fixtures are synthetic trace-cmd version 6 files; no trace
recording or root access is needed. Zoom and filtering are not covered.

## Results and overrides

Local reports: `tests/playwright-report/`. Logs, screenshots, and failure traces:
`tests/test-results/`.

The [PR Build workflow](../.github/workflows/pr-build.yml) runs tests after the
WASM build on a separate runner. Results are uploaded as `browser-test-results`
and retained for three days, including on test failure.

- `KS_TEST_DIST`: override the default `out/wasm-release/dist/` directory.
- `KS_TEST_BASE_URL`: test an existing server instead of starting the local one.
