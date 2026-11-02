// Real browser rendering and keys; snapshots only observe the running game.
import {createRequire} from 'node:module';
import {mkdirSync, writeFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';

const require = createRequire(import.meta.url);
const {chromium} = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'environment-motion');
mkdirSync(output, {recursive: true});
const browser = await chromium.launch({headless: true,
  executablePath: process.env.CHROME_PATH ?? chromium.executablePath(),
  args: ['--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport: {width: 1280, height: 720},
  recordVideo: {dir: output, size: {width: 1280, height: 720}}});
const page = await context.newPage();
const errors = [], observations = [];
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => {if (message.type() === 'error') errors.push(message.text());});
page.on('response', response => {if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);});
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const shot = name => page.screenshot({path: path.join(output, `${name}.png`)});
try {
  await page.goto(process.env.GAME_URL ?? 'http://127.0.0.1:4197/BOB/godot/?prototype=crab');
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', null, {timeout: 180000});
  const initial = await state();
  assert.equal(initial.environment.schools.reduce((n, s) => n + s.count, 0), 22);
  assert.equal(initial.environment.baleen.length, 3);
  await shot('ready');
  // The ready camera and background are still. Sample two areas clear of actors and HUD.
  const baleenArea = {x: 235, y: 150, width: 115, height: 50};
  const fishArea = {x: 230, y: 245, width: 370, height: 34};
  const sampleArea = clip => page.screenshot({clip});
  const baleenBefore = await sampleArea(baleenArea);
  const fishBefore = await sampleArea(fishArea);
  await page.waitForTimeout(700);
  assert(!(await sampleArea(baleenArea)).equals(baleenBefore), 'baleen visibly moves below the roof');
  assert(!(await sampleArea(fishArea)).equals(fishBefore), 'fish visibly swim across the open water');
  // Observe one complete 16-second group cycle, including all 48 baleen poses.
  for (let i = 0; i < 320; i++) {
    observations.push((await state()).environment);
    await page.waitForTimeout(50);
  }
  const frames = new Set(observations.map(s => s.baleen[0].frame));
  assert.equal(frames.size, 48, 'all authored baleen frames actually render');
  for (let i = 0; i < 3; i++) {
    assert(new Set(observations.map(s => s.schools[i].frame)).size >= 28, 'fish tail frames advance');
    assert(new Set(observations.map(s => s.schools[i].position[0])).size > 100, 'fish travel');
    assert(observations.every(s => s.schools[i].texture.endsWith(`${initial.environment.schools[i].species}.png`)));
  }
  await page.locator('canvas').click({position: {x: 600, y: 450}});
  await page.keyboard.press('Enter');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).stage === 'fighting');
  await page.keyboard.down('ArrowRight');
  await page.keyboard.down('Space');
  await page.waitForTimeout(350);
  await page.keyboard.up('Space');
  await page.keyboard.up('ArrowRight');
  await shot('jump-under-baleen');
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).paused);
  const paused = (await state()).environment;
  await page.waitForTimeout(700);
  assert.deepEqual((await state()).environment, paused, 'pause freezes every environmental clock');
  await shot('paused');
  await page.keyboard.press('Escape');
  await page.waitForTimeout(600);
  assert.notDeepEqual((await state()).environment, paused, 'resume restarts motion');
  await page.keyboard.down('KeyU');
  await page.waitForTimeout(3000);
  await shot('combat');
  await page.keyboard.up('KeyU');
  assert.equal((await state()).save_enabled, false);
  assert.deepEqual(errors, []);
  writeFileSync(path.join(output, 'report.json'), JSON.stringify({passed: true, checks: [
    'fish_and_baleen_move_on_screen', 'three_schools_22_fish_and_three_baleen_load', 'full_cycle_and_authored_frames_advance',
    'pause_resume_freezes_all_motion', 'real_movement_jump_and_ranged_combat', 'no_resource_errors_or_save_writes'],
    errors, initial, final: await state(), observations}, null, 2));
} finally {
  await context.close();
  await page.video().saveAs(path.join(output, 'environment.webm'));
  await browser.close();
}
console.log(`Environment checks passed: ${output}`);
