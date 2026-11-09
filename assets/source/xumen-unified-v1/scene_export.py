"""Generate the editable Godot node scene from the same world master contract."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[3];O=R/'assets/runtime/scenes/xumen-unified-v1'
d=json.loads((O/'scene.json').read_text(encoding='utf8'))
files=sorted({t['file'] for t in d['tiles']}|{i['file'] for i in d['instances']}|{m['texture'] for m in d['meshes']})
ids={f:str(i+3) for i,f in enumerate(files)}
out=['[gd_scene load_steps='+str(len(files)+6)+' format=3]',
'[ext_resource type="Script" path="res://src/campaign/connected/unified_scene.gd" id="1"]',
'[ext_resource type="Shader" path="res://src/campaign/connected/unified_membrane.gdshader" id="2"]']
out.append('[ext_resource type="Shader" path="res://src/campaign/connected/unified_water.gdshader" id="Water"]')
for f in files:out.append('[ext_resource type="Texture2D" path="res://art/xumen-unified/'+f+'" id="'+ids[f]+'"]')
out+=['[sub_resource type="ShaderMaterial" id="Membrane"]','shader = ExtResource("2")','[sub_resource type="ShaderMaterial" id="WaterMaterial"]','shader = ExtResource("Water")','[node name="UnifiedXumen" type="Node2D"]','script = ExtResource("1")']
for layer in ['Far','Middle','World','Foreground']:out.append('[node name="'+layer+'" type="Node2D" parent="."]')
def nums(v):return ', '.join(str(round(float(x),5)) for x in v)
def points(v):return 'PackedVector2Array('+nums([x for p in v for x in p])+')'
for i,t in enumerate(d['tiles']):
 out += ['[node name="Tile'+str(i)+'" type="Sprite2D" parent="'+t['layer']+'"]','texture = ExtResource("'+ids[t['file']]+'")','centered = false','position = Vector2('+nums(t['at'])+')','z_index = '+str(t['z'])]
 if t['layer']=='Far':out+=['material = SubResource("WaterMaterial")']
for m in d['meshes']:
 out+=['[node name="'+m['id']+'" type="Polygon2D" parent="'+m['layer']+'"]','texture = ExtResource("'+ids[m['texture']]+'")','texture_repeat = 2','antialiased = true','polygon = '+points(m['polygon']),'uv = '+points(m['uv']),'z_index = '+str(m['z']),'color = Color('+nums(m['color'])+')']
 if m['id'].startswith('MAIN-JAW'):out+=['material = SubResource("Membrane")']
 if 'polygons' in m:out+=['polygons = Array[PackedInt32Array](['+', '.join('PackedInt32Array('+', '.join(map(str,p))+')' for p in m['polygons'])+'])']
for i in d['instances']:out+=['[node name="'+i['id']+'" type="Sprite2D" parent="'+i['layer']+'"]','texture = ExtResource("'+ids[i['file']]+'")','centered = false','position = Vector2('+nums(i['at'])+')','scale = Vector2('+str(i['scale'])+', '+str(i['scale'])+')','z_index = '+str(i['z'])]
p=R/'game/content/whalebelly/environment/unified/unified_world.tscn';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(('\n\n'.join(out)+'\n').encode('utf8'));print(p)
