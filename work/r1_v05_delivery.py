from pathlib import Path
import json,shutil,hashlib,html,csv
ROOT=Path('G:/鲸落万物生');P=ROOT/'BOB/godot/WhalebellyRuins'
OUT=ROOT/'outputs/须门遗港_v0.5_参考图可玩关卡';OUT.mkdir(parents=True,exist_ok=True)
for d in ['images','reference','docs']:(OUT/d).mkdir(exist_ok=True)
rooms=json.loads((P/'assets/rooms.json').read_text('utf8'))
manifest=json.loads((P/'docs/element-manifest.json').read_text('utf8'))
for r in rooms:
 for source,target in [(P/'evidence'/f'{r["id"]}.png',OUT/'images'/f'{r["id"]}.png'),(P/'assets/reference/r1'/f'{r["id"]}.png',OUT/'reference'/f'{r["id"]}.png')]:shutil.copy2(source,target)
for name in ['layer-0','layer-1','layer-2','layer-3','dynamic-camera-left','dynamic-camera-right','dynamic-motion-a','dynamic-motion-b','membrane-loaded','gate-open','reward-collected','terrain-02']:
 if (P/'evidence'/f'{name}.png').exists():shutil.copy2(P/'evidence'/f'{name}.png',OUT/'images'/f'{name}.png')
for directory,names in [('package-normal',['normal-01-start','normal-boss-start','normal-boss-defeated','normal-earned-dash','normal-complete']),('deep',['deep-entry','deep-350','deep-1350','deep-rebound-return']),('elements',['06-new-bottom-slope','07-outbound-ring-1','07-outbound-ring-4','07-right-wall'])]:
 for n in names:
  f=P/'evidence'/directory/(n+'.png')
  if f.exists():shutil.copy2(f,OUT/'images'/(n+'.png'))
for f in ['element-manifest.json','全要素覆盖表.md','coverage-readiness.md','asset-provenance.json','source-manifest.json','build-manifest.json','environment-contract.json','native-export.json']:
 if (P/'docs'/f).exists():shutil.copy2(P/'docs'/f,OUT/'docs'/f)
with (OUT/'docs/全要素覆盖表.csv').open('w',encoding='utf-8-sig',newline='')as f:
 writer=csv.writer(f);writer.writerow(['ID','名称','类型','来源判断','预期实例','运行节点','外观','空间','动态','物理','交互','声音','恢复','状态'])
 for e in manifest['elements']:
  writer.writerow([e['element_id'],e['name'],e['category'],e['origin'],e['instances'].get('expected_count','生成规则'),'; '.join(e['instances'].get('runtime_node_paths',[])),*[e['dimensions'][k]['status']for k in ['appearance','spatial','motion','physics','interaction','audio','lifecycle']],e['status']])
cards=''
locations=['下颌外伤与口缘入口','上颚鲸须筛与两条回访门','舌背隆起、中央薄膜与下层返坡','口腔后部负壳蟹战场','通往食管的流膜育窝','鼻道外颅侧旧伤与上层骨板','上颚须根记忆袋，右壁封闭']
for i,r in enumerate(rooms):
 cards+=f'''<section class="room" id="{r['id']}"><div class="eyebrow">{r['id']} · {locations[i]}</div><h2>{r['name']}</h2><div class="compare"><img src="reference/{r['id']}.png" alt="原始参考"><img class="after" src="images/{r['id']}.png" alt="实际Godot固定机位"><span class="tag">左：引擎实景 ／ 右：源图</span></div><input aria-label="原图与引擎对照" class="slider" type="range" min="0" max="100" value="50"><div class="facts"><span>{len(r['surfaces'])} 条曲面碰撞</span><span>{len(r['doors'])} 个通道触发区</span><span>{len(r['rings'])} 个锚环</span><span>{len(r['enemies'])} 个敌人实例</span></div><p>全景按原图画幅等比显示；正常出生点与图中悬空参考姿态分开。可按 F3 查看碰撞，F4 独显四层，Tab 进入近景。</p></section>'''
