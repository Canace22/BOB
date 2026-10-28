'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5.2_地图原画设计规范';
for(const f of ['build-map21.cjs','verify-map21.cjs','map21-world.cjs','map21-editor.json'])fs.copyFileSync('G:/鲸落万物生/BOB/work/'+f,root+'/data/'+f);
fs.writeFileSync(root+'/制作与复核说明.md',`# 制作与复核说明\n\n基于V5完整游戏设计，采用V5.1既有五域36房的门位、营地和交通细化。日期：2026-10-26。\n\n- 本轮产出：五域各21项设计文档，共105项；新增总地图与36房位置示意SVG/PNG；完整HTML、Markdown及JSON。\n- 沿用原画44张：5区域总览、36独立房间与3张整体/空间研究。参考图不计入原画数量。\n- 沿用42张结构SVG，新增1张总位置示意，共43张SVG。\n- 全部36房均有原画、结构、通关步骤、门位、失败恢复、回访、英文绘图提示词及中文审阅说明。\n- 澄清H4完成位置：母蟹战胜结果不自动完成H4，仍需回R3-06安置。原V5与V5.1文件未改。\n\n静态检查通过：105项章节覆盖、36房索引、原画文件独立性、门与节点数量、图片签名、HTML与SVG本地链接和锚点。新位置示意已渲染目检。没有浏览器交互、引擎碰撞、动作手感与真人通关测试；不将设计参数表述为实测值。\n\n原画展示的是构图和玩法意图，精确门条件与尺寸以房间JSON和结构图为准。六画面层的k是视差系数，不是缩放倍率。第五版借鉴方向仅为互联探索、能力回访和手绘氛围，海洋生物造型、主角与地图保持原创。\n\n参考图保存在references，实际绘图记录在data/room-art及data/region-art。源记录中的生成路径为历史路径；本包已包含最终PNG与参考。data中的构建脚本保留项目绝对源路径，跨机器重建需先调整路径；离线阅读无需执行脚本。\n`);
const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(d,e.name)):[path.join(d,e.name)]);
const files=walk(root).filter(f=>path.basename(f)!=='交付清单.json').sort().map(f=>{const b=fs.readFileSync(f);return {file:path.relative(root,f).replace(/\\/g,'/'),bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex')};});
const m={edition:'V5.2 地图原画设计规范',regions:5,sections:105,rooms:36,retainedArtworks:44,newRasterArtworks:0,newPlacementDiagram:1,structureSvgs:43,browserTested:false,engineTested:false,fileCount:files.length,bytes:files.reduce((s,f)=>s+f.bytes,0),files};
fs.writeFileSync(root+'/交付清单.json',JSON.stringify(m,null,2));console.log(JSON.stringify({files:m.fileCount,bytes:m.bytes}));
