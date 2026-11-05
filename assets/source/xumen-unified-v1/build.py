"""One world-space editable master, same-source chunks + textured terrain mesh data."""
from pathlib import Path
import json,io,zipfile,hashlib,math
import xml.etree.ElementTree as ET
import numpy as np
import cv2
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[3];S=Path(__file__).resolve().parent;O=R/'assets/runtime/scenes/xumen-unified-v1';O.mkdir(parents=True,exist_ok=True)
def write(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
def crop_alpha(im):
 a=np.array(im.convert('RGBA'));yy,xx=np.where(a[:,:,3]>30)
 return im.crop((int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)))
def save(im,name):im.save(O/(name+'.png'),compress_level=6);return name+'.png'
def seamless(im,axis,margin=50):
 a=np.array(im).astype(float);a=np.moveaxis(a,axis,0)
 for i in range(margin):
  q=(i+.5)/margin;v=(a[i]*(.5+.5*q)+a[-1-i]*(.5-.5*q));u=(a[-1-i]*(.5+.5*q)+a[i]*(.5-.5*q));a[i]=v;a[-1-i]=u
 return Image.fromarray(np.moveaxis(a,0,axis).clip(0,255).astype('uint8'))
def sample(points,x):return float(np.interp(x,[p[0] for p in points],[p[1] for p in points]))
def densify(points,step=20):
 out=[]
 for a,b in zip(points,points[1:]):
  for q in np.linspace(0,1,max(1,math.ceil(math.dist(a,b)/step)),endpoint=False):out.append([a[0]+(b[0]-a[0])*q,a[1]+(b[1]-a[1])*q])
 return out+[points[-1]]
def ribbon(points,depth,taper=False,organic=False):
 p=densify(points);left,right=p[0][0],p[-1][0];bottom=[]
 for x,y in reversed(p):
  f=min(1,(x-left+12)/50,(right-x+12)/50) if taper else 1
  variation=(.82+.16*math.sin(x/151)+.08*math.sin(x/49)) if organic else 1
  bottom.append([x,y+depth*f*variation])
 return p+bottom
def tube(points,width):
 p=densify(points,24);left=[];right=[]
 for i,(x,y) in enumerate(p):
  a=np.array(p[max(0,i-1)]);b=np.array(p[min(len(p)-1,i+1)]);v=b-a;v=v/max(1,np.linalg.norm(v));n=np.array([-v[1],v[0]])*width*.5
  left.append([x+n[0],y+n[1]]);right.append([x-n[0],y-n[1]])
 return left+right[::-1]

data=json.loads((S/'layout.json').read_text(encoding='utf8'));rooms=json.loads((R/'game/art/whalebelly/rooms.json').read_text(encoding='utf8'))
mat=Image.open(S/'originals/bone-material.png').convert('RGBA').resize((512,512),Image.Resampling.LANCZOS)
mat=seamless(seamless(mat,0),1);save(mat,'bone-material')
rims=Image.open(S/'originals/rim-sheet.png').convert('RGBA')
for i,(y0,y1) in enumerate([(100,400),(430,680),(690,950)]):
 im=crop_alpha(rims.crop((0,y0,rims.width,y1)));a=np.array(im);count=(a[:,:,3]>120).sum(axis=1);top=int(np.where(count>im.width*.7)[0][0]);im=im.crop((0,top,im.width,min(top+95,im.height)))
 im=im.resize((1024,68),Image.Resampling.LANCZOS);save(seamless(im,1,64),'rim-'+str(i))