layers=''.join(f'<figure><img src="images/layer-{i}.png" loading="lazy"><figcaption>{name}</figcaption></figure>'for i,name in enumerate(['远景：原可见水体细节＋补绘遮挡底板','中景：须幕、侧壁、组织框架','可玩层：曲面组织、门、角色、敌人与奖励','前景：近组织、暗菌簇和虚化框景']))
flowpics=''.join(f'<figure><img src="images/{n}.png" loading="lazy"><figcaption>{t}</figcaption></figure>'for n,t in [('normal-01-start','从首房正常开始'),('normal-boss-start','真实进入 Boss 战'),('normal-boss-defeated','击败后主体消失，补绘背面显露'),('normal-earned-dash','胜利解锁后实际使用冲刺'),('normal-complete','正常能力条件到达首关出口'),('deep-entry','S＋空格主动下穿受压薄膜'),('deep-1350','下层返坡真实向右探索'),('deep-rebound-return','从下层中心回弹返回主路')])
payload=json.dumps(manifest,ensure_ascii=False).replace('</','<\\/')
page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 v0.5 · 参考图到可玩关卡</title><style>
:root{color-scheme:dark;--bg:#071319;--panel:#10222a;--ink:#e2ede9;--muted:#9bb7b7;--accent:#d9b877}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.75 system-ui,"Microsoft YaHei",sans-serif}header{min-height:75vh;display:flex;align-items:end;background:linear-gradient(0deg,#071319 2%,#07131922 100%),url(images/R1-01.png) center/cover;padding:7vw}header div{max-width:850px}h1{font-size:clamp(34px,5vw,72px);line-height:1.18;letter-spacing:.06em}h2{font-size:30px;margin:8px 0 20px}h3{font-size:20px}.eyebrow{color:var(--accent);letter-spacing:.1em;font-size:13px}main{max-width:1400px;margin:auto;padding:0 4vw 80px}nav{position:sticky;top:0;z-index:8;background:#071319ed;border-bottom:1px solid #41616b;display:flex;gap:24px;padding:14px 4vw;overflow:auto;white-space:nowrap}a{color:#a6dbe4;text-decoration:none}a:hover{text-decoration:underline}.button{display:inline-block;border:1px solid #7baab6;padding:10px 20px;border-radius:6px;margin:4px 10px 4px 0;background:#102b35}section{padding:50px 0;border-bottom:1px solid #28414b}p{color:var(--muted)}.notice{background:#30251a;border-left:4px solid var(--accent);padding:22px 26px;margin:30px 0}.facts{display:flex;gap:12px;flex-wrap:wrap;color:#accbd1}.facts span{background:var(--panel);padding:8px 14px;border-radius:4px}.compare{position:relative;aspect-ratio:16/9;background:#061319;overflow:hidden;border-radius:9px}.compare img{position:absolute;width:100%;height:100%;object-fit:contain}.compare .after{clip-path:inset(0 50% 0 0)}.tag{position:absolute;left:15px;bottom:12px;background:#071319b8;font-size:12px;padding:6px 12px}.slider{width:100%;accent-color:#d9b877}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:0;background:#10222a;border-radius:8px;overflow:hidden}figure img{display:block;width:100%}figcaption{padding:12px 18px;color:var(--muted)}.tablewrap{overflow:auto;max-height:720px}table{width:100%;border-collapse:collapse;font-size:13px}th,td{padding:10px 12px;text-align:left;border-bottom:1px solid #29414b;vertical-align:top}th{position:sticky;top:0;background:#17303a}code{color:#c5d5ce;font-size:12px}input[type=search]{width:100%;padding:14px;background:#122731;border:1px solid #386270;color:#fff;font-size:16px;margin-bottom:15px}.pass{color:#92ccb7}.blocked,.fail{color:#ffc07e}.not_run{color:#d8c27f}.na{color:#6f939d}.links{display:flex;gap:20px;flex-wrap:wrap}.route{width:100%;background:#0d2029;border:1px solid #325360;border-radius:8px}.small{font-size:13px}.kpis{display:flex;gap:32px;flex-wrap:wrap}.kpis b{font-size:38px;display:block;color:#d9b877}@media(max-width:800px){.grid{grid-template-columns:1fr}nav{gap:15px}main{padding:0 18px 50px}section{padding:34px 0}h1{font-size:36px}}
</style><header><div><div class="eyebrow">GODOT 4.7.2 · WINDOWS · V0.5</div><h1>须门遗港<br>从参考图走进关卡</h1><p>七房原图、四层空间、连续曲面与真实角色操作。原始构图、补绘、引擎实景和验收证据分别保存。</p><a class="button" href="../../builds/须门遗港-v0.5-参考图可玩关卡/Whalefall.exe">运行关卡</a><a class="button" href="../../builds/须门遗港-v0.5-参考图可玩关卡.zip">便携运行包 ZIP</a><a class="button" href="../../BOB/godot/WhalebellyRuins/project.godot">可编辑 Godot 工程</a></div></header><nav><a href="#status">交付状态</a><a href="#map">七房路线</a><a href="#R1-01">原图对照</a><a href="#layers">四层资产</a><a href="#play">实际试玩</a><a href="#elements">全要素表</a><a href="#handoff">操作与接续</a></nav><main>
<section id="status"><div class="eyebrow">真实实现 / 实际验证 / 保留限制</div><h2>可玩版本已构建，整体验收尚未关闭</h2><div class="notice"><strong>当前阻塞：Windows 音频设备输出。</strong><br>Godot WASAPI 初始化返回 ERR_CANT_OPEN，随后回落 Dummy。数字混音、事件播放与淡入淡出已有证据；这些不能代替当前真实设备发声。静音运行包与画面/玩法验证正常。没有将本轮标记为“所有必需维度通过”。</div><div class="kpis"><div><b>7</b>可见房间</div><div><b>25</b>原图地表碰撞轮廓</div><div><b>4</b>独立显示层级</div><div><b>15</b>局部/遮挡补绘任务</div></div><p>连续正常首访：01 → 02 → 03 → 04 → 05；未使用全能力开局或中途设位置，Boss 胜利才解锁冲刺。支路与失败恢复另有真实输入测试。全部版本保留，旧 v0.4 未覆盖。</p><div class="links"><a href="../../BOB/godot/WhalebellyRuins/evidence/package-normal/normal-run.json">独立运行包连续试玩</a><a href="../../BOB/godot/WhalebellyRuins/evidence/normal/normal-reload.json">跨进程存档与 Boss 状态</a><a href="../../BOB/godot/WhalebellyRuins/evidence/dynamics.json">动态与暂停证据</a><a href="../../BOB/godot/WhalebellyRuins/evidence/benchmark.json">本机性能实测</a><a href="../../BOB/godot/WhalebellyRuins/evidence/audio-devices.log">音频阻塞原始日志</a></div></section>
<section id="map"><div class="eyebrow">保留原设计连接 · 不虚构画外章节</div><h2>七房关系与实际路线</h2><svg class="route" viewBox="0 0 1100 350" role="img" aria-label="主路01至05，上支06与右上支07回到02"><g fill="none" stroke="#82b6bd" stroke-width="3"><path d="M160 220H260M390 220H470M600 220H690M820 220H900"/><path d="M325 195V100H500M325 100V55H760"/></g><g font-family="Microsoft YaHei,sans-serif" font-size="18" fill="#dfe9e7"><g fill="#16333f" stroke="#6895a1"><rect x="30" y="185" width="130" height="75" rx="8"/><rect x="260" y="185" width="130" height="75" rx="8"/><rect x="470" y="185" width="130" height="75" rx="8"/><rect x="690" y="185" width="130" height="75" rx="8"/><rect x="900" y="185" width="165" height="75" rx="8"/><rect x="500" y="65" width="185" height="70" rx="8"/><rect x="760" y="20" width="185" height="70" rx="8"/></g><text x="50" y="217">01 外伤坡</text><text x="280" y="217">02 须筛</text><text x="490" y="217">03 舌台</text><text x="700" y="217">04 负壳蟹</text><text x="915" y="217">05 流膜育窝</text><text x="515" y="95">06 喷气孔外伤</text><text x="775" y="50">07 鲸须记忆袋</text><g font-size="13" fill="#9bbac1"><text x="50" y="243">营地与入港</text><text x="280" y="243">三层台＋三环</text><text x="490" y="243">膜下返坡</text><text x="705" y="243">胜利解锁冲刺</text><text x="915" y="243">三软床 → 首关出口</text><text x="515" y="120">A2 回访，远侧闩此侧不开</text><text x="775" y="75">A3 回访，四环，原路返回</text><text x="140" y="308">主路可往返；03 中央 S＋空格下穿软膜；06 侧台/底坡可恢复；07 右壁不通关。</text></g></g></svg><p>01–04 连续组织坡面按原图描摹；05 四岸三隙；06 上升阶梯、侧台和底部恢复坡；07 三岸两隙。门与环固定在可玩坐标上，不跟随背景漂移。</p></section>
'''+cards+'''<section id="layers"><div class="eyebrow">图层母版与运行资源分开</div><h2>远景 · 中景 · 可玩层 · 前景</h2><div class="grid">'''+layers+'''</div><p>PNG 原图保留；SVG 分类/角色遮罩、Shader 和场景节点可编辑。干净远景母版在 assets/clean/*-far.png；运行远景同时叠加原图可见水体细节，因此单独显示时可见少量原遮挡边界。实际近景最大视差已检查，无空边。导出的分层 PNG 是复用副本；运行场景实际使用原件＋遮罩＋补绘绑定。</p><div class="links"><a href="../../BOB/godot/WhalebellyRuins/assets/runtime/layers/">Godot 原生导出的 43 项图层/角色</a><a href="../../BOB/godot/WhalebellyRuins/assets/masks/">可编辑 SVG 遮罩</a><a href="../../BOB/godot/WhalebellyRuins/assets/clean/">补绘母版与连续远景</a><a href="docs/asset-provenance.json">工具任务与资产来源</a></div><div class="grid" style="margin-top:24px"><figure><img src="images/dynamic-camera-left.png"><figcaption>实际近景左机位</figcaption></figure><figure><img src="images/dynamic-camera-right.png"><figcaption>实际行走后的右机位，显示角色和空间关系</figcaption></figure></div></section>
<section id="play"><div class="eyebrow">真实 Godot 运行截图，不是原画冒充实机</div><h2>通关、战斗与返坡</h2><div class="grid">'''+flowpics+'''</div><p>过程截图证明对应时刻；完整操作/事件记录见测试 JSON。性能测试为本机 RTX 5060、1280×720、60Hz 上限的七房采样，不承诺其它硬件同样表现。</p></section>
<section id="elements"><div class="eyebrow">逐项绑定 / 逐维度状态</div><h2>全要素覆盖表</h2><p id="coverage"></p><input type="search" id="search" placeholder="搜索房间、元素ID、名称、类别或状态"><div class="tablewrap"><table><thead><tr><th>元素 / 来源</th><th>运行绑定</th><th>外观</th><th>空间</th><th>动态</th><th>物理</th><th>交互</th><th>声音</th><th>恢复</th></tr></thead><tbody id="rows"></tbody></table></div><p class="small">装饰簇可共享一个原图细节渲染节点；交互物件、实体碰撞、角色、门叶、生成器则分别绑定。N/A 都在 JSON 中附有理由，未决与未测不算通过。</p><div class="links"><a href="docs/element-manifest.json">完整元素合同 JSON</a><a href="docs/全要素覆盖表.csv">可筛选 CSV</a><a href="docs/全要素覆盖表.md">可读覆盖记录</a><a href="docs/coverage-readiness.md">剩余验收与接续条件</a></div></section>
<section id="handoff"><h2>操作与后续接续</h2><table><tr><th>操作</th><th>用途</th></tr><tr><td>A/D · 空格 · Q</td><td>移动、跳跃、攻击；Boss 胜利后 Shift 冲刺</td></tr><tr><td>E / A或D＋E</td><td>营地与拾取 / 明确穿门，避免同位营地与门冲突</td></tr><tr><td>W · J · F9</td><td>浮游、锚环、临时练习；两项是后续章节获得的回访能力</td></tr><tr><td>舌台 S＋空格</td><td>受压膜下穿；下层中央空格回弹返回主路</td></tr><tr><td>Esc · M · F5 · F6</td><td>暂停、静音、存安全位置、重载</td></tr><tr><td>Tab · F2 · F3 · F4 · 数字1–7</td><td>近景、原图、碰撞与机制、分层、房间检查</td></tr></table><p>独立包采用官方 Godot 便携程序＋项目 PCK；不是未安装的发行模板导出。工程固定版本见 engine-version.txt。新项目保存目录与旧 v0.4 分开；自动验收使用独立 QA 存档。</p><div class="links"><a href="../../BOB/godot/WhalebellyRuins/RESUME.md">中断后接续入口</a><a href="../../BOB/godot/WhalebellyRuins/.production/state.json">当前任务状态</a><a href="../../BOB/godot/WhalebellyRuins/evidence/">全部原始证据与失败记录</a><a href="../../builds/须门遗港-v0.5-参考图可玩关卡/操作说明.txt">运行操作说明</a></div></section></main>
<script id="manifest" type="application/json">'''+payload+'''</script><script>
const data=JSON.parse(document.getElementById('manifest').textContent);const keys=['appearance','spatial','motion','physics','interaction','audio','lifecycle'];const label={pass:'通过',fail:'返修',blocked:'阻塞',not_run:'待验证',not_applicable:'N/A'};const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function render(){let q=document.getElementById('search').value.toLowerCase();let rows=data.elements.filter(e=>[e.element_id,e.name,e.category,e.status].join(' ').toLowerCase().includes(q));document.getElementById('rows').innerHTML=rows.map(e=>'<tr><td><strong>'+esc(e.name)+'</strong><br><code>'+esc(e.element_id)+'</code><br>'+esc(e.origin)+'</td><td>'+e.instances.runtime_node_paths.map(esc).join('<br>')+'</td>'+keys.map(k=>{const d=e.dimensions[k];return '<td class="'+esc(d.status)+'" title="'+esc(d.reason)+'">'+esc(label[d.status]||d.status)+'</td>'}).join('')+'</tr>').join('');let required=0,passed=0,pending=0;data.elements.forEach(e=>keys.forEach(k=>{let d=e.dimensions[k];if(d.requirement==='required'){required++;if(d.status==='pass')passed++;else pending++}}));document.getElementById('coverage').textContent=data.elements.length+' 个元素合同；'+passed+'/'+required+' 必需维度已有通过记录；'+pending+' 项仍需验证。整体设备音频阻塞另记于全局验收，不会由素材覆盖率抵消。'}document.getElementById('search').addEventListener('input',render);render();document.querySelectorAll('.slider').forEach(s=>s.addEventListener('input',()=>s.previousElementSibling.querySelector('.after').style.clipPath='inset(0 '+(100-s.value)+'% 0 0)'));
</script></html>'''
page=page.replace('当前阻塞：Windows 音频设备输出。','整体验收 7/10：分层素材待精修；设备音频和真实窗口关闭复验受阻。')
page=page.replace('<section id="layers">','<section id="layers"><div class="notice"><strong>分层资产仍需精修：</strong>导出可玩层的平台、锚环周边还带有源图蓝色背景。完整合成对照已检查，但独立拆件的边缘验收尚未通过；不能以合成画面通过抵消这一缺陷。</div>')
(OUT/'交付与验收.html').write_text(page,encoding='utf8')
readme='''# 须门遗港 v0.5：参考图到可玩关卡

固定引擎：Godot 4.7.2.stable.official.ed1daf0bf，Windows x64 / Compatibility。
工程入口：project.godot；主场景 scenes/main.tscn；七房 scenes/r1。
原始图片不修改；source-manifest.json 记录摘要。assets/masks + Shader + 场景是可编辑母版，assets/clean 是本轮补绘，assets/runtime/layers 是 Godot 导出的复用图。

当前：首关正常主路、Boss、两回访支路、下层返坡、四环、软床恢复、保存重载与独立包已实测。当前系统音频输出设备失败，不能签为整体验收完成。见 evidence/audio-devices.log。

运行：使用固定版本打开 project.godot 后 F6/F5，或运行 builds/须门遗港-v0.5-参考图可玩关卡/Whalefall.exe。编辑器F6是运行当前场景，与游戏内F6重载不同。
操作以运行包“操作说明.txt”为准。F9是临时回访练习，不是正式取得A2/A3。

存档：项目使用WhalefallArtmatchV05独立user目录。qa标志下用artmatch_qa_save.json；不覆盖旧v0.4用户数据。
验收：docs/element-manifest.json；真实图形/输入证据 evidence/；失败历史保留，不抹掉返修过程。
正常通关测试并未靠整图背景、文件存在或日志无错冒充玩法。
'''
readme+='\n待返修：部分可玩层平台/锚环拆件仍含原图背景，精细分层边缘验收未通过；详见交付册与coverage-readiness.md。\n'
(P/'README.md').write_text(readme,encoding='utf8')
(P/'engine-version.txt').write_text('4.7.2.stable.official.ed1daf0bf\nCompatibility / Windows x64\n',encoding='utf8')
resume='''# 接续入口

1. 先读取本文件、.production/state.json、docs/element-manifest.json、docs/coverage-readiness.md。
2. 已有七房源件、可编辑遮罩、分层图、正常玩法、实际证据和独立包；不要重新生成全部图片，也不要覆盖旧v0.4。
3. 尚需恢复/选择可用Windows默认音频输出。当前Audiosrv服务运行，但Godot WASAPI ERR_CANT_OPEN并回落Dummy；不能用Dummy证明设备发声。
4. 音频可用后运行以下真实命令并保存新日志：

```powershell
& 'C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --path 'G:/鲸落万物生/BOB/godot/WhalebellyRuins' --script res://tests/audio_devices.gd
& 'C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --path 'G:/鲸落万物生/BOB/godot/WhalebellyRuins' --script res://tests/audio_mixer.gd
```

5. 只有driver=WASAPI且混音/独立包设备输出实际通过，才更新该全局阻塞。不要把以前成功、现在失败或主观未试听相混同。
6. 若源文件改动：先按manifest的摘要使依赖验收失效；只复测受影响项。完整重建母版脚本是 work/r1_v05_build.py（会重生成scene/mask并把阶段恢复in_progress，因此一般无需重跑）；图形capture是work/r1_v05_capture.py；包是work/r1_v05_package.py；交付册是work/r1_v05_delivery.py。
7. 当前构建是官方便携exe+导出PCK，不依赖未安装的export templates；正式发行前再采用发行模板构建和人工玩法/审美签收。
'''
resume+='\n8. 分层边缘待返修：assets/runtime/layers/R1-02/World.png 的平台/锚环周边仍含源图背景。需逐物件精细分割，复验独显、合成和最大视差后再更新相关PNG/PCK；此前全局色键删坏地形的方案已撤回。\n9. 最终包本次真实窗口关闭测试遇交互桌面拒绝访问；保留受阻记录。独立包自动流程正常退出通过，不冒充点击窗口关闭通过。桌面恢复后重跑正常窗口关闭脚本。\n'
(P/'RESUME.md').write_text(resume,encoding='utf8')
instruction='''# 本轮实际执行指令与结果

R0 读图：读取用户4张附件及参考册7房原图，九宫格/四边/功能/四层扫描；元素合同见element-manifest.json。原始PNG摘要见source-manifest.json。
R1 合同：原图轮廓优先于旧矩形U表，1源像素=1世界单位；固定参考机位与近景机位分别验证；图中悬空姿态与正常spawn分离。按原设计保留01–05主路及06/07回访，画外R2/R3仅保留出口关系。
R2 灰盒：Godot原生25曲面碰撞、脚底锚点、移动/跳跃/冲刺/攻击/锚环/浮游/保存与恢复；真实输入测试见evidence/normal、revisit、deep、elements。
R3 分件补绘：原件复制保留；15次内置imagegen局部/遮挡补绘任务，未调用第三方付费生成。Godot原生Shader+SVG遮罩+独立角色/敌人/门/奖励构图，原生SubViewport导出43层/角色复用图；工具来源见asset-provenance.json。
R4 对照：逐房实际窗口固定机位截图，首批邻域克隆出现人形/蟹形补洞，返修为补绘底板；全局色键误删暗组织的尝试已撤回，最终保留原可见像素，补绘仅用于隐藏处。原始失败证据保留。
R5 动态：软膜图形与碰撞同步42px下沉、S+空格下潜/底部回弹；原图Boss钳独立铰接；奖励浮动、门叶淡出；须幕微摆、分层视差、鱼/泡/尘/雾、营地光、事件效果、非空间事件混音与环境音跨房淡化。图中看不到的行为标为继承/设计补足，不冒充观察事实。
R6 验收：独立输入运行、正常无全能力通关、支路、逐元素、数字音频、动态/暂停、实际库存、跨进程恢复和本机性能；明细见各证据JSON与manifest。当前真实音频设备输出blocked，不能宣称全部维度通过。
R7 扩展：只制作原参考册七房，不扩建后续章节。
R8 构建交付：官方Godot4.7.2便携程序+PCK，脱离编辑器再做正常通关与重载；工作区保留工程、原件、母版、原生导出、覆盖表、真实截图、未完成项与接续指令。

下一步：音频设备恢复后，按RESUME.md实际复测并更新全局状态。所有普通可逆修复已在授权内执行，未另行发布或联网部署。
'''
instruction+='\n最后交付复查：独立拆件尚残留背景，必须定向精修。部分Windows设备/桌面验证受阻，见RESUME.md与覆盖表；不可称整体验收完成。\n'
(P/'docs/instruction-v05.md').write_text(instruction,encoding='utf8')
print('DELIVERY',OUT/'交付与验收.html')
