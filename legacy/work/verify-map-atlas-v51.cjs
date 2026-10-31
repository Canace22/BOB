const fs=require('fs'),vm=require('vm');
const OUT='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const h=fs.readFileSync(OUT+'/地图设计册.html','utf8');
const ids=[...h.matchAll(/\sid="([^"]+)"/g)].map(x=>x[1]);
const data=JSON.parse(h.match(/<script id="map-data" type="application\/json">([\s\S]*?)<\/script>/)[1]);
const duplicateIDs=ids.filter((x,i)=>ids.indexOf(x)!==i);
const brokenAnchors=[...new Set([...h.matchAll(/href="#([^"]+)"/g)].map(m=>m[1]).filter(id=>!ids.includes(id)))];
const result={htmlIDs:ids.length,duplicateIDs,brokenAnchors,embeddedRooms:data.topo.rooms.length,scriptSyntax:'passed'};
const client=fs.readFileSync(OUT+'/atlas.js','utf8');new vm.Script(client);
const sets=vm.runInNewContext('('+client.match(/const sets=(\{.*?\});/)[1]+')');
const aliases={none:'start',dash:'dash',lung:'lung',gut:'gut',join:'join',spine:'bone',end:'final'};
const stageMismatches=[];for(const [ui,id]of Object.entries(aliases)){const canonical=data.topo.stages.find(s=>s.id===id).flags;if([...sets[ui]].sort().join()!==[...canonical].sort().join())stageMismatches.push(ui)}
const edgeOpen=vm.runInNewContext('('+client.slice(client.indexOf('function edgeOpen('),client.indexOf('function preview('))+')');
const missingFlags=[...new Set(data.topo.stages.flatMap(s=>s.flags))].filter(f=>!data.conditions.includes(f));
const ear=data.topo.edges.find(e=>e.id==='E30');
result.stagePresets=stageMismatches.length?'mismatch':'all match topology';result.missingStageFlags=missingFlags;
result.shortcutRequiresAbilityAndOpenFlag=!edgeOpen(ear,new Set(['SC_EAR']))&&!edgeOpen(ear,new Set(['A5']))&&edgeOpen(ear,new Set(['A5','SC_EAR']));
fs.writeFileSync(OUT+'/data/图册交互静态复核.json',JSON.stringify({...result,scope:'Node 静态解析与纯条件函数校验，不是浏览器交互或引擎通关测试'},null,2));
console.log(JSON.stringify(result));
try{console.log(require.resolve('jsdom',{paths:['C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules']}))}catch{console.log('jsdom unavailable')}
if(duplicateIDs.length||brokenAnchors.length||stageMismatches.length||missingFlags.length||!result.shortcutRequiresAbilityAndOpenFlag)process.exitCode=1;
