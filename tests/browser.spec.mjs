import { writeFile } from 'node:fs/promises';
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
  const uploaded = await page.evaluate(() =>
    Array.from(qtLoader.module().FS.readFile(activeTracePaths.at(-1))));
  expect(uploaded, 'Uploaded trace bytes in the WASM filesystem').toEqual(Array.from(fixture.buffer));
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
