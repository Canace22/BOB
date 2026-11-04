import {createRequire} from 'node:module';
import fs from 'node:fs';import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const out=path.resolve('game/build/qa/xumen-e01',process.env.TEST_LABEL||'motion-local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});const page=await context.newPage();
const errors=[],checks=[],samples=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(id,pass);if(!pass)throw Error(id)}
async function walk(x){const key=(await state()).connected_world.world_x<x?'d':'a';await page.keyboard.down(key);try{for(let i=0;i<250;i++){const s=await state();if(Math.abs(s.connected_world.world_x-x)<25)return;await page.waitForTimeout(70)}throw Error('walk timeout')}finally{await page.keyboard.up(key)}}
try{
await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:600000});await page.keyboard.press('Enter');await page.waitForTimeout(700);
await walk(1900);await page.waitForTimeout(500);const first=await state();
for(let i=0;i<14;i++){const s=await state();samples.push(s);if([0,1,6,13].includes(i))await page.screenshot({path:path.join(out,'loop-'+i+'.png')});await page.waitForTimeout(4000)}
const end=await state();check('56s real playback covers fish24s twice, flex4s and bubble recycle',end.connected_world.e01.time-first.connected_world.e01.time>53,{start:first.connected_world.e01,end:end.connected_world.e01});
check('bounded element counts unchanged',end.connected_world.e01.fish===22&&end.connected_world.e01.bubbles===10&&end.connected_world.e01.flex===3);
await page.keyboard.press('Escape');await page.waitForTimeout(250);const frozen=await state();await page.waitForTimeout(900);check('pause holds E01 clock',(await state()).connected_world.e01.time===frozen.connected_world.e01.time);await page.keyboard.press('Escape');await page.waitForTimeout(500);
await page.keyboard.press('F9');await page.waitForTimeout(500);await walk(2120);await page.keyboard.down('d');await page.keyboard.down('Space');await page.waitForTimeout(60);await page.keyboard.up('Space');await page.keyboard.press('l');await page.waitForTimeout(220);await page.screenshot({path:path.join(out,'air-dash-boundary.png')});await page.waitForTimeout(450);await page.keyboard.up('d');check('practice air dash crosses E01',(await state()).room==='R1-02');
await walk(1900);await page.keyboard.press('F9');await page.waitForTimeout(300);
await page.setViewportSize({width:1920,height:720});await page.waitForTimeout(900);await page.screenshot({path:path.join(out,'wide-1920.png')});check('wide canvas renders',await page.locator('#canvas').evaluate(c=>c.width===1920));
check('audio stream remains playing',(await state()).audio.playing);check('no browser errors',errors.length===0,errors);
}finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,samples,scope:'Fresh actual default entry; real keyboard; 56s playback and practice ability explicitly separate from earned progression'},null,2));await context.close();await browser.close()}
