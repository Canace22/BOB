const fs=require('fs'),p='G:/鲸落万物生/BOB/work/extend-all-map-art.cjs';
let s=fs.readFileSync(p,'utf8');
s=s.replace("describe(meta.review||meta.caveat||'生成后按角色、区域材质、主要平台和门位置进行概念审阅，非引擎碰撞验收。')","describe([meta.review||'生成后按角色、区域材质、主要平台和门位置进行概念审阅，非引擎碰撞验收。',meta.caveat||''])");
s=s.replace("document.querySelectorAll('[data-art-mode]').forEach(btn=>","function openRegion(){const h=decodeURIComponent(location.hash);if(h.startsWith('#region-')){const el=document.getElementById(h.slice(1));if(el&&el.tagName==='DETAILS')el.open=true;}}window.addEventListener('hashchange',openRegion);document.querySelectorAll('a[href^=\"#region-\"]').forEach(a=>a.addEventListener('click',()=>{const el=document.getElementById(a.hash.slice(1));if(el)el.open=true;}));openRegion();document.querySelectorAll('[data-art-mode]').forEach(btn=>");
fs.writeFileSync(p,s);
