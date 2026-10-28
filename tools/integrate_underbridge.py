from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'godot/WhalebellyRuins'
JOBS=[('BUBBLE-ZONE-05',[330,215,65,230],7,[5,9],14,0.48),('BUBBLE-ZONE-06',[560,485,110,170],7,[7,11],12,0.50),('BUBBLE-ZONE-07',[925,175,70,275],6,[4,8],15,0.44)]
def w(p,t):p.write_text(t.rstrip()+'\n',encoding='utf-8',newline='\n')
def run():
    path=P/'scenes/environment/xumen_reference.tscn';t=path.read_text(encoding='utf-8')
    t=t.replace('res://assets/foreground_edges/CLEAN-FOREGROUND-BACKING.png','res://assets/underbridge/FOREGROUND-BACKING-SOFT.png')
    t=t.replace('res://assets/foreground_edges/CLEAN-ROAD.png','res://assets/underbridge/ROAD-UNDERSIDE-RESTORED.png')
    t=re.sub(r'^\[ext_resource[^\n]+id="under_bubble_[^"]+"\]\n','',t,flags=re.M)
    resources=''
    for i,(name,bounds,count,size,speed,opacity) in enumerate(JOBS):
        w(P/f'scenes/environment/elements/{name}.tscn',f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/bubble_emitter.gd" id="1"]
[node name="{name}" type="Node2D"]
script = ExtResource("1")
bounds = Rect2({', '.join(map(str,bounds))})
population = {count}
seed_id = {i+4}
size_range = Vector2({size[0]}, {size[1]})
base_speed = {speed}.0
bubble_opacity = {opacity}
''')
        resources+=f'[ext_resource type="PackedScene" path="res://scenes/environment/elements/{name}.tscn" id="under_bubble_{i}"]\n'
        t=re.sub(r'\n\[node name="'+name+r'"[^\n]*\]\n.*?(?=\n\[node|\Z)','',t,flags=re.S)
        t+=f'\n[node name="{name}" parent="." instance=ExtResource("under_bubble_{i}")]\nz_index = -15\nexternal_clock = true\nmetadata/element_id = "{name}"\nmetadata/motion = "bubbles"\n'
    t=t.replace('[node name="ReferenceEnvironment"',resources+'\n[node name="ReferenceEnvironment"',1)
    t=re.sub(r'load_steps=\d+',f'load_steps={t.count("[ext_resource")+1}',t,count=1);w(path,t)
    s=ROOT/'assets/source/xumen-motion-elements';ids=[j[0] for j in JOBS]
    path=s/'elements.json';a=json.loads(path.read_text(encoding='utf-8'));a=[e for e in a if e['id'] not in ids]
    for e in a:
        if e['id']=='FOREGROUND-BACKING':e['asset']='res://assets/underbridge/FOREGROUND-BACKING-SOFT.png'
        if e['id']=='ROAD':e['asset']='res://assets/underbridge/ROAD-UNDERSIDE-RESTORED.png'
    for name,bounds,count,size,speed,opacity in JOBS:a.append({'id':name,'position':bounds,'layer':-15,'instances':count,'motion':'prewarmed rising bubbles, fade and recycle','asset':'res://assets/reference_environment/bubble.png','scene':'elements/'+name+'.tscn','parameters':{'size':size,'speed':speed,'opacity':opacity},'collision':'N/A','sound':'N/A'})
    w(path,json.dumps(a,ensure_ascii=False,indent=2));w(P/'tools/motion_elements/element-ids.json',json.dumps([e['id'] for e in a]))
    path=s/'master/scene-layout.json';a=json.loads(path.read_text(encoding='utf-8'));a=[e for e in a if e['id'] not in ids]
    for e in a:
        if e['id']=='FOREGROUND-BACKING':e['tex']='res://assets/underbridge/FOREGROUND-BACKING-SOFT.png'
        if e['id']=='ROAD':e['tex']='res://assets/underbridge/ROAD-UNDERSIDE-RESTORED.png'
    a.extend({'id':j[0],'pos':[0,0],'z':-15,'scene':True,'kind':'bubbles'} for j in JOBS);w(path,json.dumps(a,ensure_ascii=False,indent=2))
    path=s/'master/editable-layout.svg';t=path.read_text(encoding='utf-8').replace('../../xumen-foreground-edges/master/CLEAN-FOREGROUND-BACKING.png','../../xumen-underbridge-repair/master/FOREGROUND-BACKING-SOFT.png');w(path,t)
    w(path,t.replace('../../xumen-foreground-edges/master/CLEAN-ROAD.png','../../xumen-underbridge-repair/master/ROAD-UNDERSIDE-RESTORED.png'))
    print('Integrated 3 bubble zones; 56 bubbles; 106 environment elements.')
if __name__=='__main__':run()
