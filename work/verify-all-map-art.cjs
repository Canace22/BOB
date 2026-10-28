const fs=require('fs'),p=require('path'),assert=require('assert/strict'),vm=require('vm'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const read=f=>JSON.parse(fs.readFileSync(root+'/'+f,'utf8'));
const html=fs.readFileSync(root+'/地图设计册.html','utf8'),rooms=read('data/房间布局.json').rooms;
const errors=[],ok=(b,m)=>{if(!b)errors.push(m);};
const ids=[...html.matchAll(/\sid="([^"]+)"/g)].map(x=>x[1]);ok(new Set(ids).size===ids.length,'duplicate HTML IDs');
const refs=[...html.matchAll(/(?:href|src)="([^"]+)"/g)].map(m=>m[1]);
for(const ref of refs){if(ref.startsWith('#'))ok(ids.includes(ref.slice(1)),'missing anchor '+ref);else if(!/^(https?:|data:|mailto:)/.test(ref)){const local=ref.split('#')[0];ok(fs.existsSync(p.resolve(root,local)),'missing file '+local);}}
const hashes=[];let imageCount=0;for(const r of rooms){const file=root+'/images/rooms/'+r.id+'.png';ok(fs.existsSync(file),'missing room art '+r.id);ok(html.includes('data-art-id="'+r.id+'"'),'room not integrated '+r.id);const meta=read('data/room-art/'+r.id+'.json');ok(meta.id===r.id,'metadata mismatch '+r.id);ok(typeof(meta.prompt||meta.englishPrompt)==='string','prompt missing '+r.id);const b=fs.readFileSync(file);ok(b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])),'PNG invalid '+r.id);hashes.push(crypto.createHash('sha256').update(b).digest('hex'));imageCount++;}
ok(new Set(hashes).size===36,'duplicated room bitmap');
for(let n=1;n<=5;n++){const file=root+'/images/regions/R'+n+'.png';ok(fs.existsSync(file),'region missing '+n);const meta=read('data/region-art/R'+n+'.json');ok(meta.id==='R'+n,'region metadata mismatch');imageCount++;}
const gallery=JSON.parse(html.match(/<script type="application\/json" id="all-art-data">([\s\S]*?)<\/script>/)[1]);ok(gallery.length===41,'gallery count');ok(new Set(gallery.map(a=>a.id)).size===41,'gallery duplicate IDs');
for(const f of ['atlas.js','all-art.js'])new vm.Script(fs.readFileSync(root+'/'+f,'utf8'));
const client=fs.readFileSync(root+'/atlas.js','utf8');
ok(client.includes("$$('.room-card > details:not(.art-production)').forEach"),'expand-all must use the plural selector');
ok(!/(?<!\$)\$\((['"])[^'"]*\1\)\.forEach/.test(client),'single-node selector cannot be iterated with forEach');
const result={newPaintings:imageCount,roomPaintings:36,regionPaintings:5,retainedPaintings:3,totalPaintings:44,uniqueRoomHashes:new Set(hashes).size,htmlIDs:ids.length,errors,browserInteractionTested:false,geometryTestedInEngine:false,notes:['逐图已作概念审阅与必要修图','PNG为合成原画；SVG/JSON为结构依据','网页脚本通过语法及引用检查，未做浏览器实机交互验收']};
fs.writeFileSync(root+'/data/全地图原画验收.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,2));assert.equal(errors.length,0);
