import {createRequire} from 'node:module';
import fs from 'node:fs';import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const out=path.resolve('game/build/qa/xumen-transitions',process.env.TEST_LABEL||'web-local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage();const errors=[],checks=[],route=[];
const edge=process.env.EDGE||'E02',shift={E02:0,E03:2184,E04:4287}[edge],source={E02:2,E03:3,E04:4}[edge];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(id,pass);if(!pass)throw Error(id)}
async function walk(x){const key=(await state()).connected_world.world_x<x?'d':'a';await page.keyboard.down(key);try{for(let i=0;i<500;i++){const s=await state();route.push({x:s.connected_world.world_x,room:s.room,id:s.connected_world.player_id});if(Math.abs(s.connected_world.world_x-x)<25||(key==='d'&&s.connected_world.world_x>=x)||(key==='a'&&s.connected_world.world_x<=x))return s;if(i%18===0)await page.keyboard.press('Space');await page.waitForTimeout(60)}throw Error('walk timeout '+x)}finally{await page.keyboard.up(key)}}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:600000});
 await page.keyboard.press('Enter');await page.waitForTimeout(650);
 check('unified chapter layers present',(await state()).connected_world.unified.meshes===91);
 // Explicit room-start fixture through the existing preview key; all subsequent crossing uses keyboard.
 if(edge==='E04'){
  // Actual pre-existing keyboard counterplay; no defeated flag injection.
  await page.keyboard.press('4');await page.waitForTimeout(500);
  let jumpUntil=0,lastHit=0,lastOrb=0;const end=Date.now()+150000;
  while(Date.now()<end){
   const s=await state(),e=s.enemies.find(e=>e.boss);if(!e.alive)break;
   if(s.hp<=0)throw Error('E04 keyboard fight died');
   const b=e.combat,now=Date.now(),gap=Math.abs(e.x-s.player.x),right=e.x>s.player.x;
   const retreat=['slam','charge'].includes(b.kind)&&['tell','active'].includes(b.state);
   let motion=0;if(retreat&&gap<(b.kind==='charge'?440:345)&&s.player.x>292)motion=right?-1:1;
   else if(!retreat&&gap>210)motion=right?1:-1;else if(s.player.facing!==(right?1:-1))motion=right?1:-1;
   await page.keyboard[motion>0?'down':'up']('d');await page.keyboard[motion<0?'down':'up']('a');
   if(['sweep','second'].includes(b.kind)&&b.state==='tell'&&b.timer>.38&&s.player.floor&&now>=jumpUntil)jumpUntil=now+590;
   await page.keyboard[now<jumpUntil?'down':'up']('Space');
   if(['recover','stagger'].includes(b.state)&&gap<265&&now-lastHit>420){await page.keyboard.press('j');lastHit=now}
   if(['recover','stagger'].includes(b.state)&&gap<450&&s.soul>=33&&now-lastOrb>1500){await page.keyboard.press('u');lastOrb=now}
   await page.waitForTimeout(65);
  }
  for(const k of ['d','a','Space'])await page.keyboard.up(k);
  check('normal boss fight unlocks E04',!(await state()).enemies.find(e=>e.boss).alive&&(await state()).abilities.dash);
 }else{await page.keyboard.press(String(source));await page.waitForTimeout(500)}
 await walk(4090+shift);
 await page.screenshot({path:path.join(out,edge+'-center.png')});
 const before=await state(),id=before.connected_world.player_id;
 await walk(4610+shift);check(edge+' forward physical crossing same player',(await state()).room==='R1-0'+(source+1)&&(await state()).connected_world.player_id===id);
 await page.screenshot({path:path.join(out,edge+'-destination.png')});
 await walk(3610+shift);check(edge+' reverse physical crossing same player',(await state()).room==='R1-0'+source&&(await state()).connected_world.player_id===id);
 await walk(4100+shift);const t0=(await state()).connected_world.unified.time;
 await page.keyboard.press('Escape');await page.waitForTimeout(200);const held=(await state()).connected_world.unified.time;
 await page.waitForTimeout(600);check('authored environment clock paused',(await state()).connected_world.unified.time===held);
 await page.keyboard.press('Escape');await page.waitForTimeout(500);check('authored environment resumed',(await state()).connected_world.unified.time>held);
 if(process.env.MOTION_CHECK!=='0'){
  for(let i=0;i<13;i++){if(i%3===0)await page.screenshot({path:path.join(out,edge+'-motion-'+i+'.png')});await page.waitForTimeout(4000)}
  const s=await state();check('52s continuous playback',s.connected_world.unified.time-t0>50,s.connected_world.authored);
  check('bounded transition populations',s.connected_world.unified.fish===80&&s.connected_world.unified.bubbles===66);
 }
 check('no screenshot dissolve',!(await state()).continuity.transition_active);
 check('chapter water stream still playing',(await state()).audio.playing);
 check('no resource engine or browser errors',errors.length===0,errors);
}finally{
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({edge,checks,errors,route,scope:'Source room start is explicit existing preview fixture; subsequent crossing forward/reverse uses real keyboard input; isolated storage; no injected gameplay state.'},null,2));
 await context.close();await browser.close();
}
