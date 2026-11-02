// Targeted idle/feedback regression. Real keys/UI, read-only game snapshots, isolated saves.
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, renameSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'idle-feedback-local');
mkdirSync(output, { recursive: true });
const candidates = [chromium.executablePath(), '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', 'C:/Program Files/Google/Chrome/Application/chrome.exe'];
const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH ?? candidates.find(existsSync), headless: process.env.HEADED !== '1', args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, recordVideo: { dir: output, size: { width: 1280, height: 720 } } });
const page = await context.newPage(), video = page.video();
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4190/BOB/godot/?prototype=crab';
const errors = [], observations = [], checks = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
page.on('response', r => { if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`); });
page.on('requestfailed', r => errors.push(`${r.failure()?.errorText} ${r.url()}`));
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const capture = name => page.screenshot({ path: path.join(output, `${name}.png`) });
const wait = (fn, arg = null, timeout = 10000) => page.waitForFunction(fn, arg, { polling: 'raf', timeout });
function observe(s, section) {
  assert.equal(s.save_enabled, false);
  assert.deepEqual(s.flags, []);
  const a = s.player.animation;
  observations.push({ section, wallTime: Date.now(), gameTime: s.time, stage: s.stage, hp: s.hp,
    mode: s.player.mode, elapsed: s.player.elapsed, dead: s.player.dead,
    direction: a.direction, clip: a.clip, frame: a.frame, opacity: a.opacity,
    bossClip: s.boss.animation, bossFrame: s.boss.frame, bossOpacity: s.boss.opacity });
  return s;
}
async function sample(section, milliseconds, verify) {
  const began = Date.now();
  while (Date.now() - began < milliseconds) {
    const s = observe(await state(), section);
    verify(s);
    await page.waitForTimeout(40);
  }
}
async function ready(direction) {
  await sample(`ready-${direction}`, 5100, s => {
    assert.equal(s.stage, 'ready');
    assert.equal(s.player.animation.direction, direction);
    assert.equal(s.player.animation.opacity, 1, 'spawn protection must not flash in ready');
    assert.equal(s.boss.animation, '01_idle');
    assert.equal(s.boss.frame, 0, 'idle must hold the accepted boss pose');
    assert.equal(s.boss.opacity, 1);
  });
  await capture(`${direction}-ready`);
  checks.push(`${direction}:ready-5s-opacity1-boss-frame0`);
}

try {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await wait(() => typeof window.render_game_to_text === 'function', null, 120000);
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'ready');
  await page.locator('canvas').click({ position: { x: 600, y: 450 } });
  await ready('right');
  await page.keyboard.press('Enter');
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'fighting');
  await sample('spawn-protection', 400, s => assert.equal(s.player.animation.opacity, 1));
  await page.keyboard.press('Escape');
  await wait(() => JSON.parse(window.render_game_to_text()).paused);
  const paused = await state();
  await sample('paused', 1100, s => {
    assert.deepEqual(s.player.animation, paused.player.animation);
    assert.equal(s.boss.frame, paused.boss.frame);
    assert.equal(s.boss.opacity, paused.boss.opacity);
  });
  await capture('paused');
  await page.keyboard.press('Escape');
  await wait(() => !JSON.parse(window.render_game_to_text()).paused);
  checks.push('spawn-protection-opaque-and-pause-frozen');
  await page.keyboard.down('a');
  await wait(() => JSON.parse(window.render_game_to_text()).player.animation.direction === 'left');
  await page.keyboard.up('a');
  let sawHurtFlash = false, sawRecovered = false, sawBossAction = false;
  const began = Date.now();
  while (Date.now() - began < 60000) {
    const s = observe(await state(), 'hurt-through-defeat');
    sawBossAction ||= !['01_idle', '10_walk'].includes(s.boss.animation);
    if (s.player.animation.opacity < 1) {
      assert.equal(s.player.mode, 'hurt', 'only a real hurt action flashes');
      assert.equal(s.player.dead, false);
      sawHurtFlash = true;
    } else if (sawHurtFlash && s.player.mode === 'idle' && s.hp > 0) sawRecovered = true;
    if (s.stage === 'lost') break;
    await page.waitForTimeout(20);
  }
  assert(sawHurtFlash && sawRecovered && sawBossAction, 'damage feedback recovers and boss combat still animates');
  assert.equal((await state()).stage, 'lost', 'actual boss damage reaches defeat');
  await sample('defeat', 600, s => {
    assert.equal(s.player.dead, true);
    assert.equal(s.player.animation.opacity, 1, 'dead player stays visible');
  });
  await capture('defeat');
  checks.push('real-hurt-brief-recovered-and-death-opaque');
  // Normal menu toggle calls prepare while retaining the player's left facing.
  await page.mouse.click(1100, 90);
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'ready');
  await ready('left');
  await page.keyboard.press('Enter');
  await wait(() => JSON.parse(window.render_game_to_text()).stage === 'fighting');
  await sample('retry-protection', 650, s => {
    assert.equal(s.player.dead, false);
    assert.equal(s.player.animation.opacity, 1);
  });
  checks.push('retry-protection-opaque');
  assert.deepEqual(errors, []);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: true, url, checks, observations, errors, video: 'route.webm' }, null, 2));
  console.log(`PASS idle feedback; ${output}`);
} catch (error) {
  await page.keyboard.up('a').catch(() => {});
  await capture('failure').catch(() => {});
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({ passed: false, url, checks, observations, errors, current: await state().catch(() => null), error: error.stack }, null, 2));
  throw error;
} finally {
  await context.close();
  renameSync(await video.path(), path.join(output, 'route.webm'));
  await browser.close();
}
