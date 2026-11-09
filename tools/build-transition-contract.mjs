import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..');
const source=path.join(root,'assets/source/xumen-transition-style-v1');
const book=path.join(root,'docs/鲸腹遗城原画集/过渡样式设计');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const sha=s=>crypto.createHash('sha256').update(s).digest('hex');
const rooms=JSON.parse(read('game/art/whalebelly/rooms.json'));
const snapshot=JSON.parse(read('assets/source/xumen-connected-v2/layout-snapshot.json'));
const origins=snapshot.rooms.map(r=>r.origin);
const round=x=>Math.round(x*1000)/1000;
const point=(a,b)=>a.map((x,i)=>round(x+b[i]));
const edges=[];
for(let i=0;i<4;i++){
 const a=point(origins[i],[rooms[i].size[0]-8,rooms[i].surfaces[0].at(-1)[1]]);
 const b=point(origins[i+1],[8,rooms[i+1].surfaces[0][0][1]]);
 if(Math.abs(a[1]-b[1])>.001)throw Error('Unmatched floor');
 const floor=[a[0]-18,b[0]+18];
 edges.push({id:`E0${i+1}`,from:rooms[i].id,to:rooms[i+1].id,fromName:rooms[i].name,toName:rooms[i+1].name,
  style:i===0?'T01':'T02',anchors:{from:a,to:b},existingFloor:{x:floor,y:a[1],width:round(floor[1]-floor[0]),thickness:38},
  roomBoundaryGap:512,proposedArtReplacement:{x:[floor[0]-256,floor[1]+256],width:round(floor[1]-floor[0]+512),overlapEachSide:256},
  proposedWorkingCanvas:{x:[floor[0]-800,floor[1]+800],y:[round(a[1]-896),round(a[1]+640)],width:round(floor[1]-floor[0]+1600),height:1536},
  gate:i===3?'boss defeated':'none',preserve:'Original surface and ability graph; proposed art must conform, no collision changes.',status:'specified_not_implemented'});
}
const starts=[point(origins[1],[150,190]),point(origins[1],[1660,277])];
const ends=[point(origins[5],[100,795]),point(origins[6],[12,565])];
const shafts=[origins[5][0]-160,origins[6][0]-140];
for(let n=0;n<2;n++){
 const a=starts[n],b=ends[n],count=Math.ceil(Math.abs(b[1]-a[1])/130);
 const platforms=Array.from({length:count+1},(_,i)=>({id:`Floor_${n===0?'E33':'E35'}_${i}`,x:[shafts[n]-105,shafts[n]+105],y:round(a[1]+(b[1]-a[1])*i/count),width:210,oneWay:true}));
 edges.push({id:n===0?'E33':'E35',from:rooms[1].id,to:rooms[n+5].id,fromName:rooms[1].name,toName:rooms[n+5].name,style:'T03',anchors:{from:a,to:b},shaftX:shafts[n],rise:round(a[1]-b[1]),platformCount:platforms.length,platforms,gate:n===0?'float':'anchor',
  existingAccess:{lower:[a,[shafts[n],a[1]]],upper:[[shafts[n],b[1]],b]},
  proposedWorkingCanvas:{x:[Math.min(a[0],b[0],shafts[n]-105)-800,Math.max(a[0],b[0],shafts[n]+105)+800],y:[round(b[1]-720),round(a[1]+640)]},
  visualRule:'Paint an irregular continuous bone spine in middle depth; three or more distinct ledge silhouettes align with ALL original tops. Support pixels stay behind traversal and do not imply blocking walls.',status:'specified_not_implemented'});
}
const contract={version:'1.0',scope:'seamless transition integration specification only; no runtime patch or publication',
 sources:{rooms:{path:'game/art/whalebelly/rooms.json',sha256:sha(read('game/art/whalebelly/rooms.json'))},layout:{path:'game/src/campaign/connected/connected_layout.gd',sha256:sha(read('game/src/campaign/connected/connected_layout.gd'))},snapshot:{path:'assets/source/xumen-connected-v2/layout-snapshot.json',sha256:sha(read('assets/source/xumen-connected-v2/layout-snapshot.json'))}},
 coordinates:{unit:'Godot world pixel at1x; exported illustration pixels are not automatically world pixels',x:'right positive',y:'down positive',roomToWorld:'room.origin + local',rebase:'world = local + activeOrigin; scene and camera translate by negative deltaOrigin',rounding:'numbers shown to0.001; runtime source remains authoritative'},
 defaults:{artOverlap:256,workingMargin:800,minimumStandingClearance:97,proposedJumpVisualClearance:240,worldTopTolerance:2,collisionTolerance:0,landmarkScreenTolerance:1,referenceViewport:[1280,720],checkZooms:[1,1/1.05],warning:'All art margins and tolerances are project-specific proposals, not measured success. Check real viewport/zoom coverage and adjust margins instead of stretching.'},
 policy:{keepSevenRooms:true,keepSixEdges:true,keepV6:true,keepExistingCollision:true,keepAbilityGates:true,newPlayableRegions:false,wholeImageAsRuntime:false,blurAsSeamFix:false},
 edges};
