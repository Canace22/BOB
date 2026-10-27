import assert from 'node:assert/strict';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, resolve, sep } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
if(Number(process.versions.node.split('.')[0])<20){const r=spawnSync(join(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'),[fileURLToPath(import.meta.url)],{stdio:'inherit',env:process.env});process.exit(r.status??1);}
const {chromium}=await import(pathToFileURL(join(homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs')));
const executablePath=existsSync(chromium.executablePath())?undefined:'C:/Program Files/Google/Chrome/Application/chrome.exe';
const browser=await chromium.launch({headless:true,...(executablePath?{executablePath}:{})});
const out=process.env.TEST_OUTPUT?pathToFileURL(resolve(process.env.TEST_OUTPUT)+sep):new URL('../output/campaign-ui/',import.meta.url);mkdirSync(out,{recursive:true});
const url=process.env.GAME_URL||'http://127.0.0.1:4177/';
const results=[];
try{
  for(const blocked of [false,true]){
    const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage(),errors=[];
    page.on('pageerror',e=>errors.push(e.message));
    if(blocked)await page.route('**/*.webp',route=>route.abort());
    const started=performance.now();await page.goto(url);await page.waitForFunction(()=>!document.querySelector('#start-btn').disabled);const readyMs=performance.now()-started;
    await page.click('#start-btn');await page.evaluate(()=>window.advanceTime(100));
    const state=()=>page.evaluate(()=>JSON.parse(window.render_campaign_to_text()));
    assert.equal((await state()).room,'R1-01');const x=(await state()).player.x;
    await page.keyboard.down('d');await page.evaluate(()=>window.advanceTime(300));await page.keyboard.up('d');
    assert.ok((await state()).player.x>x+30);
    await page.keyboard.press('m');assert.equal((await state()).paused,true);await page.keyboard.press('Escape');
    await page.click('#settings-btn');await page.getByRole('button',{name:'短击 · Q',exact:true}).click();await page.keyboard.press('z');await page.keyboard.press('Escape');
    await page.keyboard.down('z');await page.evaluate(()=>window.advanceTime(16));await page.keyboard.up('z');
    assert.equal((await state()).attack.kind,'short');
    await page.screenshot({path:fileURLToPath(new URL(blocked?'fallback.png':'loaded.png',out))});
    await page.reload();await page.waitForFunction(()=>!document.querySelector('#start-btn').disabled);await page.click('#continue-btn');await page.evaluate(()=>window.advanceTime(100));
    await page.keyboard.down('z');await page.evaluate(()=>window.advanceTime(16));await page.keyboard.up('z');assert.equal((await state()).attack.kind,'short');
    assert.deepEqual(errors,[]);results.push({blocked,readyMs,rebind:true,reload:true,errors});await context.close();
  }
  writeFileSync(new URL('result.json',out),JSON.stringify({url,results},null,2));console.log('Campaign UI, pause, persisted rebinding and all-WebP failure checks passed.');
}finally{await browser.close();}
