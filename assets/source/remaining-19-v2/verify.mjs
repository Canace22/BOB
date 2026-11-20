// Read-only batch audit. Run from any directory after world-room generation.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {collisionSignature} from './collision-signature.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const read=p=>fs.readFileSync(path.join(root,p));
const json=p=>JSON.parse(read(p));
const hash=p=>crypto.createHash('sha256').update(read(p)).digest('hex');
const baseline=json('assets/source/remaining-19-v2/input-contract.json');
const manifest=json('game/art/manifest.json').entries;
const catalog=new Map(json('assets/catalog.json').assets.map(a=>[a.id,a]));
const checks=[];
const check=(name,pass)=>{checks.push({name,pass});console.log(`${pass?'PASS':'FAIL'} ${name}`)};
for(const [p,expected] of Object.entries(baseline.r1)) check(p+' unchanged',hash(p)===expected);
check('complete twelve-room gameplay table unchanged',hash('game/content/whalebelly/world/rooms.json')===baseline.world_rooms_sha256);
for(const id of ['r2-lung-depth','r3-gastric-depth','r4-vertebrae-depth','r5-cranial-depth','r5-tail-depth','red-tether-segment','r3-shell-nest-before']) {
 const asset=catalog.get(id),entry=manifest.find(e=>e.dest===`world-kit/${id}.png`);
 check(id+' uses registered native source',!!entry&&entry.src===asset.file);
 if(!entry.max)check(id+' runtime bytes equal source',hash(asset.file)===hash('game/art/'+entry.dest));
 else {
  const png=read('game/art/'+entry.dest),scale=Math.min(1,entry.max/Math.max(asset.width,asset.height));
  check(id+' runtime has declared uniform export size',png.readUInt32BE(16)===Math.round(asset.width*scale)&&png.readUInt32BE(20)===Math.round(asset.height*scale));
  check(id+' original source hash preserved',hash(asset.file)===asset.sha256);
 }
}
const expected={'R2':'r2-lung-depth','R3':'r3-gastric-depth','R4':'r4-vertebrae-depth','R5':'r5-cranial-depth'};
const retiredFar=Object.values(json('game/content/whalebelly/world/recipes/_world.json').kits).map(kit=>`world-kit/${kit.far.art}.png`);
for(const room of json('game/content/whalebelly/world/rooms.json').rooms) {
 const id=room.id,region=id.slice(0,2),scene=read(`game/content/whalebelly/${region.toLowerCase()}/${id}.tscn`).toString();
 const recipe=json(`game/content/whalebelly/world/recipes/${id}.json`);
 const depth=recipe.reference_background?.art??(id==='R5-08'?'r5-tail-depth':expected[region]);
 check(id+' selected source depth is rendered',scene.includes(`world-kit/${depth}.png`));
 check(id+' no duplicate transparent far painting',retiredFar.every(file=>!scene.includes(file)));
 check(id+' collision nodes and one-way settings unchanged',collisionSignature(scene)===baseline.collision[id]);
}
const failure=checks.filter(c=>!c.pass).length;
const out=process.env.SOURCE_QA_OUT??'game/build/qa/remaining-19-v2/source-audit.json';
fs.writeFileSync(path.join(root,out),JSON.stringify({checks,failures:failure},null,2)+'\n');
if(failure)process.exitCode=1;
