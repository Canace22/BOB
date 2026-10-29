"""Place the approved shared 48-frame asset in R1-01 without warping its art.

Three near curtains share an atlas with individual similarity transforms/phases.
BALEEN-DISTANT contains the whole blue pillar and is deliberately preserved.
"""
from pathlib import Path
import hashlib, json, math, re, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'godot/WhalebellyRuins'
SOURCE=ROOT/'assets/source/baleen-loop-v3'
OUT=SOURCE/'integration'
RUNTIME=ROOT/'assets/runtime/baleen-loop-v3'
ATLAS='res://assets/baleen_loop_v3/baleen-sway-atlas.png'
PLACEMENTS=[
    dict(id='BALEEN-LEFT',source_points=[[54,175],[344,74]],target_points=[[285,74],[660,-56]],phase=0,flip=False),
    dict(id='BALEEN-CENTER',source_points=[[54,175],[344,74]],target_points=[[645,-16],[900,-26]],phase=13,flip=False),
    dict(id='BALEEN-RIGHT',source_points=[[40,74],[330,175]],target_points=[[900,-26],[1190,134]],phase=29,flip=True),
]

def text(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(value.rstrip()+'\n',encoding='utf-8',newline='\n')
def dump(path,value):text(path,json.dumps(value,ensure_ascii=False,indent=2))
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def transform(job):
    a,b=np.array(job['source_points'],float);c,d=np.array(job['target_points'],float)
    u=b-a;v=d-c;s=np.linalg.norm(v)/np.linalg.norm(u)
    angle=math.atan2(v[1],v[0])-math.atan2(u[1],u[0])
    rot=np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]])
    pos=c-s*rot@a
    return pos,s,angle

def clean_static_roots(content):
    # Existing "ROOT" plates contain whole frozen fringe silhouettes. Keep the
    # ceiling architecture, remove the old fibers from all seven owning layers.
    # The bare ceiling RGB is existing painted underlay, at its authored x=20.
    master=OUT/'master';master.mkdir(exist_ok=True)
    points=[[0,158],[100,158],[140,107],[200,101],[260,99],[300,97],[340,77],
            [400,38],[440,38],[480,51],[500,50],[520,44],[550,24],[585,30],
            [610,43],[650,47],[675,43],[695,25],[725,0],[950,0],[970,17],
            [1000,32],[1040,38],[1080,58],[1105,80],[1125,110],[1140,140],
            [1150,158],[1260,158]]
    # Coordinates above are in the clean painted underlay, whose scene x is 20.
    mask=Image.new('L',(1280,360));d=ImageDraw.Draw(mask)
    d.polygon([(0,0),(1280,0),(1280,158)]+[(x+20,y) for x,y in reversed(points)],fill=255)
    mask=mask.filter(ImageFilter.GaussianBlur(.65));mask.save(master/'ceiling-retain-mask.png')
    original=(OUT/'xumen-before.tscn.txt').read_text(encoding='utf-8')
    cleaned=[]
    for name in ['ROOF']+[f'BALEEN-{i:02d}-ROOT' for i in range(1,7)]:
        node=re.search(r'\[node name="'+name+r'"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',original,re.S)
        rid=re.search(r'texture = ExtResource\("([^"]+)"\)',node[1])[1]
        source=re.search(r'\[ext_resource type="Texture2D" path="([^"]+)" id="'+rid+r'"\]',original)[1]
        p=re.search(r'position = Vector2\(([^,]+), ([^)]+)\)',node[1]);x,y=[int(float(v)) for v in p.groups()]
        im=Image.open(PROJECT/source.removeprefix('res://')).convert('RGBA')
        a=np.asarray(im).copy();keep=np.asarray(mask.crop((x,y,x+im.width,y+im.height)),np.float32)/255
        if name=='BALEEN-01-ROOT':
            # This plate is the left bone branch and vines, not ivory fringe.
            keep[:]=1.0
        if name=='BALEEN-06-ROOT':
            # Retain the right wall lip; it extends below the ceiling strip.
            wall_keep=np.clip((np.arange(im.width)+x-1154)/24,0,1)
            keep=np.maximum(keep,wall_keep[None,:])
        before=a[:,:,3].copy();a[:,:,3]=np.uint8(before*keep+.5)
        if name=='ROOF':
            bare=Image.open(PROJECT/'assets/foreground_edges/CLEAN-ENV-DEPTH.png').convert('RGB')
            rgb=Image.new('RGB',im.size);rgb.paste(bare,(20,0));a[:,:,:3]=np.asarray(rgb)
        a[a[:,:,3]==0]=0
        file=f'CLEAN-{name}.png';Image.fromarray(a).save(master/file)
        shutil.copy2(master/file,PROJECT/'assets/baleen_loop_v3'/file)
        path=f'res://assets/baleen_loop_v3/{file}'
        content=re.sub(r'(\[ext_resource type="Texture2D" path=")[^"]+(" id="'+rid+r'"\])',lambda m:m[1]+path+m[2],content)
        cleaned.append({'id':name,'source':source,'asset':path,'position':[x,y],'removed_alpha_pixels':int(np.sum((before>0)&(a[:,:,3]==0)))})
    dump(OUT/'static-cleanup.json',{'method':'Painted clean underlay supplies ceiling RGB; traced ceiling mask removes frozen old fringe ownership from roof and six root plates. Source files unchanged.','ceiling_points_underlay_space':points,'layers':cleaned})
    return content,cleaned

