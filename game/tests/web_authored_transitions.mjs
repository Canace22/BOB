import {createRequire} from 'node:module';
import fs from 'node:fs';import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const out=path.resolve('game/build/qa/xumen-transitions',process.env.TEST_LABEL||'web-local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage();const errors=[],checks=[],route=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(id,pass);if(!pass)throw Error(id)}
async function walk(x){const key=(await state()).connected_world.world_x<x?'d':'a';await page.keyboard.down(key);try{for(let i=0;i<500;i++){const s=await state();route.push({x:s.connected_world.world_x,room:s.room,id:s.connected_world.player_id});if(Math.abs(s.connected_world.world_x-x)<25)return s;if(i%18===0)await page.keyboard.press('Space');await page.waitForTimeout(60)}throw Error('walk timeout '+x)}finally{await page.keyboard.up(key)}}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:600000});
 await page.keyboard.press('Enter');await page.waitForTimeout(650);
 check('new authored layers present',(await state()).connected_world.authored.edges.includes('E02'));
 // Explicit room-start fixture through the existing preview key; all subsequent crossing uses keyboard.
 await page.keyboard.press('2');await page.waitForTimeout(500);await walk(4090);
 await page.screenshot({path:path.join(out,'E02-center.png')});
 const before=await state(),id=before.connected_world.player_id;
 await walk(4610);check('E02 forward physical crossing same player',(await state()).room==='R1-03'&&(await state()).connected_world.player_id===id);
 await page.screenshot({path:path.join(out,'E02-tongue.png')});
 await walk(3610);check('E02 reverse physical crossing same player',(await state()).room==='R1-02'&&(await state()).connected_world.player_id===id);
 await walk(4100);const t0=(await state()).connected_world.authored.time;
 await page.keyboard.press('Escape');await page.waitForTimeout(200);const held=(await state()).connected_world.authored.time;
 await page.waitForTimeout(600);check('authored environment clock paused',(await state()).connected_world.authored.time===held);
 await page.keyboard.press('Escape');await page.waitForTimeout(500);check('authored environment resumed',(await state()).connected_world.authored.time>held);
 if(process.env.MOTION_CHECK!=='0'){
  for(let i=0;i<7;i++){await page.screenshot({path:path.join(out,'E02-motion-'+i+'.png')});await page.waitForTimeout(4000)}
  const s=await state();check('28s continuous playback',s.connected_world.authored.time-t0>27,s.connected_world.authored);
  check('bounded E02 populations',s.connected_world.authored.fish>=12&&s.connected_world.authored.bubbles>=8);
 }
 check('no screenshot dissolve',!(await state()).continuity.transition_active);
 check('chapter water stream still playing',(await state()).audio.playing);
 check('no resource engine or browser errors',errors.length===0,errors);
}finally{
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,route,scope:'Room2 start is explicit existing preview fixture; subsequent E02 forward/reverse are real keyboard input; isolated storage; no injected gameplay state.'},null,2));
 await context.close();await browser.close();
}
