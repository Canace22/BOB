"""Build the seven authored Xumen rooms from actual-coordinate recipes and bitmap pieces."""
import json,math,copy,hashlib
from pathlib import Path
from PIL import Image
from build_xumen_layers import build_layers
from build_xumen_foundations import build_foundations
from build_xumen_structures import build_structures
from build_xumen_ambience import build_ambience
from build_xumen_background import build_background, parameters as background_parameters
GAME=Path(__file__).resolve().parents[1]
ROOT=GAME.parent
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
recipes=read(GAME/'content/whalebelly/layout/recipes.json')['rooms']
physics=read(GAME/'content/whalebelly/layout/physics-v1.json')
# Keep the original geometry signature for retained platforms and wall records.
# Explicit user removals suppress whole assemblies without editing their boxes.
geometry=[{'id':r['id'],'platforms':r['platforms'],'walls':[{k:v for k,v in wall.items() if k!='removed'} for wall in r['walls']]} for r in recipes]
signature=hashlib.sha256(json.dumps(geometry,sort_keys=True,separators=(',',':')).encode()).hexdigest()
if signature!=physics['recipe_geometry_sha256']:
    raise ValueError('Layout changed: review the physics contract before rebuilding art.')
frozen={r['id']:r for r in physics['rooms']}
native=['original-ledge','original-membrane','original-membrane-pressed','original-bone-ledge','original-soft-ledge','porous-wall','cavity-roof','anatomy-fracture']
used={}

def texture_path(name):
    if name=='ivory-ledge':return 'res://art/world-kit/r4-bone-platform.png'
    folder='xumen-original-style-v1' if name in native else 'xumen-layout-v1'
    return 'res://art/'+folder+'/'+name+'.png'

def deck_piece(rid,spec):
    if spec.get('membrane'):return 'original-membrane'
    return 'original-ledge'
def metrics(name):
    if name not in used:
        im=Image.open(GAME/texture_path(name).removeprefix('res://')).convert('RGBA')
        a=im.getchannel('A');used[name]=(im,a,a.point(lambda v:255 if v>=32 else 0).getbbox())
    return used[name]
def v(p):return 'Vector2(%s,%s)'%(round(p[0],3),round(p[1],3))
def poly(points):return 'PackedVector2Array('+','.join(str(round(n,3)) for p in points for n in p)+')'
def top_at(alpha,x,lo,hi):
    for y in range(lo,hi):
        if alpha.getpixel((int(x),y))>=128:return y
    return lo

def segment_crosses_box(start,end,box):
    """Conservative visual keep-out only; never creates or changes collision."""
    near,far=0.0,1.0
    for axis in range(2):
        delta=end[axis]-start[axis]
        if abs(delta)<.0001:
            if not box[axis]<=start[axis]<=box[axis+2]:return False
        else:
            first=(box[axis]-start[axis])/delta;last=(box[axis+2]-start[axis])/delta
            near=max(near,min(first,last));far=min(far,max(first,last))
            if near>far:return False
    return True

