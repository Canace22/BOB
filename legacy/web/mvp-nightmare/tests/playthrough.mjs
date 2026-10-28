import assert from 'node:assert/strict';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Only real keyboard/button input changes gameplay. advanceTime controls time;
// render_game_to_text is read-only. No teleporting or injected game-state writes.
async function loadPlaywright() {
  if (process.env.PLAYWRIGHT_MODULE) return import(process.env.PLAYWRIGHT_MODULE);
  try { return await import('playwright'); }
  catch {
    return import(pathToFileURL(resolve(homedir(), '.codex/skills/develop-web-game/node_modules/playwright/index.mjs')).href);
  }
}

const { chromium } = await loadPlaywright();
const baseURL = process.env.BASE_URL || 'http://127.0.0.1:4174/';
const output = resolve(process.env.TEST_OUTPUT || 'output/playthrough');
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader'] });
const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
const errors = [];
const checks = [];
const oldSave = JSON.stringify({ sentinel: 'original-mvp-must-stay-unchanged', chapter: 7 });
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const advance = ms => page.evaluate(value => window.advanceTime(value), ms);

function check(condition, label) {
  assert.ok(condition, label);
  checks.push(label);
  console.log(`PASS ${label}`);
}
async function ready() {
  await page.waitForFunction(() => !document.querySelector('#start-btn')?.disabled, null, { timeout: 45000 });
  await advance(1);
}
async function burst(keys, ms) {
  for (const key of keys) await page.keyboard.down(key);
  await advance(ms);
  for (const key of [...keys].reverse()) await page.keyboard.up(key);
  return state();
}
const tap = key => burst([key], 20);
async function moveTo(x, modifiers = [], speed = modifiers.includes('KeyC') ? 80 : modifiers.includes('ShiftLeft') ? 265 : 168) {
  for (let attempt = 0; attempt < 120; attempt++) {
    const before = await state();
    assert.equal(before.mode, 'playing', `moving to x=${x}: ${before.message}`);
    const delta = x - before.player.x;
    if (Math.abs(delta) < 1) return before;
    const after = await burst([...modifiers, delta > 0 ? 'KeyD' : 'KeyA'], Math.min(200, Math.abs(delta) / speed * 1000));
    assert.equal(after.mode, 'playing', `died while moving to x=${x}, current x=${after.player.x}`);
    assert.ok(Math.abs(after.player.x - before.player.x) > .01, `blocked at x=${after.player.x}, target=${x}`);
  }
  throw new Error(`Could not reach x=${x}`);
}
async function waitUntil(predicate, maxMs = 15000) {
  for (let elapsed = 0; elapsed < maxMs; elapsed += 100) {
    const current = await state();
    if (predicate(current)) return current;
    await advance(100);
  }
  throw new Error(`Wait timed out: ${JSON.stringify(await state())}`);
}
async function snapshot(name) {
  await page.screenshot({ path: resolve(output, `${name}.png`), fullPage: true });
  const current = await state();
  await writeFile(resolve(output, `${name}.json`), JSON.stringify(current, null, 2));
  return current;
}
async function jump(name) {
  for (const key of ['ShiftLeft', 'KeyD', 'Space']) await page.keyboard.down(key);
  await advance(350);
  const airborne = await snapshot(name);
  check(!airborne.player.grounded && airborne.player.y < 470, `${name}: jump reaches clearance height`);
  await advance(500);
  for (const key of ['Space', 'KeyD', 'ShiftLeft']) await page.keyboard.up(key);
  const landed = await state();
  check(landed.mode === 'playing' && landed.player.grounded, `${name}: landed safely`);
}

