import {createRequire} from 'node:module';
import fs from 'node:fs';import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const edge=process.env.EDGE||'E33',axis=edge==='E33'?2123:3893,low=edge==='E33'?103.847:190.847,high=edge==='E33'?-681.153:-911.153;
const out=path.resolve('game/build/qa/xumen-transitions',process.env.TEST_LABEL||edge+'-web');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage(),checks=[],errors=[],route=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(id,pass);if(!pass)throw Error(id)}
async function walk(x){const key=(await state()).connected_world.world_x<x?'d':'a';await page.keyboard.down(key);try{for(let i=0;i<300;i++){const s=await state();route.push(s.connected_world);if(Math.abs(s.connected_world.world_x-x)<17)return;await page.waitForTimeout(60)}throw Error('walk timeout '+x)}finally{await page.keyboard.up(key)}}
async function climbOrDescend(up){
 let held=false,until=0,lastDrop=0;const end=Date.now()+60000;
 try{while(Date.now()<end){const s=await state(),w=s.connected_world;route.push(w);
  if(up&&s.player.floor&&w.world_y<=high+21)return;
  // Existing drop immunity can skip the last step at browser frame cadence.
  // Use the existing float key to brake, not injected position/collision.
  if(!up&&!s.player.floor&&w.world_y>=low-100){for(const k of ['d','a','s','Space'])await page.keyboard.up(k);await page.keyboard.down('w');await page.waitForTimeout(180);await page.keyboard.up('w');await page.waitForTimeout(750);const landed=await state();if(landed.player.floor&&Math.abs(landed.connected_world.world_y-low)<24)return;throw Error('lowest platform landing missed: '+landed.connected_world.world_y)}
  const dx=axis-w.world_x;
  await page.keyboard[dx>12?'down':'up']('d');await page.keyboard[dx< -12?'down':'up']('a');
  const now=Date.now();
  if(up){if(held&&now>=until){await page.keyboard.up('Space');held=false} else if(!held&&s.player.floor){await page.keyboard.down('Space');held=true;until=now+430}}
  else{await page.keyboard.down('s');if(now-lastDrop>740){await page.keyboard.press('Space');lastDrop=now}}
  await page.waitForTimeout(65);
 }throw Error('vertical traversal timeout '+up)}finally{for(const k of ['d','a','s','Space'])await page.keyboard.up(k)}
}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:600000});await page.keyboard.press('Enter');await page.waitForTimeout(650);
 check('new shaft assets present',(await state()).connected_world.shafts.edges.includes(edge));
 // Existing preview and practice keys are explicit test fixtures; no injected state.
 await page.keyboard.press('F9');await page.keyboard.press(edge==='E33'?'6':'7');await page.waitForTimeout(600);
 const id=(await state()).connected_world.player_id;
 await walk(axis);await page.screenshot({path:path.join(out,'top.png')});
 await climbOrDescend(false);await page.screenshot({path:path.join(out,'bottom.png')});
 await walk(edge==='E33'?2390:3790);check('descend then enter hub same player',(await state()).room==='R1-02'&&(await state()).connected_world.player_id===id&&Math.abs((await state()).connected_world.world_y-low)<30);
 await walk(axis);await climbOrDescend(true);await walk(edge==='E33'?2440:4100);
 check('climb then enter upper same player',(await state()).room===(edge==='E33'?'R1-06':'R1-07')&&(await state()).connected_world.player_id===id);
 await page.screenshot({path:path.join(out,'upper-return.png')});
 await page.keyboard.press('Escape');await page.waitForTimeout(200);const t=(await state()).connected_world.shafts.time;await page.waitForTimeout(700);
 check('shared shaft clock paused',(await state()).connected_world.shafts.time===t);await page.keyboard.press('Escape');await page.waitForTimeout(500);check('clock resumes',(await state()).connected_world.shafts.time>t);
 if(process.env.MOTION_CHECK!=='0') {const start=(await state()).connected_world.shafts.time;for(let i=0;i<13;i++){await page.waitForTimeout(4000);if(i%3===0)await page.screenshot({path:path.join(out,'motion-'+i+'.png')})}check('52s continuous motion',(await state()).connected_world.shafts.time-start>50)}
 check('no dissolve',!(await state()).continuity.transition_active);check('water stream playing',(await state()).audio.playing);check('no engine browser resource errors',errors.length===0,errors);
}finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({edge,checks,errors,route,scope:'Explicit existing upper-room preview and F9 practice; real keyboard thereafter down/up and adjacent-room movement; not natural unlock acquisition.'},null,2));await context.close();await browser.close()}
