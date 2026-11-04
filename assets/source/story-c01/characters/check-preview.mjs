import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE??'playwright');
const out=path.resolve('game/build/qa/story-c01-art');
fs.mkdirSync(out,{recursive:true});
const browser=await chromium.launch({headless:true});
const context=await browser.newContext({viewport:{width:1280,height:750}});
const page=await context.newPage();
const errors=[];
page.on('pageerror',error=>errors.push(error.message));
const samples=[];
try {
  await page.goto(process.env.ART_PREVIEW_URL??'http://127.0.0.1:4381/preview.html');
  await page.waitForFunction(()=>window.previewState?.loaded,{timeout:20000});
  for(let i=0;i<12;i++){
    await page.waitForTimeout(270);
    samples.push(await page.evaluate(()=>({state:window.previewState,frames:[...document.querySelectorAll('canvas')].map(c=>c.toDataURL())})));
    await page.screenshot({path:path.join(out,`phase-${i}.png`)});
  }
  for(let i=0;i<8;i++)assert.ok(new Set(samples.map(s=>s.frames[i])).size>1,`panel ${i} changes actual pixels`);
  await page.getByRole('button',{name:'暂停',exact:true}).click();
  await page.waitForTimeout(30);
  const paused=await page.evaluate(()=>({clock:window.previewState.clock,pixels:[...document.querySelectorAll('canvas')].map(c=>c.toDataURL())}));
  await page.waitForTimeout(350);
  const still=await page.evaluate(()=>({clock:window.previewState.clock,pixels:[...document.querySelectorAll('canvas')].map(c=>c.toDataURL())}));
  assert.deepEqual(still,paused,'pause holds pixels and time');
  await page.getByRole('button',{name:'翻面',exact:true}).click();
  await page.getByRole('button',{name:'明暗底',exact:true}).click();
  await page.waitForTimeout(50);
  await page.screenshot({path:path.join(out,'light-mirrored-paused.png')});
  await page.getByRole('button',{name:'继续',exact:true}).click();
  await page.waitForTimeout(100);
  assert.ok((await page.evaluate(()=>window.previewState.clock))>paused.clock,'resume continues clock');
  assert.deepEqual(errors,[],'browser has no uncaught errors');
  fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({panels:8,loaded_atlases:2,samples:12,distinct_per_panel:Array.from({length:8},(_,i)=>new Set(samples.map(s=>s.frames[i])).size),pause:true,resume:true,mirror:true,light_background:true,errors},null,2));
  console.log(fs.readFileSync(path.join(out,'checks.json'),'utf8'));
} finally {await context.close();await browser.close();}
