import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { test as base, expect } from '@playwright/test';
import { traceFixture } from './trace-fixture.mjs';

const test = base.extend({
  expectedConsoleErrors: [[], { option: true }],
  page: async ({ page, expectedConsoleErrors }, use, testInfo) => {
    const errors = [];
    const messages = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      messages.push(`[${message.type()}] ${message.text()}`);
      if (/\bERROR:|Aborted\(|RuntimeError:/.test(message.text()) &&
          !expectedConsoleErrors.some(pattern => pattern.test(message.text())))
        errors.push(message.text());
    });
    page.on('requestfailed', request => errors.push(`${request.url()}: ${request.failure()?.errorText}`));
    await use(page);
    await testInfo.attach('browser.log', {
      body: messages.join('\n'),
      contentType: 'text/plain',
    });
    expect(errors, 'Browser errors and failed requests').toEqual([]);
    for (const pattern of expectedConsoleErrors)
      expect(messages.some(message => pattern.test(message)), `Expected diagnostic: ${pattern}`).toBe(true);
  },
});

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await page.waitForFunction(() => typeof qtLoader !== 'undefined' && qtLoader?.status === 'Running');
  await expect(page.locator('#qtspinner')).toBeHidden();
  await expect(page.locator('#qtcanvas')).toBeVisible();
  await page.locator('#qtcanvas').click({ position: { x: 800, y: 40 } });
});

async function waitForTrace(page, fixture, count = 1) {
  await page.waitForFunction(({ name, count }) =>
    !dropBusy && activeTracePaths.length === count && activeTracePaths.at(-1).endsWith(`-${name}`),
  { name: fixture.name, count });
  await expect(page.locator('#dropoverlay')).toBeHidden();
  const uploaded = await page.evaluate(async () => {
    const bytes = qtLoader.module().FS.readFile(activeTracePaths.at(-1));
    return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)));
  });
  expect(Buffer.from(uploaded).toString('hex'), 'Uploaded trace checksum').toBe(
    createHash('sha256').update(fixture.buffer).digest('hex'));
  return page.evaluate(() => [...activeTracePaths]);
}

async function selectTraceFile(page, fixture, append = false) {
  const chooser = page.waitForEvent('filechooser');
  await page.keyboard.press(append ? 'Control+a' : 'Control+o');
  await (await chooser).setFiles(fixture);
}

async function pickTrace(page, fixture, append = false, count = 1) {
  await selectTraceFile(page, fixture, append);
  return waitForTrace(page, fixture, count);
}

test('starts the real threaded WASM application', async ({ page }) => {
  await expect(page).toHaveTitle('Kernel Shark');
  const runtime = await page.evaluate(() => ({
    isolated: crossOriginIsolated,
    sharedMemory: qtLoader.module().HEAPU8.buffer instanceof SharedArrayBuffer,
    canvasWidth: document.querySelector('#qtcanvas').width,
    canvasHeight: document.querySelector('#qtcanvas').height,
  }));
  expect(runtime.isolated).toBe(true);
  expect(runtime.sharedMemory).toBe(true);
  expect(runtime.canvasWidth).toBeGreaterThan(0);
  expect(runtime.canvasHeight).toBeGreaterThan(0);
});

test('requires an open trace before appending', async ({ page }) => {
  await page.keyboard.press('Control+a');
  await expect(page.locator('#dropoverlay')).toHaveClass(/error/);
  await expect(page.locator('#dropmessage')).toHaveText('Open a trace file before appending');
  expect(await page.evaluate(() => activeTracePaths)).toEqual([]);
});

test('opens a synthetic trace through the browser file picker', async ({ page }, testInfo) => {
  const canvas = page.locator('#qtcanvas');
  const emptyView = await canvas.screenshot();
  await pickTrace(page, traceFixture());
  await expect(page).toHaveTitle(/Kernel Shark \(.*synthetic\.dat\)/);
  const loadedView = await canvas.screenshot({ path: testInfo.outputPath('loaded-trace.png') });
  await testInfo.attach('loaded-trace', { body: loadedView, contentType: 'image/png' });
  expect(loadedView.equals(emptyView), 'Trace changes the rendered view').toBe(false);
  await expect(canvas).toHaveScreenshot('opened-trace.png');
});

