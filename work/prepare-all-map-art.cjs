const fs=require('fs'),p=require('path');
const sharp=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
const rooms=JSON.parse(fs.readFileSync(root+'/data/房间布局.json')).rooms;
for(const d of ['images/rooms','images/regions','data/room-art','data/region-art','references/layout'])fs.mkdirSync(root+'/'+d,{recursive:true});
const backup='G:/鲸落万物生/BOB/work/v51-before-all-art';fs.mkdirSync(backup,{recursive:true});
for(const f of ['地图设计册.html','style.css','atlas.js','地图设计说明.md','地图原画提示词.md','交付清单.json','阅读说明.txt']){if(!fs.existsSync(backup+'/'+f))fs.copyFileSync(root+'/'+f,backup+'/'+f);}
(async()=>{for(const r of rooms){const f=fs.readdirSync(root+'/maps/rooms').find(n=>n.startsWith(r.id)&&n.endsWith('.svg'));if(!f)throw Error(r.id);await sharp(root+'/maps/rooms/'+f).resize({width:1600}).png().toFile(root+'/references/layout/'+r.id+'.png');}console.log('36 structure PNGs ready');})();
