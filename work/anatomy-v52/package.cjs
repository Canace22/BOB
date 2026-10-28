'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计';
const work='G:/鲸落万物生/BOB/work/anatomy-v52';
fs.mkdirSync(root+'/data/build',{recursive:true});
for(const f of ['build.cjs','build-diagrams.cjs','build-room-locators.cjs','verify.cjs','package.cjs','placement.json'])fs.copyFileSync(work+'/'+f,root+'/data/build/'+f);
fs.writeFileSync(root+'/制作与复核说明.md',`# V5.2 地图解剖与尺度修订

基于既有 V5.2 地图规范完成，保留第五版主角、能力、五域36房39边及其条件。原版本未修改。

- 五域各21项，共105项；逐房部位落点、逐边连接依据、总图、六个关键转场及尺度说明。
- 新绘19张：整鲸1、区域6、房间12；沿用24张房间画。当前共展示43张原画。
- 120米巨鲸是明确的幻想设计，30厘米主角不变。器官位置参考鲸类构型；创伤、聚落改造和超大尺度属于原创设定。
- 耳区六房与尾柄两房分别定位；跨越长距离的连接有方向、路程和地标过渡，不解释为相邻小门。
- 所有图均为概念设计；碰撞、动作手感和真实通关未在引擎测试。原画目检及静态结构核验记录见 data/验收记录.json。

直接打开原画册.html，图片、结构图和文档均在本包。返回历史版本的链接需要同级旧版文件夹，不影响本册阅读。

实际新图英文提示词、参考和审阅记录位于 data/anatomy-art；保留房间的历史记录位于 data/room-art-retained。参考图在 references。data/build 保存重建脚本；脚本使用原项目绝对路径，跨机器重建需调整路径并保留旧版源数据。离线阅读不需要运行脚本。

交付清单列出每个文件的 SHA-256。验收范围是静态内容和文件完整性，不代表浏览器、引擎或生物解剖测量认证。
`);
const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(d,e.name)):[path.join(d,e.name)]);
const files=walk(root).filter(f=>path.basename(f)!=='交付清单.json').sort().map(f=>{const b=fs.readFileSync(f);return {file:path.relative(root,f).replace(/\\/g,'/'),bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')};});
const manifest={edition:'V5.2 完整游戏设计 · 地图解剖与尺度修订',regions:5,sections:105,rooms:36,edges:39,newArtworks:19,retainedArtworks:24,fileCount:files.length,bytes:files.reduce((s,f)=>s+f.bytes,0),files};
fs.writeFileSync(root+'/交付清单.json',JSON.stringify(manifest,null,2));
console.log(JSON.stringify({files:manifest.fileCount,bytes:manifest.bytes}));
