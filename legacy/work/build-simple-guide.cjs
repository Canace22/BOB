'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const base='G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计';
const v5='G:/鲸落万物生/outputs/鲸落万物生_V5_完整游戏设计';
const out='G:/鲸落万物生/outputs/鲸落万物生_V5.2_简明设计文档';
const routes=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/simple-guide-routes.json','utf8'));
const chars=JSON.parse(fs.readFileSync('G:/鲸落万物生/BOB/work/simple-guide-characters.json','utf8'));
fs.mkdirSync(out+'/images',{recursive:true});
const assets=new Map();
function asset(src){if(assets.has(src))return assets.get(src).file;const file='images/'+String(assets.size+1).padStart(2,'0')+'_'+path.basename(src);fs.copyFileSync(src,out+'/'+file);assets.set(src,{file,source:src,sha256:crypto.createHash('sha256').update(fs.readFileSync(src)).digest('hex')});return file;}
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let md='# 鲸落万物生｜超级简单设计文档\n\n基于 V5.2，原图配短句。2026-10-26。\n\n';
function p(s){md+=s+'\n\n';return '<p>'+esc(s)+'</p>';}
function fig(src,caption){const f=asset(src);md+='!['+caption+']('+f+')\n\n';return '<figure><a href="'+f+'" target="_blank"><img loading="lazy" src="'+f+'" alt="'+esc(caption)+'"></a><figcaption>'+esc(caption)+' · 点击看原图</figcaption></figure>';}
function heading(n,title,id){md+='## '+n+' '+title+'\n\n';return '<section id="'+id+'"><h2><small>'+n+'</small>'+title+'</h2>';}
function table(head,rows){md+='| '+head.join(' | ')+' |\n| '+head.map(()=> '---').join(' | ')+' |\n'+rows.map(r=>'| '+r.join(' | ')+' |').join('\n')+'\n\n';return '<div class="table"><table><thead><tr>'+head.map(s=>'<th>'+esc(s)+'</th>').join('')+'</tr></thead><tbody>'+rows.map(r=>'<tr>'+r.map(s=>'<td>'+esc(s)+'</td>').join('')+'</tr>').join('')+'</tbody></table></div>';}
const vi=f=>v5+'/images/'+f;
let body='<header><a href="#top">鲸落万物生 <b>V5.2 简明版</b></a><nav><a href="#world">世界</a><a href="#route">路线</a><a href="#player">操作</a><a href="#areas">关卡</a><a href="#cast">角色</a><a href="#growth">收获</a></nav></header><main id="top"><div class="hero"><span>原图 + 短句 / 2026.10.26</span><h1>一具巨鲸，<br>一趟让新生命归海的冒险。</h1><p>先读正文了解全貌；想看某个小关卡，再展开它的原图。所有图片沿用已有设计。</p></div>';
body+=heading('01','这个游戏讲什么？','world');
body+=p('你扮演30厘米高的“拾潮者”，在一具已死的巨鲸中探索、战斗、学会新能力，修通旧路，把依附鲸落的幼体送回大海。');
body+=fig(base+'/images/anatomy/WORLD.png','整体场景｜120米古代巨鲸是幻想设定；身体内部与表面形成五个探索区域。');
body+=table(['是什么','简单说明'],[['游戏类型','原创、单人、2D横版动作冒险；走跳、战斗、探索和少量机关。'],['世界气质','全程水下，阴郁而有生命微光；住民用空壳、红绳和旧声槽建立聚落。'],['最后目标','修通出海通道，释放幼体。鲸始终死亡，新生命继续生长。'],['规模','5个区域、36个小关卡；主线目标5–7小时，完整探索7–9小时，尚未实测。']]);
body+='</section>'+heading('02','地图怎么走？','route');
body+=fig(base+'/maps/总地图_鲸体落位.png','鲸体总地图｜头在左、尾在右、背在上。位置条说明每个房间落在哪个部位。');
body+='<div class="route">';
for(const [i,s] of (routes.mainRouteSteps||routes.mainRoute).entries())body+='<div><b>'+String(i+1).padStart(2,'0')+'</b>'+p(s)+'</div>';
body+='</div>'+p('最容易记的顺序：口腔 → 胃枢分岔 → 肺心与胃肠都探索 → 椎旁 → 向头返回耳区 → 再去远尾归海。胃肠母蟹可以不打，断脊上、下路选一条即可。');
body+=p('部位不会凭空相连：口咽经食管裂缘去胃；胃外侧经横膈旧裂口去肺心；腹腔旧破口接椎旁。耳区在头端、尾槽在尾端，两者要经过椎旁长廊，或使用已经亲访并调律的快速旅行点。');
body+=table(['关键进度','在哪里取得','有什么用'],routes.flags.map(f=>[f.name+'（'+f.id+'）',f.source,f.use]));
body+='</section>'+heading('03','主角是谁？玩家怎么操作？','player');
body+=fig(vi('H01_拾潮者·三视图与挂点.png'),'主角：拾潮者｜单圆镜潜水盔、青色短披风、左腰菌灯、U形骨鸣器。');
body+=p('类型：可操控的探索者。骨鸣器负责近身攻击和共振，菌灯照明并影响部分敌人的警觉；红绳只连接指定锚环。');
body+=table(['动作','玩家怎么用'],[['移动、跳跃','沿亮边平台前进，先看清落脚点；失败通常落到下层恢复台。'],['短击（默认Q）','近身两段攻击；敌人出招后再接近，打完及时退开。'],['重鸣（默认R）','消耗2格蓄振，打出较强共振、对付硬壳。'],['调息','停在安全位置，消耗2格蓄振恢复1格生命；被打中会中断。'],['交互（默认E）、灯罩（默认L）','开闩、交谈、调律；关灯可降低未警觉嗅脂甲的感知。'],['手柄与辅助','按键可重绑定；跳跃、能力等依当前设备提示，不在简版另定新键位。']]);
body+=fig(vi('A02_出手·受击·重试.png'),'动作原图｜短击、重鸣、受击与重新出发的姿态；图板是动作设计，不是可运行动画。');
body+=table(['新能力','获得地点','用途／限制'],[['贴流冲','须门首Boss后','越宽沟、短时避开攻击；每次离地一次，不能穿墙。'],['浮膜','肺心育床','浮升与缓降；压力有限，要在补压台停靠。'],['锚定','胃肠的肠入口','挂固定环越过危险槽；不能任意抓墙，挂环不能攻击。'],['迎珠','断脊练习房','迎击有环的完整钙珠，借力升高并回击；不是踩敌反弹。'],['敛膜潜隙','耳区安全池','穿标记的短柔膜缝换边；不能穿硬骨和普通墙。']]);
body+=fig(v5+'/archive/V4.3_玩法逐帧图解/images/C02_五能力与失败恢复.png','五能力原图｜图示帮助理解动作，规则以本页文字和V5.2详细册为准。');
body+=p('每次探索的小循环：看出口 → 选打、绕或用机关 → 拿奖励 → 开捷径 → 回营地 → 用新能力打开旧路。战斗的关键是看预告、躲危险、抓空当，不是一直按攻击。');
body+='</section>'+heading('04','五个区域，分别玩什么？','areas');
for(const r of routes.regions){
 body+='<article id="'+r.id+'"><h3>'+esc(r.id+' '+r.name)+'</h3>';md+='### '+r.id+' '+r.name+'\n\n';
 body+=p('位置：'+(r.location||r.position));
 for(const [i,img] of (r.images||[r.image]).entries())body+=fig(img,r.name+(r.id==='R5'?(i===0?'·头段耳周创伤区':'·尾段尾柄出口'):'')+'｜'+r.play);
 body+=table(['看这一项','就能懂'],[['怎么玩',r.play],['要完成什么',r.goal],['首通路线',r.mainRoute||r.route],['支线与回访',r.sideRoute||r.side],['为什么能走过去',r.connection]]);
 const rr=r.rooms||routes.rooms.filter(x=>x.id.startsWith(r.id+'-'));
 body+='<details class="rooms"><summary>展开 '+rr.length+' 个小关卡：原图、位置、玩法</summary><div class="grid">';
 for(const room of rr){body+='<div class="room" id="'+room.id+'"><h4>'+esc(room.id+' '+room.name)+'</h4><span class="tag">'+esc(room.kind||room.type)+'</span>'+fig(room.image,room.part)+p(room.play)+'</div>';}
 body+='</div></details></article>';
}
body+='</section>'+heading('05','会遇见谁？','cast');
body+=p('角色分为五类：主角、普通敌人、区域Boss、友好住民、受保护的生态生物。能移动的生物不一定是敌人。');
// Character groups are supplied by a separate source audit; images are the existing original plates.
for(const group of chars.groups){body+='<h3>'+esc(group.title)+'</h3>';md+='### '+group.title+'\n\n';if(group.image)body+=fig(group.image,group.caption||group.title);body+=table(['角色／类型','会做什么','玩家怎么应对'],group.characters.map(c=>[c.name+' · '+c.type,c.skill,c.response]));}
body+='<h3>五个区域Boss</h3>';md+='### 五个区域Boss\n\n';
body+=table(['Boss／类型','主要技能','怎么打'],chars.bosses.map(b=>[b.name+' · '+b.type,b.skill,b.response]));
for(const b of chars.bosses){const room=routes.rooms.find(r=>r.id===b.room);body+='<details class="boss"><summary>看原图：'+esc(b.name)+'</summary>'+fig(room.image,b.name+'｜'+room.part)+p('战后收获：'+b.reward)+'</details>';}
body+=p(chars.eliteNote);
body+=p('受保护住民与幼体不会提供战斗掉落。不要把攻击它们当作恢复资源的方法。旧版角色图板只引用人物与动作；器官位置以本页新总图为准。');
body+='</section>'+heading('06','能收集什么？失败怎么办？','growth');
body+=fig(vi('P01_工具·共生模块·固定奖励.png'),'工具与收获原图｜骨鸣器、菌灯、共生模块和固定收集品。');
body+=table(['内容','简单规则'],[['生命碎片','初始4格生命；集齐4枚加1格，最多6格。不刷随机装备。'],['蓄振','最多4格；战斗获得，用来重鸣或调息，二者需要做取舍。'],['两个模块槽','营地免费换：运动槽选稳足／滑膜／系索；共鸣槽选圆腔／复振／静菌。'],['模块作用','稳足减击退，滑膜缩短冲刺冷却，系索帮助脱锚修方向；圆腔偏射程，复振偏伤害，静菌加快调息。'],['记忆与栖息地','看见旧住民故事，帮助生态恢复；改变尾声声部与生物丰度。'],['机关','开闩、调流、搬壳、补压、穿缝；永远先看出口和安全台。'],['存档与重试','能力、奖励、开闩、Boss胜利会保存。生命归零回营地满状态，不跑尸、不收费。']]);
body+=fig(vi('I02_地图·营地·暂停.png'),'界面原图｜地图找路线，营地换模块，暂停查看信息。');
body+=p('地图实线是已走路线，虚线是看见但未进入，未知区域留白。八处营地负责休息；六个交通节点要先亲访、再调律，不能传送到没去过的地方。');
body+=p('六处生态支线：须门清流窝、肺膜育床、胃枢菌圃、肠侧搬壳巢、肋骨红冠园、尾下幼体槽。每处做一次小帮助，回访看到变化；没有每日喂养。');
body+='</section>'+heading('07','怎样结束这趟旅程？','ending');
const ending=routes.rooms.find(r=>r.id==='R5-08');body+=fig(ending.image,'最终场景原图｜幼体沿尾柄释放槽游向外海，鲸仍留在海床。');
body+=p('集齐潮压稳定P、骨音调律B、安全静默S，来到远尾打开出口，释放幼体。支线做得越多，尾声的生命与声音越丰富；少收集也能得到完整的基础结局。');
body+=p('制作边界：适合2–3人围绕固定五域迭代。当前交付是概念设计与原画，未制作Demo；时长、操作手感和关卡跳距仍需开发验证。');
body+=p('原图来源：V5角色、动作和物件图；V4.3能力与敌人图板；V5.2解剖修订后的世界、区域和房间图。简版不另增人物、能力或地图。');
body+='<div class="links"><a href="简明设计文档.md">下载文字版（附原图）</a><a href="../鲸落万物生_V5.2_完整游戏设计/原画册.html">查看详细原画册</a></div></section></main><footer>鲸落万物生 · V5.2 简明版 / 原图均可点击放大</footer>';
const css=`*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:95px}body{margin:0;background:#0c1d25;color:#d2dcda;font:16px/1.85 "Microsoft YaHei","Segoe UI",sans-serif}a{color:#a9d4cb;text-decoration:none}header{position:sticky;top:0;z-index:9;background:#0c1d25f5;border-bottom:1px solid #30424a;display:flex;justify-content:space-between;gap:25px;padding:17px 5vw}header b{font-size:11px;color:#c0a87c;margin-left:8px}nav{display:flex;gap:20px;font-size:13px}main{max-width:1150px;margin:auto;padding:0 32px}.hero{padding:76px 0 45px}.hero span{font:12px monospace;letter-spacing:2px;color:#aebd9f}h1{font-size:clamp(32px,4.2vw,59px);line-height:1.3;color:#eee6d1;font-weight:500}h2{font-size:31px;font-weight:500;color:#e6dcc2}h2 small{display:block;font:12px monospace;color:#af9973;margin-bottom:12px}h3{font-size:23px;color:#d9d3bd;font-weight:500}h4{font-size:16px;margin:5px 0}section{padding:30px 0 55px;border-bottom:1px solid #30424a}article{margin:45px 0}figure{margin:23px 0;background:#132b34;border:1px solid #304a54}figure img{display:block;width:100%;max-height:760px;object-fit:contain}figcaption{padding:11px 16px;font-size:12px;color:#a8bebc}p{max-width:1000px}.table{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th{text-align:left;color:#e1d4b4;background:#1b3540}th,td{padding:13px 16px;border:1px solid #30434c;vertical-align:top}td:first-child{min-width:145px;color:#c6d9d2}.route{display:grid;gap:10px}.route>div{display:flex;gap:20px;padding:10px 20px;background:#18323b;align-items:center}.route b{color:#dec597;font:25px Georgia}.route p{margin:8px 0}details{background:#122a33;border:1px solid #34505b;padding:16px 22px;margin:18px 0}summary{cursor:pointer;color:#dcc697;font-weight:bold}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:20px}.room{padding:14px;background:#0e222b;border:1px solid #294652}.room figure{margin:12px 0}.room p{font-size:14px;margin:9px 0}.room figcaption{font-size:11px}.tag{font-size:11px;color:#a7c9c6}.links{display:flex;gap:20px;flex-wrap:wrap;margin-top:28px}.links a{border:1px solid #557168;padding:12px 20px}footer{padding:35px;text-align:center;color:#88a19f;font-size:12px}@media(max-width:700px){header{position:relative;display:block}nav{margin-top:10px;gap:15px;flex-wrap:wrap}main{padding:0 18px}.grid{grid-template-columns:1fr}td:first-child{min-width:95px}th,td{padding:10px;font-size:12px}details{padding:13px}.hero{padding-top:35px}}@media print{header,footer,.links{display:none}body{background:white;color:#222}h1,h2,h3,h4,p,td,th,summary{color:#222}main{max-width:none}section{break-before:page}figure{break-inside:avoid}details{background:white}.grid{grid-template-columns:1fr 1fr}}`;
fs.writeFileSync(out+'/设计文档.html','<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>鲸落万物生 V5.2｜超级简单设计文档</title><link rel="stylesheet" href="style.css"></head><body>'+body+'</body></html>');
fs.writeFileSync(out+'/style.css',css);fs.writeFileSync(out+'/简明设计文档.md',md);
fs.writeFileSync(out+'/原图来源.json',JSON.stringify([...assets.values()],null,2));
fs.writeFileSync(out+'/阅读说明.txt','打开设计文档.html。主文用短句说明全貌，小关卡与Boss可展开看原图。所有原图保存在images目录，图片未重新绘制或修改。Markdown包含相同正文与图片。返回详细册需同级旧版目录。\n');
console.log(JSON.stringify({out,images:assets.size,rooms:routes.rooms.length,groups:chars.groups.length,bosses:chars.bosses.length,htmlBytes:Buffer.byteLength(body),markdownBytes:Buffer.byteLength(md)}));
