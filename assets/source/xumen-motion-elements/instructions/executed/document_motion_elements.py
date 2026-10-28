from pathlib import Path
import json,hashlib,html
root=Path('G:/鲸落万物生/BOB');src=root/'assets/source/xumen-motion-elements';proj=root/'godot/WhalebellyRuins';ev=proj/'evidence/motion_elements';out=root.parent/'outputs/须门遗港_独立环境动画';out.mkdir(parents=True,exist_ok=True)
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
write(ev/'.gdignore','')
# Capture intermediates are local; final MP4 and evidence are versioned.
write(ev/'.gitignore','*-capture.avi\n*.import\nmain/*.import\n')
contracts=json.loads((src/'elements.json').read_text(encoding='utf-8'))
layout=json.loads((src/'master/scene-layout.json').read_text(encoding='utf-8'))
svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1280" height="720" viewBox="0 0 1280 720">','<title>Editable bitmap layout master — live motion is authored in matching Godot element scenes</title>']
for a in sorted(layout,key=lambda a:a['z']):
 if a['kind']=='bubbles':continue
 id=a['id'];tex=a.get('tex',id);x,y=a['pos']
 if id=='FRONT-01':tex='FRONT-CONTINUOUS'
 if id.startswith('CAUSTIC'):tex='CAUSTIC-RIBBONS'
 if a['kind']=='fish':tex=id+'-source';x-=20;y-=10
 # SVG uses the exact source bitmaps; it is a layout master, not the runtime shader preview.
 from PIL import Image
 p=src/'master'/f'{tex}.png'
 w,h=Image.open(p).size
 if a['kind']=='fish':w/=3;h/=3
 opacity=0.32 if id=='CAUSTIC-01' else .16 if id=='CAUSTIC-02' else 1
 svg.append(f'<g id="{id}"><title>{id} · {a["kind"]} · z={a["z"]}</title><image x="{x}" y="{y}" width="{w}" height="{h}" opacity="{opacity}" xlink:href="{tex}.png"/></g>')
svg.append('</svg>');write(src/'master/editable-layout.svg','\n'.join(svg))
provenance={'engine':'4.7.2.stable.official.ed1daf0bf','tools':['Godot native Image/Shader/Sprite2D','local FFmpeg 7.1','built-in image_gen'], 'third_party_paid_generation':False,'inputs':[],'generated':[{'file':'generated/foreground-backing.png','source':'existing dynamic-backing.png','instruction':'Keep the same framing/road/ceiling/walls/portal. Remove only the dark blurry bottom foreground ridge. Paint the hidden continuation of blue ruins and lower supports. No fish, bubbles, characters or curtains. Only masked occlusion regions enter the scene.','tool_output':'exec-625067db-667c-4268-bdd3-dead4155c758.png'},{'file':'generated/caustic-master.png','instruction':'Transparent 2D hand-painted underwater caustic light decal, pale cyan/ivory sparse irregular rippling lace, soft transparent edges, light from upper right. No floor, scene, objects, fish or bubbles.','tool_output':'exec-54eccd9e-3daf-4d8a-b3e2-80d122e4382a.png'}]}
for p in [src/'reference/environment.mp4',src/'reference/camera.gif',root/'assets/source/xumen-reference-environment/original/reference.png']:
 provenance['inputs'].append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
