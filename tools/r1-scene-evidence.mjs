// Build a local-only review page. Never copies screenshots/videos into source control.
import fs from 'node:fs';
import path from 'node:path';
const spec=JSON.parse(fs.readFileSync('assets/source/r1-chapter-scenes/chapter.json','utf8'));
const folder='game/build/qa/r1-chapter-scenes';
const escape=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const rows=spec.rooms.map(room=>{
 const counts=Object.fromEntries(['static','flex','fish','bubbles','lamp','water','existing_actor'].map(k=>[k,room.elements.filter(e=>e.kind===k&&(k!=='flex'||e.status==='motion')).length]));
 return `<section id="${room.id}"><h2>${room.id} · ${escape(room.name)}</h2><p>四层原图结构、角色与机关保留。柔性簇${counts.flex}，鱼群${counts.fish}，气泡区${counts.bubbles}，暖灯${counts.lamp}，背景水光蒙版${counts.water}。原生实机全景镜头：</p><img src="${room.id}-static.png"><details><summary>动态相位与镜头两端</summary><img src="${room.id}-motion.png"><img src="${room.id}-edge--1.png"><img src="${room.id}-edge-1.png"></details><table><tr><th>ID</th><th>静/动</th><th>层</th><th>首选与理由</th></tr>${room.elements.map(e=>`<tr><td>${e.id}</td><td>${e.status}</td><td>${e.layer}</td><td>${escape(e.primary_method)} · ${escape(e.reason??'')}</td></tr>`).join('')}</table></section>`;
}).join('');
const html=`<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>R1 后续六房 · 实机验收</title><style>body{background:#071820;color:#dce5e2;font:16px/1.7 system-ui;max-width:1280px;margin:auto;padding:30px}h1,h2{color:#edcc93}a{color:#9bdbd9}video,img{width:100%;height:auto}section{margin:55px 0}table{border-collapse:collapse;width:100%;font-size:13px}td,th{padding:10px;border-bottom:1px solid #294955;text-align:left}nav{position:sticky;top:0;background:#071820e8;padding:15px;display:flex;gap:20px}</style><h1>须门遗港 · 后续六房环境接入</h1><p>当前工程：game/project.godot，F5主场景，数字2–7为已有房间预览，Tab为已有镜头切换。能力门和原存档保持原规则。下面是实际Godot截图与24FPS连续环境展示，房间切换采用预览，不能把本页录像当作连续通关。</p><nav>${spec.rooms.map(r=>`<a href="#${r.id}">${r.id}</a>`).join('')}</nav><video src="chapter-motion.mp4" controls preload="metadata" poster="chapter-contact.png"></video><p>原件/可编辑SVG与OpenRaster母版：assets/source/r1-chapter-scenes；运行素材64个RGBA导出。详细验收、失败修复与接续指令见 game/progress.md。当前页面/录像/日志仅本地保存，不提交或上传。</p>${rows}</html>`;
fs.writeFileSync(path.join(folder,'场景验收与对照.html'),html);
console.log('Local review page: '+path.resolve(folder,'场景验收与对照.html'));
