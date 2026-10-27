import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdir, readFile, realpath, stat, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { homedir } from 'node:os';
import { dirname, extname, join, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { ART_ASSETS } from '../art-manifest.js';

if (Number(process.versions.node.split('.')[0]) < 20) {
  const runtime = join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin', process.platform === 'win32' ? 'node.exe' : 'node');
  const result = spawnSync(runtime, [fileURLToPath(import.meta.url)], { stdio: 'inherit', env: process.env });
  if (result.error) console.error(result.error.message);
  process.exit(result.status ?? 1);
}

async function loadPlaywright() {
  if (!process.env.PLAYWRIGHT_MODULE) {
    try { return await import('playwright'); } catch { /* Try bundled desktop dependency. */ }
  }
  let path = process.env.PLAYWRIGHT_MODULE || join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
  if ((await stat(path)).isDirectory()) path = join(path, 'index.mjs');
  return import(pathToFileURL(resolve(path)).href);
}

// A plain static server proves that the Pages build works beneath /BOB/;
// the development server's special mounts cannot hide broken relative paths.
async function servePages() {
  const root = await realpath(resolve(dirname(fileURLToPath(import.meta.url)), '../../.pages-dist'));
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.webp': 'image/webp', '.json': 'application/json' };
  const server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
      assert(pathname.startsWith('/BOB/'));
      const suffix = pathname.slice('/BOB/'.length);
      const candidate = resolve(root, suffix.endsWith('/') ? `${suffix}index.html` : suffix);
      const path = await realpath(candidate);
      assert(path.startsWith(`${root}${sep}`));
      const body = await readFile(path);
      response.writeHead(200, { 'Content-Type': types[extname(path)] || 'application/octet-stream' });
      response.end(body);
    } catch { response.writeHead(404); response.end('Not found'); }
  });
  await new Promise(accept => server.listen(0, '127.0.0.1', accept));
  return { server, url: `http://127.0.0.1:${server.address().port}/BOB/mvp-v2/` };
}

const { chromium } = await loadPlaywright();
const out = new URL('../output/art-integration/', import.meta.url);
await mkdir(out, { recursive: true });
const installedBrowser = process.platform === 'win32' ? [
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
].find(path => existsSync(path)) : undefined;
const executablePath = process.env.BROWSER_EXECUTABLE || (!existsSync(chromium.executablePath()) ? installedBrowser : undefined);
const browser = await chromium.launch({ headless: true, ...(executablePath ? { executablePath } : {}) });
let pagesServer;
const results = [];

