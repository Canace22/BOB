// Real keyboard/mouse, read-only state, fresh profile. Numeric room keys are explicit fixtures.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out=path.resolve(process.env.TEST_OUTPUT??'game/build/qa/corpse-crab/web');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROME_PATH??'C:/Program Files/Google/Chrome/Application/chrome.exe',args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}});
const page=await context.newPage();page.setDefaultTimeout(Number(process.env.READY_TIMEOUT_MS??600000));
const checks=[],errors=[],snapshots=[],held=new Set();
const start=Date.now();
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,snapshots,elapsedMs:Date.now()-start,method:'Fresh profile; real keyboard/mouse only; room 2/3 keys are explicit fixtures; no state writes'},null,2));
const check=(name,pass)=>{checks.push({name,pass:Boolean(pass)});save();console.log(pass?'PASS':'FAIL',name);if(!pass)throw Error(name)};
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
async function key(k,on){if(on&&!held.has(k)){await page.keyboard.down(k);held.add(k)}else if(!on&&held.has(k)){await page.keyboard.up(k);held.delete(k)}}
async function release(){for(const k of [...held])await key(k,false)}
async function tap(k){await page.keyboard.press(k,{delay:40})}
async function shot(name){snapshots.push({name,...await state()});await page.screenshot({path:path.join(out,name+'.png')});save()}
async function until(fn,ms=10000){const end=Date.now()+ms;let s;while(Date.now()<end){s=await state();if(fn(s))return s;await sleep(30)}throw Error('Condition timeout: '+JSON.stringify(s))}
async function walk(x,ms=8000){const end=Date.now()+ms;while(Date.now()<end){const s=await state();if(Math.abs(s.player.x-x)<12)break;await key('d',s.player.x<x);await key('a',s.player.x>x);await sleep(40)}await release()}
async function click(name){const s=await state();const c=s.ui.controls.find(x=>x.name===name);if(!c)throw Error('Missing UI '+name);const r=await page.locator('#canvas').boundingBox();const z=Math.min(r.width/s.ui.width,r.height/s.ui.height);await page.mouse.click(r.x+(r.width-s.ui.width*z)/2+(c.x+c.width/2)*z,r.y+(r.height-s.ui.height*z)/2+(c.y+c.height/2)*z);await sleep(300)}
let recorder;
try {
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4199/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function');
 console.log('READY',Date.now()-start);await click('NewGame');await tap('2');await sleep(600);
 let s=await state();check('R1-02 contains one animated ordinary crab',s.room==='R1-02'&&s.enemies.length===1&&s.enemies[0].combat?.type==='corpse-crab');
 // Record canvas only after loading, not a long blank download video.
 recorder=await page.evaluate(()=>{const canvas=document.querySelector('#canvas');if(!canvas.captureStream||typeof MediaRecorder==='undefined')return false;window.crabChunks=[];window.crabRecorder=new MediaRecorder(canvas.captureStream(30),{mimeType:'video/webm;codecs=vp9',videoBitsPerSecond:3500000});window.crabRecorder.ondataavailable=e=>{if(e.data.size)window.crabChunks.push(e.data)};window.crabRecorder.start();return true});
 await shot('01-arrival');await walk(425);
 await until(s=>s.enemies[0].combat.state==='tell'&&s.enemies[0].combat.timer>.35);
 await shot('02-left-anticipation');
 const before=(await state()).hp;
 await until(s=>s.hp<before,7000);check('Low sweep damages player once',(await state()).hp===before-1);
 await shot('03-left-hit');
 await tap('Escape');await sleep(120);const frozen=await state();await sleep(350);s=await state();
 check('Pause freezes enemy time and pose',s.paused&&s.enemies[0].combat.timer===frozen.enemies[0].combat.timer&&s.enemies[0].combat.frame===frozen.enemies[0].combat.frame);
 await tap('Escape');await sleep(150);
 await key('d',true);await key('Space',true);await sleep(870);await release();await sleep(500);
 s=await state();await walk(s.enemies[0].x+95);
 await until(s=>s.enemies[0].combat.facing===1&&s.enemies[0].combat.state==='tell'&&s.enemies[0].combat.timer>.3,12000);
 await shot('04-right-anticipation');check('Right-facing attack uses same crab', (await state()).enemies[0].combat.facing===1);
 // Screenshots can consume the remaining windup; wait for a real opening before countering.
 await until(s=>s.enemies[0].combat.state==='recover'&&s.enemies[0].combat.timer>.3&&s.player.state!=='hit',5000);
 await key('a',true);await sleep(60);await release();await tap('j');
 await until(s=>s.enemies[0].hp<3,2500);
 s=await state();check('Player melee damages and interrupts the crab',s.enemies[0].hp<3&&(!s.enemies[0].alive||s.enemies[0].combat.state==='hurt'));
 await shot('05-hurt');
 for(let i=0;i<8;i++){s=await state();if(!s.enemies[0].alive)break;await tap('j');await sleep(390)}
 s=await state();check('Ordinary crab defeated without boss reward',!s.enemies[0].alive&&!s.abilities.dash);
 await shot('06-death');await sleep(650);await shot('07-collapsed');
 check('Dead crab no longer blocks or receives hits',!(await state()).enemies[0].combat.collidable);
 await walk(1550,12000);await tap('e');await until(s=>s.room==='R1-03',6000);
 s=await state();check('Actual exit loads two animated tongue terrace crabs',s.enemies.length===2&&s.enemies.every(e=>e.combat?.type==='corpse-crab'));await shot('08-next-room');
 await tap('2');await sleep(500);check('Ordinary room re-entry respawns crab',(await state()).enemies[0].hp===3);
 // Stay in reach through genuine attacks until the normal death UI; no health injection.
 await walk(425);await release();
 // Knockback can leave the crab's leash; walk back into range using real input.
 const deathDeadline=Date.now()+45000;
 while(Date.now()<deathDeadline){s=await state();if(s.ui.page==='death')break;
  const dx=s.enemies[0].x-s.player.x;
  await key('d',dx>75);await key('a',dx< -75);await sleep(40);
 }
 await release();check('Enemy attack reaches normal player death', (await state()).hp===0);await shot('09-player-death');
 await tap('r');await sleep(650);check('Normal revive restores player',(await state()).hp===5);await shot('10-revive');
 check('No browser or engine errors',errors.length===0);
} catch(e) {errors.push(String(e.stack??e));console.error(String(e));try{await shot('failure')}catch{}}
finally {
 await release();save();
 if(recorder){try{const bytes=await page.evaluate(async()=>{await new Promise(r=>{window.crabRecorder.onstop=r;window.crabRecorder.stop()});return Array.from(new Uint8Array(await new Blob(window.crabChunks,{type:'video/webm'}).arrayBuffer()))});fs.writeFileSync(path.join(out,'keyboard-play.webm'),Buffer.from(bytes))}catch(e){console.log('recording',String(e))}}
 await browser.close();save();
}
if(errors.length||checks.some(c=>!c.pass))process.exitCode=1;
