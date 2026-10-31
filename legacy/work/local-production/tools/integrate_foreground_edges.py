from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'godot/WhalebellyRuins'
SOURCE=ROOT/'assets/source/xumen-foreground-edges'
def write(path,text):path.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
def run():
    data=json.loads((SOURCE/'manifest.json').read_text(encoding='utf-8'))
    scene_path=PROJECT/'scenes/environment/xumen_reference.tscn'
    text=scene_path.read_text(encoding='utf-8')
    for row in data['cleaned_static_layers']:
        node=re.search(r'\[node name="'+re.escape(row['node'])+r'"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',text,re.S)
        resource_id=re.search(r'texture = ExtResource\("([^"]+)"\)',node[1])[1]
        text=re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="'+resource_id+r'"\])',lambda m:m[1]+row['path']+m[2],text)
    ids=[e['id'] for e in data['foreground']]+['FOREGROUND-CORNER-BACKING']
    for i,row in enumerate(data['foreground']):
        name=row['id']
        write(PROJECT/f'scenes/environment/elements/{name}.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/motion_element.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/foreground_edges/{name}.png" id="2"]
[node name="{name}" type="Sprite2D"]
texture = ExtResource("2")
centered = false
script = ExtResource("1")
animation_kind = "parallax"
parallax_amount = -0.14
''')
    text=re.sub(r'^\[ext_resource[^\n]+id="fg_corner_[^"]+"\]\n','',text,flags=re.M)
    for name in ids:text=re.sub(r'\n\[node name="'+name+r'"[^\n]*\]\n.*?(?=\n\[node|\Z)','',text,flags=re.S)
    resources=''.join(f'[ext_resource type="PackedScene" path="res://scenes/environment/elements/{r["id"]}.tscn" id="fg_corner_{i}"]\n' for i,r in enumerate(data['foreground']))
    resources+='[ext_resource type="Texture2D" path="res://assets/foreground_edges/CORNER-BACKING.png" id="fg_corner_back"]\n'
    resources+='[ext_resource type="Texture2D" path="res://assets/foreground_edges/FRONT-BOTTOM-PAD.png" id="fg_corner_bottom"]\n'
    text=text.replace('[node name="ReferenceEnvironment"',resources+'\n[node name="ReferenceEnvironment"',1)
    def bottom(m):
        props=re.sub(r'^(?:texture|offset) = .*\n','',m[2],flags=re.M)
        return m[1]+props+'texture = ExtResource("fg_corner_bottom")\noffset = Vector2(-32, -32)\n'
    text=re.sub(r'(\[node name="FRONT-01"[^\n]*\]\n)(.*?)(?=\n\[node|\Z)',bottom,text,flags=re.S)
    for i,row in enumerate(data['foreground']):
        x,y=row['position'];name=row['id']
        text+=f'\n[node name="{name}" parent="." instance=ExtResource("fg_corner_{i}")]\nz_index = 51\nposition = Vector2({x}, {y})\nexternal_clock = true\nmetadata/element_id = "{name}"\nmetadata/motion = "parallax"\n'
    text+='\n[node name="FOREGROUND-CORNER-BACKING" type="Sprite2D" parent="."]\nz_index = -1\ntexture = ExtResource("fg_corner_back")\ncentered = false\nmetadata/element_id = "FOREGROUND-CORNER-BACKING"\nmetadata/motion = "static"\n'
    text=re.sub(r'load_steps=\d+',f'load_steps={text.count("[ext_resource")+1}',text,count=1)
    write(scene_path,text)
    src=ROOT/'assets/source/xumen-motion-elements'
    path=src/'elements.json';entries=json.loads(path.read_text(encoding='utf-8'));entries=[e for e in entries if e['id'] not in ids]
    for item in entries:
        if item['id']=='FRONT-01':item.update(asset='res://assets/foreground_edges/FRONT-BOTTOM-PAD.png',texture_offset=[-32,-32],edge_padding=32)
        for row in data['cleaned_static_layers']:
            if item['id']==row['node']:item['asset']=row['path']
    for row in data['foreground']:
        entries.append(dict(row,asset='res://assets/foreground_edges/'+row['id']+'.png',motion='rigid foreground parallax',scene='elements/'+row['id']+'.tscn',collision='N/A decorative foreground',sound='N/A',acceptance='mask visibility, matching parallax, backing coverage, no residual baked silhouette'))
    entries.append({'id':ids[-1],'position':[0,0],'layer':-1,'asset':'res://assets/foreground_edges/CORNER-BACKING.png','motion':'static hidden backing patches','collision':'N/A','sound':'N/A'})
    write(path,json.dumps(entries,ensure_ascii=False,indent=2))
    write(PROJECT/'tools/motion_elements/element-ids.json',json.dumps([e['id'] for e in entries]))
    path=src/'master/scene-layout.json';layout=json.loads(path.read_text(encoding='utf-8'));layout=[e for e in layout if e['id'] not in ids]
    for item in layout:
        for row in data['cleaned_static_layers']:
            if item['id']==row['node']:item['tex']=row['path']
    layout.extend({'id':row['id'],'pos':row['position'],'z':51,'scene':True,'kind':'parallax'} for row in data['foreground'])
    layout.append({'id':ids[-1],'pos':[0,0],'z':-1,'scene':False,'tex':'res://assets/foreground_edges/CORNER-BACKING.png','kind':'static'})
    write(path,json.dumps(layout,ensure_ascii=False,indent=2))
    path=src/'master/editable-layout.svg';svg=path.read_text(encoding='utf-8')
    for row in data['cleaned_static_layers']:
        pattern=r'(<g id="'+re.escape(row['node'])+r'">.*?xlink:href=")[^"]+(".*?</g>)'
        svg=re.sub(pattern,lambda m:m[1]+'../../xumen-foreground-edges/master/CLEAN-'+row['node']+'.png'+m[2],svg)
    svg=re.sub(r'<g id="FRONT-01">.*?</g>', '<g id="FRONT-01"><title>Padded bottom foreground, z=50</title><image x="-32" y="-32" width="1344" height="784" xlink:href="../../xumen-foreground-edges/master/FRONT-BOTTOM-PAD.png"/></g>',svg)
    for name in ids:svg=re.sub(r'<g id="'+name+r'">.*?</g>\n?','',svg)
    backing='<g id="FOREGROUND-CORNER-BACKING"><title>Local hidden backing z=-1</title><image width="1280" height="720" xlink:href="../../xumen-foreground-edges/master/CORNER-BACKING.png"/></g>\n'
    svg=svg.replace('<g id="ROOF">',backing+'<g id="ROOF">',1)
    for row in data['foreground']:
        x,y=row['position'];w,h=row['size'];name=row['id']
        group=f'<g id="{name}"><title>Independent foreground z=51</title><image x="{x}" y="{y}" width="{w}" height="{h}" xlink:href="../../xumen-foreground-edges/master/{name}.png"/></g>\n'
        svg=svg.replace('</svg>',group+'</svg>')
    write(path,svg)
    print('Integrated corner foreground; elements',len(entries))
if __name__=='__main__':run()
