'use strict';
const fs=require('fs'),crypto=require('crypto'),path=require('path');
const root='G:/鲸落万物生/outputs/拾潮者_2D动作原画';
const plan=JSON.parse(fs.readFileSync(root+'/data/动作图板计划.json','utf8'));
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const rules=[
['待机 / 移动','方向输入；待机0.9秒循环、跑动0.5秒循环为视觉提案','脚先压台再蹬离，披风和红索延迟跟随；头盔体积恒定','图01：01—05；不是完整左右脚循环'],
['跳跃 / 下落 / 落地','跳跃输入；顶点及下落姿态由竖向速度切换','起跳压缩不额外延迟输入；普通跳落点先可见。落地压缩是视觉反馈，不新增强制硬直','图01：06—10；禁止补画二段跳或万能爬墙'],
['一段短击','Q；起手0.12秒 / 有效0.08秒 / 恢复0.20秒；伤害10，距离1.3U','U形开口侧向推击；有效段动作最利落，恢复段明确回收；发力方向锁定','图02：01—04；恢复后半才接受二段续击'],
['二段短击','Q续击；起手0.16秒 / 有效0.08秒 / 恢复0.26秒；伤害14','脚下换重心后向右斜上侧摆，与一段推击区分；不向脚下刺击','图02：05—08；乱按不能取消恢复'],
['重鸣','R；起手0.30秒 / 有效0.12秒 / 恢复0.40秒；耗2格，伤害24，范围2.4U','双手握稳→短距压力扇→身体回弹；叉头完整可辨，压力纹不画成长束射线','图02：09—12；施放会收起A2浮膜'],
['交互 / 灯罩','E交互；L灯罩；时长依对象设计','交互手、武器、腰灯各有归属。灯罩合在左腰的同一盏灯上，不让灯瞬移到手中','图03：01—02；不是新战斗技能'],
['调息','耗2格，静止1.1秒恢复1生命；被打断仍消耗','稳足收器→生物光脉冲→结束；菌光只作反馈，不新增弹体','图03：03—04；安全窗口和敌人预告必须可读'],
['受击 / 归零 / 重试','扣1格、击退0.4U、保护1秒；归零回营地满生命满蓄振','受击后躯干先离开攻击方向，再寻稳；归零动作非血腥，重试不留下可捡尸体','图03：05—08；保护描边不代表影分身'],
['A1 贴流冲','每次离地一次；2.6U/0.22秒；冷却0.8秒，中段回避0.10秒','压身→水平伸展→直立减速→稳定落地。图中起手包含在既有动作时序内，不另加慢启动','图04：01—04；不穿硬墙、酸或持续激流'],
['A2 浮膜','余压4秒，固定补压台免费恢复','软透明膜展于肩背→上浮/缓降→落台收膜；无鸟翼，蹼足不能重复蹬出二段跳','图04：05—08；浮膜中可短击，重鸣会收膜'],
['A3 锚定','只抓预置环；主路环距≤4.5U，极限6U','索先接固定环→绳绷紧身体承重→主动脱环回索→落台恢复战斗姿态','图04：09—12；挂环时不能攻击，不抓任意墙或敌人'],
['A4 迎珠','Q侧向接完整带环珠，窗口0.18秒；约2.4U上升，回珠18伤害','看珠→胸前叉口侧接→珠回返、身体上升→落稳；特效不得遮住接触点','图05：01—04；不是下劈踩敌，也不刷新空中A1'],
['A5 敛膜潜隙','只通过有标记、长度≤1.5U的短柔膜缝','披风与工具收近→侧身推膜→柔膜包裹但头盔不变形→出缝恢复','图05：05—08；不穿硬骨，未出缝时不能突然闭缝夹死']
];
const pipeline=[
'保持三个尺度：角色常态身高为U、头盔直径稳定、所有动作按同一根节点定位。趴伏和收身只改变姿态包围盒，不能随机缩放整个角色。',
'图板统一朝右且展示左侧挂灯。朝左版本必须重画/校正左右挂点；不能直接镜像整图，把菌灯移到解剖右腰。',
'身体、披风、骨鸣器、腰灯、红索、能力膜和特效分开制作。重鸣与迎珠有效范围由规则驱动，不能直接取特效外框当碰撞。',
'关键姿态之间仍需补过渡帧、统一画布/脚底基线、检查跑动左右腿循环与接触脚滑移。原画是动作方向提案，不是已切好透明背景的精灵表。',
'动作优先级提案：生命归零＞受击反馈＞当前技能/攻击锁定段＞移动。二段短击仅在既有接受窗续接；其他取消关系未擅自扩展为可用连招。',
'衔接验证：普通跳→A1→落地；A2→短击→缓降；A3脱环→落台→短击；A4上升→一次尚未用过的A1→落台；A5出缝→移动。已用掉A1时，A4不能再给一次空冲。',
'24fps仅可作为美术预览的采样提案，战斗窗口以秒为准。0.18秒迎珠窗口、0.08秒短击有效段不应被简单按整数曝光帧改写。',
'缩小到实机角色尺寸时，优先检查头盔单镜、U形叉头、左腰单灯和蹼足方向是否仍能分辨；删减纹理不能改变身份特征。'
];
let md='# 拾潮者 · 2D动作原画与衔接规范\n\n沿用《鲸落万物生：遗潮回声》第五版主角。参考《Hollow Knight》的动作清晰度、轮廓表达和前摇—发力—恢复节奏，不复用其角色或具体动作素材。\n\n本轮五张新绘动作图板，50个关键姿态格。全部为内置imagegen生成的概念原画；非完整逐帧动画、透明拆层或已验证的碰撞资产。\n\n';
let html='<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>拾潮者 · 2D动作原画册</title><style>*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#111e24;color:#d6dedb;font:15px/1.8 "Microsoft YaHei",sans-serif}main{max-width:1450px;margin:auto;padding:55px 32px}h1{font-size:48px;line-height:1.3;color:#f0e4ca;font-weight:500}h2{font-size:28px;color:#e0cfad;font-weight:500;margin-top:50px}h3{font-size:18px}a{color:#a1d3cb;text-decoration:none}nav{display:flex;gap:20px;flex-wrap:wrap;border-block:1px solid #3b4c50;padding:18px 0;margin:28px 0}.eyebrow{font:12px monospace;letter-spacing:3px;color:#a9b7a3}.intro{max-width:950px;font-size:18px;color:#a8bebb}figure{margin:22px 0;background:#203138;border:1px solid #3b4c50}figure img{display:block;width:100%}figcaption{padding:12px 18px;font-size:12px;color:#a9c2c1}.poses{display:grid;grid-template-columns:repeat(2,1fr);gap:5px 30px;padding:0;list-style:none}.poses li{padding:12px 16px;background:#1c3038;border-left:2px solid #789f95}.table{overflow:auto}table{border-collapse:collapse;min-width:900px;width:100%;font-size:13px}td,th{padding:14px;border:1px solid #3a5057;text-align:left;vertical-align:top}th{background:#29414a;color:#e7d7ba}tr:nth-child(even){background:#1a3039}details{padding:18px;background:#1a3039;margin:18px 0}summary{cursor:pointer}pre{white-space:pre-wrap;font:12px/1.8 Consolas,monospace;max-height:350px;overflow:auto;overflow-wrap:anywhere;color:#acc9c8}.note{border-left:3px solid #b29d77;padding:16px 20px;background:#1d3038}li{margin:8px 0}footer{margin-top:60px;padding-top:30px;border-top:1px solid #3b4c50}@media(max-width:720px){main{padding:30px 16px}h1{font-size:34px}.poses{grid-template-columns:1fr}}</style></head><body><main><span class="eyebrow">WHALEFALL / TIDE GATHERER / ACTION ART</span><h1>拾潮者<br>2D动作原画与技能姿态</h1><p class="intro">从脚下的一次蹬跃，到骨鸣器的一次侧迎。沿用单圆镜、青披风、左腰菌灯和双叉骨鸣器，以清楚的重心、轮廓和动作阶段表达操作。</p><p class="note">5张新绘动作图板 · 50个关键姿态格。参考《Hollow Knight》的动作读性和节奏方向，角色、武器、能力及具体原画保持本作设计。关键姿态图还需补帧、拆层和动画实测。</p><nav>'+plan.sheets.map(s=>'<a href="#sheet-'+s.id+'">'+s.id+' '+esc(s.title.split(' · ')[0])+'</a>').join('')+'<a href="#rules">时序与衔接</a></nav>';
for(const s of plan.sheets){const img=root+'/images/'+s.id+'.png';if(!fs.existsSync(img))throw Error('missing '+img);const reviewFile=root+'/data/'+s.id+'.json';const review=fs.existsSync(reviewFile)?JSON.parse(fs.readFileSync(reviewFile,'utf8')):{};const reviewText=review.review||'已按身份特征、格数和动作阶段目检；图板尚未经过逐帧动画测试。';html+='<section id="sheet-'+s.id+'"><h2>'+s.id+' / '+esc(s.title)+'</h2><figure><a href="images/'+s.id+'.png" target="_blank"><img src="images/'+s.id+'.png" alt="'+esc(s.title)+'" loading="lazy"></a><figcaption>'+s.rows+'行 × '+s.cols+'列；从左向右、从上向下阅读 · 点击打开原尺寸</figcaption></figure><ol class="poses">'+s.poses.map(x=>'<li>'+esc(x)+'</li>').join('')+'</ol><p>'+esc(reviewText)+'</p><details><summary>英文绘图提示词与修订</summary><pre>'+esc(s.prompt)+'</pre>'+(review.editPrompt?'<pre>'+esc(review.editPrompt)+'</pre>':'')+'</details></section>';md+='## '+s.id+' '+s.title+'\n\n!['+s.title+'](images/'+s.id+'.png)\n\n'+s.poses.map(t=>'- '+t).join('\n')+'\n\n'+reviewText+'\n\n```text\n'+s.prompt+'\n```\n\n'+(review.editPrompt?'修订提示词：\n\n```text\n'+review.editPrompt+'\n```\n\n':'');}
html+='<section id="rules"><h2>动作时序与衔接</h2><p>攻击、能力与生命规则继承V5；新增循环时长仅是美术提案，不代表经过手感测试。</p><div class="table"><table><tr><th>动作</th><th>输入 / 时序</th><th>原画表现</th><th>对应图格 / 限制</th></tr>'+rules.map(row=>'<tr>'+row.map(c=>'<td>'+esc(c)+'</td>').join('')+'</tr>').join('')+'</table></div><h2>从原画到动画的制作要求</h2><ol>'+pipeline.map(t=>'<li>'+esc(t)+'</li>').join('')+'</ol></section><footer><a href="动作规范.md">完整动作说明与提示词 Markdown ↗</a> · <a href="images/身份基准.png">沿用的角色身份基准 ↗</a> · <a href="data/动作时序.json">动作规则 JSON ↗</a><p>本轮产出为概念原画，无Demo、精灵切片或引擎动画测试。</p></footer></main></body></html>';
md+='## 动作时序与衔接\n\n|动作|输入/时序|原画表现|对应图格/限制|\n|---|---|---|---|\n'+rules.map(r=>'|'+r.join('|')+'|').join('\n')+'\n\n## 从原画到动画\n\n'+pipeline.map((t,i)=>(i+1)+'. '+t).join('\n\n')+'\n';
fs.writeFileSync(root+'/动作原画册.html',html);fs.writeFileSync(root+'/动作规范.md',md);fs.writeFileSync(root+'/data/动作时序.json',JSON.stringify({basedOn:'V5完整游戏视觉设计',rules,pipeline},null,2));
const walk=d=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(d,e.name)):[path.join(d,e.name)]);const files=walk(root).filter(f=>path.basename(f)!=='交付清单.json').map(f=>({file:path.relative(root,f).replace(/\\/g,'/'),bytes:fs.statSync(f).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')}));fs.writeFileSync(root+'/交付清单.json',JSON.stringify({newActionSheets:5,plannedKeyPoseCells:50,retainedIdentityReferences:1,engineAnimationTested:false,files},null,2));console.log(JSON.stringify({sheets:5,poseCells:50,files:files.length}));
