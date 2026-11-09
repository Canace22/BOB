import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = path.resolve(import.meta.dirname, '..');
const source = path.join(root, 'assets/source/world-continuity-v1');
const book = path.join(root, 'docs/鲸腹遗城原画集/连续世界设计');
const design = process.env.WHALE_DESIGN_ROOT || 'G:/鲸落万物生/outputs/鲸落万物生_V5.2_完整游戏设计';
const read = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const write = (p, value) => { fs.mkdirSync(path.dirname(p), {recursive:true}); fs.writeFileSync(p, value, 'utf8'); };
const hash = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const snapshotDir = path.join(source, 'inputs');
const names = ['地图拓扑.json', '鲸体位置与连接.json', '房间布局.json'];
if (!fs.existsSync(snapshotDir)) {
  fs.mkdirSync(snapshotDir, {recursive:true});
  for (const name of names) fs.copyFileSync(path.join(design, 'data', name), path.join(snapshotDir, name));
  fs.copyFileSync(path.join(root, 'game/art/whalebelly/rooms.json'), path.join(snapshotDir, 'runtime-r1.json'));
}
const topology = read(path.join(snapshotDir, names[0]));
const anatomy = read(path.join(snapshotDir, names[1]));
const runtime = read(path.join(snapshotDir, 'runtime-r1.json'));
const prompts = read(path.join(source, 'prompts.json'));
const regionNames = {R1:'须门遗港',R2:'肺心潮庭',R3:'胃肠沉城',R4:'鸣肋断脊',R5:'耳海归墟'};
const colours = {R1:'#84c7cf',R2:'#cba4d0',R3:'#d9ba72',R4:'#cbd4ba',R5:'#9dbbdc'};
const special = {
  E01:['口角分层伤面延伸到口腔衬层；远处同一束须刷逐渐放大。','骨白伤缘→浅珊瑚衬层，冷蓝水雾不换。'],
  E02:['保留同一根斜向颌骨；沿口侧坡下降到舌面，不能借换房瞬移高度。','顶部须幕连续，台面起伏逐渐变宽。'],
  E03:['舌脊进入舌根宽台；蟹前安全前室与战场用软腭弯折隔开。','同一根分叉颌骨在两屏出现，光束角度一致。'],
  E04:['战后穿过已打开软帘；鲸须在口腔终止，食管以粗大纵褶接替。','先让前景软腭遮镜，再显示三段短冲台与下层承接坡。'],
  E05:['沿食管纵裂外缘下行；用横膈小裂孔与胃入口共同锚定两端。','长廊分数屏渐变，不把肺删掉换成巨型食管大厅。'],
  E10:['从胃外裂口上到横膈后面，经旧撕裂进肺后缘；天然消化道仍独立。','胃褶赭黄→剥离膜灰紫→肺缘冷蓝；跨数屏完成。'],
  E17:['母蟹巢外沿系膜维护坡回折，远景重见原胃枢灯；从远侧开原闩。','短返是折回同一胃外壁，不是穿实心肝脏或瞬移。'],
  E18:['胃外缘沿腹腔背侧创伤爬升到椎骨外侧；旧强流门保留P+A3。','组织逐渐脱落露骨；同一椎侧大突起先远后近。'],
  E20:['由训练骨台向椎体上外侧上升，既有迎珠门槛保持。','上路较亮、开阔，不能画进脊髓腔。'],
  E21:['从训练台沿下外侧筋膜沟回绕固定环；保持A3。','下路菌毯偏暗，隔着实体椎骨与上路互见。'],
  E22:['上路沿同一骨突回落到双贝宽台。','与下路看到的是同一双贝地标，不能复制两个Boss。'],
  E23:['下路绕过同一骨突上到双贝宽台。','合流台共用背景、灯、骨裂纹和营地。'],
  E25:['从交通椎向头折返60–70m的设计距离，依次见腰椎、胸椎肋根、颈后和枕骨侧。','长过渡属于原边；耳区与尾根绝不贴邻。'],
  E31:['从交通椎向尾走15–20m的设计距离，尾椎逐渐细化，肌腱比例增加。','尾鳍基部只画纤维与软组织，不新增肋骨。'],
  E32:['保持P+B+S同步环；释放闸连接尾柄侧裂与外海。','封闭内腔逐步打开外海负空间，尾叶保持无骨。'],
  E33:['从口侧剥离层绕上硬腭侧面，利用颅侧旧伤坡抵达鼻道破口。','硬腭实体必须保留；不能画成嘴直接通鼻的竖井。'],
  E34:['从肺心远侧沿气管旁向头上行，经鼻道纵裂台到喷气孔。','头顶双孔作为终点地标，开闩方向仍是R2-05。'],
  E35:['沿须筛固定环进入同一上颚须根旁脱层袋，尽头见记忆奖励。','不连接喷气孔、不添额外出口。'],
};
const edges = topology.edges.map(e => {
  const a = e.anatomy || anatomy.edges.find(x => x.id === e.id) || {};
  const [landmark, transition] = special[e.id] || [a.why, '保留所属器官同一条大轮廓，以局部褶层转折解释房间切换；不重复使用通用圆门。'];
  const from = runtime.find(r => r.id === e.from);
  const targetIndex = runtime.findIndex(r => r.id === e.to);
  const door = from?.doors.find(d => d.to === targetIndex && targetIndex >= 0);
  return {id:e.id,from:e.from,to:e.to,kind:e.kind,requiresAll:e.requiresAll || [],completionFlags:e.completionFlags || [],unlock:e.unlock || null,anatomy:a,landmark,transition,
    runtime:door ? {status:'existing_r1_link',door:door.pos,targetSpawn:door.spawn,ability:door.ability} : {status:'design_only_or_boundary_stub'},
    artStatus:'concept_proposal_not_runtime_geometry',
    seamContract:{scale:'两侧采用同一角色高度与像素比例，接缝区不缩放角色',height:'以脚底世界坐标对齐；当前局部像素不能直接拼接，需沿原边补连接坡或统一房间原点',overlap:'建议两侧各预留0.5屏静态补底；不是已测定参数',foreground:'前景在镜头跨界前淡出，避免整片前景贴屏瞬移',motion:'同水域共用方向/时间基准；鱼、气泡仍按原房所有权回收',safety:'切房不得把玩家出生于落差、敌人或未见过的危险区；保留原门槛与存档ID'}};
});
const data = {date:'2026-11-04',status:'concept_art_only',rooms:topology.rooms,edges,regions:anatomy.regions,locations:anatomy.rooms,abilities:topology.abilities,checkpoints:topology.checkpoints,travel:topology.travel,
  sourceHashes:names.map(n=>({path:'inputs/'+n,sha256:hash(path.join(snapshotDir,n))})),runtimeHash:hash(path.join(snapshotDir,'runtime-r1.json'))};
