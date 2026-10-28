'use strict';
const fs=require('fs'),p=require('path'),assert=require('assert/strict'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计',base='G:/鲸落万物生/outputs/鲸落万物生_V5.2_地图原画设计规范';
const read=(r,f)=>JSON.parse(fs.readFileSync(r+'/'+f,'utf8'));
const doc=read(root,'data/地图21项设计.json'),topo=read(root,'data/地图拓扑.json'),layout=read(root,'data/房间布局.json'),place=read(root,'data/鲸体位置与连接.json'),oldTopo=read(base,'data/地图拓扑.json'),oldLayout=read(base,'data/房间布局.json');
const errors=[],check=(b,m)=>{if(!b)errors.push(m)};
check(doc.regions.length===5&&doc.regions.every(r=>r.sections.length===21),'5 x 21 sections');
check(place.rooms.length===36&&new Set(place.rooms.map(r=>r.id)).size===36,'36 anatomical placements');
check(place.edges.length===39&&new Set(place.edges.map(r=>r.id)).size===39,'39 transition reasons');
const keys=['id','from','to','requires','requiresAll','completionFlags','bidirectional'];
for(const e of topo.edges){const old=oldTopo.edges.find(o=>o.id===e.id);check(keys.every(k=>JSON.stringify(e[k])===JSON.stringify(old[k])),'Changed route rule '+e.id);const detail=place.edges.find(o=>o.id===e.id);check(Boolean(detail?.via&&detail.why&&detail.nature),'Missing anatomy reason '+e.id);check((old.completionFlags||[]).every(f=>(detail.completionFlags||[]).includes(f)),'Lost Boss exit requirement '+e.id);}
for(const r of layout.rooms){const old=oldLayout.rooms.find(o=>o.id===r.id);check(r.width===old.width&&r.height===old.height,'Changed room size '+r.id);check(JSON.stringify(r.platforms)===JSON.stringify(old.platforms),'Changed platform geometry '+r.id);check(Boolean(r.anatomy?.part&&r.anatomy?.position),'Missing part '+r.id);check(fs.existsSync(root+'/maps/room-locator-'+r.id+'.svg'),'Missing locator '+r.id);}
check(place.scale.whaleLengthM===120&&place.scale.heroHeightM===0.3&&place.scale.fictional===true,'Explicit fictional scale');
check(!topo.edges.some(e=>(e.from==='R5-05'&&e.to==='R5-07')||(e.from==='R5-07'&&e.to==='R5-05')),'No head-tail direct tunnel');
const html=fs.readFileSync(root+'/原画册.html','utf8'),ids=[...html.matchAll(/\sid="([^"]+)"/g)].map(m=>m[1]);check(ids.length===new Set(ids).size,'Duplicate HTML IDs');
check(!/undefined|\[object Object\]/.test(html),'Bad template serialization');
const files=[];function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const f=p.join(d,e.name);if(e.isDirectory())walk(f);else files.push(f)}}walk(root);
for(const f of files.filter(f=>/\.(html|svg)$/.test(f))){const s=fs.readFileSync(f,'utf8');for(const m of s.matchAll(/(?:href|src)="([^"]+)"/g)){const ref=m[1];if(/^(?:https?:|data:|mailto:)/.test(ref))continue;const [rel,anchor]=ref.split('#');const dest=rel?p.resolve(p.dirname(f),rel):f;check(fs.existsSync(dest),'Missing local reference '+ref+' in '+p.basename(f));if(anchor&&dest.endsWith('原画册.html')&&dest===p.resolve(root,'原画册.html'))check(ids.includes(anchor),'Missing anchor '+ref);}}
const newIds=['WORLD','R1','R2','R3','R4','R5-head','R5-tail','R1-05','R1-06','R2-05','R4-06',...Array.from({length:8},(_,i)=>'R5-'+String(i+1).padStart(2,'0'))];
const hashes=[];for(const id of newIds){const f=root+'/images/anatomy/'+(/^R\d-\d{2}$/.test(id)?'rooms/':'')+id+'.png';check(fs.existsSync(f),'Missing new art '+id);const m=read(root,'data/anatomy-art/'+id+'.json');check(Boolean(m.prompt||m.englishPrompt),'Missing actual prompt '+id);check(Boolean(m.review),'Missing visual review '+id);const b=fs.readFileSync(f);check(b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])),'Invalid PNG '+id);hashes.push(crypto.createHash('sha256').update(b).digest('hex'));}
check(new Set(hashes).size===19,'19 unique new images');
const displayed=[...new Set([...html.matchAll(/<img[^>]+src="([^"]+)"/g)].map(m=>m[1]).filter(f=>f.startsWith('images/')))];check(displayed.length===43,'43 active paintings, got '+displayed.length);
check(displayed.filter(f=>f.startsWith('images/anatomy/')).length===19,'19 new paintings displayed');
check(!html.includes('images/M01.png')&&!html.includes('images/regions/'),'No retired world or area artwork in current page');
const report={edition:'V5.2 地图解剖与尺度修订',regions:5,sections:105,rooms:36,edgesWithAnatomy:39,roomLocators:36,newArtworks:19,retainedRoomArtworks:24,displayedArtworks:displayed.length,topologyConditionsUnchanged:true,platformCoordinatesUnchanged:true,fictionalWhaleLengthM:120,heroHeightM:0.3,errors,browserInteractionTested:false,enginePhysicsTested:false,scope:'图片目检、结构数据/编号/本地路径静态核验；地理解剖逻辑为参考资料支持下的原创设计，不是医学剖面认证'};
fs.writeFileSync(root+'/data/验收记录.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));assert.equal(errors.length,0);
