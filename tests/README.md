# Local browser tests

These Playwright tests run the compiled Qt/WASM application in headless Chromium
with software WebGL rendering. All test-specific code and npm dependencies live
in this directory.

## Run with Docker

Build the application first using `./build.sh`. From the repository root, run:

```bash
docker run --rm --init --ipc=host \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace/tests \
  mcr.microsoft.com/playwright:v1.64.1-noble \
  sh -c 'npm ci --no-audit --no-fund && npm test'
```

The official image supplies Node.js, npm, browser binaries, and system libraries.
Only the small npm test dependencies are installed into `tests/node_modules/`;
no host Node.js installation or additional browser download is needed. The first
run downloads the image unless it has already been pulled. Keep the image tag
and the Playwright dependency in `package.json` at the same version.

The configured server starts automatically and serves `out/wasm-release/dist/`
with the COOP/COEP headers required by WASM threads. Both Chromium and the server
run inside the container, so no published ports or separate runtime container
are needed. The command uses the host user ID to avoid root-owned output files.

For subsequent runs, replace the final command with `npm test` to reuse installed
dependencies, or `npm test -- --grep append` to select tests.

## Run with host tools

With Node.js 20 or newer and npm installed:

```bash
cd tests
npm ci
npx playwright install --with-deps chromium
npm test
```

Installing browser system libraries may require administrator privileges. The
Docker approach avoids changing the host's packages.

## Coverage

- Threaded WASM startup, cross-origin isolation, and a visible canvas.
- Refusing to append before opening a trace.
- Loading a trace through the real browser file-picker callback and file input.
- Appending while retaining the original uploaded file.
- Reopening the same filename, replacing all traces and removing old uploads.
- Loading a trace through the drag-and-drop handlers.

Tests fail on JavaScript exceptions, failed requests, Qt `ERROR:` diagnostics,
and WASM abort messages. Loading also verifies the uploaded bytes in Emscripten's
filesystem, completion, and the hidden progress overlay. The open test checks
that the rendered canvas changes and attaches an image of the loaded trace.

`trace-fixture.mjs` generates an 8 KiB trace-cmd version 6 file in memory. It
contains one CPU, a synthetic `test:tick` event, and three records for
`test-worker` at 1.000, 1.001, and 1.002 seconds, with values 1, 2, and 3. No
real host data, root access, kernel tracing, or fixture downloads are needed.

The suite does not assert decoded event-row counts or exercise zoom,
filtering, invalid-file handling, other browsers, or nginx compression/caching.
Qt widgets are canvas-rendered, so these checks are not DOM assertions about
individual event rows. The synthetic fixture covers only the version 6,
uncompressed, little-endian trace format, not every supported input format.

## Results and overrides

The HTML report is written to `tests/playwright-report/`. Screenshots, traces,
and other test artifacts are written to `tests/test-results/`. JavaScript
console messages are attached as `browser.log`; failure screenshots and
Playwright traces are retained automatically. Generated output is gitignored.

`KS_TEST_DIST` selects a different distribution directory for the local server.
`KS_TEST_BASE_URL` targets an already running application instead of starting the
test server. Pass these as Docker environment variables when using a container,
and use paths and addresses reachable from inside that container. On Linux,
`--network host` lets a container reach a host server at `127.0.0.1`.

The test server is a local harness, not a production server; it binds to
`127.0.0.1:8090`. It intentionally serves raw artifacts without testing nginx's
compression or cache policies.
