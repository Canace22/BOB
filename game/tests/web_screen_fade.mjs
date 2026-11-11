import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const out=path.resolve('game/build/qa/screen-fade',process.env.TEST_LABEL||'web-local');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage();
const errors=[],checks=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
const check=(id,pass,detail)=>{checks.push({id,pass,detail});console.log(JSON.stringify(checks.at(-1)));if(!pass)throw Error(id);};
async function until(predicate,timeout=20000){const end=Date.now()+timeout;while(Date.now()<end){const s=await state();if(predicate(s))return s;await sleep(25);}throw Error('timeout '+JSON.stringify(await state()));}
try {
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4187/BOB/godot/',{waitUntil:'domcontentloaded'});
 const bootProgress=setInterval(async()=>{
  try { console.log('BOOT '+await page.locator('#status-detail').innerText({timeout:1000})); } catch {}
 },30000);
 try {
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:Number(process.env.READY_TIMEOUT_MS||900000)});
 } finally {clearInterval(bootProgress);}
 await page.keyboard.press('Enter');await sleep(700);
 await page.keyboard.down('d');
 let s=await until(s=>s.continuity.transition_active);
 check('door fades before destination loads',s.room==='R1-01',s.room);
 await page.keyboard.up('d');
 await sleep(190);await page.screenshot({path:path.join(out,'door-fade.png')});
 await until(s=>s.room==='R1-02'&&!s.continuity.transition_active);
 check('door arrives with controls',!(await state()).paused,(await state()).player);
 await page.screenshot({path:path.join(out,'arrival.png')});
 // Approach the existing enemy and allow natural combat damage; no injected HP.
 await page.keyboard.down('d');await until(s=>s.player.x>=500||s.hp===0);await page.keyboard.up('d');
 for(let i=0;i<60;i++) {
  s=await state();if(s.ui.page==='death')break;
  if(s.hp>0 && s.enemies[0]?.alive) {
   const delta=s.enemies[0].x-s.player.x;
   if(Math.abs(delta)>35){const key=delta>0?'d':'a';await page.keyboard.down(key);await sleep(100);await page.keyboard.up(key);}
  }
  await sleep(450);
 }
 s=await until(s=>s.ui.page==='death',12000);
 check('natural enemy death opens paused menu',s.paused&&s.hp===0);
 await page.keyboard.press('r');await sleep(120);await page.keyboard.press('r');await page.keyboard.press('Escape');
 s=await state();check('retry fade survives repeated keys',s.continuity.transition_active);
 await sleep(200);await page.screenshot({path:path.join(out,'death-fade.png')});
 await until(s=>!s.continuity.transition_active&&!s.paused&&s.hp===5);
 s=await state();check('retry returns to checkpoint',s.room==='R1-01'&&s.ui.page==='',s.checkpoint);
 const x=s.player.x;await page.keyboard.down('d');await sleep(300);await page.keyboard.up('d');
 check('movement restored after retry',(await state()).player.x>x+20);
 await page.keyboard.press('Escape');await until(s=>s.ui.page==='pause');
 await page.keyboard.press('Escape');await until(s=>!s.paused);
 check('pause still works after transition',true);
 check('no engine or browser errors',errors.length===0,errors);
} catch(error) {
 await page.screenshot({path:path.join(out,'failure.png')}).catch(()=>{});
 throw error;
} finally {
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,passed:checks.length===8&&checks.every(c=>c.pass)&&!errors.length,scope:'Isolated browser; real movement, automatic door, natural enemy death and R retry.'},null,2));
 await context.close();await browser.close();
}