try {
  await page.goto(baseURL);
  await ready();
  check(await page.evaluate(() => Boolean(document.querySelector('#game').getContext('webgl2'))), 'the game renders through a real WebGL2 context');
  await page.evaluate(value => localStorage.setItem('whalefall-mvp-v1', value), oldSave);
  await snapshot('00-title');
  await page.click('#start-btn');
  await advance(20);
  check((await state()).room === 0, 'new game starts in the first room');

  await tap('Escape');
  const paused = await state();
  await burst(['KeyD'], 1200);
  const stillPaused = await state();
  check(stillPaused.mode === 'paused' && stillPaused.player.x === paused.player.x && stillPaused.elapsed === paused.elapsed, 'pause freezes movement and gameplay time');
  await page.click('#resume-btn');

  await moveTo(514);
  await burst(['KeyE', 'KeyD'], 360 / 110 * 1000);
  let current = await snapshot('01-weight-puzzle');
  check(current.plateDown && current.gateOpen && Math.abs(current.crate.x - 900) < 2, 'holding E and moving places the crate on the plate and opens the gate');
  await burst(['KeyD', 'Space'], 850);
  current = await moveTo(1080);
  check(current.player.x > current.crate.x + current.crate.w && current.checkpoint.stage === 'gate', 'jumping over the crate reaches and saves the gate checkpoint');

  await page.reload();
  await ready();
  check(await page.locator('#continue-btn').isVisible(), 'saved progress exposes Continue after reload');
  await page.click('#continue-btn');
  await advance(20);
  current = await state();
  check(current.room === 0 && current.checkpoint.stage === 'gate' && current.gateOpen && current.player.x === 1020, 'Continue restores the solved gate checkpoint');
  await moveTo(1404);
  current = await burst(['KeyD'], 500);
  check(Math.abs(current.player.x - 1404) < 1 && !current.player.crouching, 'standing player is blocked by the low passage');
  await moveTo(1540, ['KeyC']);
  current = await snapshot('02-crawl');
  check(current.player.crouching && current.player.h === 34, 'crouching fits inside the low passage');
  await moveTo(1720, ['KeyC']);
  await advance(20);
  check(!(await state()).player.crouching, 'player can stand after leaving the low passage');
  await moveTo(1867);
  await burst(['KeyW'], 450);
  await tap('KeyE');
  check((await state()).memories.includes('memory-0'), 'depth movement reaches the first optional memory');
  await burst(['KeyS'], 450);
  await moveTo(2167);
  await tap('KeyE');
  check((await state()).room === 1, 'the first exit enters the stealth room');

  await moveTo(760, ['ShiftLeft']);
  current = await burst(['KeyC'], 100);
  check(!current.player.hidden && Math.abs(current.player.z) < .01, 'crouching in the front lane alone does not hide the player');
  await snapshot('03a-front-lane');
  current = await burst(['KeyW'], 450);
  check(!current.player.hidden && current.player.z < -.6, 'walking into the back lane without crouching does not hide the player');
  await snapshot('03b-back-lane');
  await page.keyboard.down('KeyC');
  await advance(20);
  check((await state()).player.hidden, 'back lane plus crouching inside a niche hides the player');
  await waitUntil(value => value.watcher.phase === 'watch');
  await advance(1700);
  current = await snapshot('03-depth-stealth');
  check(current.mode === 'playing' && current.player.hidden && current.alert === 0, 'the niche protects the player throughout an active scan');
  await waitUntil(value => value.watcher.phase === 'sleep');
  await page.keyboard.up('KeyC');
  await moveTo(1267, ['ShiftLeft']);
  await tap('KeyE');
  current = await state();
  check(current.fuseTaken && current.checkpoint.stage === 'fuse', 'collecting the fuse creates a checkpoint');
  await waitUntil(value => value.mode === 'dead');
  await snapshot('04-detected');
  check((await state()).deaths === 1, 'standing exposed during a scan triggers detection and a retry screen');
  await tap('Enter');
  current = await state();
  check(current.mode === 'playing' && current.player.x === 1260 && current.fuseTaken && current.checkpoint.stage === 'fuse', 'Enter retries from the fuse checkpoint with the item retained');
  await moveTo(2067, ['ShiftLeft']);
  await tap('KeyE');
  await burst(['KeyS'], 450);
  await moveTo(2307, ['ShiftLeft']);
  await tap('KeyE');
  current = await snapshot('05-powered-door');
  check(current.powerOn && current.gateOpen, 'inserting the recovered fuse powers the door');
  await moveTo(2537, ['ShiftLeft']);
  await tap('KeyE');
  check((await state()).room === 2, 'the powered exit enters the final room');

  await moveTo(647);
  await tap('KeyE');
  check(JSON.stringify((await state()).sequence) === '[2]', 'the second valve starts the sequence');
  await moveTo(817);
  await tap('KeyE');
  current = await snapshot('06-wrong-order');
  check(current.sequence.length === 0 && !current.pumpOn, 'a wrong next valve resets the partial sequence');
  await moveTo(647);
  await tap('KeyE');
  await moveTo(477);
  await tap('KeyE');
  await moveTo(817);
  await tap('KeyE');
  current = await snapshot('07-heart-awake');
  check(JSON.stringify(current.sequence) === '[2,1,3]' && current.pumpOn && current.checkpoint.stage === 'pump', 'the 2-1-3 order starts the chase and saves the pump checkpoint');

  await moveTo(1037, ['ShiftLeft']);
  await burst(['KeyW'], 450);
  await tap('KeyE');
  check((await state()).memories.length === 3, 'all three optional memories can be collected through depth movement');
  await tap('KeyR');
  current = await state();
  check(current.pumpOn && current.player.x === 920 && current.memories.length === 3, 'R restores the active chase checkpoint and preserves collected memories');
  await advance(6000);
  current = await snapshot('07b-caught-by-tide');
  check(current.mode === 'dead' && current.deaths === 2, 'standing still during the chase lets the tide catch the player');
  await tap('Enter');
  current = await state();
  check(current.mode === 'playing' && current.pumpOn && current.player.x === 920 && current.memories.length === 3, 'Enter restores the chase checkpoint after the tide catches the player');
  await moveTo(1220, ['ShiftLeft']);
  await jump('08-first-gap');
  await moveTo(1610, ['ShiftLeft']);
  await jump('09-first-obstacle');
  await moveTo(1880, ['ShiftLeft']);
  await jump('10-second-gap');
  await moveTo(2330, ['ShiftLeft']);
  await jump('11-second-obstacle');
  await moveTo(2947, ['ShiftLeft']);
  await tap('KeyE');
  current = await snapshot('12-ending');
  check(current.mode === 'ending' && current.deaths === 2, 'sprinting and four jumps reach the ending without additional chase or fall deaths');
  check(await page.evaluate(value => localStorage.getItem('whalefall-mvp-v1') === value, oldSave), 'the original MVP storage key remains byte-for-byte unchanged');

  await page.setViewportSize({ width: 1024, height: 768 });
  await advance(20);
  await snapshot('13-small-window');
  const layout = await page.evaluate(() => ({ width: innerWidth, body: document.body.scrollWidth, canvas: document.querySelector('#game').getBoundingClientRect().toJSON() }));
  check(layout.body <= layout.width && layout.canvas.width > 0, '1024px window keeps the canvas visible without horizontal overflow');
  check(errors.length === 0, `browser has no page or console errors (${errors.length})`);
  await writeFile(resolve(output, 'report.json'), JSON.stringify({ passed: true, checks, errors, finalState: current }, null, 2));
  await Promise.all(['failure.png', 'failure.json'].map(name => rm(resolve(output, name), { force: true })));
  console.log(`Completed ${checks.length} checks. Evidence: ${output}`);
} catch (error) {
  await snapshot('failure').catch(() => {});
  await writeFile(resolve(output, 'report.json'), JSON.stringify({ passed: false, checks, errors, failure: error.stack }, null, 2));
  throw error;
} finally {
  await browser.close();
}
