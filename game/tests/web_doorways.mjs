// Browser checks use real keys and read-only state. Room preview fixtures are labeled.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out=path.resolve('game/build/qa/doorways',process.env.TEST_LABEL??'web-local');fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}}),page=await context.newPage();
page.setDefaultTimeout(240000);
const errors=[],checks=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const check=(label,pass)=>{checks.push({label,pass});console.log(pass?'PASS':'FAIL',label);assert.ok(pass,label);};
async function hold(key,ms){await page.keyboard.down(key);await page.waitForTimeout(ms);await page.keyboard.up(key);}
async function walkTo(x){
 for(let i=0;i<70;i++){
  const s=await state();if(Math.abs(s.player.x-x)<13)return;
  await hold(s.player.x<x?'d':'a',Math.min(100,Math.abs(s.player.x-x)*3));
 }
 throw Error('walkTo failed '+x+' '+JSON.stringify((await state()).player));
}
async function room(id){await page.waitForFunction(id=>{const s=JSON.parse(window.render_game_to_text());return s.room===id&&!s.continuity.travelling;},id,{timeout:20000});}
try{
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4196/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function');
 await page.keyboard.press('Enter');await page.waitForTimeout(600);
 check('seven-room live entrance',(await state()).room==='R1-01');
 await page.keyboard.down('d');await room('R1-02');await page.keyboard.up('d');
 check('natural side passage needs movement only',(await state()).room==='R1-02');
 await walkTo(110);await page.waitForTimeout(250);
 check('background arch exposes enter prompt',(await state()).continuity.doorways.some(d=>d.nearby&&d.kind==='door'&&d.prompt.length>0));
 await page.screenshot({path:path.join(out,'door-prompt.png')});
 await page.keyboard.press('e');await room('R1-01');
 check('E returns through arch',true);
 await hold('d',450);
 check('arrival cannot immediately bounce',(await state()).room==='R1-01');
 await walkTo(1430);await page.keyboard.down('d');await room('R1-02');await page.keyboard.up('d');
 check('leaving entrance rearms passage',true);
 // Existing preview keys isolate other rooms; these are not a continuous campaign run.
 await page.keyboard.press('F9');
 for(const [number,target,doorX] of [[3,'R1-02',110],[4,'R1-03',110],[5,'R1-04',130],[6,'R1-02',130],[7,'R1-02',125]]){
  await page.keyboard.press(String(number));await room('R1-0'+number);await page.waitForTimeout(400);
  if(number===6) await walkTo(240);
  if(number===4){await page.keyboard.down('a');await hold('Space',600);await page.keyboard.up('a');}
  await walkTo(doorX);await page.waitForTimeout(300);
  await page.screenshot({path:path.join(out,'preview-'+number+'.png')});
  await page.keyboard.press('e');await room(target);
  check('preview '+number+' real keyboard return door',true);
 }
 await page.keyboard.press('Escape');await page.waitForTimeout(150);check('pause after transitions',(await state()).paused);
 await page.keyboard.press('Escape');await page.waitForTimeout(200);check('resume after transitions',!(await state()).paused);
 check('no browser or engine errors',errors.length===0);
}finally{
 fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({checks,errors,scope:'natural R1-01/02 return; room-preview fixtures for other return doors'},null,2));
 await browser.close();
}
console.log(JSON.stringify({checks,errors}));
