import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const out=path.resolve('game/build/qa/xumen-connected',process.env.TEST_LABEL||'web-local');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage();
const checks=[],errors=[],route=[];let completed=false;
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(JSON.stringify(checks.at(-1)));if(!pass)throw Error(id);}
async function walk(target,shot){
 const begin=await state(),key=begin.connected_world.world_x<target?'d':'a';
 await page.keyboard.down(key);
 let taken=false;
 for(let i=0;i<220;i++){
  const s=await state();route.push({room:s.room,x:s.connected_world.world_x,camera:s.connected_world.camera_world[0],id:s.connected_world.player_id});
  if(shot&&!taken&&s.connected_world.world_x>1840&&s.connected_world.world_x<2080){await page.screenshot({path:path.join(out,shot+'.png')});taken=true;}
  if(Math.abs(s.connected_world.world_x-target)<35||(key==='d'&&s.connected_world.world_x>=target)||(key==='a'&&s.connected_world.world_x<=target)){await page.keyboard.up(key);return s;}
  await page.waitForTimeout(80);
 }
 await page.keyboard.up(key);throw Error('walk target not reached: '+target);
}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:Number(process.env.READY_TIMEOUT_MS||600000)});
 await page.keyboard.press('Enter');await page.waitForTimeout(500);
 let s=await state();if(s.ui.page==='confirm-new'){await page.keyboard.press('Enter');await page.waitForTimeout(500);}
 s=await state();check('default entry is connected seven-room world',s.connected_world.enabled&&s.connected_world.chunks===7&&s.connected_world.edges===6,s.connected_world);
 check('unified master owns the current scene',s.connected_world.unified.meshes>=86&&s.connected_world.unified.baleen>=10&&!s.connected_world.unified.old_static,s.connected_world.unified);
 const id=s.connected_world.player_id;
 s=await walk(2440,'actual-bridge-walking');
 check('real keyboard traverses ground from 01 to 02 without E',s.room==='R1-02');
 check('same player persists across chapter coordinates',s.connected_world.player_id===id&&s.connected_world.crossings===1);
 check('no screenshot dissolve',!s.continuity.transition_active);
 check('camera crosses former room edge',s.connected_world.camera_world[0]>2183);
 await page.screenshot({path:path.join(out,'actual-room02.png')});
 await page.keyboard.press('Escape');await page.waitForTimeout(150);const held=await state();await page.waitForTimeout(350);s=await state();
 check('pause freezes world and independent motion',s.paused&&s.connected_world.world_x===held.connected_world.world_x&&s.connected_world.unified.time===held.connected_world.unified.time);
 await page.keyboard.press('Escape');await page.waitForTimeout(250);check('resume restores motion',(await state()).connected_world.unified.time>s.connected_world.unified.time);
 await page.keyboard.press('c');await page.waitForTimeout(200);check('anatomy map opens',(await state()).ui.page==='map');await page.screenshot({path:path.join(out,'connected-map.png')});await page.keyboard.press('Escape');await page.waitForTimeout(200);
 s=await walk(1400);check('physical reverse crossing 02 to 01',s.room==='R1-01'&&s.connected_world.player_id===id&&s.connected_world.crossings===2);
 await walk(125);await page.waitForTimeout(700);await page.keyboard.press('e');
 await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).checkpoint.pos.length===2,null,{timeout:10000});
 s=await state();check('physical camp still saves',s.checkpoint.room===0&&s.ui.save_ok,s.checkpoint);
 fs.writeFileSync(path.join(out,'saved-state.json'),JSON.stringify(s,null,2));
 await page.waitForTimeout(2200);
 await page.reload({waitUntil:'domcontentloaded'});await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:600000});await page.keyboard.press('Enter');await page.waitForTimeout(600);s=await state();
 fs.writeFileSync(path.join(out,'reloaded-state.json'),JSON.stringify(s,null,2));
 check('reload restores local save into connected world',s.room==='R1-01'&&s.connected_world.chunks===7&&s.player.x<200&&s.checkpoint.pos.length===2,s.connected_world);
 check('no browser engine or resource errors',errors.length===0,errors);completed=true;
}finally{
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,route,passed:completed&&checks.every(c=>c.pass)&&errors.length===0,scope:'Real default entry, same-player 01/02 physical round trip, moving camera, pause/map/camp/reload. No room-preview shortcuts used.'},null,2));
 await context.close();await browser.close();
}
