from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];P=R/'godot/WhalebellyRuins'
a=json.loads((P/'assets/reference_environment/manifest.json').read_text('utf8'))['assets']
lines=['[gd_scene load_steps='+str(len(a)+2)+' format=3]','', '[ext_resource type="Script" path="res://scenes/environment/reference_environment.gd" id="1"]']
for i,e in enumerate(a,2):lines.append(f'[ext_resource type="Texture2D" path="res://assets/reference_environment/{e["path"]}" id="{i}"]')
lines+=['','[node name="ReferenceEnvironment" type="Node2D"]','script = ExtResource("1")','']
for i,e in enumerate(a,2):
 if e['id']=='BUBBLE-TEXTURE':continue
 x,y,w,h=e['source_rect'];id=e['id']
 lines += [f'[node name="{id}" type="Sprite2D" parent="."]',f'z_index = {e["layer"]}',f'position = Vector2({x}, {y})',f'texture = ExtResource("{i}")','centered = false',f'metadata/element_id = "{id}"',f'metadata/motion = "{e["motion"]}"','']
(P/'scenes/environment/xumen_reference.tscn').write_text('\n'.join(lines),encoding='utf8')
print('Scene sprite count',len(a)-1)
