/* Concept topology checks only. No physics, combat, or engine execution. */
const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const root=process.argv[2]||'G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const t=JSON.parse(fs.readFileSync(path.join(root,'data/地图拓扑.json'),'utf8'));
const checks=[];
function test(name,fn){fn();checks.push({name,status:'PASS'});}
const rooms=new Set(t.rooms.map(r=>r.id));
const all=(flags,req=[])=>req.every(f=>flags.has(f));
const canCross=(e,from,flags)=> (from===e.from||(e.bidirectional&&from===e.to))&&all(flags,e.requiresAll)&&all(flags,e.completionFlags)&&(!e.unlock||flags.has(e.unlock.flag));
const canUnlock=(e,from,flags)=>!!e.unlock&&from===e.unlock.from&&all(flags,e.unlock.requiresAll)&&all(flags,e.unlock.completionFlags);
function closure({blockedRooms=[],blockedEvents=[],initialFlags=[],start=t.initial.room}={}){
 const flags=new Set(initialFlags),seen=new Set([start]),trace=[];
 let changed=true;
 while(changed){changed=false;const add=(f,via)=>{if(!flags.has(f)){flags.add(f);trace.push({flag:f,via});changed=true;}};
  for(const ev of t.events)if(seen.has(ev.room)&&!blockedEvents.includes(ev.id)&&all(flags,ev.requiresAll))for(const f of ev.grants)add(f,ev.id);
  for(const e of t.edges)if(e.unlock&&seen.has(e.unlock.from)&&canUnlock(e,e.unlock.from,flags))add(e.unlock.flag,'open@'+e.unlock.from);
  for(const e of t.edges)for(const [a,b]of[[e.from,e.to],[e.to,e.from]])if(seen.has(a)&&!blockedRooms.includes(b)&&canCross(e,a,flags)&&!seen.has(b)){seen.add(b);changed=true;}
 }
 return {flags,seen,trace};
}
function walkingOnly(flags,start=t.initial.room){
 const seen=new Set([start]);let change=true;
 while(change){change=false;for(const e of t.edges)for(const[a,b]of[[e.from,e.to],[e.to,e.from]])if(seen.has(a)&&canCross(e,a,flags)&&!seen.has(b)){seen.add(b);change=true;}}
 return seen;
}
test('固定规模：36房39边、30主结构与6选修、唯一ID',()=>{assert.equal(rooms.size,36);assert.equal(t.rooms.length,36);assert.equal(t.edges.length,39);assert.equal(new Set(t.edges.map(e=>e.id)).size,39);assert.equal(t.rooms.filter(r=>r.kind==='optional').length,6);assert.equal(t.rooms.filter(r=>r.kind==='main_structure').length,30);});
test('所有连接、事件、营地、交通、生态、碎片都引用既有房',()=>{for(const e of t.edges){assert(rooms.has(e.from));assert(rooms.has(e.to));assert.deepEqual(e.requiresAll,e.requires);}for(const e of t.events)assert(rooms.has(e.room));for(const list of[t.checkpoints,t.travel,t.habitats.rooms])for(const v of list)assert(rooms.has(v.room));for(const id of t.fragments)assert(rooms.has(id));});
const known=new Set(t.events.flatMap(e=>e.grants).concat(t.edges.filter(e=>e.unlock).map(e=>e.unlock.flag)));
test('所有能力/旗标门有来源，胜利与静默事件不串房',()=>{for(const e of t.edges)for(const f of[...e.requiresAll,...e.completionFlags,...(e.unlock?[...e.unlock.requiresAll,...e.unlock.completionFlags]:[])])assert(known.has(f),f);for(const e of t.events)for(const f of e.requiresAll)assert(known.has(f));for(const id of['R1-04','R2-04','R4-05'])assert(!t.rooms.find(r=>r.id===id).grantWhen.includes('R5-04'));assert.equal(t.events.find(e=>e.grants.includes('S')).room,'R5-04');});
test('初始步行仅到首Boss入口，不自动授能或胜利',()=>{assert.deepEqual([...walkingOnly(new Set())].sort(),['R1-01','R1-02','R1-03','R1-04']);});
test('只拥有五能力不等于Boss胜利，三战后出口和三捷径仍不能绕入',()=>{const f=new Set(['A1','A2','A3','A4','A5']);for(const[a,b]of[['R1-04','R1-05'],['R2-04','R2-05'],['R5-04','R5-05']]){const e=t.edges.find(e=>e.from===a&&e.to===b);assert(!canCross(e,a,f));assert(!canCross(e,b,f));}for(const e of t.edges.filter(e=>e.unlock)){assert(!canCross(e,e.from,f));assert(!canCross(e,e.to,f));assert(!canUnlock(e,e.unlock.from,f));}});
test('完整探索静态可到36房并获得END',()=>{const s=closure();assert.equal(s.seen.size,36);assert(s.flags.has('END'));});
test('胃肠先行：不进肺心即得A3，随后两支汇合可END',()=>{const blocked=t.rooms.filter(r=>r.region==='R2').map(r=>r.id),s=closure({blockedRooms:blocked});assert(s.flags.has('A3'));assert(!s.flags.has('A2'));assert(!s.flags.has('P'));assert(!s.seen.has('R4-01'));assert(closure({initialFlags:[...s.flags]}).flags.has('END'));});
test('肺心先行：不走肠侧即得A2/P，随后两支汇合可END',()=>{const blocked=t.rooms.filter(r=>r.region==='R3'&&r.id!=='R3-01').map(r=>r.id),s=closure({blockedRooms:blocked});assert(s.flags.has('A2'));assert(s.flags.has('P'));assert(!s.flags.has('A3'));assert(!s.seen.has('R4-01'));assert(closure({initialFlags:[...s.flags]}).flags.has('END'));});
test('母蟹可选：不进R3-07且不击败仍能END，食道捷径保持锁定',()=>{const s=closure({blockedRooms:['R3-07'],blockedEvents:['EV_BOSS_R3']});assert(s.flags.has('END'));assert(!s.flags.has('BOSS_R3'));assert(!s.flags.has('SC_ESOPHAGUS'));});
test('断脊上/下路线任择其一能END',()=>{for(const blocked of['R4-03','R4-04'])assert(closure({blockedRooms:[blocked]}).flags.has('END'));});
test('未完成静默仍可返程，但无S不能到释放槽',()=>{const s=closure({blockedEvents:['EV_S']});assert(s.flags.has('BOSS_R5'));assert(s.seen.has('R5-05'));assert(s.seen.has('R5-07'));assert(!s.seen.has('R5-08'));assert(!s.flags.has('END'));});
test('尾门逐项检查P+B+S；缺任一项不通过',()=>{const e=t.edges.find(e=>e.from==='R5-07'&&e.to==='R5-08');for(const missing of['P','B','S'])assert(!canCross(e,e.from,new Set(['P','B','S'].filter(f=>f!==missing))));assert(canCross(e,e.from,new Set(['P','B','S'])));});
test('3捷径未开时不能通行，只有远侧可开，开后双向',()=>{const s=closure();for(const e of t.edges.filter(e=>e.unlock)){const f=new Set(s.flags);f.delete(e.unlock.flag);assert(!canCross(e,e.from,f));assert(!canCross(e,e.to,f));assert(canUnlock(e,e.unlock.from,f));const near=e.unlock.from===e.from?e.to:e.from;assert(!canUnlock(e,near,f));f.add(e.unlock.flag);assert(canCross(e,e.from,f));assert(canCross(e,e.to,f));}});
test('授能不依赖进入后的未得能力；3内部动作门必须有能力',()=>{for(const [a,b,f]of[['R2-01','R2-02','A2'],['R3-05','R3-06','A3'],['R5-02','R5-03','A5']]){const e=t.edges.find(e=>e.from===a&&e.to===b);assert(!canCross(e,a,new Set()));assert(canCross(e,a,new Set([f])));assert(t.events.some(ev=>ev.room===a&&ev.grants.includes(f)&&!ev.requiresAll.includes(f)));}});
test('8营地6旅行节点落位；旅行需B与两端亲访调律',()=>{assert.equal(t.checkpoints.length,8);assert.equal(t.travel.length,6);assert.equal(new Set(t.checkpoints.map(x=>x.room)).size,8);assert.equal(new Set(t.travel.map(x=>x.room)).size,6);const tune=(n,flags,visits,at)=>at===n.room&&visits.has(n.room)&&all(flags,n.activation.requiresAll);const travel=(a,b,flags,at)=>at===a.room&&flags.has('B')&&flags.has(a.activation.flag)&&flags.has(b.activation.flag);for(const n of t.travel){assert(!tune(n,new Set(),new Set([n.room]),n.room));assert(!tune(n,new Set(['B']),new Set(),n.room));assert(tune(n,new Set(['B']),new Set([n.room]),n.room));}const[a,b]=t.travel;assert(!travel(a,b,new Set(['B',a.activation.flag]),a.room));assert(travel(a,b,new Set(['B',a.activation.flag,b.activation.flag]),a.room));});
test('8固定碎片=4主结构+4选修；6栖息地不成为主门',()=>{assert.equal(new Set(t.fragments).size,8);const opt=new Set(t.rooms.filter(r=>r.kind==='optional').map(r=>r.id));assert.equal(t.fragments.filter(id=>opt.has(id)).length,4);assert.equal(t.habitats.rooms.length,6);assert(!t.edges.some(e=>e.requiresAll.some(f=>/^H\d$/.test(f))));});
const result={version:'V5.1',method:'单调永久旗标+可达房间闭包；事件满足后可由玩家完成；未模拟动作、敌人或碰撞',passed:checks.length,failed:0,checks,limitations:['静态可达性不证明跳跃尺寸可行','未测战斗难度、手感、回跑时间或存档实现','旅行只验证节点授权规则；未把旅行当初次探索捷径'],counts:{rooms:t.rooms.length,edges:t.edges.length,checkpoints:t.checkpoints.length,travel:t.travel.length,shortcuts:t.edges.filter(e=>e.unlock).length,fragments:t.fragments.length}};
fs.writeFileSync(path.join(root,'data/拓扑验证结果.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
