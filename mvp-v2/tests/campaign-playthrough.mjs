import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { mkdir, stat, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { UNIT } from '../campaign-levels.js';

if (Number(process.versions.node.split('.')[0]) < 20) {
  const runtime = join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin', process.platform === 'win32' ? 'node.exe' : 'node');
  const result = spawnSync(runtime, [fileURLToPath(import.meta.url)], { stdio: 'inherit', env: process.env });
  if (result.error) console.error(result.error.message);
  process.exit(result.status ?? 1);
}

async function loadPlaywright() {
  if (!process.env.PLAYWRIGHT_MODULE) {
    try { return await import('playwright'); } catch { /* Use bundled desktop dependency. */ }
  }
  let path = process.env.PLAYWRIGHT_MODULE || join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
  if ((await stat(path)).isDirectory()) path = join(path, 'index.mjs');
  return import(pathToFileURL(resolve(path)).href);
}

// A valid save captured from the completed legacy four-room keyboard run.
// It is seeded only into this test's isolated browser context, never user storage.
const legacyKey = 'whalefall-v2-2d-save';
const legacySave = JSON.stringify({
  version: 2, room: 0, checkpoint: { room: 0, x: 155, y: 532 },
  flags: ['short-gate', 'long-gate', 'habitat-mouth', 'food', 'fed', 'drain', 'course-climb', 'course-powered', 'course-lift', 'habitat-stomach', 'course-swing', 'course-clear', 'float', 'shortcut', 'finished', 'habitat-lung'],
  memories: ['song', 'drift', 'surface', 'return'], abilities: ['float'], visited: [0, 1, 3, 2],
  habitats: { 'habitat-mouth': 12, 'habitat-stomach': 12, 'habitat-lung': 12 }, elapsed: 87.6894333333491, deaths: 1,
});
const { chromium } = await loadPlaywright();
const out = resolve(process.env.TEST_OUTPUT || fileURLToPath(new URL('../output/campaign-playthrough/', import.meta.url)));
await mkdir(out, { recursive: true });
const installedBrowser = process.platform === 'win32' ? [
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
].find(path => existsSync(path)) : undefined;
const executablePath = process.env.BROWSER_EXECUTABLE || (!existsSync(chromium.executablePath()) ? installedBrowser : undefined);
const browser = await chromium.launch({ headless: true, ...(executablePath ? { executablePath } : {}) });
const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
const page = await context.newPage(), errors = [], httpErrors = [], checkpoints = [], combat = [];
await context.addInitScript(({ key, save }) => { if (!localStorage.getItem(key)) localStorage.setItem(key, save); }, { key: legacyKey, save: legacySave });
page.on('pageerror', error => errors.push(error.message));
page.on('response', response => { if (response.status() >= 400) httpErrors.push({ status: response.status(), url: response.url() }); });
const state = () => page.evaluate(() => JSON.parse(window.render_campaign_to_text()));
const tick = frames => page.evaluate(frames => window.advanceTime(frames * 1000 / 60), frames);
async function key(code, frames = 1) {
  await page.keyboard.down(code); await tick(frames);
  await page.keyboard.up(code); await tick(2);
}
async function chord(codes, frames) {
  for (const code of codes) await page.keyboard.down(code);
  await tick(frames);
  for (const code of [...codes].reverse()) await page.keyboard.up(code);
  await tick(2);
}
async function screenshot(name) {
  const snapshot = await state(); checkpoints.push({ name, room: snapshot.room, player: snapshot.player });
  await page.screenshot({ path: join(out, `${name}.png`) });
  await writeFile(join(out, `${name}.json`), JSON.stringify(snapshot, null, 2));
}
async function until(predicate, frames = 600) {
  for (let i = 0; i < frames; i += 3) {
    const snapshot = await state(); if (predicate(snapshot)) return snapshot;
    await tick(3);
  }
  assert.fail(`Timed out: ${JSON.stringify(await state())}`);
}

async function walk(x) {
  for (let frames = 0; frames < 1000; frames += 12) {
    const p = (await state()).player, distance = x - p.x;
    if (Math.abs(distance) < 5) return;
    await key(distance > 0 ? 'ArrowRight' : 'ArrowLeft', Math.max(1, Math.min(12, Math.floor(Math.abs(distance) / 3.2))));
  }
  assert.fail(`Could not walk to ${x}: ${JSON.stringify(await state())}`);
}
async function jumpTo(x) {
  const p = (await state()).player, frames = Math.round(Math.abs(x - p.x) / 3.2);
  await chord([x > p.x ? 'ArrowRight' : 'ArrowLeft', 'Space'], frames); await tick(55);
  assert((await state()).player.grounded, `Jump to ${x} did not land`);
}
async function enterRoom(expected) {
  await key('KeyE'); assert.equal((await state()).room, expected);
  await tick(8);
}
async function fight(id) {
  const phases = new Set(), seenMoves = new Set(), held = new Set();
  const initial = await state();
  for (let frame = 0; frame < 3600; frame += 4) {
    const s = await state(), enemy = s.enemies.find(enemy => enemy.id === id);
    if (!enemy || enemy.hp <= 0) {
      for (const code of held) await page.keyboard.up(code);
      await tick(2);
      assert.equal(s.deaths, initial.deaths, `Died fighting ${id}`);
      assert(phases.has('telegraph') && phases.has('active') && phases.has('recovery'), `${id} did not exercise warning/attack/recovery`);
      const result = { id, phases: [...phases], moves: [...seenMoves], life: s.life, deaths: s.deaths };
      combat.push(result); return result;
    }
    assert.equal(s.room, initial.room, `Unexpected room while fighting ${id}`);
    assert.equal(s.deaths, initial.deaths, `Died fighting ${id}`);
    phases.add(enemy.phase); seenMoves.add(enemy.move);
    const p = s.player, desired = new Set();
    // Read the visible enemy warning, then use ordinary keyboard movement:
    // jump the low sweep; step away from the locked smash landing marker.
    const evadingSmash = ['telegraph', 'active'].includes(enemy.phase) && enemy.move === 'smash';
    const target = evadingSmash ? enemy.targetX - 110 - p.w / 2 : enemy.x - p.w + 14;
    if (Math.abs(target - p.x) > 7) desired.add(target > p.x ? 'ArrowRight' : 'ArrowLeft');
    else if (p.facing !== 1) desired.add('ArrowRight');
    if (enemy.phase === 'telegraph' && enemy.move === 'sweep' && enemy.timer < .30 && p.grounded) desired.add('Space');
    const inRange = enemy.x - (p.x + p.w / 2) < 1.3 * UNIT && p.x < enemy.x + enemy.w && p.y + p.h > enemy.y && p.y + 7 < enemy.y + enemy.h;
    if (enemy.phase === 'recovery' && inRange && s.attackCooldown <= 0 && p.facing === 1) desired.add('KeyQ');
    for (const code of held) if (!desired.has(code)) { await page.keyboard.up(code); held.delete(code); }
    for (const code of desired) if (!held.has(code)) { await page.keyboard.down(code); held.add(code); }
    await tick(4);
  }
  for (const code of held) await page.keyboard.up(code);
  assert.fail(`Fight timed out: ${JSON.stringify(await state())}`);
}
async function dashAcross(direction = 1) {
  const before = await state(), arrow = direction > 0 ? 'ArrowRight' : 'ArrowLeft';
  await page.keyboard.down(arrow); await page.keyboard.down('Space'); await tick(12);
  await page.keyboard.down('ShiftLeft'); await tick(10);
  await page.keyboard.up('ShiftLeft'); await page.keyboard.up('Space'); await tick(20);
  await page.keyboard.up(arrow); await tick(30);
  const after = await state();
  assert(after.player.grounded && after.dash.available, 'Dash gap did not end on a stable landing');
  assert.equal(after.deaths, before.deaths);
  assert.equal(after.life, before.life);
  assert(direction * (after.player.x - before.player.x) > 190, 'Dash did not cross the four-unit gap');
}

async function route() {
  assert.equal((await state()).room, 'R1-01');
  assert(!(await state()).abilities.includes('A1'));
  await key('KeyM');
  const initialMap = await page.locator('#overlay-content').innerText();
  assert(!initialMap.includes('负壳蟹') && !initialMap.includes('流膜育窝'), 'Map reveals rooms that have not been discovered');
  await key('Escape');
  await key('KeyE'); await screenshot('01-wound-slope');
  await walk(350); await jumpTo(470);
  await walk(640); await jumpTo(730);
  await walk(880); await jumpTo(960);
  await walk(1360); await enterRoom('R1-02');
  await walk(410); await fight('R1-02-corpse-crab');
  await screenshot('02-baleen-crab');
  await walk(1005); await jumpTo(1160);
  await walk(1730); await enterRoom('R1-03');
  await walk(410); await fight('R1-03-corpse-crab-left');
  await walk(720); await jumpTo(875);
  await walk(1010); await fight('R1-03-corpse-crab-right');
  await walk(24.5 * UNIT - 15); await key('Space', 21); await key('KeyE'); await tick(55);
  assert((await state()).collected.includes('FRAGMENT_R1_03'), 'Fixed life fragment was not collected');
  await screenshot('03-tongue-fragment');
  await walk(1640); await enterRoom('R1-04');
  await key('KeyE');
  const camp = (await state()).checkpoint;
  assert.equal(camp.room, 'R1-04');
  const beforeDeath = await state();
  await walk(22 * UNIT - 15);
  // Deliberately stay in the boss's telegraphed attack range. Recovery is
  // reached through actual damage, never by calling respawn or editing state.
  await until(s => s.deaths > beforeDeath.deaths, 1800);
  const recovered = await state();
  assert.equal(recovered.room, 'R1-04');
  assert.equal(recovered.checkpoint.x, camp.x);
  assert.equal(recovered.player.x, camp.x);
  assert.equal(recovered.life, recovered.maxLife);
  assert(recovered.collected.includes('FRAGMENT_R1_03'));
  assert(!recovered.flags.includes('BOSS_R1'));
  await screenshot('04a-boss-death-recovery');
  await walk(8 * UNIT); await screenshot('04-boss-arena');
  const boss = await fight('BOSS_R1');
  assert((await state()).flags.includes('BOSS_R1'));
  assert(!(await state()).abilities.includes('A1'), 'Boss victory must not silently grant the ability');
  assert(boss.moves.includes('smash'), 'Boss smash was not exercised');
  await walk(32 * UNIT - 15); await key('KeyE');
  assert((await state()).abilities.includes('A1'));
  await screenshot('05-dash-granted');
  await walk(35 * UNIT - 15); await enterRoom('R1-05');
  // Fail a normal jump into the source's four-unit teaching gap. Recovery is
  // free and returns to the last stable platform, without granting A1 again.
  await walk(6 * UNIT - 23);
  const beforeFailure = await state();
  await chord(['ArrowRight', 'Space'], 50); await tick(60);
  const afterFailure = await state();
  assert.equal(afterFailure.life, beforeFailure.life);
  assert.equal(afterFailure.deaths, beforeFailure.deaths);
  assert(afterFailure.player.x < 6 * UNIT, 'Ordinary jump bypassed the dash teaching gap');
  await walk(6 * UNIT - 23); await dashAcross();
  assert((await state()).flags.includes('DASH_PRACTICED'));
  await screenshot('06-first-dash-gap');
  // Return with the acquired ability to perform the source's H1 side action.
  await walk(10 * UNIT + 8); await dashAcross(-1);
  await walk(4 * UNIT - 15); await key('Space', 1); await tick(60); await key('KeyE');
  assert((await state()).flags.includes('H1'));
  await screenshot('07-clearwater-nest');
  for (const edge of [6, 15, 24]) { await walk(edge * UNIT - 23); await tick(18); await dashAcross(); }
  await walk(36.5 * UNIT - 15); await key('KeyE');
  assert.equal((await state()).room, 'R1-05', 'Unavailable R3 should not become a fake playable room');
  assert((await state()).flags.includes('BATCH_R1'));
  await screenshot('08-r1-complete');
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.locator('#continue-btn').waitFor({ state: 'visible' });
  await page.click('#continue-btn'); await tick(4);
  const resumed = await state();
  assert.equal(resumed.room, 'R1-04');
  for (const flag of ['BOSS_R1', 'H1', 'BATCH_R1']) assert(resumed.flags.includes(flag));
  assert(resumed.abilities.includes('A1') && resumed.collected.includes('FRAGMENT_R1_03'));
  assert(!resumed.enemies.some(enemy => enemy.id === 'BOSS_R1' && enemy.hp > 0), 'Defeated boss returned after reload');
  await screenshot('09-resumed-boss-camp');
  await walk(0); await enterRoom('R1-03');
  await walk(1640); await enterRoom('R1-04');
  assert((await state()).flags.includes('BOSS_R1') && (await state()).abilities.includes('A1'));
  await screenshot('10-return-route');
}

try {
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:4177/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.locator('#start-btn:not([disabled])').waitFor({ timeout: 60000 });
  assert.equal(await page.evaluate(({ key }) => localStorage.getItem(key), { key: legacyKey }), legacySave);
  await page.click('#start-btn'); await tick(2);
  await route();
  assert.equal(await page.evaluate(({ key }) => localStorage.getItem(key), { key: legacyKey }), legacySave, 'Campaign changed the old V2 save');
  assert.deepEqual(errors, [], 'Browser exceptions');
  assert.deepEqual(httpErrors, [], 'HTTP errors');
  await writeFile(join(out, 'result.json'), JSON.stringify({ passed: true, url: page.url(), checkpoints, combat, state: await state(), errors, httpErrors }, null, 2));
  console.log('PASS: source-driven R1 campaign keyboard route, persistence and legacy save isolation.');
} catch (error) {
  await page.screenshot({ path: join(out, 'failure.png') });
  await writeFile(join(out, 'failure.json'), JSON.stringify({ error: error.stack, errors, httpErrors, checkpoints, state: await state().catch(() => null) }, null, 2));
  throw error;
} finally { await browser.close(); }
