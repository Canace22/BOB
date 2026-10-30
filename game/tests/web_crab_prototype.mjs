// Node 20+. Real keys in an isolated browser; snapshots are read-only observations.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'crab-prototype');
mkdirSync(output, { recursive: true });
const fallback = process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const executablePath = existsSync(chromium.executablePath()) ? chromium.executablePath() : fallback;
const browser = await chromium.launch({ executablePath, headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 },
  ...(process.env.RECORD_VIDEO === '1' ? {recordVideo: {dir: output, size: {width: 1280, height: 720}}} : {}) });
const page = await context.newPage();
page.setDefaultTimeout(120000);
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4188/BOB/godot/?prototype=crab';
const errors = [], held = new Set(), shots = new Set(), trace = [], checks = [], damage = [];
let completeState, deathState, retryState, dashState;
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
page.on('requestfailed', request => errors.push(`${request.failure()?.errorText} ${request.url()}`));
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const capture = name => page.screenshot({ path: path.join(output, `${name}.png`) });
const waitStage = stage => page.waitForFunction(expected => JSON.parse(window.render_game_to_text()).stage === expected, stage);
async function key(name, pressed) {
  if (held.has(name) === pressed) return;
  if (pressed) { held.add(name); await page.keyboard.down(name); }
  else { held.delete(name); await page.keyboard.up(name); }
}
async function release() { for (const name of [...held]) await key(name, false); }
async function ready() {
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', null, { timeout: 120000 });
  await waitStage('ready');
  await page.locator('canvas').click({ position: { x: 600, y: 450 } });
  const s = await state();
  assert.equal(s.room, 'prototype.crab');
  assert.equal(s.save_enabled, false, 'training disables campaign autosave');
  assert.deepEqual(s.flags, [], 'training does not award campaign flags');
  return s;
}
async function begin() {
  await page.keyboard.press('Enter');
  await waitStage('fighting');
}
function observe(s) {
  trace.push(s);
  if (trace.length > 240) trace.shift();
  assert.equal(s.save_enabled, false, 'autosave remains disabled during training');
  assert.deepEqual(s.flags, [], 'no campaign progress is granted');
}

async function fightWithoutDash() {
  const began = Date.now();
  let lastTap = 0, jumpUntil = 0, lastHp = 4;
  while (Date.now() - began < 180000) {
    const s = await state(), p = s.player, b = s.boss;
    observe(s);
    if (s.hp !== lastHp) { damage.push({ time: s.time, from: lastHp, to: s.hp, boss: b.kind, state: b.state }); lastHp = s.hp; }
    if (s.stage === 'won') return s;
    assert.notEqual(s.stage, 'lost', 'no-dash combat route must survive');
    if (b.state === 'tell' && !shots.has(b.kind)) {
      shots.add(b.kind);
      await capture(`tell-${b.kind}`);
      console.log(`SAW ${b.kind} hp=${s.hp} boss=${b.hp}`);
    }
    if (b.phase === 2 && !shots.has('phase-2')) { shots.add('phase-2'); await capture('phase-2'); }
    if (b.state === 'active' && !shots.has(`active-${b.kind}`)) {
      shots.add(`active-${b.kind}`); await capture(`active-${b.kind}`);
      assert(b.frame >= (b.kind === 'charge' ? 7 : b.kind === 'slam' ? 5 : 4), 'damage uses contact poses');
    }
    const dx = b.x - p.x, distance = Math.abs(dx), toward = Math.sign(dx);
    let movement = 0, tap;
    const attackState = b.state === 'tell' || b.state === 'active';
    if (attackState) {
      // The mother crab is solid and far taller than the hero's jump. Jump
      // only over its low claw; retreat from the high slam and full shell.
      const bossFacesPlayer = Math.sign(p.x - b.x) === b.facing;
      const clearance = b.kind === 'slam' ? 320 : 370;
      if (['slam', 'charge'].includes(b.kind) && bossFacesPlayer && distance < clearance) movement = -toward;
      if (['sweep', 'second'].includes(b.kind) && b.state === 'tell' && p.floor && distance < 330
          && b.timer > (b.kind === 'second' ? 0.32 : 0.43) && Date.now() >= jumpUntil) {
        jumpUntil = Date.now() + 450;
      }
    } else if (b.state === 'recover' || b.state === 'phase') {
      const longRecovery = ['slam', 'charge'].includes(b.kind) && b.state === 'recover';
      if (longRecovery && b.timer < 0.18 && s.hp <= 2 && s.energy >= 2 && p.floor && p.mode === 'idle') {
        tap = 'f';
      } else if (p.mode !== 'heal') {
        if (distance > 195) movement = toward;
        else if (p.mode === 'idle' && p.facing !== toward) movement = toward;
        else if (distance <= 205 && p.facing === toward) {
          if (p.mode === 'idle') tap = longRecovery && b.timer < 0.65 && s.energy >= 2 ? 'k' : 'j';
          else if (p.mode === 'attack' && p.kind === 'short1' && p.elapsed >= 0.26) tap = 'j';
        }
      }
    } else {
      // Let the boss choose at melee distance, rather than damage it through
      // the whole observation phase. This records every advertised move.
      if (distance > 210) movement = toward;
    }
    await key('a', movement < 0);
    await key('d', movement > 0);
    await key('Space', Date.now() < jumpUntil);
    if (tap && Date.now() - lastTap > 90) { await page.keyboard.press(tap, { delay: 18 }); lastTap = Date.now(); }
    await page.waitForTimeout(20);
  }
  throw new Error('No-dash boss route exceeded three minutes');
}