def run():
    assert json.loads((SOURCE/'review/technical-pass.json').read_text())['passed']
    assert json.loads((SOURCE/'review/krita-validation.json').read_text())['all_pixel_identical']
    OUT.mkdir(exist_ok=True)
    protected=['project.godot','assets/rooms.json','scripts/main.gd','scenes/CampaignPlayer.tscn','scenes/environment/elements/BALEEN-DISTANT.tscn']
    if not (OUT/'protected-before.json').exists():
        dump(OUT/'protected-before.json',{p:digest(PROJECT/p) for p in protected})
        shutil.copy2(PROJECT/'scenes/environment/xumen_reference.tscn',OUT/'xumen-before.tscn.txt')
        for job in PLACEMENTS:shutil.copy2(PROJECT/f'scenes/environment/elements/{job["id"]}.tscn',OUT/(job['id']+'-before.tscn.txt'))
    dump(OUT/'instructions.json',{
        'input':'baleen-loop-v3 48 RGBA frames and shared atlas, existing R1-01 environment',
        'engine':'Godot 4.7.2.stable.official.ed1daf0bf / Compatibility',
        'steps':['Capture the existing environment at time zero.','Use shared V3 atlas for the three near curtains; equal XY scale, orientation and phase per attachment. Keep distant blue pillar.','Import fixed-engine resources, render environment and test phase, frame rate, root transforms, road isolation and two cycles.','Launch actual main scene; test current controller, camera, pause/toggle/zero speed and room reload.','Export to pending PCK, run same main tests from the standalone executable, then replace existing package on success.'],
        'source_scope':'no new gameplay, collision, camera logic or saves',
        'failure_action':'Keep failed evidence, repair only the placement or binding; do not publish failing package.'})
    for folder in [RUNTIME,PROJECT/'assets/baleen_loop_v3']:
        folder.mkdir(parents=True,exist_ok=True)
        shutil.copy2(SOURCE/'baleen-sway-atlas.png',folder/'baleen-sway-atlas.png')
    shutil.copy2(SOURCE/'frames/0000.png',RUNTIME/'preview.png')
    scene=PROJECT/'scenes/environment/xumen_reference.tscn';content=scene.read_text(encoding='utf-8')
    placements=[]
    for job in PLACEMENTS:
        pos,scale,angle=transform(job)
        text(PROJECT/f'scenes/environment/elements/{job["id"]}.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/baleen_frames.gd" id="1"]
[ext_resource type="Texture2D" path="{ATLAS}" id="2"]
[node name="{job['id']}" type="Sprite2D"]
texture = ExtResource("2")
centered = false
flip_h = {str(job['flip']).lower()}
hframes = 8
vframes = 6
script = ExtResource("1")
playback_fps = 12.0
frame_count = 48
period = 4.0
phase_offset_frames = {job['phase']}
''')
        pattern=r'(\[node name="'+re.escape(job['id'])+r'" parent="\." instance=.*?\])(.*?)(?=\n\[node|\Z)'
        found=re.search(pattern,content,re.S);assert found
        body=found[2]
        body=re.sub(r'z_index = [^\n]+','z_index = -1',body)
        body=re.sub(r'position = Vector2\([^\n]+\)',f'position = Vector2({pos[0]:.6f}, {pos[1]:.6f})',body)
        body=re.sub(r'\n(?:rotation|scale) = [^\n]+','',body)
        body=body.replace('external_clock = true',f'rotation = {angle:.9f}\nscale = Vector2({scale:.9f}, {scale:.9f})\nexternal_clock = true')
        body=re.sub(r'metadata/motion = "[^"]+"','metadata/motion = "wan22_keyart_delayed_tip_loop_12fps"',body)
        content=content[:found.start()]+found[1]+body+content[found.end():]
        placements.append({**job,'position':pos.tolist(),'uniform_scale':float(scale),'rotation_radians':float(angle),'z':-1,'source_asset':'BALEEN-LOOP-V3','frame_count':48,'fps':12,'period':4.0,'texture':ATLAS})
    content,cleaned=clean_static_roots(content)
    text(scene,content)
    dump(OUT/'placements.json',placements)
    dump(PROJECT/'assets/baleen_loop_v3/manifest.json',{'asset':'BALEEN-LOOP-V3','atlas':'baleen-sway-atlas.png','frames':48,'fps':12,'columns':8,'rows':6,'cell':[384,384],'source':'assets/source/baleen-loop-v3','instances':placements,'distant':'Original blue pillar atlas retained; not an ivory fringe'})
    # Keep inventory positions consistent with the actual editable scene.
    byid={p['id']:p for p in placements}
    path=ROOT/'assets/source/xumen-motion-elements/elements.json';items=json.loads(path.read_text(encoding='utf-8'))
    for item in items:
        if item['id'] in [c['id'] for c in cleaned]:
            item['asset']=next(c['asset'] for c in cleaned if c['id']==item['id'])
            item['source']='baleen-loop-v3/integration/master; original baked fringe removed'
        if item['id'] not in byid:continue
        p=byid[item['id']]
        item.update(position=p['position'],layer=-1,asset=ATLAS,motion='48 RGBA frames / 12 FPS / 4s periodic delayed-tip loop',source='baleen-loop-v3/krita/baleen-sway-12fps.kra',parameters=p)
    dump(path,items)
    path=ROOT/'assets/source/xumen-motion-elements/master/scene-layout.json';items=json.loads(path.read_text(encoding='utf-8'))
    for item in items:
        if item['id'] in [c['id'] for c in cleaned]:item['texture']=next(c['asset'] for c in cleaned if c['id']==item['id'])
        if item['id'] in byid:
            p=byid[item['id']];item.update(pos=p['position'],z=-1,kind='wan22_keyart_delayed_tip_loop_12fps',texture=ATLAS,scale=p['uniform_scale'],rotation=p['rotation_radians'],flip_h=p['flip'])
    dump(path,items)
    path=ROOT/'assets/source/xumen-motion-elements/master/editable-layout.svg'
    svg=path.read_text(encoding='utf-8')
    for row in cleaned:
        pattern=r'(<g id="'+re.escape(row['id'])+r'">.*?xlink:href=")[^"]+(".*?</g>)'
        svg=re.sub(pattern,lambda m:m[1]+'../../baleen-loop-v3/integration/master/CLEAN-'+row['id']+'.png'+m[2],svg)
    groups=[]
    for p in placements:
        svg=re.sub(r'<g id="'+p['id']+r'".*?</g>\n?','',svg,flags=re.S)
        x,y=p['position'];s=p['uniform_scale'];angle=math.degrees(p['rotation_radians'])
        flip=' transform="translate(384 0) scale(-1 1)"' if p['flip'] else ''
        groups.append(f'<g id="{p["id"]}" transform="translate({x} {y}) rotate({angle}) scale({s})"><title>V3 delayed tip loop, phase {p["phase"]}/48; z=-1</title><image width="384" height="384"{flip} xlink:href="../../baleen-loop-v3/frames/{p["phase"]:04d}.png"/></g>')
    svg=svg.replace('<g id="ROOF">','\n'.join(groups)+'\n<g id="ROOF">',1)
    text(path,svg)
    dump(OUT/'progress.json',{'stage':'source_bound_pending_runtime_validation','instances':3,'distant_pillar_preserved':True,'atlas_sha256':digest(SOURCE/'baleen-sway-atlas.png'),'next':'fixed-engine import, rendered tests and package verification'})
    print('BOUND_THREE_NEAR_CURTAINS',json.dumps(placements,ensure_ascii=False),flush=True)

if __name__=='__main__':run()
