'use strict';
const fs=require('fs'),p=require('path'),assert=require('assert/strict'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_地图原画设计规范';
const read=f=>JSON.parse(fs.readFileSync(root+'/'+f,'utf8'));
const errors=[],check=(b,m)=>{if(!b)errors.push(m)};
const data=read('data/地图21项设计.json'),topo=read('data/地图拓扑.json'),rooms=read('data/房间布局.json').rooms;
const html=fs.readFileSync(root+'/地图原画设计册.html','utf8');
const ids=[...html.matchAll(/\sid="([^"]+)"/g)].map(m=>m[1]);
check(new Set(ids).size===ids.length,'Duplicate HTML ids');check(data.regions.length===5,'Region count');
for(const r of data.regions){check(r.sections.length===21,r.id+' sections');check(r.sections.map(s=>s.number).join(',')===Array.from({length:21},(_,i)=>i+1).join(','),r.id+' section order');for(const s of r.sections)check(ids.includes(r.id+'-s'+s.number),'Missing section anchor');const layers=r.sections.find(s=>s.number===20).blocks.find(b=>b.type==='table');check(layers.rows.length===6,r.id+' six layers');}
const sourceFiles=[];function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const f=p.join(dir,e.name);if(e.isDirectory())walk(f);else sourceFiles.push(f)}}walk(root);
for(const f of sourceFiles.filter(f=>f.endsWith('.html')||f.endsWith('.svg'))){const str=fs.readFileSync(f,'utf8');for(const m of str.matchAll(/(?:href|src)="([^"]+)"/g)){const ref=m[1];if(/^(?:https?:|data:|mailto:)/.test(ref))continue;const [part,anchor]=ref.split('#');const dest=part?p.resolve(p.dirname(f),part):f;check(fs.existsSync(dest),'Missing ref '+ref+' in '+p.basename(f));if(anchor&&dest.endsWith('地图原画设计册.html'))check(ids.includes(anchor),'Missing anchor '+ref);}}
const roomHashes=[];
for(const r of rooms){check(ids.includes('room-'+r.id),'Missing room '+r.id);const m=read('data/room-art/'+r.id+'.json');check(Boolean(m.prompt||m.englishPrompt),'Missing prompt');for(const ref of m.referenceRoles||[])check(fs.existsSync(root+'/'+ref.file),'Missing art reference '+ref.file);const b=fs.readFileSync(root+'/images/rooms/'+r.id+'.png');check(b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])),'PNG signature '+r.id);roomHashes.push(crypto.createHash('sha256').update(b).digest('hex'));}
check(new Set(roomHashes).size===36,'Independent room paintings');
const placement=fs.readFileSync(root+'/maps/总地图与关卡位置.svg','utf8');
for(const r of rooms)check(placement.includes('#room-'+r.id),'Room absent on total diagram '+r.id);
check(!/undefined|\[object Object\]/.test(html),'Bad templating placeholder');
check(topo.rooms.length===36&&topo.edges.length===39&&topo.checkpoints.length===8&&topo.travel.length===6,'Canon counts');
const report={date:'2026-10-26',regions:5,sections:105,rooms:36,topologyEdges:39,checkpoints:8,travelNodes:6,retainedArtworks:44,newRasterArtworks:0,newPlacementDiagrams:1,structureSvgFiles:sourceFiles.filter(f=>f.endsWith('.svg')).length,roomImageHashesUnique:new Set(roomHashes).size,htmlIds:ids.length,errors,validationScope:'内容覆盖、数据一致性、路径锚点、图片签名与独立性；新SVG已目检',browserTested:false,engineTested:false};
fs.writeFileSync(root+'/data/验收记录.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));assert.equal(errors.length,0);
