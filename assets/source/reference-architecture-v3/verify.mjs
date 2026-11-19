import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
const contract=read('assets/source/reference-architecture-v3/source-contract.json');
const catalog=new Map(read('assets/catalog.json').assets.map(a=>[a.id,a]));
const checks=[];
const check=(name,pass)=>{checks.push({name,pass});console.log((pass?'PASS ':'FAIL ')+name)};
for(const item of contract.assets){
 check(item.id+' original source retained',hash(item.source)===item.sha256);
 if(!item.selected)continue;
 check(item.id+' library bytes equal original',hash(catalog.get(item.id).file)===item.sha256);
 check(item.id+' runtime bytes equal original',hash('game/art/world-kit/'+item.id+'.png')===item.sha256);
}
const recipe=read('game/content/whalebelly/world/recipes/R5-01.json');
check('three progress flags preserve their original meanings',JSON.stringify(recipe.progress_slots.map(s=>s.flag))==='["pressure","bone","silence"]');
const camp=read('game/content/whalebelly/world/recipes/R3-01.json');
check('two resident identities remain at original positions',camp.interactables[0].art==='yusuo'&&camp.interactables[1].art==='beituo'&&JSON.stringify(camp.interactables[0].at)==='[17.4,26]'&&JSON.stringify(camp.interactables[1].at)==='[21,26]');
const failures=checks.filter(c=>!c.pass).length;
fs.writeFileSync(path.join(root,'game/build/qa/reference-architecture-v3/source-audit.json'),JSON.stringify({checks,failures},null,2)+'\n');
if(failures)process.exitCode=1;