write(src/'provenance.json',json.dumps(provenance,ensure_ascii=False,indent=2))
# Central/runtime copies must be identical, not just similarly named.
files=list((root/'assets/runtime/xumen-motion-elements').glob('*.png'));mismatches=[p.name for p in files if p.read_bytes()!=(proj/'assets/motion_elements'/p.name).read_bytes()]
write(ev/'asset-integrity.json',json.dumps({'checked_png':len(files),'mismatches':mismatches,'original_unchanged_sha256':provenance['inputs'][-1]['sha256']},indent=2))
bench=json.loads((ev/'live-fixed-runtime.json').read_text());checks=json.loads((ev/'checks.json').read_text());loops=json.loads((ev/'loop-render.json').read_text());main=json.loads((ev/'main/reference-level-route.json').read_text())
readme=f'''# 须门遗港 · 独立环境动画（2026-10-28）

本次继续同一个 Godot 4.7.2 工程；原图定构图，MP4定局部运动，GIF仅参考分层镜头关系。

## 打开与编辑

- 场景总入口：`godot/WhalebellyRuins/scenes/environment/motion_preview.tscn`，F6。固定镜头，**C** 切换小幅镜头运动，**空格**暂停。角色保持展示姿态。
- 单类效果：`scenes/environment/element_gallery.tscn`，F6，左右键切换5组效果、空格暂停。
- 主关卡：F5；R1-01继续共享`xumen_reference.tscn`。既有角色移动时镜头平滑跟随；Tab切换全景/跟随，其余房间沿用旧逻辑。
- 独立动件：`scenes/environment/elements/*.tscn`，Inspector调节period/phase/amplitude_px/intensity；素材在`assets/motion_elements/`。布局在`xumen_reference.tscn`。
- 布局母版：[master/editable-layout.svg](master/editable-layout.svg)（同目录PNG不可搬散）；动画母版是Godot分件场景、Shader和鱼帧图，SVG只记录静态布局。

## 实际制作内容

{len(contracts)}个元素/装饰簇/发射器合同；48条逐鱼实例，各12帧摆尾图集；6组垂须的固定根片与动片；4植物、4垂藤；4个气泡发射器共36实例；3束光、1灯、2层焦散；连贯前景与遮挡补绘。静态洞顶、道路、侧壁、洞口和装饰继续保留原图像素。

鱼：原图裁切后注册根点，Godot原生重采样制作12时相尾摆，身体尺度不变；区域缓游与边缘淡出回收是独立路径逻辑。不是手绘逐帧，也不是整簇图片横移。
垂须/植物：独立透明贴图+局部根部权重Shader，不移动静态根片与洞壁。顶须6/7/8秒，末端约数像素；每簇错相。
光：独立绘制的透明光纹贴图+12秒周期光纹变形，独立光束/灯平滑变化；不扭曲地形，也不重复叠加整张原图。
前景：独立整片暗色框景，避免3块分开运动时接缝裂开；小幅镜头保留裁切余量。远、中、可玩、前景有不同视差响应。

## 验证

- 环境状态检查：{len(checks['checks'])}项通过；含103个ID引用、无新增物理节点、鱼帧差异、180秒加速状态检查、36气泡上限、暂停/恢复、重载、正负视差。
- 实际渲染循环：{len(loops['checks'])}项通过；抽查垂须/植物/焦散的一个周期首尾渲染最大通道误差0；鱼边界回收两侧alpha低于0.0001。不是逐帧人工观感验收。
- 主场景原有流程：{len(main['tests'])}项通过，含行走、支路/房间往返、既有角色操作、死亡复活、暂停与原存档坐标兼容；未新增这些玩法。
- 实际Godot录制：64秒固定画面，32秒视差镜头，30fps。全程实时渲染成帧，非参考MP4播放。
- 另行正常播放64秒性能：RTX5060，1280×720，OpenGL Compatibility，帧间隔P50={bench['frame_ms_p50']:.3f}ms / P95={bench['frame_ms_p95']:.3f}ms，约60fps；{int(bench['draw_calls'])}次绘制，纹理约{bench['texture_bytes']/1048576:.1f}MiB。录制编码耗时未冒充游戏性能。
- 原图SHA256未变；{len(files)}份中央PNG与工程PNG逐文件相同。

## 范围与仍需确认的部分

没有新增角色控制器、玩法碰撞、地图、战斗、敌人、任务、存档或音频；主场景只调整同一环境和既有角色的镜头。
构图主要锚点、道路轮廓和暖光洞口保留。细须与暗前景采用透明抠图；放大观察仍可能见少量边缘/补绘纹理差异，不宣称逐像素还原。
已查看固定时刻、两侧镜头、长录制抽样帧和循环端点；未声称人工连续观看每帧或获得用户最终观感认可。原视频只有5秒，周期与幅度是制作值，不是精确测量值。

## 重建与接续

先运行`BOB/tools/build_motion_elements.py`准备输入，再用固定Godot执行`--headless --script res://tools/motion_elements/export_assets.gd`原生导出；随后`build_motion_elements.py --assemble`组装、Godot导入、运行`tests/motion_elements_qa.gd`与`tests/motion_loop_render.gd`。不要用旧reference_environment生成器覆盖新装配。
该流水线保留原件、生成底图、SVG遮罩、PNG母版、JSON坐标和元素场景。后续美术修正按ID定位，独立预览通过后回总场景复测。

修复记录：原生导出类型推断修复；收窄前景补绘范围；同步转身改为持续游动；垂须增加透明余量并把侧壁像素归固定根片；修正焦散alpha重复乘法导致动态过弱。
'''
write(src/'README.md',readme)
write(src/'progress.json',json.dumps({'stage':'SC06','completed':['SC00','SC01','SC02','SC03 major composition review','SC04','SC05 state/render/recording checks'],'pending':['portable package startup','final git commit'],'evidence':str(ev),'limitations':['Fine matte edges are approximate','No continuous human per-frame playback certification'],'repairs':['foreground backing too broad -> bounded swept region','synchronized fish turn -> continuous flow','baleen sidewall deformation -> rigid root mask','caustic alpha squared -> vertex tint preserved']},ensure_ascii=False,indent=2))
# Update established documentation, rather than inventing a second project.
p=root/'assets/catalog.md';s=p.read_text(encoding='utf-8');s+='\n## 2026-10-28 独立环境动画\n\n`xumen-motion-elements`：146份位图（含48条鱼的源裁片/12帧图集）、103个场景元素合同、独立动画场景和光效。已替换R1-01共享环境的对应资源。[编辑与验证说明](source/xumen-motion-elements/README.md)、[全元素表](source/xumen-motion-elements/elements.json)、[来源](source/xumen-motion-elements/provenance.json)。以该记录为当前环境动画版本；旧记录保留历史。\n';write(p,s)
p=root/'docs/godot-project.md';s=p.read_text(encoding='utf-8');s+='\n## 2026-10-28 环境动态更新\n\n新纯环境预览：`scenes/environment/motion_preview.tscn`（F6，C视差、空格暂停）；分组预览：`element_gallery.tscn`。R1-01主关卡已共享新分件，默认平滑跟随既有角色，Tab切回全景。[母版、参数、来源、运行证据](../assets/source/xumen-motion-elements/README.md)。旧`preview-reference-environment.ps1`继续可用，推荐新预览入口。\n';write(p,s)
# Repo skill: one validated reusable correction, no broad new workflow.
p=root/'.agents/skills/consistent-2d-game-assets/references/sprite-animation.md';s=p.read_text(encoding='utf-8');s+='\n## 环境分件补充（Godot实机验证）\n\n- 鱼群使用独立个体时，避免同一个正弦路径让所有鱼同时翻转；可使用有预热分布、边缘透明回收的持续游动。尾摆帧与路径分别定义循环。\n- 动态贴图要留足透明余量；含屋顶/洞壁的裁片必须拆成固定根片和动片，不能只把UV位移整体加大。\n- CanvasItem光纹Shader注意`COLOR`已可能含贴图采样；再次乘采样会把alpha平方，导致动画几乎看不见。用vertex传递调制色，在fragment只采样/混合一次，并通过实际像素变化复查。\n- 录制模式的帧时间包含编码，不等于实时帧率。另跑无录制场景测量。参考实现与证据见`assets/source/xumen-motion-elements/README.md`。\n';write(p,s)
print('DOCS',out,'integrity mismatches',mismatches)
