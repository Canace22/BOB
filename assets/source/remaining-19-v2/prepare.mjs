// Presentation-only additions to the user's accepted nineteen-room campaign.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const dir=path.join(root,'game/content/whalebelly/world/recipes');
const file=path.join(dir,'_world.json');
const data=JSON.parse(fs.readFileSync(file,'utf8'));
for(const [kit,art] of Object.entries({R2:'r2-lung-depth',R3:'r3-gastric-depth',R4:'r4-vertebrae-depth',R5:'r5-cranial-depth','R5-tail':'r5-tail-depth'}))data.kits[kit].depth={art};
fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const qa=path.join(root,'game/build/qa/remaining-19-v2');
const baseline={head:'600a95683d5a21951c83091d8422a692b465a549',r1:Object.fromEntries(Array.from({length:7},(_,i)=>{const p=`game/content/whalebelly/r1/R1-0${i+1}.tscn`;return[p,hash(path.join(root,p))]})),world_rooms_sha256:hash(path.join(root,'game/content/whalebelly/world/rooms.json'))};
fs.writeFileSync(path.join(qa,'frozen-input.json'),JSON.stringify(baseline,null,2));
console.log('Enabled five source-painted depth families; R1 snapshots retained.');
