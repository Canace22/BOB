const fs=require('fs'),p=require('path');
const [id,sourcePath]=process.argv.slice(2),root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计';
const item=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/anatomy-v52/back-room-edits.json','utf8'))[id];
if(!item||!sourcePath)throw Error('id/source');
const review={
'R5-05':'已目检：嵌套鲸骨/肋骨背景改为颅侧实体骨板和创伤膜，记忆鲸群明确为投影；原台面、角色、记忆片及右侧返程闩保留。',
'R5-06':'已目检：背景嵌套鲸颅与肋架删除，换颅侧实体骨板/膜；三处短柔膜缝、唯一左入口与右上三腔碎片保留。',
'R5-07':'已目检：尾根改纵向肌束与肌腱剥离，远尾叶无骨；左营地/幼体槽/交通与右三槽门、连续宽台保留。',
'R5-08':'已目检：尾柄释放沟移除椎链和肋架，背景为软组织与外海；连续地面、唯一左门、右释放碗和幼体保留。',
'R4-06':'已目检：删除嵌套鲸头，背景为椎体外侧筋膜，不是脊髓管；交通环与三门及台面保持。'
}[id];
fs.copyFileSync(sourcePath,root+'/images/anatomy/rooms/'+id+'.png');
fs.writeFileSync(root+'/data/anatomy-art/'+id+'.json',JSON.stringify({id,prompt:item.prompt,editPrompt:item.prompt,description:item.description,sourcePath,originalSource:'G:/鲸落万物生/outputs/鲸落万物生_V5.2_地图原画设计规范/images/rooms/'+id+'.png',referenceLayout:'references/layout/'+id+'.png',review,caveat:'本轮定向修改背景解剖与材质，不重新验证碰撞；准确台面、门条件和可达性以对应JSON/SVG为准。',tool:'built-in imagegen'},null,2));
console.log(id+' saved');