def checkpoint_lanes(platforms,walls,surfaces):
    """Subtract body-overlapping solids from the original foot-point lanes."""
    def clip_height(polygon,height,keep_above):
        result=[]
        for first,last in zip(polygon,polygon[1:]+polygon[:1]):
            inside=lambda point:point[1]>=height if keep_above else point[1]<=height
            a,b=inside(first),inside(last)
            if a:result.append(first)
            if a!=b:
                t=(height-first[1])/(last[1]-first[1])
                result.append([first[0]+t*(last[0]-first[0]),height])
        return result
    solids=[]
    for spec,contour in zip(platforms,surfaces):
        if spec.get('one_way'):continue
        depth=100 if spec.get('membrane') else 30
        solids.append((spec['id'],contour+[[spec['x']+spec['w']-14,spec['y']+depth],[spec['x']+14,spec['y']+depth]]))
    for wall in walls:
        x,y,w,h=wall['box']
        solids.append((wall['id'],[[x+12,y+12],[x+w-12,y+12],[x+w-12,y+h-12],[x+12,y+h-12]]))
    result=[]
    for spec in platforms:
        if spec['w']<100:continue
        foot=spec['y'];spans=[[spec['x']+35,spec['x']+spec['w']-35]]
        for owner,polygon in solids:
            if owner==spec['id'] or foot<=min(p[1] for p in polygon) or foot-94>=max(p[1] for p in polygon):continue
            overlap=clip_height(clip_height(polygon,foot-94,True),foot,False)
            if not overlap:continue
            # 0.01px prevents float/serialized-boundary contact from becoming
            # penetration; the required actor envelope is +/-18 by 94 pixels.
            left=min(p[0] for p in overlap)-18-.01;right=max(p[0] for p in overlap)+18+.01
            remaining=[]
            for start,end in spans:
                if right<=start or left>=end:remaining.append([start,end]);continue
                if left>start:remaining.append([start,min(left,end)])
                if right<end:remaining.append([max(right,start),end])
            spans=remaining
        result.extend({'x':[round(start,3),round(end,3)],'y':foot,'surface_id':spec['id']} for start,end in spans if end-start>=1)
    return result
class Scene:
    def __init__(self):self.resources={};self.subs=[];self.nodes=[]
    def ext(self,typ,path):
        if path not in self.resources:self.resources[path]=(typ,str(len(self.resources)+1))
        return 'ExtResource("'+self.resources[path][1]+'")'
    def node(self,name,typ,parent,**props):
        h=f'[node name="{name}" type="{typ}"'+(']' if parent is None else f' parent="{parent}"]')
        self.nodes.append(h+'\n'+'\n'.join(f'{k} = {value}' for k,value in props.items()))
    def sprite(self,name,parent,path,pos,scale,z=0,**extra):
        self.node(name,'Sprite2D',parent,texture=self.ext('Texture2D',path),position=v(pos),scale=v([scale,scale]),centered='false',z_index=z,**extra)
    def material(self,shader,params=None):
        key='m'+str(len(self.subs)+1)
        self.subs.append(f'[sub_resource type="ShaderMaterial" id="{key}"]\nshader = '+self.ext('Shader',shader)+'\n'+'\n'.join('shader_parameter/'+k+' = '+str(val) for k,val in (params or {}).items()))
        return 'SubResource("'+key+'")'
    def text(self):
        res='\n'.join(f'[ext_resource type="{typ}" path="{p}" id="{i}"]' for p,(typ,i) in self.resources.items())
        return '[gd_scene format=3]\n\n'+res+'\n\n'+'\n\n'.join(self.subs+self.nodes)+'\n'
