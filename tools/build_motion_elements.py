from pathlib import Path
import json,re,shutil
root=Path('G:/鲸落万物生/BOB'); src=root/'assets/source/xumen-motion-elements'; project=root/'godot/WhalebellyRuins'
def write(p,s): p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
old=json.loads((root/'assets/runtime/xumen-reference-environment/manifest.json').read_text(encoding='utf-8'))
assets=old['assets']
fish=[]
for g in ['02','03']:
 s=(root/f'assets/source/xumen-reference-environment/masks/FISH-{g}.svg').read_text()
 for i,m in enumerate(re.findall(r'<ellipse cx="([\d.]+)" cy="([\d.]+)" rx="([\d.]+)" ry="([\d.]+)"',s)):
  x,y,rx,ry=map(float,m);fish.append(dict(id=f'FISH-{g}-{i+1:02}',center=[x,y],radius=[rx,ry],group=g))
spec={'source':str(root/'assets/source/xumen-reference-environment/original/reference.png'),'old':str(root/'assets/runtime/xumen-reference-environment'),'source_dir':str(src),'runtime':str(root/'assets/runtime/xumen-motion-elements'),'project_runtime':str(project/'assets/motion_elements'),'assets':assets,'fish':fish}
write(project/'tools/motion_elements/spec.json',json.dumps(spec,ensure_ascii=False,indent=2))
# A coherent foreground mask: hand-traced from this turn's image; dark coral above the ridge is retained.
points='0,475 28,476 48,499 68,507 89,526 112,540 137,558 163,568 194,582 223,594 251,601 282,606 310,601 337,593 368,584 396,588 424,600 453,611 484,617 513,625 541,637 567,639 589,646 610,640 632,650 651,645 671,654 692,647 714,649 742,646 763,649 786,646 810,646 837,647 864,648 888,652 914,655 938,660 961,669 981,674 1003,672 1026,672 1053,678 1080,679 1106,685 1130,690 1156,699 1184,705 1210,703 1233,706 1257,700 1280,705 1280,720 0,720'
write(src/'master/foreground-mask.svg',f'<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720"><polygon points="{points}" fill="white"/></svg>')
write(src/'reference-analysis.md','''# 参考与范围\n原图锁定构图；视频只提取局部运动。原件保存在 reference/，原图复用 ../xumen-reference-environment/original/reference.png。\n\n- observed：MP4 1280×720、24fps、5.06秒；0.00–4.75秒每0.25秒解码，右侧近景气泡从底部上升，顶部垂须末端有明显变化。\n- observed：同一片段道路与纹理也有生成漂移；不复制这种整体形变。\n- observed：GIF 1108×636、10fps、13.6秒；早期连续片段展示人物行走、相机平移、近景相对远景位移；后段有剪辑，不用于推导速度。\n- estimated：鱼群运动幅度较小、光束方向稳定。5秒片段不能确定完整周期。\n- proposed：垂须6–8秒、末端5–7像素；逐鱼12帧摆尾1.5–2.1秒、28/32秒区域巡游；顶部水面10秒；灯8秒；移动相机采用既有角色位置，展示场景使用无输入的镜头轨迹。\n\n工具：本地FFmpeg解码、Godot原生图像裁切/透明蒙版/动画、内置imagegen补绘和光效贴图。浏览器拒绝本地file视频入口，未绕过访问限制；参考视频以加密帧观察，尚无连续播放观察结论。没有上传到第三方付费服务。\n\n范围：纯环境分件；展示角色保留姿态；不增加控制器、战斗、碰撞、任务、保存和新地图。\n''')
stages=[('SC00','用FFmpeg解码并保存时间戳观察；读取PNG与既有分层资产，区分观察/估计/提议。'),('SC01','固定Godot4.7.2，复用xumen_reference.tscn，1280x720构图，保留主场景引用。'),('SC02','运行tools/motion_elements/export_assets.gd；原图裁切逐鱼、动静垂须分离、连贯前景；新补绘只进入隐藏区域，独立焦散贴图。'),('SC03','运行tests/motion_elements_qa.gd保存静帧，检查轮廓、道路、洞口、透明边缘；失败仅修对应资产。'),('SC04','生成elements/*.tscn，每个动件独立根节点、参数和时钟；装配到原场景。'),('SC05','实际Godot渲染至少64秒，录像、暂停/恢复、重载、边缘和数量验证；另测既有角色镜头跟随。'),('SC06','保存工程、母版、48尾鱼帧图、逐元素清单、参数说明、截图和录像，固定版本打包并验证。')]
for id,cmd in stages: write(src/f'instructions/{id}.md',f'# {id}\n\n执行：{cmd}\n\n证据：../../../.. / godot/WhalebellyRuins/evidence/motion_elements/（以交付文档链接为准）。失败记入progress.json后定向修复，不能把日志无错当作视觉通过。\n')
if not (src/'progress.json').exists(): write(src/'progress.json',json.dumps({'stage':'SC02','completed':['SC00','SC01 existing project inspected'],'pending':['static reconstruction','element animation','rendered QA','delivery'],'engine':'4.7.2.stable.official.ed1daf0bf'},ensure_ascii=False,indent=2))
# Continue this reproducible builder after native bitmap export.
import sys
if '--assemble' in sys.argv:
 runtime='res://assets/motion_elements/'
 folder=project/'scenes/environment/elements'
 layout=[]
 contracts=[]
 def element(id,texture,pos,z,kind,**params):
  extra=''
  for k,v in params.items():
   if isinstance(v,bool): value=str(v).lower()
   elif isinstance(v,str) and v.startswith(('Vector2','Rect2')): value=v
   elif isinstance(v,str): value='"'+v+'"'
   else:value=str(v)
   extra+=f'{k} = {value}\n'
  isfish=kind=='fish'
  txt=f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/motion_element.gd" id="1"]
