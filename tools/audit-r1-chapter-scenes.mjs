// Read-only recovery/coverage gate. Does not regenerate any accepted artwork.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const spec=JSON.parse(fs.readFileSync('assets/source/r1-chapter-scenes/chapter.json','utf8'));
const rooms=JSON.parse(fs.readFileSync('game/art/whalebelly/rooms.json','utf8'));
const manifest=JSON.parse(fs.readFileSync('game/art/manifest.json','utf8'));
const problems=[],ids=new Set();let pngs=0;
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
for(const room of spec.rooms){
 const current=rooms.find(r=>r.id===room.id);
 if(JSON.stringify(current.doors)!==JSON.stringify(room.doors))problems.push(room.id+' door metadata changed');
 const source=fs.readFileSync(`${room.master}/original-room.tscn.txt`,'utf8');
 const scene=fs.readFileSync(`game/content/whalebelly/r1/${room.id}.tscn`,'utf8');
 const polygons=text=>[...text.matchAll(/^polygon = PackedVector2Array\([^\n]+/gm)].map(m=>m[0].trim());
 if(JSON.stringify(polygons(source))!==JSON.stringify(polygons(scene)))problems.push(room.id+' terrain collision declarations changed');
 if(!scene.includes('instance=ExtResource("chapter")'))problems.push(room.id+' environment instance missing');
 if(sha(`game/art/whalebelly/reference/r1/${room.id}.png`)!==room.source_sha256)problems.push(room.id+' original reference changed');
 const map=JSON.parse(fs.readFileSync(room.master+'/export-map.json','utf8'));
 const environment=fs.readFileSync(`game/content/whalebelly/environment/chapter/${room.id}.tscn`,'utf8');
 for(const element of room.elements){
  if(ids.has(element.id))problems.push('duplicate ID '+element.id);ids.add(element.id);
  if(['flex','lamp','water'].includes(element.kind)){
   const out=map.elements.find(e=>e.id===element.id);
   if(!out||out.pixels<=0)problems.push('empty/missing cutout '+element.id);
   if(!environment.includes(element.id+'.png'))problems.push('unused cutout '+element.id);
  }
 }
 for(const filename of fs.readdirSync(room.runtime).filter(n=>n.endsWith('.png'))){
  const src=path.join(room.runtime,filename),dest=`game/art/r1-chapter-scenes/${room.id}/${filename}`;
  if(!manifest.entries.some(e=>e.dest===`r1-chapter-scenes/${room.id}/${filename}`))problems.push('unregistered '+src);
  if(!fs.existsSync(dest)||sha(src)!==sha(dest))problems.push('sync mismatch '+dest);
  pngs++;
 }
}
const result={rooms:spec.rooms.length,inventory_ids:ids.size,png_exports:pngs,problems};
const stateFile='assets/source/r1-chapter-scenes/pipeline-state.json';
if(fs.existsSync(stateFile)){
 const accepted=JSON.parse(fs.readFileSync(stateFile,'utf8'));
 for(const entry of [...(accepted.shared_inputs??[]),...accepted.rooms.flatMap(r=>r.accepted_files)]){
  if(!fs.existsSync(entry.path)||sha(entry.path)!==entry.sha256)problems.push('accepted input changed; revalidate '+entry.path);
 }
}
console.log(JSON.stringify(result,null,2));
if(problems.length)process.exitCode=1;
