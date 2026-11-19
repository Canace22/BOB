import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const require=createRequire(import.meta.url);
const modulePath=process.env.PLAYWRIGHT_MODULE??path.join(process.env.USERPROFILE,'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const {chromium}=require(modulePath);
const url=process.env.CHAPTER01_URL??'http://127.0.0.1:4320/chapter01/';
const output=path.join(root,'game/build/qa/chapter01/browser');
fs.mkdirSync(output,{recursive:true});
const report={url,steps:[],errors:[],screenshots:[]};
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1280,height:720}});
page.on('pageerror',error=>report.errors.push(error.message));
page.on('console',message=>{if(message.type()==='error')report.errors.push(message.text());});
page.on('response',response=>{if(response.status()>=400)report.errors.push(`HTTP ${response.status()}: ${response.url()}`);});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
async function picture(name){await page.screenshot({path:path.join(output,name+'.png')});report.screenshots.push(name+'.png');}

async function approach(to){
  const before=await state(),door=before.doors.find(item=>item.to===to);assert.ok(door,`${before.room} missing door to ${to}`);
  if(Math.abs(before.player.x-door.x)>35){
    const key=before.player.x<door.x?'d':'a';
    await page.keyboard.down(key);
    try{await page.waitForFunction(x=>Math.abs(JSON.parse(window.render_game_to_text()).player.x-x)<40,door.x,{timeout:20000,polling:40});}
    finally{await page.keyboard.up(key);}
  }
  await page.waitForTimeout(180);
  return door;
}

let horizontalCaptured=false,verticalCaptured=false;
async function travel(to){
  const before=await state();const door=await approach(to);assert.ok(door.open,`unexpected locked door to ${to}`);
  await page.keyboard.press('e');
  if(!horizontalCaptured&&['left','right'].includes(door.direction)){
    await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).transitioning,{timeout:3000,polling:20});
    await picture('transition-slide');horizontalCaptured=true;
  }else if(!verticalCaptured&&['up','down'].includes(door.direction)){
    await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).transitioning,{timeout:3000,polling:20});
    await picture('transition-shaft');verticalCaptured=true;
  }
  await page.waitForFunction(({to,count})=>{const s=JSON.parse(window.render_game_to_text());return s.room===to&&!s.transitioning&&s.transitions>count;},{to,count:before.transitions},{timeout:12000,polling:30});
  const after=await state();report.steps.push({from:before.room,to,transition:after.transition_kind});
}

try{
  await page.goto(url);
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function'&&JSON.parse(window.render_game_to_text()).room,null,{timeout:120000});
  await page.locator('canvas').click({position:{x:640,y:360}});
  await picture('entry');
  const start=await state();assert.equal(start.room,'mouth-seam');assert.ok(start.player.grounded);
  await page.keyboard.press('Space');
  await page.waitForFunction(y=>JSON.parse(window.render_game_to_text()).player.y<y-35,start.player.y,{timeout:2500});
  await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).player.grounded,{timeout:3000});
  report.steps.push({check:'jump-and-land',passed:true});
  await travel('nest-court');await travel('lower-nest');
  await picture('lower-nest');
  await approach('supply-return');const locked=await state();await page.keyboard.press('e');await page.waitForTimeout(400);
  assert.equal((await state()).room,'lower-nest');assert.equal((await state()).transitions,locked.transitions);
  report.steps.push({check:'return-line-locked-before-arena',passed:true});
  for(const id of ['nest-court','song-ledge','filter-lookout','song-ledge','loose-whisker','lower-nest','loose-whisker','gate-watch','jaw-arena'])await travel(id);
  await picture('arena');
  await travel('foldwell-mouth');await picture('chapter-exit');await travel('jaw-arena');
  await travel('supply-return');await picture('return-walkway');
  for(const id of ['lower-nest','nest-court','mouth-seam'])await travel(id);
  const complete=await state();assert.equal(complete.visited.length,10);assert.ok(horizontalCaptured&&verticalCaptured);
  report.steps.push({check:'all-ten-rooms-and-return-loop',visited:complete.visited,transitions:complete.transitions});
  await page.keyboard.press('r');await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).visited.length===1);
  await page.reload();await page.waitForFunction(()=>typeof window.render_game_to_text==='function'&&JSON.parse(window.render_game_to_text()).room==='mouth-seam',null,{timeout:120000});
  assert.equal((await state()).visited.length,1);report.steps.push({check:'restart-and-refresh-isolated',passed:true});
  assert.deepEqual(report.errors,[]);
  report.passed=true;
}catch(error){report.passed=false;report.errors.push(error.stack??error.message);await picture('failure');process.exitCode=1;}
finally{fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));await browser.close();}
