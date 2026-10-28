import { chromium } from '/Users/canace/.codex/skills/develop-web-game/node_modules/playwright/index.mjs';
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const out=new URL('../output/playthrough/',import.meta.url);
await mkdir(out,{recursive:true});
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
const errors=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const game=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const tick=(frames)=>page.evaluate(f=>window.advanceTime(f*1000/60),frames);
const screenshot=async(name)=>{await page.screenshot({path:fileURLToPath(new URL(name+'.png',out))});await writeFile(new URL(name+'.json',out),JSON.stringify(await game(),null,2));};
async function key(key,frames=1){await page.keyboard.down(key);await tick(frames);await page.keyboard.up(key);}
async function walk(x){const s=await game();const direction=x>s.player.x?'ArrowRight':'ArrowLeft';await key(direction,Math.round(Math.abs(x-s.player.x)/4.5));await tick(2);}
async function leap(x){
  const before=await game();const dir=x>before.player.x?'ArrowRight':'ArrowLeft';
  const frames=Math.round(Math.abs(x-before.player.x)/4.5);
  await page.keyboard.down(dir);await page.keyboard.down('Space');await tick(Math.min(22,frames));await page.keyboard.up('Space');
  if(frames>22){await tick(1);await page.keyboard.down('Space');await tick(frames-23);await page.keyboard.up('Space');}
  await page.keyboard.up(dir);await tick(90);
  if(!(await game()).player.grounded)await tick(35);
  const after=await game();
  assert.equal(after.deaths,before.deaths,`Unexpected fall en route to ${x}: ${JSON.stringify(after.player)}`);
  assert(after.player.grounded,`Not landed at ${x}`);
}
async function resonate(id){
  await key('KeyE');await tick(55);
  const activated=(await game()).activated;
  assert(activated.includes(id),`Node ${id} not activated`);
  await key('KeyE');await tick(55);
  assert.deepEqual((await game()).activated,activated,'Repeated resonance changed activation count');
}
try{
  await page.goto('http://127.0.0.1:4173/');
  await page.locator('#start-btn:not([disabled])').waitFor();
  await screenshot('00-title');
  await page.click('#start-btn');await tick(240);
  await screenshot('01-mouth-start');
  await walk(410);await leap(650);await leap(850);
  // A closed baleen gate must physically stop the player.
  await walk(1000);assert((await game()).player.x<=935,'Closed gate can be crossed');
  await walk(865);await resonate('baleen');
  await screenshot('02-mouth-gate-open');
  await leap(1150);await walk(1300);await leap(1520);
  assert.equal((await game()).collected.length,1,'First memory missing');
  await leap(1800);await walk(2240);await key('KeyE');await tick(250);
  assert.equal((await game()).roomIndex,1);
  await screenshot('03-ribs-start');
  await walk(390);await leap(590);await resonate('bone-bridge');
  await walk(1190);await leap(1420);await leap(1770);
  assert.equal((await game()).collected.length,2,'Second memory missing');
  await screenshot('04-ribs-memory');
  await leap(2010);await leap(2300);await walk(2400);await key('KeyE');await tick(250);
  assert.equal((await game()).roomIndex,2);
  await screenshot('05-heart-start');
  await walk(365);await leap(580);await resonate('valve-1');
  await leap(920);await resonate('valve-2');
  await leap(1170);await leap(1360);await leap(1590);
  await leap(1900);await walk(1940);
  assert.equal((await game()).collected.length,3,'Third memory missing');
  await leap(2200);await walk(2330);await key('KeyE');await tick(55);
  assert.equal((await game()).mode,'playing','Exit opened without all three valves');
  assert.equal((await game()).exitOpen,false);
  await screenshot('06a-heart-exit-locked');
  await walk(2200);await leap(1940);await leap(1650);await resonate('valve-3');
  assert.equal((await game()).hazards.length,0,'Tide failed to clear hazards');
  await screenshot('06-heart-pump');
  await leap(1940);
  await leap(2200);await walk(2330);await key('KeyE');
  assert.equal((await game()).mode,'ending');
  await screenshot('07-ending');
  assert.equal(errors.length,0,errors.join('\n'));
  await writeFile(new URL('result.json',out),JSON.stringify({passed:true,errors,state:await game()},null,2));
  console.log('PASS: Real-keyboard three-room playthrough, closed gate collision, bridge, 3 valves, 3 memories, ending; no browser errors.');
}catch(e){await screenshot('failure');console.error(e);await writeFile(new URL('failure-errors.json',out),JSON.stringify(errors));process.exitCode=1;}
finally{await browser.close();}