async function verify(url, name, block = false) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  const errors = [], loaded = new Map(), failed = [], blocked = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('response', response => {
    if (response.url().includes('/assets/runtime/sprites/')) loaded.set(decodeURIComponent(new URL(response.url()).pathname), response.status());
    if (response.status() >= 400) failed.push({ url: response.url(), status: response.status() });
  });
  if (block) await page.route('**/assets/runtime/sprites/**', route => { blocked.push(route.request().url()); return route.abort('failed'); });
  await page.addInitScript(() => {
    window.__drawnImages = new Set();
    const draw = CanvasRenderingContext2D.prototype.drawImage;
    CanvasRenderingContext2D.prototype.drawImage = function (source, ...args) {
      if (source instanceof HTMLImageElement) window.__drawnImages.add(source.src);
      return draw.call(this, source, ...args);
    };
  });
  const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
  const tick = frames => page.evaluate(frames => window.advanceTime(frames * 1000 / 60), frames);
  async function key(code, frames) {
    await page.keyboard.down(code); await tick(frames);
    await page.keyboard.up(code); await tick(2);
  }
  async function screenshot(label) { await page.screenshot({ path: fileURLToPath(new URL(`${name}-${label}.png`, out)) }); }
  try {
    const navigationStarted = performance.now();
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    if (await page.locator('script[src="campaign-game.js"]').count()) await page.goto(new URL('legacy.html', await page.evaluate(() => document.baseURI)).href, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.locator('#start-btn:not([disabled])').waitFor({ timeout: Number(process.env.ART_TIMEOUT || 30000) });
    const readyMs = performance.now() - navigationStarted;
    await screenshot('title');
    const documentBase = await page.evaluate(() => document.baseURI);
    if (!block) for (const asset of Object.values(ART_ASSETS)) {
      const path = decodeURIComponent(new URL(asset.src, documentBase).pathname);
      assert.equal(loaded.get(path), 200, `${asset.id}: not loaded successfully at ${path}`);
    }
    else assert.equal(new Set(blocked).size, Object.keys(ART_ASSETS).length, 'Not all manifest images were blocked');
    await page.click('#start-btn'); await tick(2);
    const before = await state();
    await screenshot('start');
    await key('ArrowRight', 22);
    let current = await state();
    assert(current.player.x > before.player.x + 40, 'Right movement failed');
    assert.equal(current.player.facing, 1);
    await screenshot('right');
    await key('ArrowLeft', 8);
    current = await state();
    assert.equal(current.player.facing, -1);
    await screenshot('left');
    await page.keyboard.down('Space'); await tick(12);
    assert((await state()).player.y < before.player.y - 20, 'Jump did not rise');
    await page.keyboard.up('Space'); await tick(70);
    current = await state();
    assert(current.player.grounded, 'Jump did not land');
    assert.equal(current.deaths, before.deaths, 'Unexpected recovery');
    await screenshot('landed');
    const drawn = await page.evaluate(() => [...window.__drawnImages]);
    if (!block) {
      for (const id of ['tide-picker', 'tide-picker-left', 'shell-camp', 'r1-water-base', 'r1-oral-far-layer', 'r1-tongue-ledge']) {
        assert(drawn.some(url => url.endsWith(ART_ASSETS[id].src.slice(2))), `${id}: loaded but never drawn`);
      }
    } else assert(!drawn.some(url => url.includes('/assets/runtime/sprites/')), 'Blocked art unexpectedly drawn');
    assert.deepEqual(errors, [], 'Runtime exceptions');
    assert.deepEqual(failed, [], 'HTTP errors');
    let profile;
    if (process.env.ART_PROFILE === '1' && !block) profile = await page.evaluate(async () => {
      const [{ Renderer }, { Game }, { rooms }] = await Promise.all([
        import(new URL('renderer.js', document.baseURI)), import(new URL('engine.js', document.baseURI)), import(new URL('levels.js', document.baseURI)),
      ]);
      const canvas = document.createElement('canvas'), renderer = new Renderer(canvas), game = new Game();
      await renderer.load(); game.start();
      const stats = values => {
        const sorted = values.toSorted((a, b) => a - b);
        return { samples: values.length, meanMs: values.reduce((a, b) => a + b, 0) / values.length, p95Ms: sorted[Math.floor((sorted.length - 1) * .95)] };
      };
      const drawSubmission = [];
      for (let index = 0; index < rooms.length; index++) {
        game.enter(index);
        for (let i = 0; i < 30; i++) renderer.draw(game.state, rooms[index]);
        const samples = [];
        for (let i = 0; i < 300; i++) {
          game.state.time += 1 / 60;
          const before = performance.now(); renderer.draw(game.state, rooms[index]); samples.push(performance.now() - before);
        }
        drawSubmission.push({ room: rooms[index].id, ...stats(samples) });
      }
      const frames = []; let previous, warmup = 30;
      await new Promise(resolve => {
        function sample(now) {
          if (previous !== undefined && warmup <= 0) frames.push(now - previous);
          warmup--;
          previous = now;
          if (frames.length < 180) requestAnimationFrame(sample); else resolve();
        }
        requestAnimationFrame(sample);
      });
      return { note: 'Headless isolated fixture; drawSubmission measures JS Canvas command submission, not complete GPU frame time. rAF is the live mouth scene on this test machine.', drawSubmission, animationFrames: stats(frames) };
    });
    results.push({ name, url, readyMs, manifestCount: Object.keys(ART_ASSETS).length, loaded: loaded.size, blocked: blocked.length, drawn: drawn.length, state: current, errors, ...(profile ? { profile } : {}) });
  } catch (error) {
    await screenshot('failure');
    await writeFile(new URL(`${name}-failure.json`, out), JSON.stringify({ error: error.stack, errors, failed, loaded: [...loaded], blocked }, null, 2));
    throw error;
  } finally { await context.close(); }
}

try {
  if (process.env.ART_PAGES === '1') {
    const served = await servePages(); pagesServer = served.server;
    await verify(served.url, 'pages');
  } else {
    const url = process.env.GAME_URL || 'http://127.0.0.1:4177/';
    const name = process.env.ART_LABEL || 'development';
    await verify(url, name);
    await verify(url, `${name === 'development' ? '' : `${name}-`}fallback`, true);
  }
  const reportName = process.env.ART_PAGES === '1' ? 'pages-result.json' : process.env.ART_LABEL ? `${process.env.ART_LABEL}-result.json` : 'result.json';
  await writeFile(new URL(reportName, out), JSON.stringify(results, null, 2));
  console.log(JSON.stringify(results.map(({ name, readyMs, manifestCount, loaded, blocked, drawn, errors }) => ({ name, readyMs, manifestCount, loaded, blocked, drawn, errors })), null, 2));
} finally {
  await browser.close();
  if (pagesServer) { pagesServer.closeAllConnections(); await new Promise(accept => pagesServer.close(accept)); }
}
