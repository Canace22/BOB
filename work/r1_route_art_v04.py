from pathlib import Path
import json, shutil, re, hashlib
from PIL import Image

p=Path('G:/鲸落万物生/BOB/godot/first-level')
ref=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
gen=Path('C:/Users/Kingsoft/.codex/generated_images/01a15e43-0218-75b2-af77-efe609e99875')
files={'ledge':'exec-72eff7c0-c014-45c9-b3e3-772f875cd895.png','oral-depth':'exec-efa12069-134e-427c-917d-facaab119391.png','baleen':'exec-f520d9d2-e45a-4605-b54b-5b5c45b81d3b.png','frame':'exec-de628ffa-2897-413f-8103-a141e2262242.png'}
manifest=[]
for name,fn in files.items():
 for group in ['source','master','runtime']:
  out=p/f'assets/{group}/v04/{name}.png';out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(gen/fn,out)
 im=Image.open(gen/fn)
 manifest.append({'id':name,'source':str(gen/fn),'runtime':f'assets/runtime/v04/{name}.png','size':im.size,'mode':im.mode,'alpha':im.getchannel('A').getextrema() if im.mode=='RGBA' else None,'sha256':hashlib.sha256((gen/fn).read_bytes()).hexdigest(),'provider':'builtin image_gen','reference':'R1-02.png','processing':'unmodified copies; texture regions only in editable Godot scenes'})
out=p/'assets/reference/r1';out.mkdir(parents=True,exist_ok=True)
for r in range(1,8):
 name=f'R1-{r:02}'
 shutil.copy2(ref/f'references/{name}.png',out/f'{name}.png')
 shutil.copy2(ref/f'maps/{name}.svg',out/f'{name}.svg')

rooms=json.loads((p/'assets/rooms.json').read_text('utf8'))
for i,r in enumerate(rooms):
 f=p/f'scenes/r1/{r["id"]}.tscn';s=f.read_text('utf8')
 # Edit existing scenes, retaining every collision coordinate and room-specific anatomy.
 s=s.replace('[node name="Middle" type="Node2D" parent="."]\nz_index = -15','[node name="Middle" type="Node2D" parent="."]\nz_index = -15\nscript = ExtResource("1")\nparallax = Vector2(0.5, 0.5)\nreference_center = Vector2(%s, %s)'%(r['width']*32,r['height']*32))
 s=s.replace('[node name="Foreground" type="Node2D" parent="."]\nz_index = 6','[node name="Foreground" type="Node2D" parent="."]\nz_index = 6\nscript = ExtResource("1")\nparallax = Vector2(1.2, 1.2)\nreference_center = Vector2(%s, %s)\nfade_near_player = true'%(r['width']*32,r['height']*32))
 # Keep the latest separated silhouette in room01. Use the reference's fiber canopy inside the mouth.
 if i in [1,2,3,6]:
  s=s.replace('assets/runtime/v03/canopy.png','assets/runtime/v04/baleen.png')
  s=s.replace('assets/runtime/background.png','assets/runtime/v04/oral-depth.png')
 # New ledge only replaces shelf tops. Old terrain still supplies non-walkable supporting tissues.
 ext='[ext_resource type="Texture2D" path="res://assets/runtime/v04/ledge.png" id="v04_ledge"]\n[ext_resource type="Texture2D" path="res://assets/runtime/v04/frame.png" id="v04_frame"]\n'
 s=s.replace('\n\n[ext_resource', '\n\n'+ext+'\n[ext_resource',1)
 blocks=re.split(r'(?=\[node )',s)
 for n,b in enumerate(blocks):
  if b.startswith('[node name="TongueLedge"'):
   # New PNG top lies around y=290 at center; region removes padding, retaining painted overhang.
   plid=re.search(r'parent="World/Shelf_([^\"]+)"',b).group(1)
   pl=next(t for t in r['platforms'] if t['id']==plid)
   w=pl['w']*64+8;h=185 if plid.startswith('P') else 105
   b=re.sub(r'position = Vector2\([^\n]+','position = Vector2(-4, -8)',b)
   b=re.sub(r'scale = Vector2\([^\n]+',f'scale = Vector2({w/1980:.6f}, {h/410:.6f})',b)
   b=re.sub(r'texture = ExtResource\("[^\"]+"\)','texture = ExtResource("v04_ledge")',b)
   b=re.sub(r'region_rect = Rect2\([^\n]+','region_rect = Rect2(24, 280, 1980, 410)',b)
  if b.startswith('[node name="RootedOrgan"'):
   # Organic support tapers, instead of a repeated rectangular block down to the frame.
   par=re.search(r'parent="World/Shelf_([^\"]+)"',b).group(1);pl=next(t for t in r['platforms'] if t['id']==par)
   w=pl['w']*64;depth=max(420,r['height']*64-pl['y']*64+100)
   pts=[(0,95),(w,95),(w*.76,200),(w*.57,depth*.7),(w*.7,depth),(w*.32,depth),(w*.38,depth*.7),(w*.21,220)]
   b=re.sub(r'polygon = PackedVector2Array\([^\n]+','polygon = PackedVector2Array('+', '.join(str(round(a,2))for pt in pts for a in pt)+')',b)
   b=b.replace('Color(0.48, 0.40, 0.46, 1)','Color(0.34, 0.40, 0.48, 1)')
  blocks[n]=b
 s=''.join(blocks)
 W=r['width']*64;H=r['height']*64
 s+=f'\n[node name="NearShellRidge" type="Sprite2D" parent="Foreground"]\nposition = Vector2(-300, {H-460})\nscale = Vector2({(W+600)/2172:.6f}, 0.75)\ntexture = ExtResource("v04_frame")\ncentered = false\n'
 s=re.sub(r'load_steps=\d+',lambda m:'load_steps='+str(int(m.group().split('=')[1])+2),s,1)
 f.write_text(s,encoding='utf8')
(p/'docs/v04/assets.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print('Four assets copied; seven editable scenes revised without changing coordinate geometry.')
