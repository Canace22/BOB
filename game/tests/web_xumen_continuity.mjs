import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const out=path.resolve('game/build/qa/xumen-continuity',process.env.TEST_LABEL||'web-local');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}}),page=await context.newPage();
const checks=[],errors=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
function check(id,pass,detail){checks.push({id,pass,detail});console.log(JSON.stringify(checks.at(-1)));if(!pass)throw Error(id);}
try{
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:Number(process.env.READY_TIMEOUT_MS||180000)});
 await page.keyboard.press('Enter');await page.waitForTimeout(500);
 let s=await state();if(s.ui.page==='confirm-new'){await page.keyboard.press('Enter');await page.waitForTimeout(400);}
 s=await state();check('R1-01 existing environment and new connector bound',s.room==='R1-01'&&s.continuity.count===1,s.continuity);
 const begin=s.player.x;
 await page.keyboard.down('d');await page.waitForTimeout(650);await page.keyboard.up('d');
 check('real D movement',(await state()).player.x>begin+40);
 await page.keyboard.down('Space');await page.waitForTimeout(180);await page.keyboard.up('Space');
 check('real Space jump',!(await state()).player.floor);
 await page.waitForTimeout(650);
 await page.keyboard.down('d');
 for(let i=0;i<100;i++){if((await state()).room==='R1-02')break;await page.waitForTimeout(160);}
 await page.keyboard.up('d');s=await state();
 check('actual 01 to 02 door',s.room==='R1-02');
 check('02 all four existing connections',s.continuity.count===4);
 await page.screenshot({path:path.join(out,'room02.png')});
 await page.keyboard.press('Escape');await page.waitForTimeout(150);
 const held=await state();await page.waitForTimeout(300);s=await state();
 check('pause holds all new clocks',s.paused&&Math.abs(s.continuity.depth_time-held.continuity.depth_time)<.001&&s.continuity.portals.every((p,i)=>Math.abs(p.time-held.continuity.portals[i].time)<.001));
 await page.keyboard.press('Escape');await page.waitForTimeout(300);
 check('resume advances new clock',(await state()).continuity.depth_time>s.continuity.depth_time);
 await page.keyboard.press('c');await page.waitForTimeout(300);
 check('anatomical map opens',(await state()).ui.page==='map');
 await page.screenshot({path:path.join(out,'anatomy-map.png')});
 await page.keyboard.press('Escape');await page.waitForTimeout(200);
 const counts=[1,4,2,2,1,1,1];
 for(let i=0;i<7;i++){
  await page.keyboard.press(String(i+1));await page.waitForTimeout(220);s=await state();
  check('preview '+s.room+' integration',s.room==='R1-0'+(i+1)&&s.continuity.count===counts[i]&&(i===0||s.continuity.shared_depth));
 }
 await page.keyboard.press('1');await page.waitForTimeout(300);
 for(let i=0;i<35;i++){
  if((await state()).player.x<155)break;
  await page.keyboard.down('a');await page.waitForTimeout(120);await page.keyboard.up('a');
 }
 await page.waitForTimeout(700);
 await page.keyboard.press('e');
 for(let i=0;i<25;i++){if((await state()).checkpoint.pos.length===2)break;await page.waitForTimeout(100);}
 s=await state();
 check('physical camp checkpoint',s.checkpoint.room===0&&s.checkpoint.pos.length===2,{player:s.player,checkpoint:s.checkpoint,ui:s.ui.page});
 await page.reload({waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:180000});
 await page.waitForTimeout(250);await page.keyboard.press('Enter');await page.waitForTimeout(400);s=await state();
 check('reload keeps R1 and scene binding',s.room==='R1-01'&&s.continuity.count===1);
 check('no browser engine or resource errors',errors.length===0,errors);
}finally{
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,passed:checks.every(c=>c.pass)&&errors.length===0,scope:'real keyboard 01-to-02, camp/reload; remaining room keys are explicit previews, not a chapter traversal proof'},null,2));
 await browser.close();
}
