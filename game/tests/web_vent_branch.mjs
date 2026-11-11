import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(import.meta.url);
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const out = path.resolve(process.env.QA_OUTPUT || 'game/build/qa/vent-branch', process.env.TEST_LABEL || 'web-local');
fs.mkdirSync(out, {recursive:true});
const browser = await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport:{width:1440,height:900}});
const page = await context.newPage();
const checks = [], errors = [];
let routeFinished = false;
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
async function climb(x,y,ground) {
  let held='',jumpUntil=0,lastJump=0;
  try {
    for(let step=0;step<320;step++) {
      const s=await state(),p=s.player,now=Date.now(),dx=x-p.x,dy=y-p.y;
      if(Math.abs(dx)<22&&Math.abs(dy)<36&&(!ground||p.floor)) {check(`step_${s.room}_${x}_${y}`,true,p);return;}
      const direction=Math.abs(dx)>9?(dx>0?'d':'a'):'';
      if(direction!==held) {if(held)await page.keyboard.up(held);if(direction)await page.keyboard.down(direction);held=direction;}
      if(jumpUntil&&now>=jumpUntil) {await page.keyboard.up('Space');jumpUntil=0;}
      if(p.floor&&dy < -40&&now-lastJump>650&&!jumpUntil) {await page.keyboard.down('Space');jumpUntil=now+580;lastJump=now;}
      if(!p.floor&&dy < -22) await page.keyboard.down('w');else await page.keyboard.up('w');
      await pause(65);
    }
    throw Error(`Climb ${x},${y}: `+JSON.stringify(await state()));
  } finally {if(held)await page.keyboard.up(held);await page.keyboard.up('Space');await page.keyboard.up('w');}
}
try {
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:4187/BOB/godot/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
  await page.keyboard.press('Enter');await pause(600);
  check('fresh_normal_progress',(await state()).abilities.anchor && !(await state()).abilities.float && !(await state()).practice);
  await walk(1660,'R1-01','R1-02');
  await until(s=>s.room==='R1-02');
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
  await page.keyboard.down('Space');await page.keyboard.down('d');
  await until(s=>s.room==='R1-07'||(s.player.floor&&s.player.y<320&&s.player.x>1450),10000);
  await page.keyboard.up('Space');
  await until(s=>s.room==='R1-07'||(s.room==='R1-02'&&s.player.x>1585),12000);await page.keyboard.up('d');
  if((await state()).room==='R1-02') await page.keyboard.press('e');
  await until(s=>s.room==='R1-07');await pause(900);
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
  if(process.env.CHECK_GUIDANCE) {
    s=await state();
    check('reward_map_points_to_return',s.ui.guidance.includes('左门返回须筛')&&s.ui.map_nodes.some(n=>n.id==='R1-02'&&n.next));
    check('memory_marked_optional',s.ui.map_nodes.some(n=>n.id==='R1-07'&&n.route_kind==='可选支路'));
    check('unknown_boss_stays_hidden',!s.ui.map_nodes.some(n=>n.id==='R1-04'));
    await page.setViewportSize({width:1280,height:720});await pause(500);
    await page.screenshot({path:path.join(out,'memory-map-1280.png')});
    await page.setViewportSize({width:1440,height:900});await pause(300);
  }
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
  await memoryGaps(95,'R1-02');
  if((await state()).room==='R1-07') await page.keyboard.press('e');
  await until(s=>s.room==='R1-02');await pause(900);s=await state();
  check('return_on_upper_platform',s.player.y<350,s.player);
  await page.screenshot({path:path.join(out,'upper-return.png')});
  await walk(1230,'R1-02');await pause(1800);s=await state();
  check('safe_drop_to_main_route',s.player.floor&&s.player.y>600&&s.hp>0,s.player);
  await walk(850,'R1-02');await pause(250);
  await page.keyboard.down('a');await page.keyboard.down('Space');await pause(450);
  await page.keyboard.up('Space');await page.keyboard.down('w');
  await until(s=>s.player.x<350,5000);
  await page.keyboard.up('a');await page.keyboard.up('w');await pause(900);
  check('return_crosses_crab_alive',(await state()).hp>0);
  await walk(80,'R1-02');await until(s=>s.player.floor&&s.player.y>650);
  await walk(240,'R1-02');await pause(250);
  for (const [x,y,ground] of [[240,440,false],[240,495,true],[240,280,false],[240,340,true],[240,130,false],[310,197,true],[170,190,true]]) {
    await climb(x,y,ground);
    if(x===240&&y===495) await page.screenshot({path:path.join(out,"float-platform.png")});
  }
  await page.screenshot({path:path.join(out,'vent-door.png')});
  await page.keyboard.press('e');await until(s=>s.room==='R1-06');await pause(900);
  check('earned_float_opens_vent',!(await state()).practice && (await state()).ui.visited['R1-06']);
  for (const [x,y,ground] of [[350,560,false],[490,643,true],[550,420,false],[760,482,true],[850,270,false],[1173,332,true]]) await climb(x,y,ground);
  await page.keyboard.press('e');await until(s=>s.collected['R1-06']);
  check('vent_reward_collected',true);
  await page.screenshot({path:path.join(out,'vent-reward.png')});
  await walk(1380,'R1-06');await pause(350);await page.keyboard.press('e');await pause(900);
  check('far_latch_preserved',(await state()).room==='R1-06');
  for (const [x,y] of [[850,482],[550,643],[315,792],[100,795]]) await climb(x,y,true);
  await page.keyboard.press('e');await until(s=>s.room==='R1-02');await pause(900);
  check('returned_to_upper_sieve',(await state()).player.y<250);
  await climb(80,718,true);
  check('safe_main_return',(await state()).hp>0);
  await page.keyboard.press('F5');await pause(1000);
  await page.reload({waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
  await page.keyboard.press('Enter');await pause(900);
  s=await state();check('reload_keeps_both_rewards',s.collected['R1-06']&&s.collected['R1-07']&&s.abilities.float&&s.room==='R1-02');
  await page.keyboard.press('c');await pause(350);
  await page.screenshot({path:path.join(out,'vent-map.png')});
  check('vent_map_visited',(await state()).ui.map_nodes.some(n=>n.id==='R1-06'&&n.visited));
  check('no_browser_errors',errors.length===0,errors);
  routeFinished = true;
} catch(error) {
  await page.screenshot({path:path.join(out,"failure.png")}).catch(()=>{});
  errors.push(String(error.stack || error));
  throw error;
} finally {
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,passed:routeFinished&&checks.every(c=>c.pass)&&!errors.length,scope:'Fresh isolated browser: title, memory reward, earned float, upper vent reward and return, reload. No preview, F9, position or save injection.'},null,2));
  await browser.close();
}
