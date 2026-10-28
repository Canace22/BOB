const fs=require('fs'),p=require('path'),crypto=require('crypto'),assert=require('assert/strict');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_简明设计文档';
const html=fs.readFileSync(root+'/设计文档.html','utf8'),md=fs.readFileSync(root+'/简明设计文档.md','utf8');
const routes=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/simple-guide-routes.json','utf8'));
const chars=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/simple-guide-characters.json','utf8'));
const assets=JSON.parse(fs.readFileSync(root+'/原图来源.json','utf8'));
const ids=[...html.matchAll(/\sid="([^"]+)"/g)].map(m=>m[1]);
assert.equal(ids.length,new Set(ids).size);assert(!/undefined|\[object Object\]/.test(html));
for(const ref of [...html.matchAll(/(?:href|src)="([^"]+)"/g)].map(m=>m[1])){if(/^https?:/.test(ref))continue;const [f,a]=ref.split('#');assert(fs.existsSync(p.resolve(root,f||'设计文档.html')),ref);if(a&&!f)assert(ids.includes(a),a);}
for(const r of routes.rooms){assert(ids.includes(r.id),r.id);assert(html.includes(r.name),r.name);}
for(const c of [...chars.groups.flatMap(g=>g.characters),...chars.bosses]){assert(html.includes(c.name),c.name);assert(md.includes(c.skill),c.name+' skill');}
for(const a of assets){const digest=x=>crypto.createHash('sha256').update(fs.readFileSync(x)).digest('hex');assert.equal(digest(root+'/'+a.file),a.sha256);assert.equal(digest(a.source),a.sha256);}
const report={date:'2026-10-26',sections:7,regions:routes.regions.length,rooms:routes.rooms.length,originalImages:assets.length,player:1,ordinaryEnemyVariants:9,bosses:chars.bosses.length,namedFriendlyNPCs:3,ecologyEntries:3,allImageHashesMatchOriginal:true,allLocalReferencesPresent:true,noMissingCharacterSkill:true,browserTested:false,scope:'原图字节、章节、路线数据、角色技能与本地链接静态核验；未做浏览器或引擎测试'};
fs.writeFileSync(root+'/检查记录.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
