// One-time extension of the existing baseline, read from the recorded Git commit.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {collisionSignature} from './collision-signature.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const file=path.join(root,'assets/source/remaining-19-v2/input-contract.json');
const baseline=JSON.parse(fs.readFileSync(file));
if(baseline.collision)throw new Error('Baseline already recorded; refusing to replace.');
const rooms=JSON.parse(fs.readFileSync(path.join(root,'game/content/whalebelly/world/rooms.json'))).rooms;
baseline.collision=Object.fromEntries(rooms.map(({id})=>[id,collisionSignature(execFileSync('git',['show',`${baseline.head}:game/content/whalebelly/${id.slice(0,2).toLowerCase()}/${id}.tscn`],{cwd:root,encoding:'utf8'}))]));
fs.writeFileSync(file,JSON.stringify(baseline,null,2)+'\n');
