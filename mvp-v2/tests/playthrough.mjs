import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdir, stat, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { getLiftPosition, getSwingPosition } from '../mechanics.js';
import { rooms } from '../levels.js';

if (Number(process.versions.node.split('.')[0]) < 20) {
  const bundledNode = join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin', process.platform === 'win32' ? 'node.exe' : 'node');
  const result = spawnSync(bundledNode, [fileURLToPath(import.meta.url)], { stdio: 'inherit', env: process.env });
  if (result.error) console.error('浏览器测试需要 Node.js 20+；请升级 Node，或通过 Codex 的内置 Node 运行本脚本。', result.error.message);
  process.exit(result.status ?? 1);
}

// The game has no production dependencies. Install Playwright separately, or
// point PLAYWRIGHT_MODULE at its package directory / index.mjs.
async function loadPlaywright() {
  if (!process.env.PLAYWRIGHT_MODULE) {
    try { return await import('playwright'); } catch { /* Try the desktop runtime. */ }
  }
  let path = process.env.PLAYWRIGHT_MODULE || join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
  if ((await stat(path)).isDirectory()) path = join(path, 'index.mjs');
  return import(pathToFileURL(resolve(path)).href);
}

const { chromium } = await loadPlaywright();
const out = new URL('../output/playthrough/', import.meta.url);
await mkdir(out, { recursive: true });
const installedBrowser = process.platform === 'win32' ? [
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
].find(path => existsSync(path)) : undefined;
const executablePath = process.env.BROWSER_EXECUTABLE || (!existsSync(chromium.executablePath()) ? installedBrowser : undefined);
const browser = await chromium.launch({ headless: true, ...(executablePath ? { executablePath } : {}) });
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
const errors = [];
const requestedImages = [];
page.on('request', request => { if (request.resourceType() === 'image') requestedImages.push(decodeURIComponent(request.url())); });
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const tick = frames => page.evaluate(frames => window.advanceTime(frames * 1000 / 60), frames);
const roomIndex = s => typeof s.room === 'number' ? s.room : s.roomIndex;
async function screenshot(name) {
  await page.screenshot({ path: fileURLToPath(new URL(`${name}.png`, out)) });
  await writeFile(new URL(`${name}.json`, out), JSON.stringify(await state(), null, 2));
}
async function key(keyName, frames = 1) {
  await page.keyboard.down(keyName); await tick(frames);
  await page.keyboard.up(keyName); await tick(2);
}
async function walk(x) {
  const before = await state();
  await key(x > before.player.x ? 'ArrowRight' : 'ArrowLeft', Math.round(Math.abs(x - before.player.x) / 4));
}
async function interact() { await key('KeyF'); }
async function jumpTo(x) {
  const before = await state();
  const direction = x > before.player.x ? 'ArrowRight' : 'ArrowLeft';
  await page.keyboard.down(direction); await page.keyboard.down('Space');
  await tick(Math.round(Math.abs(x - before.player.x) / 4));
  await page.keyboard.up('Space'); await page.keyboard.up(direction); await tick(70);
  assert.equal((await state()).deaths, before.deaths, `Unexpected recovery jumping to ${x}`);
}
async function floatTo(x, extraFrames = 0) {
  const before = await state();
  await page.keyboard.down(x > before.player.x ? 'ArrowRight' : 'ArrowLeft');
  await page.keyboard.down('ShiftLeft');
  await tick(Math.round(Math.abs(x - before.player.x) / 4));
  await page.keyboard.up('ArrowRight'); await page.keyboard.up('ArrowLeft');
  if (extraFrames) await tick(extraFrames);
  await page.keyboard.up('ShiftLeft'); await tick(70);
  assert.equal((await state()).deaths, before.deaths, `Unexpected recovery floating to ${x}`);
  assert((await state()).player.grounded, `Not grounded after floating to ${x}`);
}
const hasFlag = async flag => assert((await state()).flags.includes(flag), `Missing flag: ${flag}`);
async function until(predicate, timeout = 900) {
  for (let i = 0; i < timeout; i += 3) {
    const s = await state();
    if (predicate(s)) return s;
    await tick(3);
  }
  assert.fail(`Timed out waiting for facility: ${JSON.stringify(await state())}`);
}
async function chord(keys, frames) {
  for (const code of keys) await page.keyboard.down(code);
  await tick(frames);
  for (const code of [...keys].reverse()) await page.keyboard.up(code);
  await tick(2);
}
async function courseRoute() {
  const lift = rooms[3].lifts[0], ring = rooms[3].swings[0];
  await walk(422); await key('KeyW', 125);
  await hasFlag('course-climb'); assert.equal((await state()).player.y, 332);
  await screenshot('03a-climbing-net');
  await walk(640); await interact(); await hasFlag('course-powered');
  await walk(708);
  await until(s => {
    const flags = new Set(s.flags), at = getLiftPosition(lift, s.time, flags), next = getLiftPosition(lift, s.time + .05, flags);
    return at.y > 415 && at.y < 465 && next.y < at.y;
  });
  await chord(['ArrowRight','Space'], 35);
  await until(s => Boolean(s.player.riding));
  await key('Escape'); const pausedLift = await state(); await tick(120);
  assert.equal((await state()).player.y, pausedLift.player.y, 'Lift moves while paused');
  await key('Escape');
  await until(s => s.flags.includes('course-lift') && s.player.y < 150);
  await screenshot('03b-lift');
  await chord(['ArrowRight','Space'], 60); await tick(40);
  assert.equal((await state()).player.y, 152, 'Lift jump must reach the high landing');
  await walk(1250);
  await until(s => { const a = getSwingPosition(ring, s.time); return Math.hypot(s.player.x + 15 - a.x, s.player.y + 12 - a.y) < 95; });
  await interact(); assert((await state()).player.swinging);
  await tick(45);
  await until(s => { const a = getSwingPosition(ring, s.time); return a.x >= 1500 && a.vx >= 180; });
  await hasFlag('course-swing'); await screenshot('03c-swing');
  await chord(['ArrowRight','Space'], 45); await tick(30);
  assert.equal((await state()).player.y, 302, 'Bone-ring momentum must reach the far landing');
  await walk(1950); await jumpTo(2060); await jumpTo(2220);
  await interact(); await hasFlag('course-clear'); await screenshot('03d-course-exit');
  await walk(2330); await interact(); assert.equal(roomIndex(await state()), 2);
}

