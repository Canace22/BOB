// Real keyboard approach and pause, observed through the read-only snapshot.
import {createRequire} from 'node:module';
import {existsSync, mkdirSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const out=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'crab-walk');
mkdirSync(out,{recursive:true});
const executablePath=existsSync(chromium.executablePath())?chromium.executablePath():(process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe');
const browser=await chromium.launch({executablePath,headless:true,args:['--enable-unsafe-swiftshader']});
try {
  const context=await browser.newContext({viewport:{width:1280,height:720}});
  const page=await context.newPage(); page.setDefaultTimeout(120000);
  await page.goto(process.env.GAME_URL ?? 'http://127.0.0.1:4188/BOB/godot/?prototype=crab',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof render_game_to_text==='function'&&JSON.parse(render_game_to_text()).stage==='ready');
  await page.locator('canvas').click({position:{x:600,y:450}});
  await page.keyboard.press('Enter');
  await page.waitForFunction(()=>JSON.parse(render_game_to_text()).boss.animation==='10_walk');
  const samples=[];
  for(let i=0;i<6;i++) {
    samples.push(await page.evaluate(()=>JSON.parse(render_game_to_text()).boss));
    await page.screenshot({path:path.join(out,`walk-${i}.png`)});
    await page.waitForTimeout(140);
  }
  if(new Set(samples.map(b=>b.frame)).size<4) throw Error('Walking phases did not advance');
  if(samples.at(-1).x>=samples[0].x) throw Error('Boss did not walk left toward player');
  await page.keyboard.press('Escape');
  await page.waitForFunction(()=>JSON.parse(render_game_to_text()).paused);
  const before=await page.evaluate(()=>JSON.parse(render_game_to_text()).boss);
  await page.waitForTimeout(500);
  const after=await page.evaluate(()=>JSON.parse(render_game_to_text()).boss);
  if(before.x!==after.x||before.frame!==after.frame) throw Error('Walking did not freeze on pause');
  writeFileSync(path.join(out,'report.json'),JSON.stringify({passed:true,samples,pausedFrame:before.frame},null,2));
  console.log('PASS walking: six sampled poses, displacement and pause');
} finally { await browser.close(); }
