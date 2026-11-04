// Fresh browser storage; the existing 4 key selects an explicit room fixture.
// Combat, camp, death/retry, exit and reload use physical keys/mouse only.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out=path.resolve('game/build/qa',process.env.TEST_LABEL??'crab-campaign/web');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROME_PATH??'C:/Program Files/Google/Chrome/Application/chrome.exe',args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}});
const page=await context.newPage();page.setDefaultTimeout(Number(process.env.WEB_READY_TIMEOUT_MS??180000));
const checks=[],errors=[],snapshots=[],held=new Set();
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
page.on('requestfailed',r=>errors.push(r.url()+': '+r.failure()?.errorText));
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
const check=(name,pass)=>{checks.push({name,pass:Boolean(pass)});console.log(pass?'PASS':'FAIL',name);if(!pass)throw new Error(name)};
async function key(k,on){if(on&&!held.has(k)){await page.keyboard.down(k);held.add(k)}else if(!on&&held.has(k)){await page.keyboard.up(k);held.delete(k)}}
async function release(){for(const k of [...held])await key(k,false)}
async function tap(k){await page.keyboard.press(k,{delay:35})}
async function shot(name){snapshots.push({name,...await state()});await page.screenshot({path:path.join(out,name+'.png')})}
async function click(name){const s=await state();const c=s.ui.controls.find(x=>x.name===name);if(!c||c.disabled)throw new Error(`Unavailable control ${name}`);const r=await page.locator('#canvas').boundingBox();const z=Math.min(r.width/s.ui.width,r.height/s.ui.height);await page.mouse.click(r.x+(r.width-s.ui.width*z)/2+(c.x+c.width/2)*z,r.y+(r.height-s.ui.height*z)/2+(c.y+c.height/2)*z);await sleep(200)}
async function walk(x,deadline=10000){const end=Date.now()+deadline;while(Date.now()<end){const s=await state();if(Math.abs(s.player.x-x)<20)break;await key('d',s.player.x<x);await key('a',s.player.x>x);await sleep(60)}await release()}
try{
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4187/BOB/godot/',{waitUntil:'domcontentloaded'});
 const startupProgress=setInterval(()=>{
   page.evaluate(()=>({detail:document.querySelector('#status-detail')?.textContent,progress:document.querySelector('#status-progress')?.value})).then(s=>console.log('STARTUP',JSON.stringify(s))).catch(()=>{});
 },30000);
 try{await page.waitForFunction(()=>typeof window.render_game_to_text==='function')}finally{clearInterval(startupProgress)}
 await click('NewGame');await sleep(400);await tap('4');await sleep(500);
 let s=await state();check('Room fixture loads exactly one mother crab',s.room==='R1-04'&&s.enemies.filter(e=>e.boss&&e.alive&&e.combat).length===1);
 check('Dash remains locked before victory',!s.abilities.dash&&s.enemies[0].combat.maximum===300);
 await shot('01-arrival');await tap('Escape');await sleep(150);const frozen=await state();await sleep(350);
 check('Pause freezes mother crab state',(await state()).enemies[0].combat.timer===frozen.enemies[0].combat.timer);
 await tap('Escape');await sleep(200);
 await walk(105);await sleep(200);await tap('e');await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).ui.page==='camp');
 check('Actual camp owns retry checkpoint',(await state()).checkpoint.room===3);await click('LeaveCamp');await sleep(300);
 // Deliberately take ordinary enemy attacks to verify the real death/retry flow.
 await walk(650);await release();
 await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).ui.page==='death',{},{timeout:75000});
 check('Boss attacks reach real death menu',(await state()).hp===0);await shot('02-death');await tap('r');await sleep(700);
 s=await state();check('Retry restores mother crab and player',s.hp===5&&s.room==='R1-04'&&s.enemies[0].hp===300&&!s.abilities.dash);
 const seen=new Set();let jumpUntil=0,lastHit=0,lastOrb=0;
 const end=Date.now()+150000;
 while(Date.now()<end){
   s=await state();const e=s.enemies.find(e=>e.boss);
   if(!e.alive)break;
   if(s.hp<=0)throw new Error('Keyboard counterplay died');
   const b=e.combat,now=Date.now(),gap=Math.abs(e.x-s.player.x),right=e.x>s.player.x;
   const retreat=['slam','charge'].includes(b.kind)&&['tell','active'].includes(b.state);
   const desired=b.kind==='charge'?440:345;
   let motion=0;
   if(retreat&&gap<desired&&s.player.x>292)motion=right?-1:1;
   else if(!retreat&&gap>210)motion=right?1:-1;
   else if(s.player.facing!==(right?1:-1))motion=right?1:-1;
   await key('d',motion>0);await key('a',motion<0);
   if(['sweep','second'].includes(b.kind)&&b.state==='tell'&&b.timer>0.38&&s.player.floor&&now>=jumpUntil)jumpUntil=now+590;
   await key('Space',now<jumpUntil);
   const opening=['recover','stagger'].includes(b.state);
   if(opening&&gap<265&&now-lastHit>420){await tap('j');lastHit=now}
   if(opening&&gap<450&&s.soul>=33&&now-lastOrb>1500){await tap('u');lastOrb=now}
   const tag=b.state==='phase'?`phase-${b.phase+1}`:(b.state==='tell'?b.kind:'');
   if(tag&&!seen.has(tag)){seen.add(tag);await shot('03-'+tag)}
   await sleep(65);
 }
 await release();s=await state();check('Keyboard counterplay defeats mother crab',!s.enemies[0].alive&&s.hp>0);
 check('Victory grants the existing dash',s.abilities.dash);check('Both phase transitions appeared',seen.has('phase-2')&&seen.has('phase-3'));
 await shot('04-victory');const startX=s.player.x;await tap('l');await sleep(260);check('Earned dash responds',Math.abs((await state()).player.x-startX)>50);
 for(let i=0;i<100;i++){s=await state();if(s.room!=='R1-04')break;await key('d',true);if(i%12===0)await tap('Space');await sleep(100)}
 await release();s=await state();check('Death removes body and opens original exit',s.room==='R1-05');await shot('05-exit');
 await page.reload({waitUntil:'domcontentloaded'});await page.waitForFunction(()=>typeof window.render_game_to_text==='function');await click('Continue');await sleep(400);
 s=await state();check('V6 reload preserves defeat and dash',s.room==='R1-04'&&s.abilities.dash&&s.enemies.every(e=>!e.boss||!e.alive));await shot('06-reload');
 check('No browser or engine errors',errors.length===0);
}catch(e){errors.push(String(e.stack??e));console.error(String(e));await page.screenshot({path:path.join(out,'failure.png')}).catch(()=>{})}
finally{await release();await browser.close();fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,snapshots,method:'Existing room-preview fixture; real camp, death/retry, keyboard fight, exit and V6 reload in fresh context'},null,2))}
if(errors.length||checks.some(c=>!c.pass))process.exitCode=1;
