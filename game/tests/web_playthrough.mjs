// Run with Node 20+, PLAYWRIGHT_MODULE if Playwright is not locally installed.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'web');
mkdirSync(output, { recursive: true });
const fallback = process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const executablePath = existsSync(chromium.executablePath()) ? chromium.executablePath() : fallback;
const browser = await chromium.launch({ executablePath, headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
const page = await context.newPage();
const errors = [], seen = [], held = new Set();
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4187/BOB/godot/';
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const capture = name => page.screenshot({ path: path.join(output, `${name}.png`) });
async function key(key, pressed) {
  if (held.has(key) === pressed) return;
  if (pressed) { held.add(key); await page.keyboard.down(key); }
  else { held.delete(key); await page.keyboard.up(key); }
}
async function release() { for (const item of [...held]) await key(item, false); }
try {
  await page.goto(url, { waitUntil: 'networkidle', timeout: 120000 });
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', { timeout: 120000 });
  await page.locator('canvas').click();
  await page.waitForTimeout(500);
  await capture('start');
  await page.keyboard.press('Tab');
  await page.waitForTimeout(150);
  assert.equal((await state()).paused, true, 'map pauses the world');
  await capture('map');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === false);
  assert.equal((await state()).paused, false, 'escape resumes');
  const start = Date.now();
  let jumped = 0, lastTap = 0, checkpoint = '', completeState;
  while (Date.now() - start < 240000) {
    const s = await state(), p = s.player;
    if (!seen.includes(s.room)) {
      seen.push(s.room);
      console.log(`ROOM ${s.room} hp=${s.hp}`);
      await capture(s.room);
    }
    if (s.flags.includes('complete.r1')) { completeState = s; break; }
    if (p.dead) { await release(); await page.waitForTimeout(400); continue; }
    let left = false, right = true, tap;
    if (['R1-01', 'R1-04'].includes(s.room) && p.x < 4 * 64 && checkpoint !== s.room) {
      tap = 'e'; checkpoint = s.room;
    }
    const target = s.enemies.find(e => e.state !== 'dead' && ((e.boss && Math.abs(e.x - p.x) < 600) || (!e.boss && Math.abs(e.x - p.x) < 220 && Math.abs(e.y - p.y) < 30)));
    if (target) {
      const dx = target.x - p.x;
      left = dx < 0; right = dx > 0;
      if (['tell', 'active'].includes(target.state)) {
        if (target.kind === 'slam') { left = dx > 0; right = dx < 0; }
        else {
          if (target.state === 'tell' && target.timer > (target.kind === 'second' ? 0.20 : 0.43) && p.floor) tap = 'Space';
          if (Math.abs(dx) < 100) { left = false; right = false; }
        }
      } else if (Math.abs(dx) < 100) {
        left = false; right = false;
        if (p.mode === 'idle' || (p.mode === 'attack' && p.kind === 'short1' && p.elapsed > 0.31)) tap = 'q';
      }
    } else {
      if (p.floor) { jumped = 0; if (!p.floor_ahead) { tap = 'Space'; jumped = Date.now(); } }
      else if (jumped && Date.now() - jumped > 300 && s.room === 'R1-05' && !p.air_dash) tap = 'Shift';
      if (s.room === 'R1-04' && s.flags.includes('boss.r1_shell_crab') && !s.abilities.includes('ability.dash') && p.x > 31 * 64) tap = 'e';
      if (s.room === 'R1-05' && p.x > 2.8 * 64 && p.x < 5 * 64 && !s.flags.includes('habitat.r1_clearflow')) tap = 'e';
      if (p.x > s.room_width - 150) tap = 'e';
    }
    await key('a', left); await key('d', right);
    if (tap && Date.now() - lastTap > 65) { await page.keyboard.press(tap, { delay: 18 }); lastTap = Date.now(); }
    await page.waitForTimeout(20);
  }
  await release();
  await capture('result');
  assert(completeState, 'five-room route completes within four minutes');
  assert.deepEqual(seen, ['R1-01', 'R1-02', 'R1-03', 'R1-04', 'R1-05']);
  assert(completeState.abilities.includes('ability.dash'));
  assert(completeState.flags.includes('boss.r1_shell_crab'));
  await page.waitForTimeout(1200);
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function');
  await page.waitForTimeout(500);
  const loaded = await state();
  assert.equal(loaded.room, 'R1-04', 'reload returns to checkpoint');
  assert(loaded.flags.includes('complete.r1') && loaded.abilities.includes('ability.dash'), 'progress survives reload');
  await capture('reload');
  assert.deepEqual(errors, [], 'no failed resources, script errors or browser errors');
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, url, seen, completeState, loaded, errors }, null, 2));
  console.log(`PASS browser route, map/pause, reload; ${output}`);
} catch (error) {
  await release();
  await capture('failure').catch(() => {});
  const current = await state().catch(() => null);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, url, seen, current, errors, error: error.stack }, null, 2));
  console.error(current, errors);
  throw error;
} finally { await browser.close(); }
