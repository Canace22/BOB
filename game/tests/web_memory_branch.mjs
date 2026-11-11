import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(import.meta.url);
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const out = path.resolve('game/build/qa/memory-branch', process.env.TEST_LABEL || 'web-local');
fs.mkdirSync(out, {recursive:true});
const browser = await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport:{width:1440,height:900}});
const page = await context.newPage();
const checks = [], errors = [];
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => {if(message.type()==='error') errors.push(message.text());});
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const pause = ms => page.waitForTimeout(ms);
function check(id, pass, detail) {
  checks.push({id,pass,detail}); console.log(JSON.stringify(checks.at(-1)));
  if(!pass) throw Error(id);
}
async function until(predicate, timeout=15000) {
  const deadline=Date.now()+timeout;
  while(Date.now()<deadline) {const s=await state(); if(predicate(s)) return s; await pause(65);}
  throw Error('Timed out: '+JSON.stringify(await state()));
}
async function walk(x, room, expected=room) {
  let s=await state(); const direction=s.player.x<x?'d':'a';
  await page.keyboard.down(direction);
  try {
    return await until(s => s.room!==room ? s.room===expected : Math.abs(s.player.x-x)<22, 18000);
  } finally {await page.keyboard.up(direction);}
}
async function memoryGaps(x, expected='R1-07') {
  const right=x>500, direction=right?'d':'a';
  let jumping=false, releaseAt=0, lastJump=0;
  await page.keyboard.down(direction);
  try {
    for(let step=0;step<240;step++) {
      const s=await state(), p=s.player, now=Date.now();
      if(s.room!=='R1-07') {check('gap_exit_destination',s.room===expected,s.room);return;}
      if(Math.abs(p.x-x)<22) return;
      if(jumping && now>releaseAt) {await page.keyboard.up('Space');jumping=false;}
      const edge=right ? (p.x>320&&p.x<410)||(p.x>790&&p.x<880) : (p.x>1020&&p.x<1110)||(p.x>555&&p.x<645);
      if(!jumping && p.floor && edge && now-lastJump>500) {
        await page.keyboard.down('Space'); jumping=true;releaseAt=now+460;lastJump=now;
      }
      await pause(65);
    }
    throw Error('Gap route timeout '+JSON.stringify(await state()));
  } finally {await page.keyboard.up(direction);await page.keyboard.up('Space');}
}
try {
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:4187/BOB/godot/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
  await page.keyboard.press('Enter');await pause(600);
  check('fresh_normal_progress',(await state()).abilities.anchor && !(await state()).abilities.float && !(await state()).practice);
  await walk(1660,'R1-01','R1-02');
  await until(s=>s.room==='R1-02'&&!s.continuity.travelling);
  // Walk past the existing crab with ordinary jumping, no injected damage or position.
  await walk(425,'R1-02');
  await page.keyboard.down('d');await page.keyboard.down('Space');await pause(520);
  await page.keyboard.up('Space');await page.keyboard.press('Space',{delay:280});
  await until(s=>s.player.x>860);await page.keyboard.up('d');
  await walk(1000,'R1-02');await pause(450);
  await page.screenshot({path:path.join(out,'ring-approach.png')});
  for(let i=0;i<3;i++) {
    await page.keyboard.press('g');
    await until(s=>s.player.grappling,2500);
    await until(s=>s.player.hanging,3000);
    await pause(350);
    check('ring_'+(i+1),true,(await state()).player);
  }
  await page.keyboard.down('Space');await page.keyboard.down('d');await pause(450);
  await page.keyboard.up('Space');
  await until(s=>s.player.x>1560&&s.player.floor,12000);await page.keyboard.up('d');
  await page.keyboard.press('e');
  await until(s=>s.room==='R1-07'&&!s.continuity.travelling,12000);
  let s=await state();
  check('real_upper_entry_no_float',s.ui.visited['R1-07']&&!s.abilities.float&&!s.practice,s.player);
  await page.screenshot({path:path.join(out,'memory-entry.png')});
  await memoryGaps(1300);await pause(700);
  await page.keyboard.press('e');
  s=await until(s=>s.collected['R1-07']);
  check('reward_grants_float_and_supplies',s.abilities.float&&s.hp===5&&s.soul===99,s.abilities);
  const rewards=s.events.filter(e=>e.event==='reward').length;
  await pause(800);await page.keyboard.press('e');await pause(800);
  check('reward_not_repeated',(await state()).events.filter(e=>e.event==='reward').length===rewards);
  await page.keyboard.press('c');await pause(300);
  await page.screenshot({path:path.join(out,'memory-map.png')});
  check('map_memory_discovered',(await state()).ui.map_nodes.some(n=>n.id==='R1-07'&&n.visited));
  await page.keyboard.press('Escape');await pause(300);
  await page.keyboard.press('F5');await pause(900);
  await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
  await page.keyboard.press('Enter');await pause(600);s=await state();
  check('reload_keeps_reward_and_float',s.room==='R1-07'&&s.collected['R1-07']&&s.abilities.float);
  await page.keyboard.down('Space');await pause(200);await page.keyboard.up('Space');
  await page.keyboard.down('w');await pause(600);s=await state();await page.keyboard.up('w');
  check('earned_float_actual_input',!s.player.floor&&s.player.vy<0,s.player);
  await pause(1400);
  await memoryGaps(95);
  await pause(300);await page.keyboard.press('e');
  await until(s=>s.room==='R1-02'&&!s.continuity.travelling);s=await state();
  check('return_on_upper_platform',s.player.y<350,s.player);
  await page.screenshot({path:path.join(out,'upper-return.png')});
  await walk(1230,'R1-02');await pause(1800);s=await state();
  check('safe_drop_to_main_route',s.player.floor&&s.player.y>600&&s.hp>0,s.player);
  check('no_browser_errors',errors.length===0,errors);
} finally {
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,passed:checks.length===13&&checks.every(c=>c.pass)&&!errors.length,scope:'Fresh isolated browser, real keys from title to memory reward and back; no preview, F9, position or save injection.'},null,2));
  await browser.close();
}
