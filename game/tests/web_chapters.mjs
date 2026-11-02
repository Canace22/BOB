import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_MODULE ?? 'playwright');
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/qa', process.env.TEST_LABEL ?? 'chapters-local');
mkdirSync(output, {recursive:true});
const executablePath = existsSync(chromium.executablePath()) ? chromium.executablePath() : (process.env.CHROME_PATH ?? 'C:/Program Files/Google/Chrome/Application/chrome.exe');
const browser = await chromium.launch({executablePath,headless:true,args:['--enable-unsafe-swiftshader','--autoplay-policy=no-user-gesture-required']});
const context = await browser.newContext({viewport:{width:1280,height:720},recordVideo:{dir:path.join(output,'video'),size:{width:1280,height:720}}});
const page = await context.newPage();
const url = process.env.GAME_URL ?? 'http://127.0.0.1:4193/BOB/godot/?chapters=1';
const errors=[],seen=[],held=new Set(),moves=new Set();
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error') errors.push(m.text());});
page.on('response',r=>{if(r.status()>=400) errors.push(`${r.status()} ${r.url()}`);});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const capture=n=>page.screenshot({path:path.join(output,n+'.png')});
async function key(k,on){if(held.has(k)===on)return;if(on){held.add(k);await page.keyboard.down(k);}else{held.delete(k);await page.keyboard.up(k);}}
async function release(){for(const k of [...held])await key(k,false);}
async function boot(){await page.goto(url,{waitUntil:'domcontentloaded',timeout:180000});await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:180000});await page.waitForTimeout(250);}
async function closeDialogue(){await release();for(let i=0;i<6&&(await state()).dialogue;i++){await page.keyboard.press('e');await page.waitForTimeout(200);}assert(!(await state()).dialogue,'dialogue closes after its last page');}
let result,loaded,deathChecked=false,retryChecked=false,pausedChecked=false;
try{
 await boot(); assert((await state()).dialogue, 'exported opening dialogue is present'); await capture('opening'); await closeDialogue(); assert((await state()).flags.includes('chapter.arrival'));
 await page.keyboard.press('Tab');await page.waitForTimeout(150);assert((await state()).paused);await capture('map');await page.keyboard.press('Escape');await page.waitForTimeout(150);assert(!(await state()).paused);pausedChecked=true;
 const start=Date.now();let jumpUntil=0,lastTap=0,checkpoint='',lastLog=0,deathStart=0;
 while(Date.now()-start<300000){
  const s=await state(),p=s.player;
  for(const e of s.enemies)if(e.boss&&['tell','active'].includes(e.state))moves.add(e.kind);
  if(s.dialogue){if(s.room==='N01-B')assert(s.flags.includes('chapter.scavenger.1')&&s.flags.includes('chapter.scavenger.2'),'both encounter flags must precede resident dialogue'); await capture('story-'+s.room);await closeDialogue();continue;}
  if(!seen.includes(s.room)){seen.push(s.room);await release();console.log('ROOM',s.room,s.hp);await capture(s.room);continue;}
  if(s.flags.includes('chapter.complete')){result=s;break;}
  if(p.dead){await release();if(s.room==='N02-B'){deathChecked=true;console.log('DEATH verified');}await page.waitForTimeout(650);continue;}
  if(s.room==='N02-B' && !deathChecked && s.arena_active){
   // First attempt deliberately stands within sweep range to verify checkpoint recovery.
   const g=s.enemies.find(e=>e.boss);
   if(!deathStart)deathStart=Date.now();
   await key('d',g.x-p.x>85);await key('a',g.x-p.x< -85);await key('Space',false);
   await page.waitForTimeout(40);continue;
  }
  if(deathChecked && !retryChecked){assert.equal(s.room,'N02-B');assert.equal(s.hp,4);retryChecked=true;await capture('retry');}
  let left=false,right=true,tap;
  if(p.x<260 && checkpoint!==s.room){
   const campX=180;
   if(Math.abs(p.x-campX)>45){await key('a',p.x>campX);await key('d',p.x<campX);await page.waitForTimeout(50);continue;}
   await release();
   if(s.checkpoint===s.room && s.hp===4){checkpoint=s.room;}
   else {if(p.floor)await page.keyboard.press('e',{delay:65});await page.waitForTimeout(150);continue;}
  }
  const target=s.enemies.find(e=>e.state!=='dead' && ((e.boss && Math.abs(e.x-p.x)<600) || (!e.boss && Math.abs(e.x-p.x)<230 && Math.abs(e.y-p.y)<35)));
  if(target){
   const dx=target.x-p.x;left=dx<0;right=dx>0;
   if(['tell','active'].includes(target.state)){
    if(target.kind==='slam'){left=dx>0 && Math.abs(dx)<235;right=dx<0 && Math.abs(dx)<235;}
    else{
     if(target.state==='tell'&&target.timer>0.40&&p.floor&&Date.now()>jumpUntil)jumpUntil=Date.now()+430;
     if(Math.abs(dx)<100){left=false;right=false;}
    }
   }else if(Math.abs(dx)<100){left=false;right=false;if((!target.boss||['recover','stagger'].includes(target.state))&&(p.mode==='idle'||(p.mode==='attack'&&p.kind==='short1'&&p.elapsed>0.25)))tap='j';}
  }else{
   if(p.floor && !p.floor_ahead && Date.now()>jumpUntil)jumpUntil=Date.now()+480;
   if(s.room==='N01-A' && p.x>870 && p.x<1090 && !s.flags.includes('chapter.echo.1')){
    right=p.x<930;left=p.x>950;
    if(p.floor && p.y>620 && Date.now()>jumpUntil)jumpUntil=Date.now()+500;
    if(p.floor && p.y<620)tap='e';
   }
   if(s.room==='N01-B' && p.x>1860 && !s.flags.includes('chapter.resident')){right=p.x<1910;tap='e';}
   if(s.room==='N02-A' && p.x>1150 && p.x<1360 && !s.flags.includes('chapter.echo.2')){
    right=p.x<1220;left=p.x>1240;
    if(p.floor && p.y>655 && Date.now()>jumpUntil)jumpUntil=Date.now()+500;
    if(p.floor && p.y<655)tap='e';
   }else if(s.room==='N02-A' && p.x>1750 && !s.flags.includes('chapter.latch')){right=p.x<1800;left=p.x>1820;tap='e';}
   if(s.room==='N02-B' && s.flags.includes('chapter.guard')){right=p.x<2010;tap='e';}
   if(p.x>s.room_width-150)tap='e';
  }
  await key('a',left);await key('d',right);await key('Space',Date.now()<jumpUntil);
  if(tap && Date.now()-lastTap>130){await page.keyboard.press(tap,{delay:65});lastTap=Date.now();}
  if(Date.now()-lastLog>10000){console.log(s.room,Math.round(p.x),Math.round(p.y),'hp',s.hp,JSON.stringify(s.enemies),s.flags.join(','));lastLog=Date.now();}
  await page.waitForTimeout(20);
 }
 await release();await capture('complete');assert(result,'complete four-room route within five minutes');
 assert.deepEqual(seen,['N01-A','N01-B','N02-A','N02-B']);assert(deathChecked&&retryChecked,'death and checkpoint restart');
 assert(result.flags.includes('chapter.echo.1')&&result.flags.includes('chapter.echo.2'),'both optional echoes reached');assert(result.flags.includes('chapter.latch'),'upper ledge shortcut opened');assert(moves.has('sweep')&&moves.has('slam'),'both drawn guard attacks observed');assert(result.flags.includes('chapter.guard')); assert(!result.abilities.includes('ability.dash'));
 await page.waitForTimeout(1300);await page.reload({waitUntil:'domcontentloaded',timeout:180000});await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:180000});await page.waitForTimeout(350);loaded=await state();
 assert.equal(loaded.room,'N02-B');assert(loaded.flags.includes('chapter.complete'));assert(loaded.enemies.find(e=>e.boss)?.state==='dead');await capture('reload');
 assert.deepEqual(errors,[]);
 writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:true,url,seen,result,loaded,deathChecked,retryChecked,pausedChecked,moves:[...moves],errors},null,2));console.log('PASS',output);
}catch(e){await release();await capture('failure').catch(()=>{});const current=await state().catch(()=>null);writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:false,url,seen,current,errors,error:e.stack},null,2));console.error(current,errors);throw e;}finally{await context.close();await browser.close();}
