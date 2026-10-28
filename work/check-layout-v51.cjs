const fs=require('fs'),assert=require('assert/strict');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const l=JSON.parse(fs.readFileSync(root+'/data/房间布局.json')),t=JSON.parse(fs.readFileSync(root+'/data/地图拓扑.json'));
let doors=0,platforms=0;const failures=[];
function check(b,m){if(!b)failures.push(m);}
for(const r of l.rooms){const locations=new Set();for(const p of r.platforms){platforms++;check(p.x>=0&&p.y>=0&&p.x+p.w<=r.width+.001&&p.y<=r.height,r.id+' platform '+p.id);}
for(const d of r.doors){doors++;const e=t.edges.find(e=>e.id===d.id);check(!!e,r.id+' missing edge '+d.id);if(e){check([e.from,e.to].includes(r.id)&&[e.from,e.to].includes(d.to),r.id+' edge endpoints');check(JSON.stringify(d.condition.requiresAll)===JSON.stringify(e.requiresAll),r.id+' edge ability');check(JSON.stringify(d.condition.completionFlags)===JSON.stringify(e.completionFlags),r.id+' edge completion');check(JSON.stringify(d.condition.unlock??null)===JSON.stringify(e.unlock??null),r.id+' edge unlock');}
const key=d.x+','+d.y;check(!locations.has(key),r.id+' duplicate door');locations.add(key);check(d.x>=0&&d.y>=0&&d.x<=r.width&&d.y<=r.height,r.id+' door bounds');}
for(const v of [...r.enemies,...r.rewards,...r.hazards])check(v.x>=0&&v.y>=0&&v.x<=r.width&&v.y<=r.height,r.id+' object bounds');
check(r.walkthrough.length>=2,r.id+' missing walkthrough');}
check(l.rooms.length===36,'room count');check(doors===78,'door count');check(l.rooms.filter(r=>r.checkpoint).length===8,'camp count');check(l.rooms.filter(r=>r.travel).length===6,'travel count');
const result={scope:'数据一致性与坐标边界，不是运动仿真；未把尺寸边界当成真实可通关证明',rooms:l.rooms.length,platforms,doors,failures};
fs.writeFileSync(root+'/data/布局复核.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result));assert.equal(failures.length,0);

