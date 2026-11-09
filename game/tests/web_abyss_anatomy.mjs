// Read-only state plus real keyboard; isolated profile, no local cache injection.
import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const out=path.resolve(process.env.TEST_OUTPUT ?? 'game/build/qa/action36/abyss-web-online');
fs.mkdirSync(out,{recursive:true});
const context=await chromium.launchPersistentContext(path.join(out,'profile'),{
  executablePath:process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe',
  headless:true,viewport:{width:1280,height:720},
  args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const page=context.pages()[0] ?? await context.newPage();
page.setDefaultTimeout(Number(process.env.READY_TIMEOUT_MS ?? 3600000));
const errors=[],checks=[],states=[],network=[];
const started=Date.now();
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const check=(name,pass)=>{checks.push({name,pass:Boolean(pass)});console.log(pass?'PASS':'FAIL',name);};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({
  method:'Actual URL download; isolated persistent profile; real keyboard; read-only state; F9 temporary practice',
  elapsedMs:Date.now()-started,checks,errors,states,network},null,2));
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
page.on('requestfailed',r=>network.push({url:r.url(),failure:r.failure()}));
const progress=setInterval(async()=>{
  try {console.log('DOWNLOAD',Date.now()-started,await page.locator('body').innerText());save();}catch{}
},30000);
try {
  const url=process.env.GAME_URL ?? 'https://canace22.github.io/BOB/godot/';
  await page.goto(url,{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>typeof window.render_game_to_text==='function' && JSON.parse(window.render_game_to_text()).campaign==='WhalebellyRuins');
  fs.writeFileSync(path.join(out,'ready.json'),JSON.stringify({elapsedMs:Date.now()-started,url}));
  console.log('READY',Date.now()-started);clearInterval(progress);
  await page.keyboard.press('Enter');await page.waitForTimeout(700);
  await page.keyboard.press('F9');await page.waitForTimeout(400);
  for(const [direction,key] of [[1,'d'],[-1,'a']]) {
    await page.keyboard.down(key);await page.waitForTimeout(120);await page.keyboard.up(key);
    await page.waitForTimeout(250);
    const before=await state();
    await page.keyboard.down('w');await page.keyboard.down('u');await page.waitForTimeout(300);
    const active=await state();states.push({direction,before,active});
    check(`cast facing ${direction}`,active.player.facing===direction && active.player.skill_key==='abyss_scream');
    await page.screenshot({path:path.join(out,`cast-${direction}.png`)});
    await page.keyboard.up('u');await page.keyboard.up('w');await page.waitForTimeout(1000);
    check(`recover facing ${direction}`,!(await state()).player.skill_active);
  }
  check('no browser or engine errors',errors.length===0);
} catch(e) {errors.push(String(e.stack ?? e));}
finally {clearInterval(progress);save();await context.close();}
if(errors.length || checks.some(c=>!c.pass))process.exitCode=1;
