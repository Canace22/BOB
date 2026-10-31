// Measure cold and warm app-ready time using an isolated browser context.
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const browser = await chromium.launch({ executablePath: existsSync(chromium.executablePath()) ? chromium.executablePath() : process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--enable-unsafe-swiftshader'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
if (process.env.STARTUP_FALLBACK === '1') await context.addInitScript(() => { window.DecompressionStream = undefined; });
if (process.env.STARTUP_NO_CACHE === '1') await context.addInitScript(() => { Object.defineProperty(window, 'caches', { value: undefined }); });
const page = await context.newPage();
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'startup');
mkdirSync(output, { recursive: true });
const errors = [];
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4187/BOB/godot/';
const results = [];
try {
  for (const temperature of ['cold', 'warm']) {
    const started = Date.now();
    if (temperature === 'cold') await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 180000 });
    else await page.reload({ waitUntil: 'domcontentloaded', timeout: 180000 });
    await page.waitForFunction(() => typeof window.render_game_to_text === 'function' && JSON.parse(window.render_game_to_text()).room === 'R1-01', null, { timeout: 180000 });
    const timing = await page.evaluate(() => ({ readyMs: performance.now(), resources: performance.getEntriesByType('resource').filter(r => /index\.(wasm|pck)|\/(wasm|pck)\.[a-f0-9]{16}\.gz/.test(r.name)).map(r => ({ file: new URL(r.name).pathname.split('/').pop(), durationMs: r.duration, endMs: r.responseEnd, transferBytes: r.transferSize, encodedBytes: r.encodedBodySize, decodedBytes: r.decodedBodySize })) }));
    results.push({ temperature, wallMs: Date.now() - started, ...timing });
    console.log(JSON.stringify(results.at(-1)));
    await page.screenshot({ path: path.join(output, `${temperature}.png`) });
  }
  if (errors.length) throw new Error(errors.join('\n'));
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, url, results, errors }, null, 2));
} catch (error) {
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, url, results, errors, error: error.stack }, null, 2));
  throw error;
} finally { await browser.close(); }
