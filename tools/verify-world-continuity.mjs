import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..');
const dir=path.join(root,'assets/source/world-continuity-v1');
const book=path.join(root,'docs/鲸腹遗城原画集/连续世界设计/原画册.html');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const source=read(path.join(dir,'inputs/地图拓扑.json'));
const data=read(path.join(dir,'connections.json'));
const prompts=read(path.join(dir,'prompts.json'));
const failures=[];
const check=(pass,msg)=>{if(!pass)failures.push(msg);};
check(data.rooms.length===36 && data.edges.length===39,'room/edge counts');
check(new Set(data.edges.map(e=>e.id)).size===39,'unique edges');
check(JSON.stringify(data.rooms)===JSON.stringify(source.rooms),'preserve source rooms');
const known=new Set(data.rooms.map(r=>r.id));
for(const e of data.edges){const s=source.edges.find(v=>v.id===e.id);check(s && s.from===e.from && s.to===e.to,'edge endpoints '+e.id);for(const key of ['requiresAll','completionFlags','unlock'])check(JSON.stringify(e[key])===JSON.stringify(s[key]||(key==='unlock'?null:[])),key+' '+e.id);check(known.has(e.from)&&known.has(e.to),'known rooms '+e.id);check(e.landmark&&e.transition&&e.seamContract,'contract '+e.id);}
const html=fs.readFileSync(book,'utf8');
new vm.Script(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
const ids=new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]));
for(const m of html.matchAll(/\b(?:src|href)="([^"]+)"/g)){
  const url=m[1];if(url.startsWith('#')){check(ids.has(url.slice(1)),'anchor '+url);continue;}
  if(/^(https?:|data:)/.test(url))continue;
  check(fs.existsSync(path.resolve(path.dirname(book),decodeURIComponent(url.split('#')[0]))),'link '+url);
}
const review={
  '01-world':'整体尸体与器官轮廓连续，脊柱作轴、胸腹分隔可辨；艺术压缩，精确门表另附。',
  '02-r1-continuous':'主路、上层旧伤坡与须根侧袋融入单一鲸头；全景不等于工程碰撞布局。',
  '03-diaphragm-junction':'冷蓝肺缘/赭黄胃褶与斜向横膈区分清楚；裂孔/旧伤细节仍需局部定稿。',
  '04-abdomen-spine':'腹腔逐步露骨，上下路绕同一骨突并重会同一双贝台；门槛按表。',
  '05-spine-directions':'向头/向尾分两幅对照；头耳不是尾根邻房。耳周尺度、闸槽为概括表现。',
  '06-r1-seams':'三条接缝各有连续台面与共同远景；须幕只在口腔，咽后改为纵褶。',
};
const assets=[];
check(prompts.specs.length===6,'six prompt records');
for(const s of prompts.specs){const file=path.join(dir,'images',s.id+'.png');if(!fs.existsSync(file)){check(false,'image '+s.id);continue;}const b=fs.readFileSync(file);check(b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])),'PNG '+s.id);const width=b.readUInt32BE(16),height=b.readUInt32BE(20);check(width>=1500&&height>=600,'dimensions '+s.id);assets.push({id:s.id,title:s.title,file:'images/'+s.id+'.png',width,height,sha256:crypto.createHash('sha256').update(b).digest('hex'),status:'concept_reviewed_not_integrated',reviewer:'AI',visualReview:review[s.id],prompt:'prompts.json#'+s.id});}
check(assets.length===6,'six saved images');
const manifest={date:'2026-11-04',scope:'concept art only',integrationStatus:'not_integrated',userArtApproval:'not_requested_or_received',assets};
fs.writeFileSync(path.join(dir,'art-manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const report={rooms:data.rooms.length,edges:data.edges.length,art:assets.length,htmlScriptParsed:true,failures};
const out=path.join(root,'game/build/qa/world-continuity');fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'integrity.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));if(failures.length)process.exitCode=1;
