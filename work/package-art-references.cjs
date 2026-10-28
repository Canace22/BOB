const fs=require('fs');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化',base='G:/鲸落万物生/outputs/鲸落万物生_V5_完整游戏设计';
fs.mkdirSync(root+'/references/style',{recursive:true});
for(let i=1;i<=5;i++){const f=fs.readdirSync(base+'/images').find(n=>n.startsWith('SC'+i+'_')&&n.endsWith('.png'));fs.copyFileSync(base+'/images/'+f,root+'/references/style/SC'+i+'.png');}
fs.copyFileSync(base+'/references/拾潮者身份基准.png',root+'/references/style/拾潮者身份基准.png');
for(const f of fs.readdirSync(root+'/data/room-art').filter(n=>n.endsWith('.json'))){const m=JSON.parse(fs.readFileSync(root+'/data/room-art/'+f));m.tool='built-in imagegen';m.referenceRoles=[{file:'references/layout/'+m.id+'.png',role:'主要平台、门位与能力门结构参考'},{file:'references/style/SC'+m.id[1]+'.png',role:'区域材质与手绘风格参考'},{file:'references/style/拾潮者身份基准.png',role:'主角造型参考'}];fs.writeFileSync(root+'/data/room-art/'+f,JSON.stringify(m,null,2));}
for(let i=1;i<=5;i++){const file=root+'/data/region-art/R'+i+'.json',m=JSON.parse(fs.readFileSync(file));m.referenceRoles=[{file:'references/style/SC'+i+'.png',role:'区域材质与风格；不直接复制布局'}];fs.writeFileSync(file,JSON.stringify(m,null,2));}
console.log('reference files and roles recorded');
