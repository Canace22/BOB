import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..'),source=path.join(root,'assets/source/xumen-continuity-v1'),out=path.join(root,'game/build/qa/xumen-continuity');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'game/art/manifest.json')));
const runtime=manifest.entries.filter(e=>e.dest.startsWith('xumen-continuity/')).map(e=>{
 const b=fs.readFileSync(path.join(root,e.src));return {source:e.src,runtime:'game/art/'+e.dest,sha256:crypto.createHash('sha256').update(b).digest('hex'),width:b.readUInt32BE(16),height:b.readUInt32BE(20)};
});
const checks=runtime.map(i=>({id:i.runtime,pass:crypto.createHash('sha256').update(fs.readFileSync(path.join(root,i.runtime))).digest('hex')===i.sha256}));
const baseline=JSON.parse(fs.readFileSync(path.join(root,'assets/source/world-continuity-v1/inputs/runtime-r1.json'))),rooms=JSON.parse(fs.readFileSync(path.join(root,'game/art/whalebelly/rooms.json')));
checks.push({id:'original seven rooms doors and collision surfaces retained',pass:rooms.length===7&&rooms.every((r,i)=>JSON.stringify(r.doors)===JSON.stringify(baseline[i].doors)&&JSON.stringify(r.surfaces)===JSON.stringify(baseline[i].surfaces))});
fs.writeFileSync(path.join(source,'runtime-manifest.json'),JSON.stringify({date:'2026-11-04',actualRuntimeImages:runtime.length,runtime},null,2)+'\n');
fs.writeFileSync(path.join(out,'delivery-integrity.json'),JSON.stringify({checks,failed:checks.filter(c=>!c.pass).length},null,2));
const elements=JSON.parse(fs.readFileSync(path.join(source,'elements.json')));
const cards=elements.instances.map(e=>`<section><h2>${e.room} · ${e.edge} → ${e.to}</h2><img src="${e.room}-${e.edge}.png"><p>原门点：${e.door.join(', ')}。地面和碰撞沿用原房；新增水域远景、独立生物与气泡。</p></section>`).join('');
const html=`<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 连续空间设计接入</title><style>body{margin:0;background:#071720;color:#dddcd0;font:16px/1.8 'Microsoft YaHei',sans-serif}header,main{max-width:1320px;margin:auto;padding:32px}h1{font-size:36px;color:#eed2a0}h2{font-size:22px}section{padding:20px 0;border-top:1px solid #31444d}img,video{width:100%;height:auto}a{color:#a1ced8}.note{padding:20px;background:#142c37;border-left:3px solid #d5b079}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}@media(max-width:800px){.grid{grid-template-columns:1fr}header,main{padding:20px}}</style><header><h1>须门遗港 · 连续空间设计接入</h1><p>正式Godot七房 / 共用口腔远景 / 六条连接双向视觉节点 / 独立鱼群与气泡 / 鲸头地图布局</p><div class="note">当前仍按房间加载。已接入连续空间识别与过门表现，未称为整章全局无缝碰撞。原道路、Boss、能力门和V6规则保留。</div></header><main><section><h2>真实引擎展示 · 约35.6秒</h2><video controls preload="metadata" src="environment-demo.mp4"></video><p>后续房间切换为明确预览；主线17项和回访37项另有输入驱动路线日志。</p></section><section><h2>C地图 · 鲸头部位与七房关系</h2><img src="anatomy-map.png"></section><div class="grid">${cards}</div><section><h2>制作源与验收</h2><p>最终日志、截图、性能与浏览器报告保存在本目录。历史失败日志保留，以accepted/delivery结果为准。</p><p><a href="../../../../assets/source/xumen-continuity-v1/README.md">制作说明与边界</a> · <a href="../../../../assets/source/xumen-continuity-v1/elements.json">元素表</a> · <a href="../../../../assets/source/xumen-continuity-v1/generation.json">提示词与来源</a></p></section></main></html>`;
fs.writeFileSync(path.join(out,'场景接入与验收.html'),html);
console.log(JSON.stringify({runtime:runtime.length,instances:elements.instances.length,failures:checks.filter(c=>!c.pass).length}));if(checks.some(c=>!c.pass))process.exitCode=1;
