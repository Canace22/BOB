// Real browser clicks/keys against production main; read-only observations, fresh storage.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out=path.resolve('game/build/qa',process.env.TEST_LABEL??'ui-system/web');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROME_PATH??'C:/Program Files/Google/Chrome/Application/chrome.exe',args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:out,size:{width:1280,height:720}}});
const page=await context.newPage();page.setDefaultTimeout(180000);
const checks=[],errors=[],snapshots=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const sleep=ms=>page.waitForTimeout(ms);
const check=(name,pass)=>{checks.push({name,pass:Boolean(pass)});console.log(pass?'PASS':'FAIL',name);if(!pass)throw new Error(name)};
const ready=()=>page.waitForFunction(()=>typeof window.render_game_to_text==='function'&&JSON.parse(window.render_game_to_text()).ui?.page==='title');
const gameplay=()=>page.waitForFunction(()=>{const s=JSON.parse(window.render_game_to_text());return s.ui.page===''&&!s.paused&&s.player.controls_enabled});
async function click(name){const s=await state();const c=s.ui.controls.find(x=>x.name===name);if(!c||c.disabled)throw new Error(`Unavailable control ${name}`);const rect=await page.locator('#canvas').boundingBox();const scale=Math.min(rect.width/s.ui.width,rect.height/s.ui.height);await page.mouse.click(rect.x+(rect.width-s.ui.width*scale)/2+(c.x+c.width/2)*scale,rect.y+(rect.height-s.ui.height*scale)/2+(c.y+c.height/2)*scale);await sleep(160)}
async function shot(name){await sleep(160);snapshots.push({name,...await state()});await page.screenshot({path:path.join(out,name+'.png')})}
async function hold(key,ms){await page.keyboard.down(key);await sleep(ms);await page.keyboard.up(key)}
try{
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4187/BOB/godot/',{waitUntil:'domcontentloaded'});await ready();
 check('Fresh profile cannot Continue',(await state()).ui.controls.find(c=>c.name==='Continue').disabled);
 await shot('01-title');await click('Settings');await click('Numbers');await click('Contrast');await click('Motion');
 check('UI settings respond to real clicks',!(await state()).ui.numbers&&(await state()).ui.contrast&&(await state()).ui.reduce_motion);
 await page.keyboard.press('m');check('M mutes actual audio',(await state()).audio.muted);await page.keyboard.press('m');
 await shot('02-settings');await click('SettingsBack');check('Settings returns to title',(await state()).ui.page==='title');
 await click('NewGame');await gameplay();await shot('03-hud');
 const before=await state();await hold('d',450);check('Real D moves player',(await state()).player.x>before.player.x+30);
 await page.keyboard.press('Escape');await sleep(150);const frozen=await state();await hold('d',250);
 check('Pause freezes real player',(await state()).paused&&Math.abs((await state()).player.x-frozen.player.x)<1);
 await shot('04-pause');await page.keyboard.down('j');await click('Resume');await sleep(220);
 check('Closing menu waits for held attack release',(await state()).ui.pending_resume&&(await state()).paused);
 await page.keyboard.up('j');await gameplay();await sleep(300);
 check('No queued attack on resume',!(await state()).player.skill_active&&!(await state()).player.state.startsWith('strike'));
 await page.keyboard.press('c');await sleep(150);check('Map shows only known rooms',(await state()).ui.page==='map'&&(await state()).ui.map_nodes.length===2);
 await click('Room_R1-02');check('Map inspection does not teleport',(await state()).room==='R1-01');await shot('05-map');await click('Back');await gameplay();
 for(let i=0;i<30;i++){if((await state()).player.x<150)break;await hold('a',100)}
 await sleep(250);await page.keyboard.press('e');await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).ui.page==='camp');
 const saved=await state();check('Real camp records a checkpoint',saved.checkpoint.pos.length===2&&saved.ui.save_ok&&saved.hp===5);
 await shot('06-camp');await click('LeaveCamp');await gameplay();
 await page.reload({waitUntil:'domcontentloaded'});await ready();
 const restored=await state();check('Saved UI preferences survive reload',restored.ui.contrast&&restored.ui.reduce_motion&&!restored.ui.numbers);
 check('Saved checkpoint enables Continue',!restored.ui.controls.find(c=>c.name==='Continue').disabled);
 await click('NewGame');check('Existing save requires confirmation',(await state()).ui.page==='confirm_new');await shot('07-confirm');await click('CancelNew');
 check('Cancelled new game preserves checkpoint',JSON.stringify((await state()).checkpoint)===JSON.stringify(saved.checkpoint));
 await click('Continue');await gameplay();check('Continue restores actual checkpoint',Math.abs((await state()).player.x-saved.checkpoint.pos[0])<8);
 const previousCamera=(await state()).camera.following;await page.keyboard.press('Tab');await sleep(200);check('Tab still switches camera',(await state()).camera.following!==previousCamera);await page.keyboard.press('Tab');
 await page.keyboard.down('d');for(let i=0;i<28;i++){await sleep(350);if((await state()).room!=='R1-01')break}await page.keyboard.up('d');await sleep(250);
 check('Authored doorway still changes room',(await state()).room==='R1-02');
 check('Room discovery follows real traversal',(await state()).ui.visited['R1-02']===true);
 await page.keyboard.press('c');await sleep(160);check('Map expands from visited room',(await state()).ui.map_nodes.length>2);await shot('08-expanded-map');await click('Back');await gameplay();
 await page.keyboard.press('Escape');await click('Settings');
 for(const size of [{width:1920,height:1080},{width:1280,height:720},{width:2560,height:1080}]){
   await page.setViewportSize(size);await sleep(700);const s=await state();
   check(`All controls in actual viewport ${size.width}`,s.ui.controls.every(c=>c.x>=-1&&c.y>=-1&&c.x+c.width<=s.ui.width+1&&c.y+c.height<=s.ui.height+1));
   await shot(`settings-${size.width}`);
 }
 await click('SettingsBack');check('Ultrawide click returns to pause',(await state()).ui.page==='pause');await click('Resume');await gameplay();
 await page.setViewportSize({width:1280,height:720});
 for(let i=0;i<4;i++){await page.keyboard.press('Escape');await sleep(100);await click('Settings');await click('SettingsBack');await click('Resume');await gameplay()}
 check('Repeated menus preserve player controls',(await state()).player.controls_enabled&&!((await state()).paused));
 check('No browser or engine errors',errors.length===0);
}catch(e){errors.push(String(e.stack??e));console.error(String(e))}
finally{const video=page.video();await context.close();if(video)fs.copyFileSync(await video.path(),path.join(out,'ui-keyboard.webm'));await browser.close();fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,snapshots,method:'Real clicks and keyboard, fresh browser context, read-only game snapshot'},null,2))}
if(errors.length||checks.some(c=>!c.pass))process.exitCode=1;
