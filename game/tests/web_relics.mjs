import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const {chromium}=createRequire(import.meta.url)(process.env.PLAYWRIGHT_MODULE||'playwright');
const out=path.resolve('game/build/qa/relics',process.env.TEST_LABEL||'web-local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}}),page=await context.newPage();
const checks=[],errors=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
function check(name,pass){checks.push({name,pass});console.log(pass?'PASS':'FAIL',name);if(!pass)throw Error(name)}
async function until(fn,ms=20000){const end=Date.now()+ms;while(Date.now()<end){const s=await state();if(fn(s))return s;await sleep(65)}throw Error('timeout '+JSON.stringify(await state()))}
async function walk(x,room){const initial=await state(),key=initial.player.x<x?'d':'a';await page.keyboard.down(key);try{return await until(s=>s.room!==room||Math.abs(s.player.x-x)<20||(key==='d'?s.player.x>x:s.player.x<x))}finally{await page.keyboard.up(key)}}
async function leap(x,room){await page.keyboard.down('d');await page.keyboard.down('Space');await sleep(400);await page.keyboard.up('Space');await page.keyboard.press('Space',{delay:180});await until(s=>s.room!==room||s.player.x>=x);await page.keyboard.up('d')}
async function platform(x,y,room){
 let lastJump=0,lastAttack=0,jumpHeld=false;
 try{for(let step=0;step<400;step++){
  const s=await state(),p=s.player,now=Date.now();
  if(s.room!==room||s.hp===0)throw Error('platform route interrupted '+JSON.stringify(s));
  if(Math.abs(p.x-x)<35&&Math.abs(p.y-y)<25&&p.floor)return;
  await page.keyboard.up('a');await page.keyboard.up('d');
  if(Math.abs(p.x-x)>18)await page.keyboard.down(p.x<x?'d':'a');
  if(jumpHeld&&now-lastJump>400){await page.keyboard.up('Space');jumpHeld=false;}
  if(!jumpHeld&&now-lastJump>900&&p.y>y+35&&p.state!=='hit'){await page.keyboard.down('Space');lastJump=now;jumpHeld=true;}
  if(now-lastAttack>700&&s.enemies.some(e=>e.alive&&!e.boss&&Math.abs(e.x-p.x)<140&&Math.abs(e.y-p.y)<100)){await page.keyboard.press('j');lastAttack=now;}
  await sleep(65);
 }throw Error('platform not reached '+JSON.stringify(await state()))}finally{await page.keyboard.up('a');await page.keyboard.up('d');await page.keyboard.up('Space');}
}
async function die(){for(let i=0;i<180;i++){const s=await state();if(s.ui.page==='death')return s;if(s.hp>0){const b=s.enemies.find(e=>e.boss&&e.alive);const dx=b.x-s.player.x;if(Math.abs(dx)>90){const key=dx>0?'d':'a';await page.keyboard.down(key);await sleep(160);await page.keyboard.up(key)}}await sleep(180)}throw Error('boss did not kill player')}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4201/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
 await page.keyboard.press('Enter');await until(s=>!s.paused);
 check('new journey has no shield',(await state()).shield.maximum===0);
 await walk(1640,'R1-01');await until(s=>s.room==='R1-02');await sleep(650);
 await walk(425,'R1-02');await leap(860,'R1-02');await walk(1580,'R1-02');await page.keyboard.press('e');await until(s=>s.room==='R1-03');await sleep(700);
 await walk(420,'R1-03');await leap(850,'R1-03');await platform(995,589,'R1-03');
 await page.keyboard.press('Space',{delay:400});await page.keyboard.down('Space');await walk(1120,'R1-03');await page.keyboard.up('Space');await until(s=>s.player.floor);await sleep(200);
 check('ordinary jumps reach shell platform',(await state()).player.y<480);
 await page.screenshot({path:path.join(out,'shell-pickup.png')});
 await page.keyboard.press('e');let s=await until(s=>s.collected['R1-03']);
 check('shell collected via E grants two points',s.shield.charges===2&&s.shield.maximum===2&&s.hp===5&&!s.practice);
 await sleep(700);await page.keyboard.press('e');await sleep(600);
 check('repeat E cannot stack shell',(await state()).shield.maximum===2);
 await page.keyboard.press('c');await sleep(350);s=await state();
 check('map describes owned shell',s.ui.map_view.detail?.includes('已获得：护潮壳'));
 await page.screenshot({path:path.join(out,'shell-map.png')});await page.keyboard.press('Escape');await sleep(300);
 await walk(1580,'R1-03');await page.keyboard.press('e');await until(s=>s.room==='R1-04');await sleep(800);
 check('collected protection reaches Boss',(await state()).shield.maximum===2);
 await walk(220,'R1-04');await sleep(600);await page.keyboard.press('e');await until(s=>s.ui.page==='camp');
 check('rest fills protection',(await state()).shield.charges===2);
 await page.screenshot({path:path.join(out,'camp-relics.png')});await page.keyboard.press('Escape');await sleep(350);
 const soul=(await state()).soul;
 await page.keyboard.down('d');try{s=await until(s=>s.shield.charges<2,30000)}finally{await page.keyboard.up('d')}
 check('real Boss strike spends shield before life',s.hp===5&&s.soul===soul);
 await page.screenshot({path:path.join(out,'boss-shield.png')});
 await die();check('depleted shield still allows normal death',(await state()).shield.charges===0);
 await page.keyboard.press('r');s=await until(s=>!s.paused&&!s.continuity.transition_active&&s.hp===5);
 check('Boss retry restores earned shield',s.room==='R1-04'&&s.shield.charges===2&&s.collected['R1-03']);
 await page.reload({waitUntil:'domcontentloaded'});await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:240000});
 await page.keyboard.press('Enter');s=await until(s=>!s.paused);
 check('reload retains collection and refills',s.collected['R1-03']&&s.shield.charges===2);
 check('no browser or engine errors',errors.length===0);
}finally{await page.screenshot({path:path.join(out,'final-state.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'final-state.json'),JSON.stringify(await state().catch(()=>({})),null,2));fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,scope:'Fresh journey, real keyboard through rooms 01/02/03 to shell and Boss; no preview, F9, position or save injection.'},null,2));await context.close();await browser.close()}
