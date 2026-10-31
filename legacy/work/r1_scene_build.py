from pathlib import Path
import json,shutil,hashlib,sys
from PIL import Image
p=Path('G:/鲸落万物生/BOB/godot/first-level');g=Path('C:/Users/Kingsoft/.codex/generated_images/01a15e43-0218-75b2-af77-efe609e99875')
files={'terrain':'exec-57044b07-b49c-479b-b15f-f7063d044447.png','canopy':'exec-861026aa-ad9d-4ca8-8bc4-798fb398e161.png','jaw':'exec-b95a4f98-c209-4aa9-a5a2-ff2ae66c44a2.png'}
if len(sys.argv)>2:files.update(ocean=sys.argv[1],skull=sys.argv[2])
records=[]
for name,fn in files.items():
 for part in ['source','master','runtime']:
  dest=p/f'assets/{part}/v03/{name}.png';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(g/fn,dest)
 im=Image.open(g/fn);a=im.getchannel('A')if im.mode=='RGBA' else None
 records.append({'id':name,'source':str(g/fn),'runtime':f'assets/runtime/v03/{name}.png','size':im.size,'mode':im.mode,'alpha_extrema':a.getextrema()if a else None,'fully_transparent_pixels':a.histogram()[0]if a else None,'sha256':hashlib.sha256((g/fn).read_bytes()).hexdigest(),'tool':'builtin image_gen','image_processing':'copy only; scene uses texture regions/scale; originals preserved'})
