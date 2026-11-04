// Real keyboard verification in a new browser context; no writable game API or user save.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(import.meta.url);
const {chromium} = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const out = path.resolve('game/build/qa', process.env.TEST_LABEL ?? 'action36/web');
fs.mkdirSync(out, {recursive:true});
const chrome = process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const browser = await chromium.launch({headless:true, executablePath:chrome, args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport:{width:1280,height:720}, recordVideo:{dir:out,size:{width:1280,height:720}}});
const page = await context.newPage();
page.setDefaultTimeout(180000);
const checks = [], errors = [], states = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => {if(m.type()==='error')errors.push(m.text());});
const state = async () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const check = (label, pass) => {checks.push({label,pass:Boolean(pass)}); console.log(pass?'PASS':'FAIL',label);};
const sleep = ms => page.waitForTimeout(ms);
const hold = async (key, ms) => {await page.keyboard.down(key);await sleep(ms);await page.keyboard.up(key);};
const capture = async label => {const s=await state();states.push({label,...s});await page.screenshot({path:path.join(out,label+'.png')});return s;};
const ready = () => page.waitForFunction(() => typeof window.render_game_to_text==='function' && JSON.parse(window.render_game_to_text()).campaign==='WhalebellyRuins');
const skill = async (label, keys, expected, release=true) => {
  for(const key of keys) await page.keyboard.down(key);
  await sleep(100);
  const s=await state();check(label,s.player.skill_key===expected);
  if(release) for(const key of [...keys].reverse()) await page.keyboard.up(key);
  await sleep(800);return s;
};
let thrown = null;
try {
  await page.goto(process.env.GAME_URL ?? 'http://127.0.0.1:4187/BOB/godot/', {waitUntil:'domcontentloaded'});
  await ready();await page.keyboard.press('Enter');await sleep(700);
  const initial=await capture('01-start');
  check('actual campaign starts in R1-01',initial.room==='R1-01');
  check('Web ambience plays through stream playback',initial.audio.playing&&initial.audio.playback_type===1&&!initial.audio.muted);
  check('default main camera follows at playable scale',initial.camera.following&&initial.camera.zoom>=.95);
  await hold('d',650);const right=await capture('02-right');
  check('D moves physical actor right',right.player.x>initial.player.x+80&&right.player.facing===1);
  await hold('a',350);const left=await capture('03-left');
  check('A moves physical actor left',left.player.x<right.player.x-40&&left.player.facing===-1);
  await page.keyboard.down('Space');await sleep(180);const jump=await capture('04-jump');await page.keyboard.up('Space');
  check('Space produces a physical jump',!jump.player.floor&&jump.player.y<left.player.y-20);
  await sleep(1000);
  await page.keyboard.down('j');await sleep(90);const attack=await state();await page.keyboard.up('j');
  check('J produces basic attack',attack.player.state==='strike_01');await sleep(500);
  await skill('W+J selects upward attack',['w','j'],'upper');
  await page.keyboard.press('F9');await sleep(600);
  await hold('d',120);await sleep(180);
  await page.keyboard.down('j');await sleep(700);await page.keyboard.up('j');await sleep(90);
  check('held J release selects charged slash',(await state()).player.skill_key==='great_slash');
  await capture('05-charge-release');await sleep(600);
  await page.keyboard.down('s');await page.keyboard.down('j');await sleep(700);await page.keyboard.up('j');await sleep(90);
  check('S+charged release selects cyclone',(await state()).player.skill_key==='cyclone');await page.keyboard.up('s');
  await capture('06-cyclone');await sleep(1000);
  await skill('B activates parry',['b'],'parry');
  await skill('T activates scan',['t'],'scan');
  await page.keyboard.down('v');await sleep(720);await page.keyboard.up('v');await sleep(100);
  const dash=await capture('07-long-dash');check('charged V releases long dash',dash.player.skill_key==='crystal_dash');
  const beforeCancel=await state();
  await page.keyboard.press('Space');await sleep(80);
  const afterCancel=await state();
  check('jump cancels long dash and physically leaves the ground',afterCancel.player.skill_key!=='crystal_dash'&&!afterCancel.player.floor&&afterCancel.player.y<beforeCancel.player.y-8);await sleep(900);
  const before=await state();
  await skill('W+U selects upgraded up spell',['w','u'],'abyss_scream');
  check('up spell costs 33 soul',(await state()).soul===before.soul-33);
  await capture('08-up-spell-recovery');
  await skill('U selects upgraded projectile',['u'],'shadow_orb');
  await page.keyboard.down('Space');await sleep(170);await page.keyboard.up('Space');
  await skill('air S+U selects upgraded dive',['s','u'],'dark_dive');
  await capture('09-dive-landing');
  await page.keyboard.press('Escape');await sleep(200);const paused=await state();
  check('Escape pauses',paused.paused);await hold('d',250);
  check('pause holds physics',Math.abs((await state()).player.x-paused.player.x)<1);
  await page.keyboard.press('Escape');await sleep(200);check('Escape resumes',!(await state()).paused);
  await page.keyboard.press('F9');await sleep(600);
  await page.keyboard.down('v');await sleep(700);await page.keyboard.up('v');await sleep(80);
  check('leaving practice restores long-dash lock',(await state()).player.skill_key!=='crystal_dash');
  await capture('10-formal-progress');
  const roomBefore=(await state()).room;
  // F9 rebuilds the actor; move away from a nearby door before approaching it
  // so the authored rearm rule is satisfied even after a long-dash endpoint.
  await hold('a',800);await sleep(150);
  await page.keyboard.down('d');
  for(let attempt=0;attempt<16;attempt++) {
    await sleep(400);
    if((await state()).room!==roomBefore)break;
  }
  await page.keyboard.up('d');await sleep(300);
  check('walking through authored door changes the actual main room',(await state()).room!==roomBefore);
  const next=await capture('11-next-room');
  check('authored room transition retains playing streamed ambience',next.audio.playing&&next.audio.playback_type===1&&!next.audio.muted);
  check('next authored room retains follow camera and playable scale',next.camera.following&&next.camera.zoom>=.95);
  await page.keyboard.press('Tab');await sleep(250);
  check('Tab selects full-room panorama',!(await state()).camera.following);
  await page.keyboard.press('Tab');await sleep(800);
  const restored=await capture('12-follow-restored');
  check('Tab restores follow mode',restored.camera.following&&restored.camera.zoom>=.95);
  const c=restored.camera, halfW=640/c.zoom,halfH=360/c.zoom;
  check('follow view and shake stay within room',c.x+c.offset_x-halfW>=-.1&&c.y+c.offset_y-halfH>=-.1&&c.x+c.offset_x+halfW<=c.room_width+.1&&c.y+c.offset_y+halfH<=c.room_height+.1);
  check('no browser or engine errors',errors.length===0);
} catch(e) {thrown=String(e.stack??e);errors.push(thrown);}
finally {
  const video=page.video();await context.close();
  if(video){const source=await video.path();fs.copyFileSync(source,path.join(out,'main-keyboard.webm'));}
  await browser.close();
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({method:'real Playwright keyboard; read-only snapshot; independent browser storage; explicit F9 practice for extended skills',checks,errors,states},null,2));
}
if(thrown||errors.length||checks.some(c=>!c.pass))process.exitCode=1;
