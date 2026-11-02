// Node 20+. Real keyboard/mouse input only; the game's snapshot API is read-only.
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, renameSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'player-animation');
mkdirSync(output, { recursive: true });
const installed = ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', 'C:/Program Files/Google/Chrome/Application/chrome.exe'];
const executablePath = process.env.CHROME_PATH ?? [chromium.executablePath(), ...installed].find(existsSync);
const browser = await chromium.launch({ executablePath, headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 },
  ...(process.env.RECORD_VIDEO !== '0' ? { recordVideo: { dir: output, size: { width: 1280, height: 720 } } } : {}) });
const page = await context.newPage();
const video = page.video();
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4187/BOB/godot/?prototype=crab';
const suite = process.env.ANIMATION_SUITE ?? 'full';
assert(['full', 'locomotion'].includes(suite), 'ANIMATION_SUITE must be full or locomotion');
const errors = [], observations = [], checks = [], held = new Set();
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
page.on('requestfailed', request => errors.push(`${request.failure()?.errorText} ${request.url()}`));
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const capture = name => page.screenshot({ path: path.join(output, `${name}.png`) });
async function key(name, pressed) {
  if (held.has(name) === pressed) return;
  if (pressed) { held.add(name); await page.keyboard.down(name); }
  else { held.delete(name); await page.keyboard.up(name); }
}
async function release() { for (const name of [...held]) await key(name, false); }
async function wait(test, argument = null, timeout = 5000) {
  await page.waitForFunction(test, argument, { timeout, polling: 'raf' });
}
function observe(s, direction, clip) {
  const a = s.player.animation;
  assert.equal(s.save_enabled, false, 'training never writes campaign saves');
  assert.deepEqual(s.flags, []);
  assert.equal(a.direction, direction);
  if (clip) assert.equal(a.clip, clip);
  assert.equal(a.using_directional, true, `${direction}/${a.clip} must use new art`);
  assert(a.file.includes(`/animation-v2/${direction}/`), `${direction} loads its own bitmap: ${a.file}`);
  assert.deepEqual(a.pivot, [192, 342], 'every pose uses the common registered pivot');
  observations.push({ time: s.time, hp: s.hp, x: s.player.x, y: s.player.y, mode: s.player.mode,
    kind: s.player.kind, elapsed: s.player.elapsed, ...a });
  return s;
}
async function clip(direction, name, timeout = 5000) {
  await wait(expected => JSON.parse(window.render_game_to_text()).player.animation.clip === expected, name, timeout);
  return observe(await state(), direction, name);
}
async function fresh(direction, dash = false) {
  await release();
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await wait(() => typeof window.render_game_to_text === 'function', null, 120000);
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'ready');
  await page.locator('canvas').click({ position: { x: 600, y: 450 } });
  if (dash) {
    await page.mouse.click(1100, 90);
    await wait(() => JSON.parse(window.render_game_to_text()).dash_enabled === true);
  }
  await page.keyboard.press('Enter');
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'fighting');
  await wait(() => { const p = JSON.parse(window.render_game_to_text()).player; return p.floor && p.animation.clip === 'idle'; });
  const movement = direction === 'left' ? 'a' : 'd';
  await key(movement, true);
  await wait(expected => JSON.parse(window.render_game_to_text()).player.animation.direction === expected, direction);
  await key(movement, false);
  await clip(direction, 'idle');
}
async function movement(direction) {
  await fresh(direction, suite === 'full');
  const movementKey = direction === 'left' ? 'a' : 'd';
  await key(movementKey, true);
  await clip(direction, 'run');
  const frames = new Set();
  let completeCycle = false;
  for (let i = 0; i < 100; i++) {
    await page.waitForTimeout(10);
    const s = observe(await state(), direction, 'run');
    frames.add(s.player.animation.file);
    const a = s.player.animation;
    if (a.run_distance >= a.stride_pixels && frames.size === a.frame_count) { completeCycle = true; break; }
  }
  assert(completeCycle && frames.size >= 2, 'travel presents every run texture through one complete stride');
  await capture(`${direction}-run`);
  await key(movementKey, false);
  await clip(direction, 'idle');
  await capture(`${direction}-idle`);
  // A fresh keyboard-started match keeps the longer gait audit clear of the boss's approach.
  await fresh(direction, suite === 'full');
  await page.keyboard.press('Escape');
  await wait(() => JSON.parse(window.render_game_to_text()).paused);
  const paused = await state();
  await page.waitForTimeout(250);
  assert.deepEqual((await state()).player.animation, paused.player.animation, 'pause freezes frames, phase and distance');
  await page.keyboard.press('Escape');
  await wait(() => !JSON.parse(window.render_game_to_text()).paused);
  await key('Space', true);
  await clip(direction, 'jump_rise');
  await capture(`${direction}-jump-rise`);
  await page.waitForTimeout(250);
  await key('Space', false);
  await clip(direction, 'jump_fall');
  await capture(`${direction}-jump-fall`);
  await clip(direction, 'land');
  await capture(`${direction}-land`);
  await clip(direction, 'idle');
  if (suite === 'full') {
    const before = await state();
    await key('Shift', true);
    await clip(direction, 'dash');
    await capture(`${direction}-dash`);
    await key('Shift', false);
    await clip(direction, 'idle');
    assert(Math.abs((await state()).player.x - before.player.x) > 10, 'dash input actually moves the player');
  }
  checks.push(`${direction}:idle/run/stop/pause/rise/fall/land${suite === 'full' ? '/dash' : ''}`);
}
async function attacks(direction) {
  await fresh(direction);
  await page.keyboard.press('j');
  await clip(direction, 'attack');
  await contact(direction, 'attack', 0.12, 0.20);
  await wait(() => { const p = JSON.parse(window.render_game_to_text()).player; return p.kind === 'short1' && p.elapsed >= 0.26 && p.elapsed < 0.4; });
  await page.keyboard.press('j');
  await clip(direction, 'attack2');
  await contact(direction, 'attack2', 0.16, 0.24);
  await capture(`${direction}-attack2`);
  await clip(direction, 'idle');
  await page.keyboard.press('k');
  await clip(direction, 'heavy');
  await contact(direction, 'heavy', 0.30, 0.42);
  await capture(`${direction}-heavy`);
  await clip(direction, 'idle');
  checks.push(`${direction}:attack/attack2/heavy`);
}
async function contact(direction, name, start, end) {
  await wait(({ name, start, end }) => {
    const p = JSON.parse(window.render_game_to_text()).player;
    return p.animation.clip === name && p.elapsed >= start && p.elapsed < end;
  }, { name, start, end });
  observe(await state(), direction, name);
}
async function hurtAndHeal(direction) {
  await fresh(direction);
  // Deliberately stand still until a real boss hit; no health/state injection.
  const hurt = await clip(direction, 'hurt', 30000);
  assert(hurt.hp < 4 && hurt.hp > 0, 'real incoming damage produces hurt');
  await capture(`${direction}-hurt`);
  await wait(() => { const p = JSON.parse(window.render_game_to_text()).player; return p.floor && p.mode === 'idle'; });
  await page.keyboard.press('f');
  await clip(direction, 'heal');
  await wait(() => { const p = JSON.parse(window.render_game_to_text()).player; return p.mode === 'heal' && p.elapsed >= 0.3; });
  observe(await state(), direction, 'heal');
  await capture(`${direction}-heal`);
  await wait(previous => JSON.parse(window.render_game_to_text()).hp > previous, hurt.hp);
  checks.push(`${direction}:hurt/heal`);
}
async function wall() {
  await fresh('left');
  await key('a', true);
  await wait(() => JSON.parse(window.render_game_to_text()).player.x <= 760.1);
  await clip('left', 'idle');
  const stopped = await state();
  await page.waitForTimeout(250);
  const later = observe(await state(), 'left', 'idle');
  assert.equal(later.player.x, stopped.player.x, 'held movement is blocked at arena wall');
  assert.equal(later.player.animation.run_distance, 0, 'wall pressure cannot advance a gait');
  await capture('left-wall-stopped');
  await release();
  checks.push('wall:held-input-stops-feet');
}

try {
  for (const direction of ['right', 'left']) {
    await movement(direction);
    if (suite === 'full') {
      await attacks(direction);
      await hurtAndHeal(direction);
    }
  }
  await wall();
  assert.deepEqual(errors, [], 'no resource, engine or browser errors');
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, suite, url, video: video ? "route.webm" : null, checks, observations, errors }, null, 2));
  console.log(`PASS player animation keyboard route; ${output}`);
} catch (error) {
  await release().catch(() => {});
  await capture('failure').catch(() => {});
  const current = await state().catch(() => null);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, suite, url, video: video ? "route.webm" : null, checks, observations, current, errors, error: error.stack }, null, 2));
  throw error;
} finally {
  await release().catch(() => {});
  await context.close();
  if (video) renameSync(await video.path(), path.join(output, "route.webm"));
  await browser.close();
}
