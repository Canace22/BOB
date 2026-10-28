import json, pathlib, shutil, html
from pathlib import Path
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');d=json.loads((p/'data/r1-design.json').read_text('utf8')); E=html.escape
(p/'maps').mkdir(exist_ok=True)
src=Path('G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计')
def text(x,y,s,size=16,c='#d8eeee'):return f'<text x="{x}" y="{y}" fill="{c}" font-size="{size}" font-family="Microsoft YaHei,sans-serif">{E(str(s))}</text>'
def start(w,h):return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}"><rect width="{w}" height="{h}" fill="#081e29"/>'
# Accurate coordinate sheets; not generative imagery.
for r in d['rooms']:
 id=r['id']; image=src/'images/anatomy/rooms'/f'{id}.png'
 if not image.exists():image=src/'images/rooms'/f'{id}.png'
 shutil.copy2(image,p/'references'/f'{id}.png')
 w,h=r['width'],r['height']; scale=24;ox=45;oy=55
 s=start(w*scale+90,h*scale+120)+text(20,28,f"{id} {r['name']} · {w}×{h}U · 坐标原点左上",18)
 for x in range(0,w+1,2):
  s+=f'<path d="M {ox+x*scale} {oy} v {h*scale}" stroke="#183643" stroke-width="1"/>'+text(ox+x*scale,oy+h*scale+20,x,10)
 for y in range(0,h+1,2):s+=f'<path d="M {ox} {oy+y*scale} h {w*scale}" stroke="#183643" stroke-width="1"/>'+text(15,oy+y*scale,y,10)
 for a in r['platforms']:
  x,y,ww=ox+a['x']*scale,oy+a['y']*scale,a['w']*scale
  s+=f'<rect x="{x}" y="{y}" width="{ww}" height="10" fill="#936d70"/><path d="M {x} {y} h {ww}" stroke="#ffcf8d" stroke-width="3"/>'+text(x+2,y+23,a['id'],10)
 for route in r['routes']:
  if route['type']=='access':continue
  color='#62dcc8' if route['type']=='main' else '#cf9bf0';pts=' '.join(f"{ox+x*scale},{oy+y*scale-10}" for x,y in route['points'])
  s+=f'<polyline points="{pts}" fill="none" stroke="{color}" stroke-width="2" stroke-dasharray="6 4"/>'
 for group,color,shape in [('enemies','#ff8c80','circle'),('rewards','#ffd275','diamond'),('hazards','#e68bba','tri'),('anchors','#e2dfbe','ring')]:
  for a in r.get(group,[]):
   x,y=ox+a['x']*scale,oy+a['y']*scale-7
   if shape=='diamond':s+=f'<path d="M{x} {y-6}l6 6 -6 6 -6 -6Z" fill="{color}"/>'
   elif shape=='tri':s+=f'<path d="M{x} {y-7}l7 12h-14Z" fill="{color}"/>'
   else:s+=f'<circle cx="{x}" cy="{y}" r="6" fill="{color if shape=="circle" else "none"}" stroke="{color}" stroke-width="2"/>'
 for a in r['doors']:
  x,y=ox+a['x']*scale,oy+a['y']*scale
  s+=f'<rect x="{x-5}" y="{y-30}" width="10" height="30" fill="#61c0ed"/>'+text(max(ox,x-35),y-38,a['to'],11,'#9bdcff')
 s+=text(20,h*scale+100,'青虚线 主路线｜紫虚线 回访｜红圆 敌人｜粉三角 危险｜金菱 奖励｜空心环 锚点',12)
 (p/'maps'/f'{id}.svg').write_text(s+'</svg>',encoding='utf8')
# Region topology
s=start(1500,520);pos={'R1-01':(30,300),'R1-02':(290,300),'R1-03':(550,300),'R1-04':(810,300),'R1-05':(1070,300),'R1-06':(290,65),'R1-07':(620,65)}
for a,b,label in [('R1-01','R1-02','走跳'),('R1-02','R1-03','基础战斗'),('R1-03','R1-04','门前营地'),('R1-04','R1-05','Boss胜利 → A1'),('R1-02','R1-06','A2 · 侧伤绕行'),('R1-02','R1-07','A3 · 固定锚环')]:
 x,y=pos[a];xx,yy=pos[b]
 if y==yy:ax,ay,bx,by=x+215,y+45,xx,yy+45
 else:ax,ay,bx,by=x+107,y,xx+107,yy+90
 s+=f'<path d="M{ax} {ay}L{bx} {by}" stroke="{"#65d6c4" if y==yy else "#c79de7"}" stroke-width="3" fill="none"/>'+text((ax+bx)/2-45,(ay+by)/2-10,label,12)