try {
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:4175/');
  await page.locator('#start-btn:not([disabled])').waitFor();
  await screenshot('00-title');
  await page.click('#start-btn'); await tick(2);
  assert.equal((await state()).mode, 'playing');
  await screenshot('01-mouth-start');

  // A closed gate must collide, and short/long resonance must be distinct.
  await walk(630); assert((await state()).player.x <= 520, 'Short gate is passable while closed');
  await key('KeyE', 3); await hasFlag('short-gate');
  await walk(1050); assert((await state()).memories.includes('song'));
  await walk(1630); assert((await state()).player.x <= 1520, 'Long gate is passable while closed');
  await key('KeyE', 3); assert(!(await state()).flags.includes('long-gate'), 'Short call opens long gate');
  await tick(35); await key('KeyE', 60); await hasFlag('long-gate');
  await walk(1910); await interact(); await hasFlag('habitat-mouth');
  await screenshot('02-resonance-and-habitat');
  await walk(2260); await interact(); assert.equal(roomIndex(await state()), 1);

  // The crab blocks the path until food is collected and offered.
  await walk(850); assert((await state()).player.x <= 725, 'Unfed crab does not block the path');
  await interact(); assert(!(await state()).flags.includes('fed'), 'Crab fed without food');
  await walk(370); await interact(); await hasFlag('food');
  await walk(730); await interact(); await hasFlag('fed');
  const deathsBefore = (await state()).deaths;
  await walk(1280); await tick(10);
  assert.equal((await state()).deaths, deathsBefore + 1, 'Unsafe liquid did not recover to checkpoint');
  await hasFlag('fed'); await hasFlag('long-gate');
  assert((await state()).memories.includes('song'), 'Recovery lost a memory');
  await walk(1080); await interact(); await hasFlag('drain');
  await interact(); assert(!(await state()).flags.includes('drain'), 'Valve cannot be reversed');
  await interact(); await hasFlag('drain');
  await walk(1460); await tick(20); assert((await state()).memories.includes('drift'));
  await walk(1620); await jumpTo(1780);
  await walk(1840); await interact();
  await walk(2010); await interact(); await hasFlag('habitat-stomach');
  await screenshot('03-stomach-restored');
  await walk(2290); await interact(); assert.equal(roomIndex(await state()), 3);
  await courseRoute();

  await walk(500); await interact(); assert((await state()).abilities.includes('float'));
  await walk(730); await interact();
  await floatTo(1100, 8);
  assert((await state()).player.y < 340, 'First floating stage did not reach the membrane platform');
  assert((await state()).pressure < 0.6, 'Floating did not consume pressure');
  await interact(); assert((await state()).pressure > 0.98, 'Midpoint pressure refill failed');
  await walk(1260); await floatTo(1660);
  assert((await state()).player.y < 150, 'Second floating stage did not reach the upper platform');
  assert((await state()).memories.includes('surface'), 'Floating route missed the high memory');
  await walk(1770); await interact(); assert((await state()).pressure > 0.98);
  await walk(1940); await interact(); await hasFlag('habitat-lung');
  await walk(2220); await interact(); await hasFlag('shortcut');
  await screenshot('04-lung-shortcut');
  await walk(2300); await interact(); assert.equal(roomIndex(await state()), 0);
  assert((await state()).player.y < 300, 'Shortcut does not lead to the previously inaccessible platform');
  await walk(620); assert((await state()).memories.includes('return'));
  await screenshot('05-return-memory');

  // Modal panels freeze gameplay and resume without stuck movement.
  await key('Escape'); const paused = await state();
  await key('ArrowRight', 90);
  assert.equal((await state()).player.x, paused.player.x, 'Player moves while paused');
  assert.equal((await state()).elapsed, paused.elapsed, 'Journey timer advances while paused');
  await screenshot('06-pause'); await key('Escape');
  for (const [button, title] of [['KeyM', '地图'], ['KeyJ', '手记']]) {
    await key(button); assert((await page.locator('#overlay-title').innerText()).includes(title));
    await screenshot(button === 'KeyM' ? '07-map' : '08-journal');
    await key('Escape'); assert.equal((await state()).mode, 'playing');
  }

  // Reload from the persisted checkpoint; no test mutates storage or game state.
  const saved = await state();
  await page.reload(); await page.locator('#continue-btn').waitFor({ state: 'visible' });
  await page.click('#continue-btn'); await tick(2);
  const restored = await state();
  for (const property of ['flags', 'memories', 'abilities']) assert.deepEqual([...restored[property]].sort(), [...saved[property]].sort(), `${property} lost after reload`);
  assert.equal(roomIndex(restored), 0);
  await walk(170); await tick(60); await interact();
  assert.equal((await state()).mode, 'ending'); await hasFlag('finished');
  assert.equal((await state()).memories.length, 4);
  assert.equal((await state()).flags.filter(flag => flag.startsWith('habitat-')).length, 3);
  await screenshot('09-ending');
  // Practice is a user-facing route entry, never a test-only teleport API.
  // It must not replace the user's main journey save.
  const mainSave = await page.evaluate(() => localStorage.getItem('whalefall-v2-2d-save'));
  await page.reload(); await page.locator('#practice-btn:not([disabled])').waitFor();
  await page.click('#practice-btn'); await tick(2);
  assert.equal((await state()).room, 3); assert.equal((await state()).practice, true);
  await walk(422); await key('KeyW', 125); await hasFlag('course-climb');
  assert.equal(await page.evaluate(() => localStorage.getItem('whalefall-v2-2d-save')), mainSave, 'Practice overwrote the main save');
  await key('Escape'); await page.click('[data-action="main-menu"]');
  await page.click('#continue-btn'); await tick(2); await hasFlag('finished');
  assert.equal((await state()).memories.length, 4);
  assert(requestedImages.some(url => url.includes('/assets/abyss-backdrop-v2.png')), 'Missing independent far-scene asset');
  assert(!requestedImages.some(url => /\/L\d{2}_/.test(url)), 'Gameplay requested a concept/storyboard sheet');
  assert.deepEqual(errors, [], 'Browser errors were emitted');
  await writeFile(new URL('result.json', out), JSON.stringify({ passed: true, errors, state: await state() }, null, 2));
  console.log('PASS: keyboard-only four-region journey; climbing net, lift passenger, momentum swing, resonance gates, drainage, float, return, all memories/habitats, pause, reload, ending; isolated practice preserves main save; no storyboard background requests or browser errors.');
} catch (error) {
  try { await screenshot('failure'); } catch { /* Preserve the original failure. */ }
  await writeFile(new URL('failure-errors.json', out), JSON.stringify(errors, null, 2));
  console.error(error); process.exitCode = 1;
} finally { await browser.close(); }