shutil.copy2('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解/images/head-mouth-v5.png',p/'assets/runtime/v03/panorama.png')
(p/'docs/v03/assets.json').write_text(json.dumps({'new':records,'reused':['background','throat','checkpoint','hero/*','crab','boss','v02/plant','v02/lamp','v02/gate','v02/cargo','v02/water'],'anchors':{'terrain':'top edge using region y=145','canopy':'upper-left','jaw':'upper-left','lamps':'top-center','plants':'bottom-center'},'new_assets_cost':'unknown','third_party_paid':False},ensure_ascii=False,indent=2),encoding='utf8')
rooms=json.loads((p/'assets/rooms.json').read_text('utf8'))
out=p/'scenes/r1';out.mkdir(parents=True,exist_ok=True)
manifest=[]
def v(x,y):return f'Vector2({x:.3f}, {y:.3f})'
for ri,r in enumerate(rooms):
 W,H=r['width']*64,r['height']*64
 ext=[];nodes=[];subs=[];ids={};uid=[0]
 def resource(path,typ='Texture2D'):
  if path not in ids:
   id=str(len(ids)+1);ids[path]=id;ext.append(f'[ext_resource type="{typ}" path="res://{path}" id="{id}"]')
  return f'ExtResource("{ids[path]}")'
 motion=resource('scripts/scenery_motion.gd','Script')
 def node(name,typ,parent='.',props=''):
  nodes.append(f'[node name="{name}" type="{typ}"'+(' parent="'+parent+'"'if parent else '')+']\n'+props)
 def sprite(name,path,parent,x,y,w,h,tint=None,region=None,moving=False):
  im=Image.open(p/path);iw,ih=im.size
  props=f'position = {v(x,y)}\nscale = {v(w/(region[2]if region else iw),h/(region[3]if region else ih))}\ntexture = {resource(path)}\ncentered = false\n'
  if region:props+='region_enabled = true\nregion_rect = Rect2('+', '.join(map(str,region))+')\n'
  if tint:props+='modulate = Color('+', '.join(map(str,tint))+')\n'
  if 'canopy.png' in path:
   mat='BaleenMaterial'+name
   subs.append(f'[sub_resource type="ShaderMaterial" id="{mat}"]\nshader = {resource("assets/runtime/v03/baleen.gdshader","Shader")}\n')
   props+=f'material = SubResource("{mat}")\nscript = {motion}\n'
  elif moving:props+=f'script = {motion}\nsway = 0.012\nphase = {x*.01:.3f}\n'
  node(name,'Sprite2D',parent,props)
 def line(name,points,color,width,parent='World'):
  ps=', '.join(str(round(a,3))for pt in points for a in pt)
  node(name,'Line2D',parent,f'points = PackedVector2Array({ps})\nwidth = {width}\ndefault_color = Color({color})\nantialiased = true\n')
 node(r['id'].replace('-','_'),'Node2D','')
 for name,z in [('Far',-30),('Middle',-15),('World',-1),('Foreground',6)]:
  node(name,'Node2D','.',f'z_index = {z}\n')
 node('FarDrift','Node2D','Far',f'position = Vector2(-1400, -900)\nscript = {motion}\nparallax = Vector2(0.10, 0.12)\n')
 bg='assets/runtime/v03/ocean.png'if ri==0 else ('assets/runtime/throat.png'if ri==4 else ('assets/runtime/v03/skull.png'if ri==5 else 'assets/runtime/background.png'))
 if not (p/bg).exists():bg='assets/runtime/background.png'
 sprite('DeepWater',bg,'Far/FarDrift',0,0,2800,1800,(.70,.79,.85,1) if ri!=5 else (.85,.89,.90,1))
 # Separate massive anatomy from actual collision shelves.
 if ri==0:
  sprite('OpenUpperJaw','assets/runtime/v03/canopy.png','Middle',-160,220,W+450,590)
  sprite('LowerJawSkin','assets/runtime/v03/jaw.png','Middle',-80,860,W+180,540)
 elif ri in [1,2,3,6]:
  yy={1:245,2:55,3:-30,6:140}[ri];hh={1:600,2:570,3:700,6:550}[ri]
  sprite('UpperPalateAndBaleen','assets/runtime/v03/canopy.png','Middle',-350,yy,W+700,hh,(.82,.87,.90,1))
  if ri in [2,3]:sprite('ContinuousTongueBase','assets/runtime/v03/terrain.png','Middle',-70,1060,W+140,500,(.33,.38,.48,1))
  if ri==6:
   # Opaque root wall is a closed dead end, no invented right exit.
   sprite('ClosedRootWall','assets/runtime/v03/terrain.png','Middle',W-55,570,330,700,(.45,.41,.44,1))
 else:
  sprite('LeftScarWall','assets/runtime/v03/terrain.png','Middle',-200,0,300,H+100,(.32,.36,.43,1))
  sprite('RearMembrane','assets/runtime/throat.png','Middle',W-350,-60,550,H+200,(.52,.51,.57,.62))
 for pi,pl in enumerate(r['platforms']):
  x,y,w=pl['x']*64,pl['y']*64,pl['w']*64
  floating=not pl['id'].startswith('P')
  root='Shelf_'+pl['id'];node(root,'StaticBody2D','World',f'position = {v(x,y)}\ncollision_layer = 1\ncollision_mask = 0\n')
  sid='Shape_'+str(pi);subs.append(f'[sub_resource type="RectangleShape2D" id="{sid}"]\nsize = {v(w,64)}')
  node('Collision','CollisionShape2D','World/'+root,f'position = {v(w/2,32)}\nshape = SubResource("{sid}")\none_way_collision = '+('true'if floating else 'false')+'\none_way_collision_margin = 6.0\n')
  # Whole slab once per shelf; long boss floor uses a single broad sprite.
  if not floating and ri<5:
   depth=max(480,H-y+250)
   pts=[(18,80),(w-18,80),(w-24,190),(w-8,310),(w+28,depth),(-25,depth),(10,310),(27,190)]
   uv=[(530,260),(1490,260),(1460,350),(1490,430),(1550,610),(470,610),(530,430),(560,350)]
   flatten=lambda a:', '.join(str(round(v,2))for xy in a for v in xy)
   node('RootedOrgan','Polygon2D','World/'+root,f'polygon = PackedVector2Array({flatten(pts)})\nuv = PackedVector2Array({flatten(uv)})\ntexture = {resource("assets/runtime/v03/terrain.png")}\ncolor = Color(0.48, 0.40, 0.46, 1)\nantialiased = true\n')
  tint=(.96,.94,.96,1)if ri<4 else ((.70,.78,.86,1)if ri==5 else (.84,.82,.90,1))
  sprite('TongueLedge','assets/runtime/v03/terrain.png','World/'+root,-4,-10,w+8,230 if not floating else 105,tint,region=(0,145,2019,560))
  line('ReadableTop_'+str(pi),[(x+9,y+2),(x+w-9,y+2)],'0.97, 0.73, 0.55, 0.40',2)
  if floating:
   for off in [.22,.78]:
    xx=x+w*off;line('Tether_'+str(pi)+'_'+str(off),[(xx,max(50,y-330)),(xx,y-8)],'0.58, 0.17, 0.12, 1',4)
   sprite('ShellHinge_'+str(pi),'assets/runtime/v02/cargo.png','World',x+w*.15,y-40,48,48)
  if not floating:
   if not(ri==3 and pi==1):
    sprite('Colonies_'+str(pi),'assets/runtime/v02/plant.png','World',x+w*.7,y-46,65,50,(.72,.76,.69,.9),moving=True)
   if pi%2==0:
    sprite('Lamp_'+str(pi),'assets/runtime/v02/lamp.png','World',x+w*.6,y-115,42,76,moving=True)
    line('LampRope_'+str(pi),[(x+w*.6+20,y-115),(x+w*.6+30,y-160)],'0.55, 0.20, 0.13, 1',2)
  if not floating and pi in [0,len(r['platforms'])-1]:
   sprite('NearColony_'+str(pi),'assets/runtime/v02/plant.png','Foreground',x-60,y+90,180,150,(.16,.26,.30,.8),moving=True)
 if ri==1:
  for x,y,label in [(5*64,6.5*64,'A2'),(33*64,10*64,'A3')]:
   sprite('Gate_'+label,'assets/runtime/v02/gate.png','World',x-65,y-150,130,150,(.66,.78,.77,1))
   node('GateLabel_'+label,'Label','World',f'offset_left = {x-65}\noffset_top = {y-190}\noffset_right = {x+100}\ntext = "{label} · 回访"\ntheme_override_font_sizes/font_size = 20\n')
 if ri==5:
  sprite('LungSideLockedGate','assets/runtime/v02/gate.png','World',W-135,11*64-190,135,190)
  for pl in r['platforms'][:3]:
   x,y=(pl['x']+pl['w']-.4)*64,pl['y']*64
   for off in [0,25,50]:line('Flow_'+str(pl['id'])+'_'+str(off),[(x+off,y-20),(x+off+35,y-200)],'0.35, 0.78, 0.81, 0.24',3)
 if ri==6:
  for ai,a in enumerate(r['anchors']):
   x,y=a['x']*64,a['y']*64
   line('RedCord_'+str(ai),[(x-30,300),(x,y)],'0.69, 0.24, 0.14, 1',5)
   import math
   pts=[(x+16*math.cos(t*math.tau/32),y+16*math.sin(t*math.tau/32))for t in range(33)]
   line('AnchorRing_'+str(ai),pts,'0.91, 0.73, 0.48, 1',4)
  node('ClosedRightWall','StaticBody2D','World',f'position = {v(W+16,H/2)}\ncollision_layer = 1\n')
  subs.append('[sub_resource type="RectangleShape2D" id="RightWall"]\nsize = Vector2(32, 1800)')
  node('Collision','CollisionShape2D','World/ClosedRightWall','shape = SubResource("RightWall")\n')
 for qi,q in enumerate(r.get('rewards',[])):
  if ri<5:continue
  sprite('Reward_'+str(qi),'assets/runtime/v02/cargo.png','World',q['x']*64-25,q['y']*64-25,50,50)
 scene='[gd_scene load_steps='+str(len(ext)+len(subs)+1)+' format=3]\n\n'+'\n\n'.join(ext+subs+nodes)+'\n'
 file=out/(r['id']+'.tscn');file.write_text(scene,encoding='utf8')
 manifest.append({'room':r['id'],'scene':str(file.relative_to(p)),'platform_count':len(r['platforms']),'collision_units':64,'layers':['Far','Middle','World','Foreground'],'anatomy':r['anatomy']['part'],'scope':'playable first visit'if ri<5 else 'full scenery + inspection camera; future ability progression not included'})
(p/'docs/v03/scene-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print('Seven editable scene files generated')
