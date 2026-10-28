const fs=require('fs'),p=require('path');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.1_地图深化';
let design=fs.readFileSync(root+'/地图设计说明.md','utf8');
if(!design.includes('全地图原画补全入口'))design=design.replace('# 鲸落万物生：遗潮回声 · V5.1 地图深化','# 鲸落万物生：遗潮回声 · V5.1 地图深化\n\n**全地图原画补全入口**：本页基础地图合同继续有效。本轮新增5区域总览＋36独立房间画，保留3张既有图，共44张原画。详见[全地图原画说明](全地图原画说明.md)与[实际绘图提示词](完整地图原画提示词.md)。下文M01/M02/M03是先期三张空间研究，本轮不再只有这三张图。');
fs.writeFileSync(root+'/地图设计说明.md',design);
let oldPrompts=fs.readFileSync(root+'/地图原画提示词.md','utf8');
oldPrompts=oldPrompts.replace('其后36房提示词是下一步制图规格，尚未逐房生成手绘PNG；现有逐房图为可编辑SVG结构设计。','其后36房提示词保留为结构规格；本轮已另完成36房手绘PNG与5区域总览，实际生成及修订提示词见《完整地图原画提示词.md》。逐房SVG仍为可编辑结构设计。');
fs.writeFileSync(root+'/地图原画提示词.md',oldPrompts);
let client=fs.readFileSync(root+'/atlas.js','utf8')
  .replaceAll("$$('.room-card details')",()=>"$$('.room-card > details:not(.art-production)')")
  .replaceAll(";$('.room-card > details:not(.art-production)').forEach",()=>";$$('.room-card > details:not(.art-production)').forEach");
fs.writeFileSync(root+'/atlas.js',client);
fs.copyFileSync('C:/Users/Kingsoft/.codex/attachments/4cf7de8a-6202-4ca6-b83f-93ef54be0817/已粘贴的文本.txt',root+'/data/本轮用户地图参考清单.txt');
for(const name of ['extend-all-map-art.cjs','verify-all-map-art.cjs','finalize-all-map-art.cjs'])fs.copyFileSync('G:/鲸落万物生/BOB/work/'+name,root+'/data/'+name);
fs.writeFileSync(root+'/阅读说明.txt','打开 地图设计册.html，页面地址沿用V5.1。\n本轮新增41张独立原画：5区域总览、36房间；保留3张既有图，共44张原画。另有42张SVG结构图。\n原画可放大，原画/结构/对照三种阅读模式；房号点击进入对应逐步走法。\n离线包无需联网；返回第五版链接需原第五版目录并列放置。\n原画为合成PNG非透明分层资产；坐标、碰撞和跳距以结构数据为准并仍需引擎验证。\n脚本通过静态检查，未做本轮浏览器实机交互与真人通关验收。\n实际提示词：完整地图原画提示词.md；逐图记录data/room-art与data/region-art。\n拓扑复验：node data/validate-map-v51.cjs "当前图册目录绝对路径"。构建脚本中的源路径是项目环境路径，跨机器需调整。');
console.log('documentation and scripts synchronized');
