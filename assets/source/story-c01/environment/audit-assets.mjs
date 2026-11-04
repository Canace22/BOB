import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

const base=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(base,'../../../..');
const entries=JSON.parse(fs.readFileSync(path.join(base,'manifest-additions.json'),'utf8')).entries;
const records=entries.map(entry=>{
  const bytes=fs.readFileSync(path.join(root,entry.src));
  if(bytes.subarray(0,8).toString('hex')!=='89504e470d0a1a0a') throw new Error('Not a PNG entity: '+entry.src);
  return {...entry,width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20),
    sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
});
fs.writeFileSync(path.join(base,'asset-lineage.json'),JSON.stringify({
  status:'integration-candidate',entries:records
},null,2)+'\n');
console.log('Verified '+records.length+' PNG entities and saved provenance hashes; runtime remains a separate check.');
