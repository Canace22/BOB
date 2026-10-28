'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(d,e.name)):[path.join(d,e.name)]);
const files=walk(root).filter(f=>path.basename(f)!=='交付清单.json').sort().map(f=>{const b=fs.readFileSync(f);return {file:path.relative(root,f).replace(/\\/g,'/'),bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')};});
const report={version:'V5.1 全地图原画补全',rooms:36,edges:39,doors:78,platforms:198,newPaintings:41,regionPaintings:5,roomPaintings:36,retainedPaintings:3,totalPaintings:44,structureSvgs:42,checkpoints:8,travel:6,topologyChecksPassed:16,browserInteractionTested:false,engineTested:false,notes:['新增41张独立生成PNG，既有3张保留；参考图不计入原画数量。','原画表达美术与玩法意图，结构SVG和JSON为精确布局依据。','清单不包含自身；所有文件SHA256用于离线包完整性核验。'],fileCount:files.length,totalBytes:files.reduce((s,f)=>s+f.bytes,0),files};
fs.writeFileSync(root+'/交付清单.json',JSON.stringify(report,null,2));
console.log(JSON.stringify({files:report.fileCount,bytes:report.totalBytes,paintings:44,structureSvgs:42}));
