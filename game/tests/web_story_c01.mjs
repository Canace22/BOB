// Continuous route with real keyboard input and read-only snapshots; isolated browser storage.
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const out = path.resolve('game/build/qa', process.env.TEST_LABEL ?? 'story-c01/web');
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe', args: ['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({ viewport: { width:1280,height:720 } });
const page = await context.newPage();
const checks=[], errors=[], snapshots=[];
page.on('pageerror', e=>{errors.push(e.message);console.error(e.message);});
page.on('console', m=>{ if(m.type()==='error') {errors.push(m.text());console.error(m.text());} });
const sleep=ms=>page.waitForTimeout(ms);
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const check=(name, pass)=>{checks.push({name,pass:!!pass}); console.log(pass?'PASS':'FAIL',name);if(!pass)throw Error(name);};
async function until(predicate, timeout=15000) { const start=Date.now();while(Date.now()-start<timeout){const s=await state();if(predicate(s))return s;await sleep(80);}throw Error('State timeout: '+JSON.stringify(await state())); }
const ready=()=>page.waitForFunction(()=>typeof window.render_game_to_text==='function'&&JSON.parse(window.render_game_to_text()).campaign==='story-c01',null,{timeout:240000});
const gameplay=()=>until(s=>!s.paused&&s.player.controls_enabled&&!s.pending_resume);
async function hold(key, ms){await page.keyboard.down(key);await sleep(ms);await page.keyboard.up(key);}
async function shot(name){snapshots.push({name,...await state()});await page.screenshot({path:path.join(out,name+'.png')});}
async function click(text){const s=await state();const c=s.ui.controls.find(c=>c.text.startsWith(text));if(!c)throw Error('Missing button '+text);const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+c.x*b.width/1280,b.y+c.y*b.height/720);await sleep(220);}
async function moveTo(x){for(let i=0;i<100;i++){const s=await state(),dx=x-s.player.x;if(Math.abs(dx)<12)return; if(s.ui.page==='death')throw Error('Died walking');await hold(dx>0?'d':'a',Math.min(220,Math.max(40,Math.abs(dx)/265*1000)));}throw Error('Cannot reach '+x);}
async function dialogue(){await page.keyboard.press('e');await until(s=>s.ui.page==='dialogue');await sleep(240);for(let i=0;i<10;i++){if((await state()).ui.page!=='dialogue')break;await page.keyboard.press('e');await sleep(240);}await gameplay();}
async function fight(index){for(let i=0;i<35;i++){const s=await state(),e=s.enemies[index];if(e.state==='settled')return;if(s.ui.page==='death')throw Error('Died in combat');if(e.state==='retreat'){await sleep(250);continue;}const dx=e.x-s.player.x;if(Math.abs(dx)>87)await hold(dx>0?'d':'a',Math.min(160,(Math.abs(dx)-75)/265*1000));else {if(Math.sign(dx)!==s.player.facing)await hold(dx>0?'d':'a',40);await page.keyboard.press('j');await sleep(390);}}throw Error('Combat stalled '+JSON.stringify(await state()));}
async function leapTo(x){await page.keyboard.down('d');await page.keyboard.down('Space');await sleep(430);await page.keyboard.up('Space');await until(s=>s.player.x>=x,6000);await page.keyboard.up('d');await sleep(600);}
try {
 console.log('Loading isolated chapter browser');
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4193/BOB/godot-story/',{waitUntil:'domcontentloaded',timeout:240000});
 console.log('HTML loaded; waiting for Godot');await ready();
 check('Fresh story title and isolated save path',(await state()).ui.page==='title'&&(await state()).save_path==='user://story-c01/progress.json');
 await shot('01-title');await click('开始新旅途');await gameplay();
 await moveTo(410);await page.keyboard.press('e');await until(s=>s.ui.page==='dialogue');await shot('02-resonance');await page.keyboard.press('Escape');await gameplay();
 check('Aborted conversation does not save encounter',!(await state()).flags['c01.met_mender']);
 await dialogue();await sleep(450);check('Full conversation saves first fact',(await state()).flags['c01.met_mender']);
 check('Closing E does not reopen conversation',(await state()).ui.page==='');
 await page.keyboard.press('Escape');await until(s=>s.paused);const frozen=(await state()).player.x;await page.keyboard.down('d');await page.keyboard.press('Escape');await sleep(250);
 check('Resume waits for held movement release',(await state()).pending_resume&&Math.abs((await state()).player.x-frozen)<1);await page.keyboard.up('d');await gameplay();
 await page.keyboard.press('Escape');await until(s=>s.paused);await page.keyboard.down('j');await page.keyboard.press('Escape');await sleep(250);
 check('Resume also waits for held attack release',(await state()).pending_resume&&(await state()).paused);await page.keyboard.up('j');await gameplay();await sleep(300);
 check('Paused attack does not leak into combat',!(await state()).player.state.startsWith('strike'));
 // Natural enemy damage and death, then a real R retry from the safe camp.
 await moveTo(1120);await until(s=>s.ui.page==='death',45000);await shot('03-death');await page.keyboard.press('r');await gameplay();
 check('Death restores saved conversation and health',(await state()).flags['c01.met_mender']&&(await state()).player.health===5&&Math.abs((await state()).player.x-620)<15);
 await moveTo(1080);await fight(0);await shot('04-left-retreated');
 check('One retreat cannot advance whole encounter',!(await state()).flags['c01.foragers_retreated']);
 // Land on first one-way perch, then clear the central baleen support.
 await moveTo(1170);await hold('Space',520);await sleep(600);await moveTo(1280);await leapTo(1510);await moveTo(1690);await leapTo(1870);await moveTo(2140);await sleep(600);
 await fight(1);await until(s=>s.flags['c01.foragers_retreated']);await shot('05-both-retreated');
 check('Both enemies remain alive at their feeding homes',(await state()).enemies.every(e=>e.alive&&e.state==='settled'&&Math.abs(e.x-e.home_x)<6));
 await moveTo(2995);check('Exit before directions does not complete',!(await state()).flags['c01.completed']);
 await until(s=>Math.abs(s.mender.x-2550)<3,20000);await moveTo(2530);await dialogue();
 check('Directions recorded but chapter waits for arrival',(await state()).flags['c01.route_known']&&!(await state()).flags['c01.completed']);
 await moveTo(3000);await until(s=>s.ui.page==='complete');await shot('06-complete');check('Active arrival completes chapter',(await state()).flags['c01.completed']);
 await click('继续探索');await gameplay();await page.keyboard.press('Tab');await sleep(300);await shot('07-overview');
 await page.reload({waitUntil:'domcontentloaded',timeout:240000});await ready();await click('继续旅途');await gameplay();
 check('Reload keeps all four facts without repeat combat',Object.keys((await state()).flags).length===4&&(await state()).enemies.every(e=>e.state==='settled'));
 await shot('08-restored');check('Browser and engine error free',errors.length===0);
}catch(e){errors.push(String(e.stack??e));console.error(String(e));try{await page.screenshot({path:path.join(out,'failure.png')});snapshots.push({name:'failure',...await state()});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,snapshots,method:'Real keyboard and mouse, fresh isolated browser context, read-only state; no teleport/damage injection'},null,2));await context.close();await browser.close();}
if(errors.length||checks.some(c=>!c.pass))process.exitCode=1;