test('appends a trace while retaining the original file', async ({ page }) => {
  const original = traceFixture();
  const originalPaths = await pickTrace(page, original);
  const paths = await pickTrace(page, traceFixture('appended.dat', 202), true, 2);
  expect(paths[0]).toBe(originalPaths[0]);
  const retained = await page.evaluate(path =>
    Array.from(qtLoader.module().FS.readFile(path)), originalPaths[0]);
  expect(retained).toEqual(Array.from(original.buffer));
  await expect(page.locator('#qtcanvas')).toHaveScreenshot('appended-traces.png');
});

test('reopening a file replaces all traces and removes old uploads', async ({ page }) => {
  await pickTrace(page, traceFixture());
  const oldPaths = await pickTrace(page, traceFixture('appended.dat', 202), true, 2);
  const paths = await pickTrace(page, traceFixture('synthetic.dat', 303));
  expect(paths).toHaveLength(1);
  expect(oldPaths).not.toContain(paths[0]);
  const oldFilesExist = await page.evaluate(paths =>
    paths.map(path => qtLoader.module().FS.analyzePath(path).exists), oldPaths);
  expect(oldFilesExist).toEqual([false, false]);
  await expect(page.locator('#qtcanvas')).toHaveScreenshot('replacement-trace.png');
});

test('opens a trace by drag and drop', async ({ page }, testInfo) => {
  const fixture = traceFixture('dropped.dat');
  const file = testInfo.outputPath(fixture.name);
  await writeFile(file, fixture.buffer);
  const bounds = await page.locator('#qtcanvas').boundingBox();
  const position = { x: bounds.x + bounds.width / 2, y: bounds.y + bounds.height / 2 };
  const data = { items: [], files: [file], dragOperationsMask: 1 };
  const input = await page.context().newCDPSession(page);
  try {
    await input.send('Input.dispatchDragEvent', { type: 'dragEnter', ...position, data });
    await expect(page.locator('#dropmessage')).toHaveText('Drop trace file to open');
    await input.send('Input.dispatchDragEvent', { type: 'dragOver', ...position, data });
    await input.send('Input.dispatchDragEvent', { type: 'drop', ...position, data });
    await waitForTrace(page, fixture);
    await expect(page).toHaveTitle(/Kernel Shark \(.*dropped\.dat\)/);
  } finally {
    await input.detach();
  }
});

for (const filter of [
  { kind: 'CPU', menu: 153, checkbox: { x: 583, y: 326 }, apply: { x: 581, y: 679 }, snapshot: 'filtered-CPU.png' },
  { kind: 'PID', menu: 126, checkbox: { x: 555, y: 351 }, apply: { x: 558, y: 679 }, snapshot: 'filtered-CPU.png' },
  { kind: 'event', menu: 99, checkbox: { x: 624, y: 259 }, apply: { x: 572, y: 679 }, snapshot: 'filtered-event.png' },
]) {
  test(`applies and clears the ${filter.kind} filter`, async ({ page }) => {
    await pickTrace(page, traceFixture('multi-cpu.dat', 101, { cpus: 2 }));
    const canvas = page.locator('#qtcanvas');
    await canvas.click({ position: { x: 71, y: 10 } });
    await canvas.click({ position: { x: 115, y: filter.menu } });
    await canvas.click({ position: filter.checkbox });
    await canvas.click({ position: filter.apply });
    await expect(canvas).toHaveScreenshot(filter.snapshot);
    await canvas.click({ position: { x: 71, y: 10 } });
    await canvas.click({ position: { x: 115, y: 207 } });
    await expect(canvas).toHaveScreenshot('cleared-filters.png');
  });
}

test('zooms and pans through an empty time range without crashing', async ({ page }) => {
  await pickTrace(page, traceFixture());
  const canvas = page.locator('#qtcanvas');
  await page.mouse.move(220, 180);
  await page.mouse.down();
  await page.mouse.move(350, 180, { steps: 8 });
  await page.mouse.up();
  await page.mouse.move(800, 40);
  await expect(page).toHaveScreenshot('empty-range-graph.png', {
    clip: { x: 9, y: 107, width: 1260, height: 270 },
  });
  const graph = { x: 9, y: 107, width: 1260, height: 111 };
  let previous = await page.screenshot({ clip: graph });
  for (const x of [74, 155, 32, 115]) {
    for (let count = 0; count < 20; count++)
      await canvas.click({ position: { x, y: 85 } });
    const current = await page.screenshot({ clip: graph });
    expect(current.equals(previous), 'Zoom/pan changes the empty range').toBe(false);
    previous = current;
  }
  await canvas.click({ position: { x: 245, y: 85 } });
  await pickTrace(page, traceFixture('after-zoom.dat'));
  await expect(canvas).toHaveScreenshot('opened-trace.png');
});