write(path.join(source,'connections.json'),JSON.stringify(data,null,2)+'\n');

const arts = [
  ['01-world','整鲸 · 一具身体的连续空间','用脊柱作纵轴、横膈作分隔，口腔、胸腔、腹腔与尾柄共享外轮廓和水体。图中细台只表达路径方向，精确连通以39边清单为准。','全世界 / 120m虚构古代须鲸；角色0.30m，尺度400:1。整图压缩景深，不能量取碰撞尺寸。'],
  ['02-r1-continuous','须门遗港 · 七房融入同一口腔','主路从口角创口沿须筛、舌背、舌根抵达咽后；上层旧伤坡通喷气孔，须根侧袋为独立回访终点。原有房间仍保留，连接带属于原边的美术展开。','E01–E04、E33、E35；局部构图衍生，不替代现有碰撞多边形。'],
  ['06-r1-seams','首章 · 三处真正接起来的门边','三条横带由上到下：须筛→舌台、舌台→蟹前室、蟹场→流膜育窝。两侧复用同一远景地标、台面趋势和光向，门不再全是相同的圆环。','E02/E03/E04；绘景接缝样板。具体过门高度差见下方工程核对表。'],
  ['03-diaphragm-junction','胃枢 · 消化主路与肺心支路','食管裂边到胃枢是主路；进入肺心要离开胃壁，经横膈旧撕裂上行到肺后缘。两条路线有各自可追溯的组织边缘，不能共用一条虚构气管。','E05/E10/E11/E37；胃枢可见下一方向，并提供回望地标。'],
  ['04-abdomen-spine','胃外到椎旁 · 上下两路再合流','组织逐渐退让，椎骨外侧显露；上锚路线与下菌毯路线绕同一骨突，汇合到同一双贝宽台。原P+A3组合门不变。','E18–E24/E38；上路开阔、下路遮蔽，循环重见同一营地。'],
  ['05-spine-directions','椎旁 · 向头与向尾是两段长旅程','上幅向头：椎旁→颈后→枕骨侧→耳周创伤腔；下幅向尾：渐细尾椎→肌腱尾柄→外海释放槽。上下是远隔两段的对照，绝非相邻房。','E25/E31/E32；60–70m与15–20m为既定设计估算，非实机测量。'],
];
const artPath = id => '../../../assets/source/world-continuity-v1/images/'+id+'.png';
const edgeRows = edges.map(e => `<tr data-kind="${e.kind}"><td><button class="edge" data-edge="${e.id}">${e.id}</button></td><td>${e.from}<br>↔ ${e.to}</td><td>${esc(e.anatomy.via)}</td><td>${esc([...e.requiresAll,...e.completionFlags,e.unlock?.flag].filter(Boolean).join(' + ') || '无能力硬门')}</td><td>${esc(e.landmark)}<br><small>${esc(e.transition)}</small></td><td>${e.runtime.status==='existing_r1_link'?'原工程已有房间连接':'设计 / 工程边界占位'}</td></tr>`).join('');
const r1Rows = edges.filter(e=>e.runtime.door).map(e=>`<tr><td>${e.id} ${e.from}→${e.to}</td><td>${e.runtime.door.join(', ')}</td><td>${e.runtime.targetSpawn.join(', ')}</td><td>${esc(e.runtime.ability||'无')}</td><td>${esc(e.transition)}</td></tr>`).join('');
const labels = [['R1 口腔',260,65,300,400],['R5 头耳段',530,65,550,505],['R2 肺心',800,65,815,360],['R4 椎旁纵轴',1290,65,1300,235],['R3 胃肠',1330,675,1330,490],['R5 尾段',1900,675,1850,470]];
const locator = `<svg class="locator" viewBox="0 0 2172 724" xmlns="http://www.w3.org/2000/svg" aria-label="区域部位注记">${labels.map(([name,x,y,tx,ty])=>`<g><path d="M${x} ${y}L${tx} ${ty}" fill="none" stroke="#efc78a" stroke-width="2" stroke-dasharray="5 5"/><circle cx="${tx}" cy="${ty}" r="7" fill="#f2cc8a"/><rect x="${x-105}" y="${y-24}" width="210" height="46" rx="5" fill="#07141ce8" stroke="#c3a775"/><text x="${x}" y="${y+8}" fill="#f1d6ab" font-size="27" text-anchor="middle">${name}</text></g>`).join('')}</svg>`;
const figures = arts.map(([id,title,desc,scope])=>`<section class="art" id="${id}"><div class="sectionhead"><p class="eyebrow">${id.slice(0,2)} / ORIGINAL CONCEPT</p><h2>${title}</h2><p>${desc}</p></div><div class="artstage"><a href="${artPath(id)}" target="_blank"><img src="${artPath(id)}" alt="${title}" ${id==='01-world'?'':'loading="lazy"'}></a>${id==='01-world'?locator:''}</div><div class="caption"><span>${scope}</span><a href="${artPath(id)}" download>下载原图 ↗</a></div></section>`).join('');
const html = `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>鲸腹遗城 · 连续世界设计原画册</title><style>
:root{color-scheme:dark;--bg:#07141c;--panel:#0d222b;--text:#e6e4d7;--sub:#9fb6bf;--gold:#e5b87c;--line:#29414a}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.8 "Microsoft YaHei",sans-serif}a{color:#a9d7dd;text-underline-offset:4px}button,select{font:inherit;color:var(--text);background:#16303a;border:1px solid #47616a;border-radius:5px;padding:6px 12px;cursor:pointer}button:hover{border-color:var(--gold)}nav{position:sticky;top:0;background:#07141cf0;backdrop-filter:blur(10px);border-bottom:1px solid var(--line);padding:10px 4%;display:flex;gap:20px;z-index:10;flex-wrap:wrap;font-size:14px}nav a{text-decoration:none}header,.content{max-width:1480px;margin:auto;padding:50px 4%}header{padding-bottom:30px}h1{font-size:clamp(30px,4vw,58px);line-height:1.3;margin:14px 0 20px}h2{font-size:clamp(23px,3vw,34px);line-height:1.4;margin:7px 0 12px}h3{font-size:20px}.eyebrow{color:var(--gold);font:12px/1.6 monospace;letter-spacing:2px}.lede{max-width:960px;color:#bfd0d4;font-size:19px}.tag{display:inline-block;padding:3px 10px;border:1px solid #52646b;margin-right:8px;font-size:13px}.note{padding:18px 22px;border-left:3px solid var(--gold);background:var(--panel)}.art{margin:35px auto 65px;max-width:1800px;scroll-margin-top:90px}.sectionhead,.caption{padding:0 4%;max-width:1480px;margin:0 auto}.sectionhead p{max-width:1100px;color:var(--sub)}.art img{display:block;width:100%;height:auto;margin:24px auto 14px}.caption{display:flex;gap:24px;justify-content:space-between;color:var(--sub);font-size:14px}.caption a{white-space:nowrap}.artstage{position:relative;margin:24px auto 14px}.artstage img{margin:0}.locator{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.card{background:var(--panel);padding:22px;border-top:2px solid #678b91}.card b{color:var(--gold)}small{color:var(--sub)}.tablewrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:13px 12px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{color:var(--gold);background:#102731}td:nth-child(2){white-space:nowrap}.edge{padding:2px 7px;font-size:13px}.diagram{overflow:auto;background:#0b1b25;border:1px solid var(--line);margin-top:18px}.diagram svg{width:100%;min-width:780px;display:block;max-height:78vh}.node{cursor:pointer}.node:hover path,.node.selected path{stroke:#ffe0a6;stroke-width:5}.link{cursor:pointer}.link:hover{stroke:#fff2c9!important;stroke-width:6!important}.link.selected{stroke:#fff2c9!important;stroke-width:6!important}.toolbar{display:flex;gap:10px;flex-wrap:wrap}.detail{padding:20px;background:#142d38;border-left:3px solid #97b9c7;min-height:130px;margin:18px 0}.r1label{font:22px "Microsoft YaHei",sans-serif;fill:#efe5d0}.rules{counter-reset:rule}.rules p{border-bottom:1px solid var(--line);padding:15px 0}.rules strong{color:var(--gold)}details{margin:16px 0;border:1px solid var(--line);padding:12px 18px}summary{cursor:pointer;color:var(--gold)}pre{white-space:pre-wrap;font:13px/1.7 monospace;color:#bfd0d4}footer{padding:40px 4%;border-top:1px solid var(--line);color:var(--sub)}@media(max-width:800px){.grid{grid-template-columns:1fr}header,.content{padding:32px 5%}.caption{display:block}nav{gap:12px}.art{margin-bottom:40px}td{min-width:100px}}
</style></head><body><nav><a href="#top">连续世界</a><a href="#02-r1-continuous">七房全景</a><a href="#06-r1-seams">接缝原画</a><a href="#map">36房连接图</a><a href="#contracts">39条连接</a><a href="#handoff">制作交接</a></nav>
<header id="top"><p class="eyebrow">WHALEBELLY RUINS / WORLD CONTINUITY / 2026.11.04</p><h1>从一间房，走进同一具巨鲸。</h1><p class="lede">保留现有36房与39条边，让器官轮廓、道路、光向和水流穿过房间边界。熟悉的地标从远处靠近，再从另一侧重见，形成可以在脑中记住的整体世界。</p><p><span class="tag">6张新原画</span><span class="tag">36房 / 39边</span><span class="tag">原创IP</span><span class="tag">设计阶段</span></p><div class="note">本轮交付概念原画、可交互连接图及制作规格。正式工程当前是R1七房；R1-05出口仍为章末，R1-06远侧闩仍提示待后章开启。新图未替换运行素材，连续空间尚未作为无缝关卡实现。</div></header>
${figures}
<main class="content"><section id="map"><p class="eyebrow">TOPOLOGY / SOURCE-PRESERVING</p><h2>36房与39条连接 · 可点击查路</h2><p>该图沿用原设计的拓扑排布，<strong>不代表鲸体部位或真实距离</strong>；部位以整鲸原画与房间信息为准。线的交叉不代表路口；只有房间节点才是连接。选择房间、连接或区域查看门槛和衔接方式。</p><div class="toolbar"><select id="region" aria-label="查看区域"><option value="all">全部区域</option>${Object.entries(regionNames).map(([k,v])=>`<option value="${k}">${k} ${v}</option>`).join('')}</select><button id="zoomIn">放大</button><button id="zoomOut">缩小</button><button id="reset">复位</button><label><input id="optional" type="checkbox" checked>选修</label><label><input id="shortcut" type="checkbox" checked>捷径</label></div><div class="diagram"><svg id="topology" viewBox="-50 160 2100 1480" xmlns="http://www.w3.org/2000/svg" aria-label="36房39边连通图"></svg></div><p><small>青色实线：主路/分支 · 金色虚线：捷径 · 灰紫点线：选修 · 点击连线查看门槛。金色圆点=存档，T=既定旅行节点；旅行仍需B、两端亲访并E调律。</small></p><div class="detail" id="detail" aria-live="polite">点击房间查看鲸体位置、玩法与相邻路线。图中的后续区域仍为设计。</div></section>
<section><h2>首章七房 · 本轮连续空间排布</h2><p>主路靠下，回访房沿上颚与旧伤坡展开。位置是本次构图提案，保留全部原连接；06通过旧伤侧廊绕过硬腭，07为须根旁死胡同。虚线末端仅标后章方向，不表示已接入。</p><div class="diagram"><svg viewBox="0 0 1300 650" xmlns="http://www.w3.org/2000/svg"><path d="M30 450Q80 160 470 100Q850 55 1260 310L1250 580Q650 620 70 550Z" fill="#172b33" stroke="#46636c" stroke-width="4"/><path d="M70 475Q200 430 320 460T580 490T850 470T1150 480" fill="none" stroke="#dbbb8a" stroke-width="10"/><path d="M320 440Q210 330 270 210Q290 160 430 150M380 400Q440 290 640 300" fill="none" stroke="#92b6b9" stroke-width="8" stroke-dasharray="12 8"/><path d="M700 110Q900 180 1130 200" fill="none" stroke="#66545a" stroke-width="35"/><path d="M430 150Q680 180 940 190" fill="none" stroke="#b4a0c3" stroke-width="4" stroke-dasharray="8 8"/><path d="M1150 480L1280 480" fill="none" stroke="#b4a0c3" stroke-width="4" stroke-dasharray="8 8"/>${[['01 外伤坡',110,470],['02 须筛',340,455],['03 舌台',590,480],['04 蟹前庭',850,470],['05 育窝',1120,480],['06 喷气孔',400,150],['07 记忆袋',650,300]].map(([n,x,y])=>`<g><circle cx="${x}" cy="${y}" r="25" fill="#16232a" stroke="#dfbb83" stroke-width="3"/><text x="${x}" y="${y+55}" text-anchor="middle" class="r1label">${n}</text></g>`).join('')}<text x="300" y="300" class="r1label">A2 / 旧伤坡</text><text x="520" y="365" class="r1label">A3 / 须根环</text><text x="980" y="175" class="r1label">← R2-05远侧开闩</text><text x="1090" y="560" class="r1label">向R3-01 →</text><text x="780" y="255" class="r1label">硬腭与口鼻隔断保留</text></svg></div></section>
<section><h2>连接应该怎样“像一个整体”</h2><div class="grid"><div class="card"><b>大形连续</b><p>每条边指定一条贯穿两屏的大轮廓：舌脊、胃褶、椎侧骨突或尾柄肌腱。局部台阶可变化，来源必须看得懂。</p></div><div class="card"><b>远景可回认</b><p>离开时看到的斜骨、横膈裂口和菌灯，从下一房的反方向再次出现。远景装饰洞不因此变成可走门。</p></div><div class="card"><b>线路会折回</b><p>胃肠回折、椎旁上下合流、耳区软膜捷径沿用原边；原门槛保留，让新能力改变旧空间的读法。</p></div></div><div class="rules"><p><strong>远景：</strong>共享水体色温、器官轴线与地标锚点；相邻房允许展示地标不同侧面。整鲸尺度与局部视窗不强行同尺。</p><p><strong>中景：</strong>同一组织跨门不断裂，材质在连接带渐变；鼻道、肺、胃、肝外缘和椎旁各有边界，必须经已有破口或旧伤接通。</p><p><strong>可玩层：</strong>沿用原碰撞与门槛设计；后续接入时统一脚底高度和出生平台。概念坡道不可直接覆盖现有碰撞，更不能靠换房隐藏落差。</p><p><strong>前景：</strong>软腭、骨根和膜边用于自然遮镜；从A房离开的框景在B房反侧有对应体块。不得遮掉落脚边和危险预告。</p><p><strong>环境动态：</strong>鱼群自身游动与路径分开；垂须只在口腔、固定根端并延迟摆动；气泡按已设水域预热和回收。新图中的运动只是制作建议，未在本轮实现或验收。</p><p><strong>镜头：</strong>先看见下一地标，再让前景遮蔽房间装卸；交界留安全落脚区。连续世界感并不自动要求整鲸同屏加载。</p></div></section>
<section><h2>工程接缝核对 · 当前局部像素</h2><p>以下直接取自当前 <code>game/art/whalebelly/rooms.json</code> 快照。不同房间的局部坐标原点与画幅不同，数值差异说明尚不能直接把图片横向拼成碰撞地图。表中是现状，接缝原画是后续返修方向。</p><div class="tablewrap"><table><thead><tr><th>连接</th><th>原房门点 px</th><th>目标出生脚点 px</th><th>现有门槛</th><th>美术衔接规格</th></tr></thead><tbody>${r1Rows}</tbody></table></div></section>
<section id="contracts"><h2>39条连接 · 逐边衔接规格</h2><p>保持原边ID、两端、能力门和开闩侧，全部可追溯到V5.2资料。距离与破口构型是原创幻想关卡设计，不作为真实鲸体医学结论。点击编号可在上图定位。</p><div class="tablewrap"><table><thead><tr><th>ID</th><th>房间两端</th><th>部位与经过空间</th><th>条件 / 持久闩</th><th>连续地标与材质过渡</th><th>工程状态</th></tr></thead><tbody>${edgeRows}</tbody></table></div></section>
<section id="handoff"><h2>制作交接与边界</h2><p>首选下一步：先在<strong>E02（须筛→舌台）</strong>做接缝样板，使用现有两房的真实画幅和碰撞，补半屏旧伤侧坡、两侧公共斜骨远景与前景遮镜。静态构图、双向过门、镜头边界通过后，再扩展E03/E04；跨区长廊等待对应房间工程就绪。</p><p>接缝规格、建议重叠长度与新镜头方法均为<strong>候选</strong>。本轮没有新引擎方法实测，不将它们写成通用Skill成功配方。已有鱼群/垂须/气泡配方按原验收状态复用。</p><p>参考《Hollow Knight》的范围仅限互联探索、能力回访、氛围层次和可读性目标；全部图片由本项目原画衍生，角色、器官空间、材质、机关、UI与Logo保持原创。</p><p><a href="../../../assets/source/world-continuity-v1/connections.json">36房39边与原工程快照映射</a> · <a href="../../../assets/source/world-continuity-v1/prompts.json">完整英文提示词</a> · <a href="设计说明.md">中文设计与验收说明</a></p>${prompts.specs.map(s=>`<details><summary>${s.id} · ${s.title} · 英文提示词</summary><pre>${esc(s.prompt)}</pre></details>`).join('')}</section></main><footer>鲸腹遗城 · 连续世界设计原画册 / 2026-11-04<br>新绘概念与原工程现状分别登记；不代表已实现无缝加载、全世界通关或用户美术定稿。</footer>
<script>const DATA=${JSON.stringify(data).replace(/</g,'\\u003c')};const COLORS=${JSON.stringify(colours)};
const svg=document.querySelector('#topology'), detail=document.querySelector('#detail');const NS='http://www.w3.org/2000/svg';
function el(tag,attrs,parent=svg){const n=document.createElementNS(NS,tag);for(const [k,v] of Object.entries(attrs))n.setAttribute(k,v);parent.appendChild(n);return n;}
const rooms=new Map(DATA.rooms.map(r=>[r.id,r]));
const cp=new Set(DATA.checkpoints.map(c=>c.room)),travel=new Set(DATA.travel.map(t=>t.room));
function linePath(e){
  const a=rooms.get(e.from),b=rooms.get(e.to),step=10,W=230,H=154,ox=-200,oy=120;
  const ix=(x,y)=>Math.round((y-oy)/step)*W+Math.round((x-ox)/step);
  const point=i=>[ox+i%W*step,oy+Math.floor(i/W)*step];
  const start=ix(a.x,a.y),end=ix(b.x,b.y),blocked=new Uint8Array(W*H);
  for(const r of DATA.rooms){if(r.id===e.from||r.id===e.to)continue;
    for(let y=r.y-40;y<=r.y+40;y+=step)for(let x=r.x-90;x<=r.x+90;x+=step){const k=ix(x,y);if(k>=0&&k<blocked.length)blocked[k]=1;}}
  const prev=new Int32Array(W*H).fill(-2),queue=new Int32Array(W*H);let head=0,tail=1;queue[0]=start;prev[start]=-1;
  const dx=b.x>=a.x?1:-1,dy=b.y>=a.y?W:-W,dirs=[dx,dy,-dy,-dx];
  while(head<tail&&prev[end]===-2){const current=queue[head++];for(const d of dirs){const next=current+d;if(next<0||next>=prev.length||prev[next]!==-2||blocked[next])continue;if(Math.abs(d)===1&&Math.floor(next/W)!==Math.floor(current/W))continue;prev[next]=current;queue[tail++]=next;}}
  if(prev[end]===-2)throw Error('No topology route '+e.id);
  const points=[];for(let k=end;k!==-1;k=prev[k])points.push(point(k));points.reverse();
  const simplified=[points[0]];for(let i=1;i<points.length-1;i++){const p=points[i-1],q=points[i],r=points[i+1];if((q[0]-p[0])*(r[1]-q[1])!==(q[1]-p[1])*(r[0]-q[0]))simplified.push(q);}simplified.push(points.at(-1));
  return simplified.map((p,i)=>(i?'L':'M')+p[0]+' '+p[1]).join(' ');
}
for(const e of DATA.edges){const g=el('g',{'data-kind':e.kind,class:'edge-group'});const p=el('path',{d:linePath(e),fill:'none',stroke:e.kind==='shortcut'?'#d3ab70':e.kind==='optional'?'#8a8da6':'#568d9f','stroke-width':3,'stroke-dasharray':e.kind==='shortcut'?'12 8':e.kind==='optional'?'4 8':'none',class:'link','data-id':e.id},g);el('title',{},p).textContent=e.id+' '+e.from+' ↔ '+e.to+' '+e.requiresAll.join('+');p.addEventListener('click',()=>showEdge(e.id));}
for(const r of DATA.rooms){const c=COLORS[r.region];const g=el('g',{class:'node','data-id':r.id,tabindex:'0',role:'button','aria-label':r.id+' '+r.name});const x=r.x,y=r.y;el('path',{d:'M'+(x-73)+' '+(y-30)+'Q'+(x-80)+' '+(y-13)+' '+(x-78)+' '+(y+18)+'L'+(x-34)+' '+(y+29)+'L'+(x+72)+' '+(y+24)+'Q'+(x+82)+' '+(y+5)+' '+(x+73)+' '+(y-25)+'Z',fill:'#142b36',stroke:c,'stroke-width':2},g);el('text',{x,y:y-3,'text-anchor':'middle',fill:c,'font-size':18},g).textContent=r.id;el('text',{x,y:y+18,'text-anchor':'middle',fill:'#e5e5d8','font-size':15},g).textContent=r.name;if(cp.has(r.id))el('circle',{cx:x-65,cy:y-24,r:5,fill:'#e9b36a'},g);if(travel.has(r.id))el('text',{x:x+65,y:y-17,fill:'#b3e2e3','font-size':12},g).textContent='T';g.addEventListener('click',()=>showRoom(r.id));g.addEventListener('keydown',e=>{if(e.key==='Enter')showRoom(r.id);});}
function clear(){svg.querySelectorAll('.selected').forEach(n=>n.classList.remove('selected'));}
function showRoom(id){clear();const r=rooms.get(id),a=DATA.locations.find(x=>x.id===id);svg.querySelector('.node[data-id="'+id+'"]').classList.add('selected');detail.textContent=id+' '+r.name+'｜'+a.part+'｜'+a.position+'。玩法：'+r.experience+'。地标：'+a.landmark+'。相邻边：'+DATA.edges.filter(e=>e.from===id||e.to===id).map(e=>e.id+' '+(e.from===id?e.to:e.from)).join('；')+'。状态：'+(id.startsWith('R1-')?'现工程有此房，新衔接为概念。':'已有设计，尚无正式房间接入。');}
function showEdge(id){clear();const e=DATA.edges.find(x=>x.id===id);svg.querySelector('.link[data-id="'+id+'"]').classList.add('selected');detail.textContent=e.id+' '+e.from+' ↔ '+e.to+'｜'+e.anatomy.via+'。'+e.landmark+' '+e.transition+' 条件：'+([...e.requiresAll,...e.completionFlags].join(' + ')||'无能力硬门')+(e.unlock?'；首次开闩侧 '+e.unlock.from+'，持久旗标 '+e.unlock.flag:'')+'。';}
document.querySelectorAll('[data-edge]').forEach(b=>b.onclick=()=>{document.querySelector('#region').value='all';svg.setAttribute('viewBox','-50 160 2100 1480');showEdge(b.dataset.edge);document.querySelector('#map').scrollIntoView();});
document.querySelector('#region').onchange=e=>{const rr=DATA.rooms.filter(r=>e.target.value==='all'||r.region===e.target.value);const xs=rr.map(r=>r.x),ys=rr.map(r=>r.y);svg.setAttribute('viewBox',[Math.min(...xs)-120,Math.min(...ys)-90,Math.max(...xs)-Math.min(...xs)+240,Math.max(...ys)-Math.min(...ys)+180].join(' '));};
for(const kind of ['optional','shortcut'])document.querySelector('#'+kind).onchange=e=>svg.querySelectorAll('[data-kind="'+kind+'"]').forEach(n=>n.style.display=e.target.checked?'':'none');
function zoom(f){const b=svg.viewBox.baseVal,w=b.width*f,h=b.height*f;svg.setAttribute('viewBox',[b.x+(b.width-w)/2,b.y+(b.height-h)/2,w,h].join(' '));}document.querySelector('#zoomIn').onclick=()=>zoom(.75);document.querySelector('#zoomOut').onclick=()=>zoom(1.333);document.querySelector('#reset').onclick=()=>{svg.setAttribute('viewBox','-50 160 2100 1480');document.querySelector('#region').value='all';};
</script></body></html>`;
write(path.join(book,'原画册.html'),html);
write(path.join(book,'设计说明.md'),`# 鲸腹遗城 · 连续世界设计\n\n2026-11-04。范围：概念原画、世界连接、后续制作规格；不修改Godot玩法、房间或运行资源。\n\n## 设计依据\n\n- V5.2的36房、39边、鲸体位置与房间布局快照：\`assets/source/world-continuity-v1/inputs/\`。\n- 当前工程真实入口：\`game/project.godot → content/whalebelly/main.tscn\`；工程R1七房与门点快照：\`runtime-r1.json\`。\n- R1七房原画、已验收环境材质及全局美术规范；保留原IP、主角和能力身份。\n- 参考《Hollow Knight》的互联探索、能力回访、氛围与可读性目标，不复制其具体地图或视觉元素。\n\n## 本轮产物\n\n${arts.map(([id,title,desc,scope])=>`### ${id} ${title}\n\n![${title}](${artPath(id)})\n\n${desc}\n\n${scope}`).join('\n\n')}\n\n## 衔接原则\n\n1. 主路径是R1→R3胃枢，胃枢分支进R2肺心，获得原P/A3后去R4；不按区域编号强排线性长廊。\n2. 每条边有器官来源、一个跨屏地标、连续台面、材质渐变和原开闩侧。\n3. 保留胃肠回折捷径、椎旁上下路合流、耳区返程和六个选修口。\n4. R5头耳段与尾段分居两端，E25/E31用长过渡说明距离，不能把两幅设计图当相邻房。\n5. 七房门的局部像素不直接等于统一世界坐标。连接带需后续灰盒、静态和动态验收后才算实现。\n6. 后续E02先做样板，逐边推进；不改变原能力门与V6进度。\n\n## 全部连接\n\n| 边 | 两端 | 经过空间 | 条件 | 连续设计 |\n|---|---|---|---|---|\n${edges.map(e=>`| ${e.id} | ${e.from} ↔ ${e.to} | ${e.anatomy.via} | ${[...e.requiresAll,...e.completionFlags,e.unlock?.flag].filter(Boolean).join('+')||'无能力硬门'} | ${e.landmark} ${e.transition} |`).join('\n')}\n\n## 验收边界\n\n人工读图与AI视觉审查、文件/链接/交互核对分别保存。未获用户美术定稿，未实机实现无缝空间，不把新衔接方法写成成功配方。英文原提示词见制作源prompts.json；图册为纯静态本地HTML，可离线浏览。\n`);
console.log(JSON.stringify({book:path.relative(root,book),rooms:data.rooms.length,edges:edges.length,art:arts.length}));
