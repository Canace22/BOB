// Real browser keyboard smoke test for the recovered campaign; isolated browser storage.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const require = createRequire(import.meta.url);
const {chromium} = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const out = path.resolve('game/build/qa/whalebelly-recovery/web');
fs.mkdirSync(out, {recursive:true});
const bundled = chromium.executablePath();
const browser = await chromium.launch({headless:true, executablePath:fs.existsSync(bundled) ? bundled : 'C:/Program Files/Google/Chrome/Application/chrome.exe', args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport:{width:1280,height:720}});
const page = await context.newPage();
page.setDefaultTimeout(180000);
const errors = [];
const checks = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => {if(m.type()==='error')errors.push(m.text());});
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const ready = () => page.waitForFunction(() => typeof window.render_game_to_text === 'function' && JSON.parse(window.render_game_to_text()).campaign === 'WhalebellyRuins');
const check = (label, ok) => {checks.push({label,pass:ok});assert.ok(ok,label);};
try {
  await page.goto(process.env.GAME_URL ?? 'http://127.0.0.1:4187/BOB/godot/', {waitUntil:'domcontentloaded'});
  await ready();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);
  check('restored seven-room campaign is running', (await state()).room === 'R1-01');
  await page.screenshot({path:path.join(out,'start.png')});
  const start = await state();
  await page.keyboard.down('d'); await page.waitForTimeout(950); await page.keyboard.up('d');
  const walked = await state();
  check('real keyboard moves the original animated character', walked.player.x > start.player.x + 100);
  await page.keyboard.down('Space'); await page.waitForTimeout(220);
  const jumped = await state(); await page.keyboard.up('Space');
  check('real keyboard jump leaves the ground', !jumped.player.floor && jumped.player.y < walked.player.y - 25);
  await page.waitForTimeout(1100);
  await page.keyboard.down('j'); await page.waitForTimeout(100);
  const attack = await state(); await page.keyboard.up('j');
  check('original short attack responds to J', attack.player.state.includes('strike'));
  await page.waitForTimeout(650);
  const energy = (await state()).soul;
  await page.keyboard.press('u'); await page.waitForTimeout(650);
  check('restored orb consumes the original soul resource', (await state()).soul < energy);
  await page.keyboard.press('Escape'); await page.waitForTimeout(200);
  const paused = await state();
  check('Escape pauses', paused.paused);
  await page.keyboard.down('d'); await page.waitForTimeout(350); await page.keyboard.up('d');
  check('pause holds the player', Math.abs((await state()).player.x - paused.player.x) < 1);
  await page.keyboard.press('Escape'); await page.waitForTimeout(200);
  check('Escape resumes', !(await state()).paused);
  // Walk back to the existing first camp; no teleportation or writable QA interface.
  for (let i=0;i<35;i++) {
    const current = await state();
    if (current.player.x < 180) break;
    await page.keyboard.down('a'); await page.waitForTimeout(120); await page.keyboard.up('a');
  }
  await page.waitForTimeout(200); await page.keyboard.press('e'); await page.waitForTimeout(500);
  const saved = await state();
  check('physical camp writes a checkpoint', saved.checkpoint.pos.length === 2);
  await page.screenshot({path:path.join(out,'camp.png')});
  await page.reload({waitUntil:'domcontentloaded'}); await ready(); await page.waitForTimeout(700);
  const reloaded = await state();
  check('independent Web reload restores V6 checkpoint', reloaded.room === 'R1-01' && Math.abs(reloaded.player.x - saved.checkpoint.pos[0]) < 10);
  check('no browser or engine errors', errors.length === 0);
  console.log(JSON.stringify({passed:true,checks,errors}));
} finally {
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors},null,2));
  await browser.close();
}