test('searches next and previous matches and wraps selection', async ({ page }) => {
  await pickTrace(page, traceFixture());
  const canvas = page.locator('#qtcanvas');
  const table = { x: 9, y: 278, width: 390, height: 100 };
  const selections = [];
  for (let row = 0; row < 3; row++) {
    await canvas.click({ position: { x: 800, y: 313 + row * 23 } });
    selections.push(await page.screenshot({ clip: table }));
  }
  await canvas.click({ position: { x: 800, y: 313 } });
  await canvas.click({ position: { x: 200, y: 255 } });
  await page.keyboard.press('End');
  await page.keyboard.press('Enter');
  await page.mouse.click(480, 255, { delay: 50 });
  await page.keyboard.type('value=', { delay: 20 });
  await page.keyboard.press('Enter');
  for (const [direction, row] of [['Next', 1], ['Prev', 0], ['Prev', 2], ['Next', 0]]) {
    await canvas.click({ position: { x: direction === 'Next' ? 607 : 655, y: 255 } });
    await expect.poll(async () =>
      (await page.screenshot({ clip: table })).equals(selections[row])).toBe(true);
  }
});

test('preserves horizontal scrolling when selecting another event', async ({ page }) => {
  await pickTrace(page, traceFixture());
  const canvas = page.locator('#qtcanvas');
  await page.mouse.move(291, 289);
  await page.mouse.down();
  await page.mouse.move(1240, 289, { steps: 10 });
  await page.mouse.up();
  await canvas.click({ position: { x: 800, y: 313 } });
  const header = { x: 9, y: 278, width: 700, height: 22 };
  const beforeScroll = await page.screenshot({ clip: header });
  await page.mouse.move(700, 350);
  await page.mouse.wheel(600, 0);
  let afterScroll;
  await expect.poll(async () => {
    const current = await page.screenshot({ clip: header });
    const stable = afterScroll !== undefined && current.equals(afterScroll);
    afterScroll = current;
    return stable;
  }).toBe(true);
  expect(afterScroll.equals(beforeScroll), 'Horizontal scrolling moves the header').toBe(false);
  await canvas.click({ position: { x: 800, y: 359 } });
  await expect.poll(async () =>
    (await page.screenshot({ clip: header })).equals(afterScroll)).toBe(true);
});

test('loads and displays records from multiple CPUs', async ({ page }) => {
  await pickTrace(page, traceFixture('multi-cpu.dat', 101, { cpus: 2 }));
  await expect(page.locator('#qtcanvas')).toHaveScreenshot('multi-cpu-trace.png');
});

for (const format of ['v7', 'v7-zstd']) {
  test(`loads ${format} trace files`, async ({ page }) => {
    const name = `trace-${format}.dat`;
    const buffer = await readFile(new URL(name, import.meta.url));
    await pickTrace(page, { name, mimeType: 'application/octet-stream', buffer });
    await expect(page.locator('#qtcanvas')).toHaveScreenshot('opened-trace.png');
  });
}