for r in d['rooms']:
 x,y=pos[r['id']];s+=f'<rect x="{x}" y="{y}" width="215" height="90" rx="14" fill="#123443" stroke="#496577"/>'+text(x+15,y+30,r['id']+' '+r['name'],17)+text(x+15,y+60,'首通' if r['id'][-2:]<'06' else '后期回访',13,'#d3aa79')
s+=text(30,465,'主路只经Boss向后进入咽食道；底部恢复段不得连成绕过Boss的通道。',20)
s+=text(30,495,'R1-06 ↔ 肺心R2-05：A2 + 远侧开闩 + BOSS_R2；R1-05 ↔ 胃枢R3-01：A1。区域内无快速旅行点。',16)
s+=text(30,28,'R1 须门遗港 · 七房连接与能力条件（拓扑示意，不代表统一物理比例）',22)
(p/'maps/topology.svg').write_text(s+'</svg>',encoding='utf8')
print('7 room references and coordinate diagrams, topology generated')
a=json.loads((p/'data/elements.json').read_text('utf8'))
def img(path,alt):return f'<a href="{path}" target="_blank"><img src="{path}" alt="{E(alt)}" loading="lazy"></a>'
def para(v):return '<p>'+E(str(v))+'</p>'
def table(headers,rows):return '<div class="scroll"><table><thead><tr>'+''.join('<th>'+E(x)+'</th>' for x in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+E(str(v))+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table></div>'
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#061823;color:#dce8e8;font:16px/1.75 "Microsoft YaHei",sans-serif}header{padding:70px 6vw 35px;background:radial-gradient(ellipse at 70% 0,#20475a,transparent 70%)}h1{font-size:clamp(32px,5vw,66px);margin:10px 0;line-height:1.2}h2{font-size:30px;color:#f4d5a3}h3{font-size:22px;color:#a3dfd5}p{max-width:1050px}small,.muted{color:#95adba}.eyebrow{letter-spacing:4px;color:#d5a873}nav{position:sticky;top:0;z-index:10;background:#0b2432ed;backdrop-filter:blur(8px);padding:12px 6vw;display:flex;gap:20px;flex-wrap:wrap;border-bottom:1px solid #345365}a{color:#9edacc;text-decoration:none}a:hover{color:#ffda9c}main{max-width:1600px;margin:auto;padding:0 5vw 70px}section{padding-top:45px;scroll-margin-top:90px}img{display:block;width:100%;height:auto;border-radius:10px;border:1px solid #304552}figure{margin:22px 0}figcaption{color:#a9b8bc;font-size:14px;margin-top:10px}.note{padding:18px 22px;border-left:3px solid #d5a773;background:#132c37;border-radius:0 9px 9px 0}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px}.card{background:#0c2533;border:1px solid #284656;padding:22px;border-radius:12px}.badge{display:inline-block;border:1px solid #50616a;border-radius:20px;padding:2px 12px;color:#e7be80;font-size:13px}table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #284656;padding:12px}th{color:#eac391;background:#0d2b3a}.scroll{overflow:auto}details{border:1px solid #294756;background:#0b2331;border-radius:10px;margin:12px 0;padding:15px 20px}summary{cursor:pointer;color:#d8ceae}ol{padding-left:24px}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#04131c;padding:20px;border-radius:8px;font-size:13px}input,button,select{background:#173747;color:#e9e6d9;border:1px solid #436675;border-radius:8px;padding:10px;margin:5px}button{cursor:pointer}.layerstrip{width:100%;aspect-ratio:10/1;background-image:url(images/layers.png);background-size:100% 400%;border:1px solid #395768;border-radius:8px}footer{color:#91acb9;padding:30px 6vw;border-top:1px solid #294553}@media(max-width:700px){main{padding:0 20px 40px}nav{gap:10px;padding:10px;font-size:13px}h2{font-size:25px}th,td{min-width:110px}.grid{grid-template-columns:1fr}}'''
b='<header id="top"><div class="eyebrow">WHALEFALL · REGION 01 · VISUAL ATLAS</div><h1>须门遗港<br>首关全景与分层拆解</h1><p>从口角旧伤进入巨鲸，穿过须筛与舌台，越过负壳蟹守卫的口咽，再沿食管裂边向胃枢深入。</p><span class="badge">7 房设计域</span> <span class="badge">5 房首通 + 2 房能力回访</span> <span class="badge">33 项元素规格</span><p class="muted">2026.10.27 · 基于 V5 / V5.1 / 两套 V5.2 原资料。图册是设计交付；本轮没有新增 Godot 内容。</p></header>'
b+='<nav><a href="#panorama">全景</a><a href="#route">地图路线</a><a href="#layers">四层拆解</a><a href="#objects">物件与动态</a><a href="#rooms">七房详图</a><a href="#sources">来源与验收</a></nav><main>'
b+='<section id="panorama"><h2>01 / 首关完整全景</h2>'+img('images/panorama.png','须门遗港七房压缩全景')+'<p class="note">全景用于空间氛围和巨物尺度，非碰撞底图。上层两袋为回访，主线依次通过下层五房。底部深色组织与记忆袋底缘是非碰撞框景，不能据此绕过锚环或 Boss；准确平台、缺口和敌人数以坐标图为准。</p><div class="grid">'
for title,body in [('鲸体位置','头部腹侧口角→口腔上颚下缘→舌背→舌根口咽→咽后食管前段。头背侧喷气孔通过旧创伤侧路抵达。'),('巨物尺度','沿用虚构120m巨鲸、0.3m拾潮者的设定。局部房宽沿组织表面回折，不能简单累加为鲸体长；全景采用压缩投影。'),('图面阅读规则','上颚挂鲸须；最右咽后改为肌膜。薄红绳表示维护痕迹；暖亮顶边提示可站面；未登记孔洞不是新出口。')]:b+='<article class="card"><h3>'+title+'</h3>'+para(body)+'</article>'
b+='</div><details><summary>原画精度说明与返修记录</summary><p>初稿的上层底缘和终段缺口不够明确，已做一次局部返修并保留初稿。修订图改善了上层断台、右段三沟与能力茧，但压缩画面未逐一准确表现三只普通蟹、H1育窝及奖励形状，底缘仍可能被误认作站立面。请使用下方精确房图放置它们；这张图通过概念构图审查，不通过直接作为碰撞/资产切片底图的验收。</p><a href="images/panorama-initial.png">查看初稿</a></details></section>'
b+='<section id="route"><h2>02 / 路线与关卡关系</h2>'+img('maps/topology.svg','首关七房精确连接关系')+table(['阶段','玩家动作','目的 / 限制'],[['01 外伤坡','存档→短跳→沿亮顶边出门','安全教学；无主动敌人'],['02 须筛','诱蟹举钳→步退→恢复窗短击','记录A2/A3上层门；首次不用新能力'],['03 舌台','分开双蟹→承重台→取高台碎片','资源取舍；不强迫双怪夹击'],['04 负壳蟹','战前存档→跳扫/退砸→胜后E取A1','必经瓶颈；不能要求战前冲刺'],['05 流膜育窝','跳起→空冲→落稳，重复三段','三处4U沟；H1生态节点可选'],['06 / 07 回访','A2浮膜竖井 / A3固定环两隙','首通不开放；奖励非终局硬门']])+'</section>'
b+='<section id="layers"><h2>03 / 远景 · 中景 · 可玩层 · 前景</h2>'+img('images/layers.png','四层视觉拆解板')+'<p class="note">这是新绘的分层解释板，不是从合成原图无损抽出的配准图层，也不是透明运行贴图。板中 MID 行的亮环与悬台只示意造型；凡可抓、可站、可交互的实例必须归 PLAY 层，不能随中景视差移动。</p><label>单层放大查看：<select id="layerpick"><option value="0">01 远景</option><option value="1">02 中景</option><option value="2">03 可玩层</option><option value="3">04 前景</option></select></label><div id="layerstrip" class="layerstrip"></div>'+table(['层','视差 k','内容','约束'],[[x['name'],x['parallax'],x['content'],x['rule']] for x in a['layers']])+'<p>视差数值是生产起点，不是本轮实机调校结果。光与雾跟随所属景深，不把所有动态烘焙成背景。框景遮住角色、落点或钳击预告时必须淡出。</p></section>'
b+='<section id="objects"><h2>04 / 物件分件与动态来源</h2>'+img('images/elements.png','十二组物件分件与动态示意')+table(['图板编号','图示','制作解释'],[['01–04','地形 / 鲸须 / 灯 / 壳营地','顶边、端帽、根部、纤维、壳罩、光芯各自拆件；灯是封闭生物光。'],['05–08','门 / 固定环 / 承重膜 / 蟹','门框不随门扇缩放；环锚点固定；承重下沉先预告；08大壳蟹用于姿态说明，普通蟹与Boss须分档。'],['09–12','奖励 / 育窝 / 水纹雾粒 / 配重桥','奖励图形只作造型方向，成品不能都像灯。12是现有v0.2增补机关，不冒充V5既有世界连线。']])+'<label>查找元素：<input id="search" placeholder="例如：鲸须、门、BG01、R1-05"></label><div id="assets">'
for x in a['assets']:
 dyn=x['dynamics'];imp=x['implementation'];b+=f'<details class="asset" data-search="{E(json.dumps(x,ensure_ascii=False))}"><summary>{E(x["id"]+" · "+x["name"])} <span class="badge">{E(x["layer"])}</span> · {E(imp["status"])}</summary>'+table(['项目','规格'],[['房间',' / '.join(x['rooms'])],['拆件',' / '.join(x['parts'])],['锚点',x['anchor']],['碰撞',x['collision']],['触发',dyn['trigger']],['循环 / 时序',dyn['loop']],['暂停 / 重建',dyn['pause']],['永久状态',dyn['state']],['现有实现',imp['notes']],['验证边界',imp['verification']]])+'</details>'
b+='</div><p>动态动因：外海水流驱动漂粒、须帘与灯绳；共生体产生微光；角色输入驱动攻击和交互；状态事件驱动开门与育窝变化。鲸尸不恢复呼吸、心跳或主动肌肉运动。</p></section>'
b+='<section id="rooms"><h2>05 / 七房原图 × 路线坐标 × 元素层级</h2><p>每房先看原画，再展开坐标图。原图来自你指定的 V5.2 完整游戏设计；05、06采用该版解剖重绘，其余沿用该目录原画。</p>'
for r in d['rooms']:
 id=r['id'];b+=f'<article class="card" id="{id}" style="margin:24px 0"><h3>{id} {E(r["name"])}</h3><span class="badge">{r["width"]} × {r["height"]}U</span> '+para(r['anatomy']['part']+'｜'+r['anatomy']['position'])+img(f'references/{id}.png',r['name']+'原画')+'<details open><summary>地图组成与精确路线</summary>'+img(f'maps/{id}.svg',r['name']+'坐标布局')+'<ol>'+''.join('<li>'+E(x)+'</li>' for x in r['walkthrough'])+'</ol>'+table(['组成','内容'],[['连接',' / '.join(r['connections'])],['敌人','；'.join(x['type']+f" @({x['x']},{x['y']})U："+x.get('skill','') for x in r['enemies']) or '无主动敌人'],['危险','；'.join(x['type']+'：'+x.get('tell','') for x in r['hazards']) or '无新增危险'],['奖励','；'.join(str(x.get('type',x.get('name',x))) for x in r['rewards']) or '无成长奖励'],['恢复',r['failure']],['环境故事',r['narrative']]])+'</details><details><summary>本房四层元素</summary>'+table(['层','构成'],[[k,v] for k,v in r['visual_layers'].items()])+'</details></article>'
b+='</section><section id="sources"><h2>06 / 来源、交付与接续</h2><p>已完成：四套资料读取、七房结构提取、全景及两张拆解板、七张坐标图、33项元素清单。未执行：新素材透明分件、引擎导入、新动画、七房物理通关。原有Godot五房和原画册保持原样。</p><div class="grid">'
for path,title in [('docs/设计依据.md','设计依据与冲突取舍'),('docs/分层与动态.md','分层与动态详细规格'),('data/r1-design.json','完整房间数据'),('data/elements.json','33项元素资产卡'),('data/prompts.json','本轮英文绘图提示词'),('docs/验收记录.md','图像与页面验收'),('RESUME.md','接续流程')]:b+=f'<a class="card" href="{path}">{title} ↗</a>'
b+='</div><details><summary>四张用户参考原图</summary><div class="grid">'+''.join(img(f'references/user-{i}.png',f'用户参考{i}') for i in range(1,5))+'</div></details></section></main><footer>原创 IP · 须门遗港 / 新绘原画使用内置 image_gen，源路径与提示已留存。参考氛围与探索精神，不复用第三方角色或地图。<br>本册中的“已实现”指既有v0.2代码状态，不代表这批概念图已接入游戏。</footer>'
js='''document.querySelector('#layerpick').addEventListener('change',e=>document.querySelector('#layerstrip').style.backgroundPosition='center '+(Number(e.target.value)*100/3)+'%');document.querySelector('#search').addEventListener('input',e=>{const q=e.target.value.toLowerCase();document.querySelectorAll('.asset').forEach(x=>x.hidden=!x.dataset.search.toLowerCase().includes(q));});'''
(p/'首关全景与拆解册.html').write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 首关全景与分层拆解</title><style>'+css+'</style>'+b+'<script>'+js+'</script></html>',encoding='utf8')
print('Atlas built: 7 rooms / 33 assets')
