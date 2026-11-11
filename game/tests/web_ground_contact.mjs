// Read-only state observations; all movement, jumping, doors and saves use real keyboard input.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const out=path.resolve('game/build/qa/ground-contact',process.env.TEST_LABEL || 'web-local');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({channel:'chrome',headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context=await browser.newContext({viewport:{width:1280,height:720}});
const page=await context.newPage();
const checks=[],errors=[],samples=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const ready=()=>page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:300000});
function check(label,pass,detail){checks.push({label,pass,detail});console.log(JSON.stringify(checks.at(-1)));assert.ok(pass,label);}
async function walk(target,{slow=false}={}){
  const start=await state(),direction=Math.sign(target-start.player.x),key=direction>0?'d':'a';
  if(slow)await page.keyboard.down('Control');
  await page.keyboard.down(key);
  let reached=false;
  try{
    for(let i=0;i<500;i++){
      await page.waitForTimeout(60);
      const s=await state();
      samples.push(s.player);
      assert.equal(s.room,'R1-01','walking stays in first room');
      assert.ok(s.player.floor,'walking does not become airborne');
      if((s.player.x-target)*direction>=0){reached=true;break;}
    }
  }finally{await page.keyboard.up(key);if(slow)await page.keyboard.up('Control');}
  await page.waitForTimeout(250);
  check(`walk ${target}${slow?' slowly':''}`,reached);
}
try{
  await page.goto(process.env.GAME_URL || 'http://127.0.0.1:4198/BOB/godot/',{waitUntil:'domcontentloaded'});
  await ready();await page.keyboard.press('Enter');await page.waitForTimeout(600);
  check('new journey starts grounded',(await state()).room==='R1-01'&&(await state()).player.floor);
  await walk(950);
  await page.screenshot({path:path.join(out,'right-slope.png')});
  const before=await state();
  check('reported slope now uses painted top',before.player.y<540,before.player);
  await page.keyboard.down('Space');await page.waitForTimeout(180);
  check('jump leaves slope',!(await state()).player.floor);
  await page.keyboard.up('Space');await page.waitForTimeout(1200);
  check('jump returns to slope',(await state()).player.floor&&Math.abs((await state()).player.y-before.player.y)<5);
  await walk(1060,{slow:true});
  await page.screenshot({path:path.join(out,'slope-descent.png')});
  await walk(1490);
  await walk(850);
  await page.screenshot({path:path.join(out,'crest-return.png')});
  await walk(110);
  await page.keyboard.press('e');await page.waitForTimeout(800);
  const saved=await state();
  check('camp saves corrected floor',saved.ui.page==='camp'&&saved.ui.save_ok);
  await page.reload({waitUntil:'domcontentloaded'});await ready();await page.waitForTimeout(600);
  if((await state()).ui.page==='title'){await page.keyboard.press('Enter');await page.waitForTimeout(600);}
  const loaded=await state();
  check('reload preserves camp and grounded character',loaded.room==='R1-01'&&loaded.player.floor&&Math.abs(loaded.player.x-saved.checkpoint.pos[0])<10,{player:loaded.player,checkpoint:saved.checkpoint,page:loaded.ui.page});
  await page.keyboard.down('d');
  for(let i=0;i<300;i++){if((await state()).room==='R1-02')break;await page.waitForTimeout(80);}
  await page.keyboard.up('d');await page.waitForTimeout(350);
  check('corrected road still reaches next room',(await state()).room==='R1-02');
  await page.keyboard.down('d');await page.waitForTimeout(600);await page.keyboard.up('d');
  await page.keyboard.down('a');
  for(let i=0;i<200;i++){if((await state()).room==='R1-01')break;await page.waitForTimeout(80);}
  await page.keyboard.up('a');await page.waitForTimeout(400);
  check('door return lands on corrected road',(await state()).room==='R1-01'&&(await state()).player.floor);
  check('no browser or engine errors',errors.length===0,errors);
}finally{
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({checks,errors,samples},null,2));
  await browser.close();
}