fs.writeFileSync(path.join(source,'integration-contract.json'),JSON.stringify(contract,null,2)+'\n');
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const tags=['E01','E02','E03','E04'];
const table=edges.map(e=>`<tr><td>${e.id}<br><small>${e.style}</small></td><td>${esc(e.fromName)} → ${esc(e.toName)}</td><td>(${e.anchors.from.join(', ')})<br>→ (${e.anchors.to.join(', ')})</td><td>${e.existingFloor?`碰撞顶面宽${e.existingFloor.width}px<br>重绘范围${e.proposedArtReplacement.x.join('…')}<br>两侧各侵入256px`:`上升${e.rise}px<br>${e.platformCount}个210px平台<br>平台位置全部保留`}</td></tr>`).join('');
const bandSvg=`<svg viewBox="0 0 1200 340" role="img" aria-label="E01接入带：两端重绘各256像素，现有连接地面564像素；概念图工作画布有额外800像素镜头余量"><defs><pattern id="hatch" patternUnits="userSpaceOnUse" width="9" height="9"><path d="M0 9L9 0" stroke="#557981" stroke-width="1"/></pattern></defs><rect x="30" y="40" width="1140" height="250" fill="#102d38"/><rect x="55" y="72" width="260" height="180" fill="#203c46"/><rect x="885" y="72" width="260" height="180" fill="#203c46"/><rect x="315" y="72" width="570" height="180" fill="#254b50"/><rect x="225" y="55" width="750" height="215" fill="url(#hatch)" stroke="#e2c58d" stroke-width="2"/><path d="M55 218L1145 218" stroke="#d5ede0" stroke-width="5"/><path d="M315 72V252M885 72V252" stroke="#7ca2a7" stroke-dasharray="8 7"/><g fill="#e5ddc7" font-size="20" font-family="sans-serif" text-anchor="middle"><text x="170" y="103">旧房 A</text><text x="1020" y="103">旧房 B</text><text x="600" y="112">完整重绘一个结构连续的接合段</text><text x="270" y="160">左重绘</text><text x="600" y="160">原连接地面 564 px</text><text x="930" y="160">右重绘</text><text x="600" y="205">固定脚底基准 Y = 631.847</text><text x="600" y="311">示意图不按比例 · 工程外侧另留镜头和视差余量</text></g></svg>`;
const topology=`<svg viewBox="0 0 1200 290" role="img" aria-label="六条连接对应三种样式"><g fill="#183d47" stroke="#709b9f" stroke-width="2"><rect x="235" y="20" width="230" height="65" rx="10"/><rect x="550" y="20" width="230" height="65" rx="10"/><rect x="25" y="190" width="180" height="65" rx="10"/><rect x="265" y="190" width="180" height="65" rx="10"/><rect x="505" y="190" width="180" height="65" rx="10"/><rect x="745" y="190" width="180" height="65" rx="10"/><rect x="985" y="190" width="190" height="65" rx="10"/></g><g stroke="#9ccbbd" fill="none" stroke-width="3"><path d="M205 220H265M445 220H505M685 220H745M925 220H985M350 190V85M410 190V130H665V85"/></g><g fill="#e1d8c2" font-family="sans-serif" text-anchor="middle" font-size="19"><text x="350" y="59">喷气孔上层</text><text x="665" y="59">鲸须记忆袋</text><text x="115" y="230">外伤坡</text><text x="355" y="230">须筛</text><text x="595" y="230">舌台</text><text x="835" y="230">负壳母蟹</text><text x="1080" y="230">喉膜育窝</text><text x="235" y="180">E01 · T01</text><text x="475" y="180">E02 · T02</text><text x="715" y="180">E03 · T02</text><text x="955" y="180">E04 · T02</text><text x="270" y="118">E33 · T03</text><text x="640" y="116">E35 · T03</text></g></svg>`;
const sections=[
 ['接入结论','保留现有七房、六边及角色移动。将每条连接从“一段桥贴图”改为同时侵入两侧旧房的完整接合结构。T01用于E01；T02拆成E02、E03、E04三个专用变体；T03分别用于两条支路，E33朝左绕上、E35朝右上行。三张概念图只提供结构语言，不能直接缩放铺满关卡。'],
 ['旧画面要怎么处理','先把A房右侧和B房左侧各256px列成重绘带；只移除被新骨架/路面替代的原像素。通过可编辑选区把旧裁片里的蓝水从骨、草、灯、前景中分开，补出隐藏背景。禁止全局按蓝色抠图：青色植物、鱼群与暗部同样可能被误删。每个实际可见像素有唯一所有者，清掉旧地面/旧鱼/旧挂须的重复副本。'],
 ['远景与层级','远景由一个世界坐标下的水域/骨架带负责，不能每房重新居中贴同一张图；各远景素材按同一锚点、尺度和水色接上。中景承载有根的骨拱、褶皱、竖井支撑；可玩层匹配原碰撞；前景只包地形底缘及外角。接合处互相咬合的图片必须同速视差，不能贴住时完整、移动时裂开。'],
 ['路面与平台','E01–E04核心碰撞顶面保持原坐标，重绘坡度/高差只能发生在不改变落脚轮廓的材质与支撑上。台面中央保持可读，根部厚实、端部破损；平台至少三种原画轮廓，按稳定实例ID选型，左右镜像只作补充。E33/E35的支撑绘在中景并绕开攀升走廊，不把可穿过的支撑画成横挡通路的实墙。每个现有平台逐一核对脚底锚点，不能一张细长图任意拉伸。'],
 ['镜头与坐标','自然跨房延用当前同一角色及镜头，不切全屏快照、不在房间边界重新钳制相机。局部原点变化时，场景、镜头锚点、Shader里的room_origin/scene_origin以及动件世界坐标一次性等量更新。相机跟随偏移85px和现有冲刺缩放保留；画布按最大可见范围扩边，余量不够就补绘。'],
 ['动态与声音','一个章时钟驱动接合段，跨房保持相位，暂停停在当前姿态。鱼身体帧与路径分开，路径穿过接合带而不因房间ID重置；气泡预热并在同一水域内有界回收；垂须根部固定、末端延迟。环境音按区域权重平滑混合，跨越整段空间渐变，不在激活帧重播。光向固定，局部亮度变化小，不用全屏水波拉扯地形。'],
 ['角色、敌人与存档','存档继续用原房间ID及局部坐标，过渡带不新增保存点；死亡回已存在的营地。Boss、浮游、锚环门槛原样保留。自然跨房角色不能重建；邻房原画角色必须清除。需要提前展示的敌人/奖励按稳定ID准备和去重，视觉可见前就准备好，逻辑仍按各自原规则激活，不生成一个假烘焙敌人。'],
 ['先做一条，再扩展','第一批只做E01：锁定脚底→A尾/接合/B头联合原画→分层与遮挡补绘→固定镜头对照→步行/冲刺双向穿越→暂停/读档。通过再做E02、E03、E04；最后分别处理E33与E35。每一条边有源图、母版、导出、实例表、对照和录像；失败只返修相关层，旧合格素材保留。']
];
const html=`<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 无缝接入规格</title><style>*{box-sizing:border-box}body{background:#081a24;color:#c8dbde;font:16px/1.85 system-ui,"Microsoft Yahei",sans-serif;margin:0}main{max-width:1180px;margin:auto;padding:36px 24px 80px}h1,h2,h3{color:#e7d7b3;line-height:1.45}h1{font-size:clamp(27px,4vw,42px)}h2{font-size:24px;margin-top:36px}a{color:#96d7d6}small{color:#9bb9be}.notice,section{border:1px solid #30525a;background:#102a35;border-radius:10px;padding:18px 22px;margin:16px 0}svg{width:100%;display:block}.table{overflow:auto}table{border-collapse:collapse;min-width:850px;width:100%;font-size:14px}td,th{border-bottom:1px solid #32515b;padding:12px;text-align:left;vertical-align:top}th{color:#dfd3b3}ol,ul{padding-left:24px}.stats{display:flex;gap:12px;flex-wrap:wrap}.stats span{background:#1b3b44;border-radius:8px;padding:9px 15px}.status{color:#f1d39d}details{border-top:1px solid #31545e;padding:12px 0}summary{cursor:pointer;color:#a6d3cc}code{overflow-wrap:anywhere;font-size:14px}@media(max-width:600px){main{padding:20px 12px}section{padding:16px}svg{min-width:700px}.diagram{overflow:auto}h2{font-size:22px}}</style><main><small>DESIGN CONTRACT · SPECIFIED / NOT IMPLEMENTED</small><h1>无缝接入：把接头画成一段完整空间</h1><p><a href="原画册.html">← 返回三张过渡样式图</a> · <a href="无缝接入设定.md">阅读完整制作规格</a></p><div class="notice"><strong>本轮已确定接入方法与坐标合同；新样式尚未接入游戏。</strong><br>现有物理连通继续沿用；视觉、动态、声音和对象生命周期需要共同连续。旧工作区Shader实验不视为已验收结果。</div><div class="stats"><span>7 个既有房间</span><span>6 条既有连接</span><span>4 段主路</span><span>2 条上行支路</span><span>26 个原地形实例保留</span></div><h2>三类样式，各有职责</h2><div class="diagram">${topology}</div><h2>E01的接合范围如何确定</h2><p>实际地面跨度564px，其中两个房间外边界相隔512px。建议将原地面两侧各再纳入256px联合重绘；图层制作范围还要覆盖镜头扫过的空间。以下示意不按比例。</p><div class="diagram">${bandSvg}</div><h2>六条边的工程锚点</h2><p>单位为世界像素，Y向下；以下取自现有工程和坐标快照。256px侵入重绘与800px制作余量是本项目拟定起点，须按实际镜头验证，并非已通过的通用数值。</p><div class="table"><table><thead><tr><th>边/样式</th><th>连接</th><th>脚底世界锚点</th><th>重绘约束</th></tr></thead><tbody>${table}</tbody></table></div>${sections.map(([title,p])=>`<section><h2>${title}</h2><p>${p}</p></section>`).join('')}<h2>当前实现需要补上的连续性</h2><ul><li>当前共用远景被放大覆盖整章，新图要改为世界锚点下的专用远景带，不能把单幅概念图硬拉成长图。</li><li>当前跨房会清短效/弹体；若升级为效果连续，应将仍存活对象迁入持久容器，原点变化时保持世界位置/剩余寿命，避免闪断或双重计时。这是待实现项。</li><li>当前相邻房间敌人在首次激活时建立，镜头提前看到邻房可能暴露显隐；需用稳定ID提前准备视觉与状态，不能依赖进门才生成。</li><li>当前房间环境音与章时钟仍有各自生命周期；接合段应按章时钟与区域混音统一。上述属于接入要求，不能由旧测试推断已完成。</li></ul><h2>每条边的验收线</h2><ol><li>固定镜头左/中/右各一张：无矩形边、双地面、材质或光向突变；关闭前景/雾后结构仍自然。</li><li>站立脚底与可玩顶面误差目标≤2px；原碰撞坐标与能力门数据必须保持一致。</li><li>步行、反向、冲刺、空中跨界：角色不重建，速度无异常突变，世界地标屏幕误差目标≤1px；暂停恢复不补播。</li><li>按当前1280×720及实际冲刺缩放检查扩边，另测计划支持宽屏；不拉伸原图补空洞。</li><li>支路能上去也能返回；营地保存、死亡、独立重载仍有效；旧档不改写成新地图编号。</li><li>原工程57项/连通38项作为已有回归入口，另新增接缝/动件跨界和音频连续检查，不能拿旧报告替代本批验收。</li></ol><p class="status">通过以上检查并留下实机证据后，才允许替换对应连接段并发布试玩。首批执行对象：E01；其余边不抢先批量替换。</p><footer><small>依据当前源文件生成，完整机器合同：assets/source/xumen-transition-style-v1/integration-contract.json。审查为设计/源码核对，未声明引擎已验证。</small></footer></main></html>`;
fs.writeFileSync(path.join(book,'无缝接入设定.html'),html,'utf8');
console.log('Specified six edges, preserved26 surfaces; wrote integration contract and page.');
