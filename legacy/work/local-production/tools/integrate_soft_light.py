"""Replace polygon scene cutouts with independent feathered underwater light."""
from pathlib import Path
import json
import re

ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'godot/WhalebellyRuins'
JOBS=[('BEAM-01',[550,-105],[0.55,0.64],0.28,0.12,0.0),
      ('BEAM-02',[740,-80],[0.38,0.58],0.24,0.08,2.1),
      ('BEAM-03',[875,-60],[0.32,0.52],0.21,0.055,4.2)]
def write(path,text):path.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
def run():
    path=PROJECT/'scenes/environment/xumen_reference.tscn'
    text=path.read_text(encoding='utf-8')
    text=text.replace('res://assets/motion_elements/ENV-DEPTH.png','res://assets/soft_light/ENV-DEPTH-RESTORED.png')
    for name,pos,scale,angle,strength,phase in JOBS:
        text=text.replace(f'elements/{name}.tscn','elements/soft_underwater_light.tscn')
        pattern=rf'(\[node name="{name}"[^\n]*\]\n).*?(?=\n\[node|\Z)'
        properties=(f'z_index = -54\nposition = Vector2({pos[0]}, {pos[1]})\n'
                    f'scale = Vector2({scale[0]}, {scale[1]})\nrotation = {angle}\n'
                    f'intensity = {strength}\nphase = {phase}\nexternal_clock = true\n'
                    f'metadata/element_id = "{name}"\nmetadata/motion = "soft_light"\n')
        text=re.sub(pattern,lambda m:m[1]+properties,text,flags=re.S)
    write(path,text)
    source=ROOT/'assets/source/xumen-motion-elements'
    path=source/'elements.json';entries=json.loads(path.read_text(encoding='utf-8'))
    for e in entries:
        if e['id']=='ENV-DEPTH':e['asset']='res://assets/soft_light/ENV-DEPTH-RESTORED.png'
        for name,pos,scale,angle,strength,phase in JOBS:
            if e['id']==name:
                e.update(position=pos,layer=-54,asset='res://assets/soft_light/UNDERWATER-SOFT-LIGHT.png',
                         scene='elements/soft_underwater_light.tscn',motion='independent painted soft light',
                         parameters=dict(scale=scale,rotation=angle,intensity=strength,phase=phase,period=12),
                         source='../xumen-soft-light/README.md',acceptance='transparent perimeter; no scene sampling; no geometry motion; cycle and camera tests')
    write(path,json.dumps(entries,ensure_ascii=False,indent=2))
    path=source/'master/scene-layout.json';entries=json.loads(path.read_text(encoding='utf-8'))
    for e in entries:
        if e['id']=='ENV-DEPTH':e['tex']='res://assets/soft_light/ENV-DEPTH-RESTORED.png'
        for name,pos,scale,angle,strength,phase in JOBS:
            if e['id']==name:e.update(pos=pos,z=-54,kind='soft_light',scale=scale,rotation=angle)
    write(path,json.dumps(entries,ensure_ascii=False,indent=2))
    path=source/'master/editable-layout.svg'
    text=path.read_text(encoding='utf-8')
    text=text.replace('xlink:href="ENV-DEPTH.png"','xlink:href="../../xumen-soft-light/master/ENV-DEPTH-RESTORED.png"')
    text=re.sub(r'<g id="BEAM-0[1-3]">.*?</g>\n?','',text)
    groups=''
    import math
    for name,pos,scale,angle,strength,phase in JOBS:
        groups+=(f'<g id="{name}" transform="translate({pos[0]} {pos[1]}) rotate({math.degrees(angle)}) scale({scale[0]} {scale[1]})">'
                 f'<title>Independent painted soft light; z=-54; runtime shader defines additive animation</title>'
                 f'<image width="512" height="768" opacity="{strength}" xlink:href="../../xumen-soft-light/master/UNDERWATER-SOFT-LIGHT.png"/></g>\n')
    text=re.sub(r'(<g id="WATER-SURFACE">.*?</g>)',lambda m:m[1]+'\n'+groups,text)
    write(path,text)
    print('Three polygon beams replaced; original background restored; total100 IDs retained.')
if __name__=='__main__':run()
