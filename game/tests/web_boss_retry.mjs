import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const {chromium}=createRequire(import.meta.url)(process.env.PLAYWRIGHT_MODULE||'playwright');
const out=path.resolve('game/build/qa/boss-retry',process.env.TEST_LABEL||'local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}});
const page=await context.newPage(),checks=[],errors=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
function check(name,pass){checks.push({name,pass});console.log(pass?'PASS':'FAIL',name);if(!pass)throw Error(name)}
async function until(fn,ms=20000){const end=Date.now()+ms;while(Date.now()<end){const s=await state();if(fn(s))return s;await sleep(100)}throw Error('timeout '+JSON.stringify(await state()))}
async function die(){for(let i=0;i<160;i++){const s=await state();if(s.ui.page==='death')return s;if(s.hp>0){const b=s.enemies.find(e=>e.boss&&e.alive);const delta=b.x-s.player.x;if(Math.abs(delta)>100){const key=delta>0?'d':'a';await page.keyboard.down(key);await sleep(180);await page.keyboard.up(key)}}await sleep(300)}throw Error('boss did not kill player')}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4193/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
 await page.keyboard.press('Enter');await until(s=>!s.paused);
 // Existing room-preview hotkey is the only fixture; damage and retry use real gameplay.
 await page.keyboard.press('4');await until(s=>s.room==='R1-04');
 const checkpoint=(await state()).checkpoint;
 let s=await die();check('natural Boss death opens retry menu',s.hp===0&&s.paused&&s.ui.controls.some(c=>c.name==='Retry')&&s.ui.controls.some(c=>c.name==='Checkpoint'));
 await page.screenshot({path:path.join(out,'death-black.png')});
 await page.keyboard.press('Escape');check('Escape keeps death menu',(await state()).ui.page==='death');
 await page.keyboard.press('r');await sleep(100);await page.keyboard.press('r');
 s=await until(s=>!s.paused&&!s.continuity.transition_active&&s.hp===5);
 check('R resets Boss and player in same room',s.room==='R1-04'&&s.enemies.some(e=>e.boss&&e.hp===e.combat.maximum)&&s.ui.page==='');
 check('retry preserves checkpoint',JSON.stringify(s.checkpoint)===JSON.stringify(checkpoint));
 const x=s.player.x;await page.keyboard.down('d');await sleep(300);await page.keyboard.up('d');check('movement resumes',(await state()).player.x>x+20);
 await die();const c=(await state()).ui.controls.find(c=>c.name==='Checkpoint');await page.mouse.click(c.x+c.width/2,c.y+c.height/2);
 s=await until(s=>!s.paused&&!s.continuity.transition_active&&s.hp===5);check('mouse returns to original checkpoint',s.room==='R1-01');
 check('no browser or engine errors',errors.length===0);
}finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,scope:'Room 4 preview fixture, natural Boss damage, real R/Escape/movement and mouse retry'},null,2));await context.close();await browser.close()}