support=Image.open(S/'originals/support-sheet.png').convert('RGBA')
for i in range(3):save(crop_alpha(support.crop((i*support.width//3,0,(i+1)*support.width//3,support.height))),'support-'+str(i))
props=Image.open(S/'originals/prop-sheet.png').convert('RGBA')
# Sheet is free-form packed: explicit selections exclude neighbouring objects.
for name,rect in {'lamp':(150,0,620,335),'ring':(880,0,1440,330),'memory':(200,340,660,635),'coral':(740,330,1450,635),'kelp':(170,640,655,1010),'arch':(690,640,1536,1015)}.items():
 im=props.crop(rect);a=np.array(im);a[:,:,3]=np.where(a[:,:,3]<35,0,a[:,:,3]);save(crop_alpha(Image.fromarray(a)),name)
front=Image.open(S/'originals/front-sheet.png').convert('RGBA')
for i in range(3):
 im=crop_alpha(front.crop((i*front.width//3,0,(i+1)*front.width//3,front.height)));a=np.array(im)
 yy,xx=np.mgrid[:im.height,:im.width];edge=np.minimum.reduce([xx,im.width-1-xx,yy,im.height-1-yy]);fade=np.clip(edge/24,0,1);fade=fade*fade*(3-2*fade)
 a[:,:,3]=(a[:,:,3]*fade).astype('uint8');save(Image.fromarray(a),'front-'+str(i))

# Main road is one authored contour across all four joins; actual bodies stay separate.
surfaces=data['surfaces'];main=[]
for ri in range(5):main.extend(next(s['points'] for s in surfaces if s['room']==ri and s.get('surface')==0))
world=[{'id':'MAIN-JAW-ROAD','points':main,'depth':110,'kind':'main','room':-2}]
for s in surfaces:
 if (s['room'] in range(5) and s.get('surface')==0) or s['id'] in ['E01','E02','E03','E04']:continue
 # Gaps in nursery are retained, no false road across them.
 world.append({**s,'depth':70 if s['room']==4 else 54 if s['kind']=='ledge' else 34})
# Nursery main was only its first island; remove its implicit connection to next islands.
meshes=[]
for i,s in enumerate(world):
 p=s['points'];poly=ribbon(p,s['depth'],True,True)
 meshes.append({'id':s['id']+'-body','polygon':poly,'uv':poly,'texture':'bone-material.png','z':2,'color':[.83,.85,.87,1],'layer':'World'})
 rim=ribbon(p,24 if s['kind']=='main' else 17)
 uv=[[x*1.4,(y-sample(p,x))*2.8] for x,y in rim]
 n=len(rim)//2
 quads=[[j,j+1,2*n-2-j,2*n-1-j] for j in range(n-1)]
 meshes.append({'id':s['id']+'-rim','polygon':rim,'uv':uv,'polygons':quads,'texture':'rim-'+str(0 if s['kind']=='main' else i%3)+'.png','z':3,'color':[1,1,1,1],'layer':'World'})

# Authored non-colliding upper jaw contour, with both vertical routes open.
ceilings=[('outer-palate',[[-640,85],[0,80],[500,35],[950,55],[1400,120],[1770,95]]),('filter-palate',[[2380,-40],[2750,-95],[3100,-110],[3660,-60]]),('tongue-vault',[[4450,30],[4900,-60],[5350,-40],[5780,30]]),('arena-vault',[[6500,10],[7080,-100],[7600,-65],[8100,30]]),('throat-vault',[[8760,10],[9400,60],[10200,130]])]
for name,edge in ceilings:
 p=densify(edge);a,b=p[0][0],p[-1][0]
 poly=[[x,y-270*min(1,(x-a)/190,(b-x)/190)] for x,y in p]+list(reversed(p))
 meshes.append({'id':name,'polygon':poly,'uv':poly,'texture':'bone-material.png','z':-5,'color':[.54,.62,.67,1],'layer':'Middle'})

instances=[]
def instance(id,tex,at,width,z,kind='static'):
 im=Image.open(O/(tex+'.png'));sc=width/im.width
 instances.append({'id':id,'file':tex+'.png','at':at,'scale':sc,'z':z,'layer':'Foreground' if z==12 else 'Middle' if z<0 else 'World','kind':kind})
for i,s in enumerate(world):
 if s['id'] in ['MAIN-JAW-ROAD']:
  for j,x in enumerate([380,1100,1850,2730,3490,4120,4750,5700,6620,7480,8370,8950]):instance('jaw-root-'+str(j),'support-'+str(j%3),[x-140,sample(s['points'],x)+130],280,-9)
 elif s['kind']!='step':
  x=(s['points'][0][0]+s['points'][-1][0])*.5;instance(s['id']+'-buttress','support-'+str(i%3),[x-85,sample(s['points'],x)+20],170,-7)
 else:
  x=(s['points'][0][0]+s['points'][-1][0])*.5;w=145+(i%3)*12;instance(s['id']+'-grown-root','support-'+str(i%3),[x-w*.5+(-14 if i%2 else 12),sample(s['points'],x)+15],w,-7)
for ri,room in enumerate(rooms):
 ox,oy=data['rooms'][ri]['origin']
 for j,ring in enumerate(room.get('rings',[])):instance(room['id']+'-ring-'+str(j),'ring',[ox+ring[0]-22,oy+ring[1]-38],44,4,'ring')
 if len(room.get('reward',[]))==2:
  x,y=room['reward'];instance(room['id']+'-memory','memory',[ox+x-24,oy+y-24],48,4,'memory:'+str(ri))
 if room.get('camp'):
  x,y=room['camp'];floor=sample(room['surfaces'][0],x);li=Image.open(O/'lamp.png');instance(room['id']+'-camp','lamp',[ox+x-29,oy+floor-li.height*58/li.width+2],58,4,'lamp')
for i,s in enumerate(world):
 p=s['points'];width=p[-1][0]-p[0][0]
 if width>250:
  x=p[0][0]+width*.67;y=sample(p,x);instance('flora-'+str(i),'coral',[x-30,y-35],60,4)
  if i%3==0:
   ki=Image.open(O/'kelp.png');kw=62;kh=ki.height*kw/ki.width
   instance('kelp-'+str(i),'kelp',[x-95,y-kh+3],kw,1,'kelp')
for i,x in enumerate([150,1100,1950,3150,4600,6150,7280,8550,9780]):
 p=world[0]['points'];y=sample(p,min(x,9029));instance('front-main-'+str(i),'front-'+str(i%3),[x-160,y+65],520,12)
ai=Image.open(O/'arch.png')
instance('boss-seal','arch',[8134-110,722.847-ai.height*220/ai.width+2],220,4,'gate')
instance('throat-exit','arch',[8654+1515-105,171.847+558-ai.height*210/ai.width+2],210,4)

X,Y,W,H=data['canvas'];layers={name:Image.new('RGBA',(W,H)) for name in ['Far','Middle','World','Foreground']}
far=Image.open(S/'originals/far-water.png').convert('RGBA');ratio=max(W/far.width,H/far.height);far=far.resize((round(far.width*ratio),round(far.height*ratio)),Image.Resampling.LANCZOS);layers['Far'].alpha_composite(far,((W-far.width)//2,(H-far.height)//2))
anatomy=Image.open(S/'originals/middle-anatomy.png').convert('RGBA');ratio=W/anatomy.width
anatomy=anatomy.resize((W,round(anatomy.height*ratio)),Image.Resampling.LANCZOS)
aa=np.array(anatomy);yy,xx=np.mgrid[:anatomy.height,:anatomy.width];detail=np.array(mat)
grain=detail[(yy+180)%mat.height,xx%mat.width,:3]
aa[:,:,:3]=((aa[:,:,:3]*.7+grain*.3)*np.array([.48,.58,.66])).astype('uint8')
aa[:,:,3]=(aa[:,:,3]*.62).astype('uint8');anatomy=Image.fromarray(aa)
layers['Middle'].alpha_composite(anatomy,(0,-180))
middle_tiles=layers['Middle'].copy()
def paint_mesh(layer,m):
 poly=np.array(m['polygon']);lo=np.floor(poly.min(axis=0)).astype(int);hi=np.ceil(poly.max(axis=0)).astype(int)+1;w,h=hi-lo
 yy,xx=np.mgrid[:h,:w];wx=xx+lo[0];wy=yy+lo[1];tx=Image.open(O/m['texture']).convert('RGBA');a=np.array(tx)
 if m['id'].endswith('-rim'):
  surface=next(s for s in world if m['id']==s['id']+'-rim');lip=np.interp(wx,[p[0] for p in surface['points']],[p[1] for p in surface['points']]);mx=(wx*1.4%tx.width).astype(np.float32);my=np.clip((wy-lip)*2.8,0,tx.height-1).astype(np.float32)
 else:mx=(wx%tx.width).astype(np.float32);my=(wy%tx.height).astype(np.float32)
 pixels=cv2.remap(a,mx,my,cv2.INTER_LINEAR,borderMode=cv2.BORDER_WRAP);mask=np.zeros((h,w),np.uint8);cv2.fillPoly(mask,[np.round(poly-lo).astype('int32')],255)
 for c,v in enumerate(m['color']):pixels[:,:,c]=(pixels[:,:,c]*v).astype('uint8')
 pixels[:,:,3]=(pixels[:,:,3].astype(float)*mask/255).astype('uint8');layer.alpha_composite(Image.fromarray(pixels),(int(lo[0]-X),int(lo[1]-Y)))
for m in sorted(meshes,key=lambda m:m['z']):paint_mesh(layers[m['layer']],m)
for item in sorted(instances,key=lambda x:x['z']):
 im=Image.open(O/item['file']).convert('RGBA');im=im.resize((round(im.width*item['scale']),round(im.height*item['scale'])),Image.Resampling.LANCZOS)
 layers[item['layer']].alpha_composite(im,(round(item['at'][0]-X),round(item['at'][1]-Y)))
tiles=[]
for name,layer in layers.items():
 if name=='Middle':layer=middle_tiles
 if name=='World':continue
 for yy in range(0,H,1024):
  for xx in range(0,W,1024):
   rect=(xx,yy,min(W,xx+1024),min(H,yy+1024));piece=layer.crop(rect)
   if piece.getchannel('A').getextrema()[1]==0:continue
   # Dynamic/sprite layer instances are placed independently at runtime.
   if name not in ['Far','Middle']:continue
   file=save(piece,name+'-'+str(xx//1024)+'-'+str(yy//1024));tiles.append({'file':file,'at':[X+rect[0],Y+rect[1]],'layer':name,'z':-45 if name=='Far' else -14})
root=ET.Element('image',w=str(W),h=str(H),name='Xumen unified world master',version='0.0.3');stack=ET.SubElement(root,'stack')
with zipfile.ZipFile(S/'masters/unified-world.ora','w',compression=zipfile.ZIP_DEFLATED) as z:
 def put(name,b):zi=zipfile.ZipInfo(name,(2026,11,5,0,0,0));zi.compress_type=zipfile.ZIP_DEFLATED;z.writestr(zi,b)
 put('mimetype','image/openraster');merged=Image.new('RGBA',(W,H))
 for name,im in layers.items():
  merged.alpha_composite(im);b=io.BytesIO();im.save(b,format='PNG');put('data/'+name+'.png',b.getvalue())
 for name in reversed(list(layers)):ET.SubElement(stack,'layer',name=name,src='data/'+name+'.png',x='0',y='0',opacity='1.0',visibility='visible',**{'composite-op':'svg:src-over'})
 put('stack.xml',ET.tostring(root));b=io.BytesIO();merged.save(b,format='PNG');put('mergedimage.png',b.getvalue())
 merged.thumbnail((2300,850));merged.save(S/'review/world-master.png')
fronds=[]
for name,edge in ceilings[:2]:
 for wx in np.arange(edge[0][0]+260,edge[-1][0]-100,245):
  sc=.82+.08*(len(fronds)%3);root_y=sample(edge,wx)
  fronds.append({'id':'BALEEN-'+str(len(fronds)),'at':[float(wx-192*sc),root_y-145*sc],'scale':sc,'phase':len(fronds)*7,'root':[float(wx),root_y],'attachment':name})
write(O/'scene.json',{'canvas':data['canvas'],'meshes':meshes,'instances':instances,'tiles':tiles,'fronds':fronds,'rooms':data['rooms'],'source_room_hash':data['source_room_hash'],'method':'world-space unified master + painted texture mesh, independent rims/supports','old_static_images':False})
write(S/'masters/source-hashes.json',{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (S/'originals').glob('*.png')})
mp=R/'game/art/manifest.json';manifest=json.loads(mp.read_text(encoding='utf8'))
manifest['entries']=[e for e in manifest['entries'] if not e['dest'].startswith('xumen-unified/')]
used={t['file'] for t in tiles}|{i['file'] for i in instances}|{m['texture'] for m in meshes}
for p in O.iterdir():
 if p.name in used or p.name=='scene.json':manifest['entries'].append({'src':p.relative_to(R).as_posix(),'dest':'xumen-unified/'+p.name})
write(mp,manifest)
cp=R/'assets/catalog.json';cat=json.loads(cp.read_text(encoding='utf8'));cat['assets']=[a for a in cat['assets'] if not a['id'].startswith('xumen-unified-')]
for p in O.glob('*.png'):
 if p.name not in used:continue
 im=Image.open(p);cat['assets'].append({'id':'xumen-unified-'+p.stem,'name':p.stem+' 统一母版资产','kind':'environment','region':'R1','target':'2d','status':'candidate','file':p.relative_to(R).as_posix(),'width':im.width,'height':im.height,'integrationStatus':'awaiting-runtime-verification','source':{'method':'built-in imagegen; same-source world master and texture kit','model':'not exposed','references':['assets/source/xumen-unified-v1/originals/world-composition.png']},'metadata':'assets/source/xumen-unified-v1/elements.json'})
cat['revision']+=1;write(cp,cat)
print('UNIFIED_EXPORTED',len(meshes),'meshes',len(instances),'instances',len(tiles),'same-source tiles')