test('loads a large trace with progress and remains usable', async ({ page }) => {
  const fixture = traceFixture('large.dat', 101, { eventsPerCpu: 1_000_000, spacing: 1000 });
  const progress = await page.locator('#dropprogress').evaluateHandle(element => {
    const observed = { value: 0 };
    const observer = new MutationObserver(() => {
      if (element.checkVisibility() && element.value > 0) {
        observed.value = element.value;
        observer.disconnect();
      }
    });
    observer.observe(element, { attributes: true, attributeFilter: ['hidden', 'value'] });
    return observed;
  });
  await selectTraceFile(page, fixture);
  await expect.poll(() => progress.evaluate(observed => observed.value), {
    message: 'Visible load progress is reported',
  }).toBeGreaterThan(0);
  await progress.dispose();
  await page.setViewportSize({ width: 1100, height: 800 });
  await expect(page.locator('#qtcanvas')).toHaveJSProperty('width', 1100);
  await waitForTrace(page, fixture);
  await page.setViewportSize({ width: 1280, height: 900 });
  await expect(page.locator('#qtcanvas')).toHaveJSProperty('width', 1280);
  await expect(page.locator('#qtcanvas')).toHaveJSProperty('height', 900);
  await page.locator('#qtcanvas').click({ position: { x: 800, y: 314 } });
  await page.keyboard.press('Control+End');
  await expect(page).toHaveScreenshot('large-trace-end-table.png', {
    clip: { x: 9, y: 278, width: 1260, height: 600 },
  });
  await pickTrace(page, traceFixture());
  await expect(page.locator('#qtcanvas')).toHaveScreenshot('opened-trace.png');
});

test('preserves the loaded trace when the browser is resized', async ({ page }) => {
  await pickTrace(page, traceFixture());
  const canvas = page.locator('#qtcanvas');
  await expect(canvas).toHaveScreenshot('opened-trace.png');
  const table = { x: 9, y: 278, width: 1260, height: 94 };
  const originalRows = await page.screenshot({ clip: table });
  for (const viewport of [{ width: 900, height: 650 }, { width: 1600, height: 1000 }]) {
    await page.setViewportSize(viewport);
    await expect(canvas).toHaveJSProperty('width', viewport.width);
    await expect(canvas).toHaveJSProperty('height', viewport.height);
  }
  await page.setViewportSize({ width: 1280, height: 900 });
  await expect.poll(async () =>
    (await page.screenshot({ clip: table })).equals(originalRows)).toBe(true);
  await pickTrace(page, traceFixture('after-resize.dat'));
  await expect(canvas).toHaveScreenshot('opened-trace.png');
});

test.describe('invalid file recovery', () => {
  test.use({ expectedConsoleErrors: [[
    /ERROR: -\d+ while opening file .*invalid\.dat/,
    /ERROR: File .* contains no data\./,
  ], { scope: 'test' }] });

  const invalidFiles = [
    { kind: 'empty', buffer: Buffer.alloc(0) },
    { kind: 'invalid', buffer: Buffer.from('not a trace file') },
    { kind: 'truncated', buffer: traceFixture().buffer.subarray(0, 128) },
  ];
  for (const { kind, buffer } of invalidFiles) {
    test(`recovers after loading ${kind} data`, async ({ page }) => {
      const rejected = page.waitForEvent('console', {
        predicate: message => /ERROR: File .* contains no data\./.test(message.text()),
      });
      await selectTraceFile(page, { name: 'invalid.dat', mimeType: 'application/octet-stream', buffer });
      await rejected;
      await page.keyboard.press('Enter');
      await expect(page.locator('#dropoverlay')).toBeHidden();
      const chooser = page.waitForEvent('filechooser');
      await page.locator('#qtcanvas').click({ position: { x: 23, y: 10 } });
      await page.locator('#qtcanvas').click({ position: { x: 90, y: 37 } });
      const fixture = traceFixture();
      await (await chooser).setFiles(fixture);
      await waitForTrace(page, fixture);
      await expect(page.locator('#qtcanvas')).toHaveScreenshot('opened-trace.png');
    });
  }

  test('can reload while an invalid-file error is displayed', async ({ page }) => {
    const rejected = page.waitForEvent('console', {
      predicate: message => /ERROR: File .* contains no data\./.test(message.text()),
    });
    await selectTraceFile(page, {
      name: 'invalid.dat', mimeType: 'application/octet-stream', buffer: Buffer.alloc(0),
    });
    await rejected;
    await expect(page.locator('#dropoverlay')).toBeHidden();
    await page.reload();
    await expect(page.locator('#qtspinner')).toBeHidden();
    await expect(page).toHaveTitle('Kernel Shark');
    await page.locator('#qtcanvas').click({ position: { x: 800, y: 40 } });
    await pickTrace(page, traceFixture());
    await expect(page.locator('#qtcanvas')).toHaveScreenshot('opened-trace.png');
  });
});
