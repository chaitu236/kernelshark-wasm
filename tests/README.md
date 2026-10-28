# Browser tests

Build the application with `./build.sh` before running tests.

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

## Run with host tools

Requires Node.js 20+ and npm:

```bash
cd tests
npm ci
npx playwright install --with-deps chromium
npm test
```

Installing browser system libraries may require administrator privileges.

## Results and overrides

Local reports: `tests/playwright-report/`. Logs, screenshots, and failure traces:
`tests/test-results/`.

For CI reports, download `browser-test-results` from the
[PR Build workflow](../.github/workflows/pr-build.yml) run.

- `KS_TEST_DIST`: override the default `out/wasm-release/dist/` directory.
- `KS_TEST_BASE_URL`: test an existing server instead of starting the local one.