[ext_resource type="Texture2D" path="{runtime+texture}.png" id="2"]
[node name="{id}" type="Sprite2D"]
texture = ExtResource("2")
centered = {'true' if isfish else 'false'}
script = ExtResource("1")
animation_kind = "{kind}"
source_origin = Vector2({pos[0]}, {pos[1]})
{extra}'''
  if isfish: txt+='hframes = 12\nscale = Vector2(0.333333, 0.333333)\n'
  write(folder/(id+'.tscn'),txt)
  layout.append(dict(id=id,scene=True,pos=pos,z=z,kind=kind))
  contracts.append(dict(id=id,position=pos,layer=z,asset=texture+'.png',scene='elements/'+id+'.tscn',motion=kind,parameters=params,acceptance='实际引用、轮廓/透明边缘、时序/遮挡与暂停重载',source='original crop or generated light/backing; see export manifest',collision='N/A 环境无碰撞',sound='N/A 本轮无声音需求'))
 def static(id,tex,pos,z):
  layout.append(dict(id=id,scene=False,tex=tex,pos=pos,z=z,kind='static'))
  contracts.append(dict(id=id,position=pos,layer=z,asset=tex+'.png',motion='static',acceptance='实机出现、位置轮廓不变',collision='N/A 环境无碰撞',sound='N/A'))
 for a in assets:
  id=a['id']
  if id.startswith(('FISH','FRONT')) or id=='BUBBLE-TEXTURE':continue
  pos=a['source_rect'][:2]; z=a['layer']
  if id.startswith('BALEEN'):pos[0]-=16
  if id.startswith(('BALEEN','PLANT','VINE')):
   if id.startswith('BALEEN'):static(id+'-ROOT',id+'-ROOT',pos,z)
   element(id,id,pos,z,'foliage',amplitude_px=6.0 if id.startswith('BALEEN') else 2.6,period=6.0+(int(id[-2:])%3),phase=int(id[-2:])*0.73,root_at_bottom=id.startswith('PLANT'))
  elif id.startswith('BEAM') or id=='LAMP':
   # Existing painted light islands retain alpha and illumination direction.
   element(id,id,pos,z,'light',period=8.0 if id=='LAMP' else 12.0,phase=len(layout)*0.61,intensity=0.26 if id=='LAMP' else 0.12)
  else:static(id,id,pos,z)
 element('FRONT-01','FRONT-CONTINUOUS',[0,0],50,'parallax',parallax_amount=-0.14)
 static('FOREGROUND-BACKING','FOREGROUND-BACKING',[0,0],-2)
 for i,f in enumerate(fish):
  element(f['id'],f['id'],f['center'],-30,'fish',period=1.5+(i%4)*0.2,phase=(i*1.71)%6.283185,swim_extent='Vector2('+str(28+i%6)+', '+str(2+i%4)+')',swim_period=28.0 if f['group']=='02' else 32.0,parallax_amount=0.18)
 element('WATER-SURFACE','WATER-SURFACE',[350,0],-55,'water',period=10.0,phase=0.0,intensity=1.0,amplitude_px=2.4)
 for i,bounds in enumerate(['Rect2(143,170,89,220)','Rect2(414,310,72,98)','Rect2(786,119,154,282)','Rect2(1036,358,95,128)']):
  id=f'BUBBLE-ZONE-{i+1:02}'
  write(folder/(id+'.tscn'),f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/bubble_emitter.gd" id="1"]
[node name="{id}" type="Node2D"]
script = ExtResource("1")
bounds = {bounds}
seed_id = {i}
near_layer = {str(i==3).lower()}
''')
  layout.append(dict(id=id,scene=True,pos=[0,0],z=-20,kind='bubbles'))
  contracts.append(dict(id=id,position=bounds,layer=-20,instances=9,motion='预热/上升/边界淡出回收',scene='elements/'+id+'.tscn',asset='../reference_environment/bubble.png',parameters=dict(speed='12–18px/s; near24–30',population=9,seed=i),acceptance='36总数稳定、不在可见区瞬移、暂停恢复',collision='N/A',sound='N/A'))
 txt=f'[gd_scene load_steps={len(layout)+2} format=3]\n\n[ext_resource type="Script" path="res://scenes/environment/reference_environment.gd" id="1"]\n'
 for i,a in enumerate(layout,2):
  typ='PackedScene' if a['scene'] else 'Texture2D'; path='res://scenes/environment/elements/'+a['id']+'.tscn' if a['scene'] else runtime+a['tex']+'.png'
  txt+=f'[ext_resource type="{typ}" path="{path}" id="{i}"]\n'
 txt+='\n[node name="ReferenceEnvironment" type="Node2D"]\nscript = ExtResource("1")\n'
 for i,a in enumerate(layout,2):
  node=f'instance=ExtResource("{i}")' if a['scene'] else 'type="Sprite2D"'
  txt+=f'\n[node name="{a["id"]}" parent="." {node}]\nz_index = {int(a["z"])}\nposition = Vector2({a["pos"][0]}, {a["pos"][1]})\nmetadata/element_id = "{a["id"]}"\nmetadata/motion = "{a["kind"]}"\n'
  if a['scene']:txt+='external_clock = true\n'
  else:txt+=f'texture = ExtResource("{i}")\ncentered = false\n'
 write(project/'scenes/environment/xumen_reference.tscn',txt)
 write(src/'elements.json',json.dumps(contracts,ensure_ascii=False,indent=2))
 write(src/'master/scene-layout.json',json.dumps(layout,ensure_ascii=False,indent=2))
 # Preserve capture/report interface used by the main level; motion is now per-element.
 p=project/'scenes/environment/reference_environment.gd'; s=p.read_text(encoding='utf-8')
 start=s.index('func _ready()'); end=s.index('func _process(')
 s=s[:start]+'''func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	qa = not level_mode and "--qa" in args
	still = not level_mode and "--static" in args
	if not FileAccess.file_exists("res://project.godot"): evidence_directory="user://environment_evidence/"
	if qa or still: DirAccess.make_dir_recursive_absolute(evidence_directory)
	if still: animate_environment = false
	if "--pan" in args: camera_drift = true
	for child in get_children():
		if child is Sprite2D: bases[child.name] = child.position
		if str(child.name).begins_with("BUBBLE-ZONE"):
			bubbles.append_array(child.bubbles)
	if level_mode:
		var display = get_node("CHARACTER")
		bases.erase(display.name)
		remove_child(display)
		display.queue_free()
	update_visuals()

func update_visuals() -> void:
	var pan = level_camera_offset if level_mode else (Vector2(sin(elapsed*TAU/24.0)*45.0,sin(elapsed*TAU/24.0)*8.0) if camera_drift else Vector2.ZERO)
	recycled=0
	for child in get_children():
		if str(child.name).begins_with("BUBBLE-ZONE"):
			child.update_at(elapsed)
			recycled+=child.recycled
		elif child.has_method("update_at"):
			child.update_at(elapsed,pan)
		elif child is Sprite2D:
			var amount=0.0
			# The far underpaint fills exposed edges; holes in the depth matte remain anchored.
			if str(child.name)=="ENV-UNDERPAINT": amount=0.14
			if str(child.name).begins_with("MID"): amount=0.045
			child.position=bases[child.name]+pan*amount

'''+s[end:]
 s=s.replace('evidence/reference_environment/motion_refinement/','evidence/motion_elements/')
 s=s.replace('or id.begins_with("BUBBLE"): group = 1','or id.begins_with("BUBBLE") or id.begins_with("CAUSTIC"): group = 1')
 write(p,s)
 print('ASSEMBLED',len(layout),'elements including',len(fish),'individual fish')

# Preserve the Blender-rendered curtain integration when regenerating the base scene.
if "--assemble" in sys.argv and (root/"assets/source/baleen-blender/jobs.json").exists():
 import subprocess
 subprocess.run([sys.executable,str(root/"tools/integrate_baleen_blender.py")],check=True)
if "--assemble" in sys.argv and (project/"assets/soft_light/UNDERWATER-SOFT-LIGHT.png").exists():
 import subprocess
 subprocess.run([sys.executable,str(root/"tools/integrate_soft_light.py")],check=True)
if "--assemble" in sys.argv and (root/"assets/source/xumen-foreground-edges/manifest.json").exists():
 import subprocess
 subprocess.run([sys.executable,str(root/"tools/integrate_foreground_edges.py")],check=True)
if "--assemble" in sys.argv and (project/"assets/underbridge/FOREGROUND-BACKING-SOFT.png").exists():
 import subprocess
 subprocess.run([sys.executable,str(root/"tools/integrate_underbridge.py")],check=True)
