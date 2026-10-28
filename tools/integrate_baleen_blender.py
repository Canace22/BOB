from pathlib import Path
import re,json
r=Path(__file__).resolve().parents[1];p=r/'godot/WhalebellyRuins';src=r/'assets/source/baleen-blender';jobs=json.loads((src/'jobs.json').read_text(encoding='utf-8'))
def w(p,s):p.write_text(s,encoding='utf-8',newline='\n')
ids=[j['id'] for j in jobs]
for j in jobs:
 w(p/f'scenes/environment/elements/{j["id"]}.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/baleen_frames.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/baleen_blender/{j['id']}.png" id="2"]
[node name="{j['id']}" type="Sprite2D"]
texture = ExtResource("2")
centered = false
hframes = 8
vframes = 9
script = ExtResource("1")
playback_fps = 12.0
frame_count = 72
''')
f=p/'scenes/environment/xumen_reference.tscn';t=f.read_text(encoding='utf-8')
t=re.sub(r'^\[ext_resource[^\n]+/BALEEN-(?:0[1-6]|LEFT|CENTER|RIGHT|DISTANT)\.tscn[^\n]*\]\n','',t,flags=re.M)
t=re.sub(r'\n\[node name="BALEEN-(?:0[1-6]|LEFT|CENTER|RIGHT|DISTANT)"[^\n]*\]\n.*?(?=\n\[node|\Z)','',t,flags=re.S)
resources='\n'.join(f'[ext_resource type="PackedScene" path="res://scenes/environment/elements/{j["id"]}.tscn" id="baleen_{i}"]' for i,j in enumerate(jobs))
t=t.replace('[node name="ReferenceEnvironment"',resources+'\n\n[node name="ReferenceEnvironment"',1)
for i,j in enumerate(jobs):t+=f'''\n[node name="{j['id']}" parent="." instance=ExtResource("baleen_{i}")]
z_index = {j['z']}
position = Vector2({j['rect'][0]}, {j['rect'][1]})
external_clock = true
metadata/element_id = "{j['id']}"
metadata/motion = "blender_frames"
'''
t=re.sub(r'load_steps=\d+',f'load_steps={len(re.findall(r"\[ext_resource",t))+1}',t,count=1);w(f,t)
def replaced(id):return bool(re.fullmatch(r'BALEEN-0[1-6]',id)) or id in ids
f=r/'assets/source/xumen-motion-elements/elements.json';a=json.loads(f.read_text(encoding='utf-8'));a=[e for e in a if not replaced(e['id'])]
for j in jobs:a.append({'id':j['id'],'position':j['rect'][:2],'layer':j['z'],'asset':f'res://assets/baleen_blender/{j["id"]}.png','scene':f'elements/{j["id"]}.tscn','motion':'Blender rendered 72 RGBA frames / 12fps / 6s loop','source':'baleen-blender/blend/baleen-painted-animation.blend','parameters':j,'collision':'N/A 环境装饰','sound':'N/A','acceptance':'根部固定、逐帧透明、无整片平移、实际引用、循环与场景遮挡'})
w(f,json.dumps(a,ensure_ascii=False,indent=2));w(p/'tools/motion_elements/element-ids.json',json.dumps([e['id'] for e in a]))
f=r/'assets/source/xumen-motion-elements/master/scene-layout.json';a=json.loads(f.read_text(encoding='utf-8'));a=[e for e in a if not replaced(e['id'])];a.extend({'id':j['id'],'scene':True,'pos':j['rect'][:2],'z':j['z'],'kind':'blender_frames'} for j in jobs);w(f,json.dumps(a,ensure_ascii=False,indent=2))
f=p/'scenes/environment/reference_environment.gd';t=f.read_text(encoding='utf-8')
t=t.replace('elif id.begins_with("MID")','elif id == "BALEEN-DISTANT" or id.begins_with("MID")');w(f,t)
print('INTEGRATED',len(jobs),'Blender frame elements;',len(a),'total elements')