try {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  const initial = await ready();
  assert.equal(initial.dash_enabled, false);
  await capture('ready');
  await begin();
  // Step clear of the left boundary so the charge has its required escape
  // space. At the spawn point that attack is correctly filtered out.
  await key('d', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.x >= 1000);
  await key('d', false);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.state === 'tell');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === true);
  const paused = await state();
  await page.waitForTimeout(500);
  const frozen = await state();
  assert.equal(frozen.time, paused.time, 'pause freezes combat clock');
  assert.equal(frozen.boss.timer, paused.boss.timer, 'pause freezes attack timer');
  assert.equal(frozen.boss.frame, paused.boss.frame, 'pause freezes animation frame');
  assert.equal(frozen.player.x, paused.player.x, 'pause freezes player position');
  await capture('paused');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused === false);
  checks.push('pause_freezes_and_resumes');
  completeState = await fightWithoutDash();
  await release();
  assert.equal(completeState.dash_enabled, false);
  for (const move of ['sweep', 'slam', 'charge', 'phase-2']) assert(shots.has(move), `combat observes ${move}`);
  assert.equal(completeState.boss.hp, 0);
  await capture('victory');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).boss.opacity === 0);
  await capture('retreated');
  checks.push('no_dash_victory_three_moves_phase_two');

  await begin();
  await release();
  // No state injection: deliberately stand still and allow the boss to win.
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).stage === 'lost', null, { timeout: 90000 });
  deathState = await state();
  assert.equal(deathState.hp, 0);
  await capture('defeat');
  await begin();
  retryState = await state();
  assert.equal(retryState.hp, 4, 'retry restores player health');
  assert.equal(retryState.boss.hp, retryState.boss.maximum, 'retry restores boss health');
  assert.equal(retryState.boss.phase, 1, 'retry clears second phase');
  assert.equal(retryState.boss.opacity, 1, 'retry restores visible body');
  assert.equal(retryState.player.dead, false);
  await capture('retry');
  checks.push('standstill_death_and_keyboard_retry');

  // A reload is an ordinary user action returning to the training menu;
  // it also verifies the independent prototype does not resume campaign data.
  await release();
  await page.reload({ waitUntil: 'domcontentloaded', timeout: 120000 });
  await ready();
  await page.mouse.click(1100, 90);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).dash_enabled === true);
  await begin();
  const beforeDash = await state();
  await key('Shift', true);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).player.mode === 'dash', null, { timeout: 3000, polling: 'raf' });
  dashState = await state();
  await capture('dash');
  await key('Shift', false);
  await page.waitForTimeout(300);
  const afterDash = await state();
  assert(Math.abs(afterDash.player.x - beforeDash.player.x) > 120, 'dash moves the player through real input');
  assert.equal(afterDash.save_enabled, false);
  assert.deepEqual(afterDash.flags, []);
  checks.push('reload_ready_and_dash_comparison');
  assert.deepEqual(errors, [], 'no resource, browser or engine errors');
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, url, checks, shots: [...shots], damage, completeState, deathState, retryState, dashState, errors }, null, 2));
  console.log(`PASS training route; ${output}`);
} catch (error) {
  await release().catch(() => {});
  await capture('failure').catch(() => {});
  const current = await state().catch(() => null);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, url, checks, shots: [...shots], damage, current, errors, trace, error: error.stack }, null, 2));
  console.error(current, errors);
  throw error;
} finally {
  await release().catch(() => {});
  await context.close();
  await browser.close();
}
