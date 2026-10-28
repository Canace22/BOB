const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root='G:/鲸落万物生/outputs/鲸落万物生_V5_完整游戏设计',work='G:/鲸落万物生/BOB/work';
const assets=JSON.parse(fs.readFileSync(root+'/data/图板设计.json','utf8'));
const coverage=JSON.parse(fs.readFileSync(root+'/需求覆盖.json','utf8')).items;
const old=JSON.parse(fs.readFileSync(root+'/archive/V4.3_玩法逐帧图解/data/图板设计.json','utf8'));
const ids=new Set([...assets,...old].map(a=>a.id));
if(ids.size!==44||coverage.length!==15)throw Error('Coverage counts');
const seen=new Set();for(const c of coverage){for(const id of c.plates||[]){if(!ids.has(id))throw Error('Unresolved plate '+id);seen.add(id);}}
if(assets.some(a=>!seen.has(a.id)))throw Error('New plate missing coverage');
fs.mkdirSync(root+'/data/生成记录',{recursive:true});
for(const a of assets){for(const suffix of ['', '-edit']){const p=work+'/v5-'+a.id+suffix+'.json';if(fs.existsSync(p))fs.copyFileSync(p,root+'/data/生成记录/'+path.basename(p));}}
fs.copyFileSync(root+'/data/图板设计.json',root+'/data/新绘图板设计.json');
const review=`# V5 新绘原画复核\n\n2026-10-22。二十张新绘图均使用内置 image_gen；初稿与最终修订均逐图目视核对。英文提示词与原始/修订生成记录随册保存。所有最终项目图片已复制到本目录，离线浏览不依赖默认生成目录。\n\n## 九张定向修订\n\n| 图板 | 发现的问题 | 最终修订 |\n|---|---|---|\n| K01 | 上层记忆奖励被画成第二盏完整菌灯 | 改为刻有同心声槽的扁平记忆片 |\n| H01 | 正背面的灯挂点不一致 | 正视观者右、背视观者左；明确解剖左侧 |\n| SC2 | 漏画鳐且模块像整灯 | 补浅色膜缘鳐预告，模块改三腔胶囊 |\n| SC3 | 甲壳敌人误带主角的灯 | 删除灯，恢复小头与感知触须 |\n| SC5 | 回声成为角色分身，薄缝画成长桥 | 改声波弧纹和门内短柔膜缝 |\n| D01 | 可玩层混有远景，HUD为连续能量条 | 清除层03远景，四生命叶与四能量格，统一鳐和育囊 |\n| D02 | 鳐材质不一致 | 六格统一为浅色半透明膜体，保持错误/修正对照 |\n| F01 | 重鸣误表现为破坏硬地形 | 改为震裂敌人壳面，地面保持完整 |\n| I01 | 群体Boss误成佩灯的巨大单体 | 改为多个小端足类组成一个群流代理，保留HUD |\n\n## 读图边界\n\n- W02按上—中—下读过去、废弃和接续；A01按01–08读跑动/跳跃关键姿；A02按01–06读攻击/受击/归营。\n- D01的00–05是场景层职责示意，06是HUD；实交PNG没有可独立导入的透明图层。\n- S01底部图形是美术语言探索，实际HUD以I01与正文规则为准。I02中的槽位图形是类别标记，模块实物造型以P01为准。\n- 旧身份参考保留用于来源追溯；V5正背面左灯挂点以H01为准。场景小角色的挂点需在正式双向动画中再次统一。\n- 部分场景为展示多层关系而压缩或放大距离，不能从原画反推碰撞或跳距；按U制文字规则进入后续灰盒验证。\n- 图板是概念设计，不是连续动画帧、已验证的可玩截图、PSD、Tileset或Sprite Sheet。\n- 36房SVG由本地矢量代码绘制；已用本地sharp渲染目视检查并修正跨区连线，未使用浏览器或替代服务绕过本地页面访问限制。\n`;
fs.writeFileSync(root+'/新绘原画复核.md',review);
const summary='\n## 本轮补充复核\n\n- 二十张新图已逐张目视查看；九张执行定向修订，详情见《新绘原画复核.md》。\n- 十五类别覆盖索引中引用的图板ID全部有效，二十张新图全部纳入覆盖。\n- 世界拓扑已通过本地sharp静态渲染视觉复核；完整网页仍未完成浏览器视觉/交互验收。\n- 基础规则、返能作用域、母蟹可绕过、S取得房位和H4来源完成独立交叉审查。\n';
fs.appendFileSync(root+'/验收记录.md',summary);
fs.writeFileSync(root+'/阅读说明.txt','鲸落万物生 V5 完整游戏设计\n\n解压后保留整个目录，打开 原画册.html。\n建议阅读：主视觉与风格 → 36房拓扑 → 主角与NPC → 五域场景 → 分层与物件 → UI → 完整设计文档 → V4.3逐帧附录。\n20张新绘原画在 images；24张沿用图板在 archive/V4.3_玩法逐帧图解/images。\n中文说明及完整英文提示词随册；图册只交付概念设计，未开发Demo。\n网页不依赖网络；浏览器交互验证尚未完成。\n');
let html=fs.readFileSync(root+'/原画册.html','utf8');
html=html.replace('<a class="btn" href="验收记录.md" download>验收记录</a>','<a class="btn" href="验收记录.md" download>验收记录</a><a class="btn" href="新绘原画复核.md" download>九张定向修订记录</a><a class="btn" href="阅读说明.txt" download>离线阅读说明</a>');
fs.writeFileSync(root+'/原画册.html',html);
let count=0;function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=dir+'/'+e.name;if(e.isDirectory())scan(p);else if(e.isFile())count++;}}scan(root);
console.log(JSON.stringify({newImages:assets.length,inheritedImages:old.length,coverage:coverage.length,coveredNewImages:assets.filter(a=>seen.has(a.id)).length,edited:assets.filter(a=>a.edit_prompt).length,files:count},null,2));
