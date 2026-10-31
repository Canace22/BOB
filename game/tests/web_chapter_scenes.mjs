// Real keyboard acceptance in a fresh browser context; room hotkeys are existing preview controls.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out='game/build/qa/r1-chapter-scenes/web';fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true,executablePath:fs.existsSync(chromium.executablePath())?chromium.executablePath():'C:/Program Files/Google/Chrome/Application/chrome.exe',args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}}),page=await context.newPage();
const errors=[],checks=[];page.setDefaultTimeout(180000);
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const check=(id,pass)=>{checks.push({id,pass});assert.ok(pass,id);};
try{
 await page.goto(process.env.GAME_URL??'http://127.0.0.1:4188/BOB/godot/',{waitUntil:'domcontentloaded'});
 await page.waitForFunction(()=>typeof window.render_game_to_text==='function');
 await page.locator('canvas').click();await page.keyboard.press('Enter');await page.waitForTimeout(500);
 for(let number=2;number<=7;number++){
  const id='R1-0'+number;await page.keyboard.press(String(number));
  await page.waitForFunction(id=>JSON.parse(window.render_game_to_text()).environment?.room===id,id);
  await page.waitForTimeout(700);const before=await state();
  check(id+' environment is live',before.environment.counts.bubbles>0);
  await page.keyboard.down('d');await page.waitForTimeout(180);await page.keyboard.up('d');
  const walked=await state();check(id+' actual D movement',walked.player.x>before.player.x+8);
  await page.keyboard.down('Space');await page.waitForTimeout(180);const jumped=await state();await page.keyboard.up('Space');
  check(id+' actual Space jump',!jumped.player.floor);
  await page.waitForTimeout(650);await page.keyboard.press('Escape');await page.waitForTimeout(100);
  const paused=await state();await page.waitForTimeout(200);const held=await state();
  check(id+' pause holds environment',paused.paused&&paused.environment.time===held.environment.time);
  await page.keyboard.press('Escape');await page.waitForTimeout(180);
  check(id+' resume advances environment',(await state()).environment.time>held.environment.time);
  await page.screenshot({path:out+'/'+id+'.png'});
 }
 check('no browser/engine/resource errors',errors.length===0);
 console.log(JSON.stringify({passed:true,checks,errors,scope:'existing room preview hotkeys and real movement; not a connected traversal proof'}));
}finally{
 fs.writeFileSync(out+'/checks.json',JSON.stringify({checks,errors},null,2));await browser.close();
}
