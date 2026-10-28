import { chromium } from '/Users/canace/.codex/skills/develop-web-game/node_modules/playwright/index.mjs';
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1280,height:720}});
const errors=[];page.on('pageerror',e=>errors.push(e.message));
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const tick=(f)=>page.evaluate(frames=>window.advanceTime(frames*1000/60),f);
async function key(k,f=1){await page.keyboard.down(k);await tick(f);await page.keyboard.up(k);}
await mkdir(new URL('../output/recovery/',import.meta.url),{recursive:true});
try{
 await page.goto('http://127.0.0.1:4173/');await page.click('#start-btn');await tick(240);
 // Walking off the first shelf without jumping must respawn once, not loop.
 await key('ArrowRight',100);await tick(85);
 let s=await state();assert.equal(s.deaths,1);assert.equal(s.health,2);assert(s.player.x<200);
 const stable={x:s.player.x,health:s.health,deaths:s.deaths};await tick(180);s=await state();assert.deepEqual({x:s.player.x,health:s.health,deaths:s.deaths},stable);
 // Resonance far from a node must not activate it.
 await key('KeyE');assert.equal((await state()).activated.length,0);
 // Pause in midair, freeze everything, clear the held key on resume.
 await page.keyboard.down('ArrowRight');await key('Space',10);await key('Escape');await page.keyboard.up('ArrowRight');
 const frozen=await state();await tick(180);assert.deepEqual(await state(),frozen);await key('Escape');await tick(60);assert.equal((await state()).player.vx,0);
 await key('KeyM');assert.equal((await state()).mode,'map');await page.click('#overlay-close');assert.equal((await state()).mode,'playing');
 await key('KeyJ');assert.equal((await state()).mode,'journal');await key('Escape');assert.equal((await state()).mode,'playing');
 await key('Escape');await page.click('[data-menu="checkpoint"]');await tick(90);assert.equal((await state()).player.x,120);
 await page.screenshot({path:'output/recovery/respawn.png'});
 assert.equal(errors.length,0,errors.join('\n'));
 await writeFile(new URL('../output/recovery/result.json',import.meta.url),JSON.stringify({passed:true,checks:['one fall = one hit','stable safe respawn','out-of-range resonance','pause freezes state','resume clears inputs','map/journal close','checkpoint recovery'],errors,state:await state()},null,2));
 console.log('PASS: recovery, out-of-range resonance, pause/resume, map, journal and checkpoint.');
}catch(e){console.error(e);process.exitCode=1;}finally{await browser.close();}