all_rooms=[]
for recipe in recipes:
    r=copy.deepcopy(recipe);rid=r['id'];idx=int(rid[-2:])-1
    sc=Scene();sc.node(rid,'Node2D',None)
    for layer,z in [('Far',-30),('Middle',-15),('World',0),('Foreground',10)]:sc.node(layer,'Node2D','.',z_index=z)
    sc.node('Art','Node2D','World');sc.node('Terrain','Node2D','World')
    # A full painted underpaint provides depth without bringing back the old road.
    # The opening room is the great mouth/jaw, not the next room's vertical grove.
    bg='res://art/xumen-scale-v1/oral-depth.png' if rid=='R1-01' else 'res://art/r1-chapter-scenes/'+rid+'/underpaint.png'
    bmp=Image.open(GAME/bg.removeprefix('res://'));scale=max(r['size'][0]/bmp.width,r['size'][1]/bmp.height)*1.08
    sc.node('Depth','Node2D','Far',script=sc.ext('Script','res://src/world/scenery/kit/kit_parallax.gd'),factor=0.14,room_center=v([n/2 for n in r['size']]))
    water_params=background_parameters(recipe,GAME)
    atmosphere=sc.material('res://src/world/scenery/layout/depth_atmosphere.gdshader',{'recess':.18,**water_params})
    sc.sprite('Paint','Far/Depth',bg,[(r['size'][0]-bmp.width*scale)/2,(r['size'][1]-bmp.height*scale)/2],scale,material=atmosphere,modulate='Color(0.76,0.84,0.88,1)')
    build_layers(sc, recipe, GAME, v, water_params)
    build_background(sc,recipe,GAME,v)
    cutout=sc.material('res://src/world/scenery/layout/bitmap_cutout.gdshader')
    surfaces=[]
    for platform_index,spec in enumerate(r.pop('platforms')):
        name=spec['id'];x,y,w=spec['x'],spec['y'],spec['w']
        piece=deck_piece(rid,spec)
        im,a,b=metrics(piece);usable=b[2]-b[0];count=max(1,math.ceil(w/620));span=w/count
        contour=[]
        for tile in range(count):
            k=(span+18)/usable;mid=(b[0]+b[2])/2
            # Register the native walking strip without stretching its pixels.
            anchor=max(top_at(a,b[0]+usable*q,b[1],b[3]) for q in [.12,.25,.4,.5,.6,.75,.88])+3
            pos=[x+tile*span-9-b[0]*k,y-anchor*k]
            # All tiles share native uniform scale; only overlap hides closed ends.
            sprite_name='MembraneArt' if spec.get('membrane') else name+'_'+str(tile)
            if spec.get('membrane'):
                material=sc.material('res://src/world/scenery/layout/membrane.gdshader',{'local_per_world':1/k,'u_left':b[0]/im.width,'u_right':b[2]/im.width})
                sc.node(sprite_name,'MeshInstance2D','World/Art',script=sc.ext('Script','res://src/world/scenery/layout/layout_membrane.gd'),texture=sc.ext('Texture2D',texture_path(piece)),position=v(pos),scale=v([k,k]),material=material)
            else: sc.sprite(sprite_name,'World/Art',texture_path(piece),pos,k,material=cutout,modulate='Color(0.84,0.88,0.91,1)')
            for n in range(9):
                localx=b[0]+usable*(.035+.93*n/8)
                px=pos[0]+localx*k
                py=pos[1]+top_at(a,localx,b[1],b[3])*k
                if x+12<=px<=x+w-12:contour.append([px,y if spec.get('membrane') else py])
        contour.sort();left=x+14;right=x+w-14
        # Replacing artwork never re-samples the validated physics contour.
        contour=copy.deepcopy(frozen[rid]['surfaces'][platform_index])
        depth=100 if spec.get('membrane') else 30
        sc.node(name,'StaticBody2D','World/Terrain')
        sc.node('Contour','CollisionPolygon2D','World/Terrain/'+name,polygon=poly(contour+[[right,y+depth],[left,y+depth]]),one_way_collision=str(bool(spec.get('one_way'))).lower(),one_way_collision_margin=6.0)
        surfaces.append(contour)
        if rid=='R1-04' and name=='Surface3':
            # The original Boss painting has a substantial tissue-and-bone
            # ground mass. A native larger rear ledge deepens it below the cap.
            fi,fa,fb=metrics('original-ledge');fw=(fb[2]-fb[0]);count=2
            for n in range(count):
                fk=(w/count+28)/fw;anchor=top_at(fa,(fb[0]+fb[2])/2,fb[1],fb[3])
                sc.sprite(name+'_Foundation'+str(n),'World/Art',texture_path('original-ledge'),[x+n*w/count-14-fb[0]*fk,y+18-anchor*fk],fk,-3,modulate='Color(0.57,0.65,0.7,1)')
    r['surfaces']=surfaces;r['layout']['checkpoint_lanes']=copy.deepcopy(frozen[rid]['checkpoint_lanes'])
    build_foundations(sc,recipe,metrics,texture_path,top_at,segment_crosses_box)
    build_structures(sc,recipe,GAME,v,poly)
    r.pop('walls')
    # New door positions retain the old source graph's exact ordering and conditions.
    sc.node('Doorways','Node2D','.')
    for n,d in enumerate(r['doors']):
        to=int(d['to']);target='R1-%02d'%(to+1) if to>=0 else 'chapter-exit' if to==-1 else 'far-latch'
        sc.node('Entrance'+str(n+1),'Node2D','Doorways',script=sc.ext('Script','res://src/campaign/campaign_doorway.gd'),destination_id=json.dumps(target),kind=json.dumps('passage' if idx==0 else 'door' if to>=0 else 'exit' if to==-1 else 'sealed'),direction=-1.0 if d['pos'][0]<r['size'][0]/2 else 1.0,height=170.0,prompt_offset='Vector2(0,-195)',tunnel_texture=sc.ext('Texture2D','res://art/whalebelly/motion_elements/PORTAL.png'),threshold_region='Rect2(0,145,130,14)',texture_bounds='Rect2(0,4,126,155)',tunnel_material=sc.material('res://content/whalebelly/environment/elements/extraction_alpha.gdshader'))
    def library_art(name,path,at,width):
        image=Image.open(GAME/path.removeprefix('res://')).convert('RGBA');b=image.getchannel('A').getbbox();k=width/(b[2]-b[0])
        cleanup=sc.material('res://content/whalebelly/environment/elements/extraction_alpha.gdshader')
        sc.sprite(name,'World',path,[at[0]-(b[0]+b[2])/2*k,at[1]-b[3]*k],k,1,material=cleanup)
    if r.get('camp') and not any(math.dist(r['camp'],door['pos'])<120 for door in r['doors']):
        library_art('CampArt','res://art/whalebelly/motion_elements/PORTAL.png',r['camp'],135)
    if r.get('reward'):
        sc.node('RewardArt','Node2D','World',position=v([r['reward'][0],r['reward'][1]+24]))
        # Existing curved shell bitmap adapts the two defensive relics; ownership,
        # capacities and pickups still use the original stable room reward IDs.
        shell_width={'R1-03':92,'R1-06':68}.get(rid)
        reward_path='res://art/world-kit/nursery-shell-support.png' if shell_width else 'res://art/xumen-layout-v1/memory.png'
        im=Image.open(GAME/reward_path.removeprefix('res://')).convert('RGBA')
        b=im.getchannel('A').point(lambda value:255 if value>=32 else 0).getbbox()
        k=shell_width/(b[2]-b[0]) if shell_width else 95/(b[3]-b[1])
        sc.sprite('Shell' if shell_width else 'Memory','World/RewardArt',reward_path,[-(b[0]+b[2])/2*k,-b[3]*k],k)
    for n,p in enumerate(r['rings']):
        # Actual authored hole center, not canvas center.
        im,a,b=metrics('ring');k=52/(b[2]-b[0])
        sc.sprite('Ring'+str(n),'World/Art','res://art/xumen-layout-v1/ring.png',[p[0]-142*k,p[1]-215.5*k],k,2)
    build_ambience(sc,recipe,GAME,v)
    sc.node('LayoutEnvironment','Node2D','.',script=sc.ext('Script','res://src/world/scenery/layout/layout_environment.gd'))
    sc.node('RoomEcology','Node2D','.',script=sc.ext('Script','res://src/world/scenery/kit/room_ecology.gd'),room_id=json.dumps(rid))
    r['layered_environment']=True;r['camera_zoom']=1.0
    r['reference']='res://art/whalebelly/reference/r1/'+rid+'.png'
    r['layout']['source_recipe']='res://content/whalebelly/layout/recipes.json'
    all_rooms.append(r)
    (GAME/'content/whalebelly/r1'/f'{rid}.tscn').write_text(sc.text(),encoding='utf-8',newline='\n')
(GAME/'content/whalebelly/layout/rooms.json').write_text(json.dumps({'version':1,'rooms':all_rooms},ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Built seven bitmap room scenes and runtime layout table; graph ordering retained.')
