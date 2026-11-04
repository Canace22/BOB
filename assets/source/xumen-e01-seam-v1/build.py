from PIL import Image,ImageDraw,ImageFilter
from pathlib import Path
import numpy as np, json, zipfile, io, hashlib
ROOT=Path(__file__).resolve().parents[3]
S=ROOT/'assets/source/xumen-e01-seam-v1'; O=ROOT/'assets/runtime/scenes/xumen-e01-seam-v1'
O.mkdir(parents=True,exist_ok=True)
def save(im,name):
 im.save(O/(name+'.png'),compress_level=9)
def fade(im,left=0,right=0):
 a=np.array(im.convert('RGBA')).copy();w=a.shape[1]
 f=np.ones(w)
 if left:f*=np.clip(np.arange(w)/left,0,1)
 if right:f*=np.clip((w-1-np.arange(w))/right,0,1)
 a[:,:,3]=(a[:,:,3]*f[None,:]).astype('uint8');return Image.fromarray(a)
# Equal pixel scale only, crop rather than warp. Canvas records origin, never bbox inference.
depth=Image.open(S/'originals/depth.png').convert('RGBA').resize((2164,1535),Image.Resampling.LANCZOS)
depth=fade(depth,330,330); save(depth,'depth')
ground=Image.open(S/'originals/ground.png').convert('RGBA').crop((0,364,2172,724))
ground=ground.resize((1600,265),Image.Resampling.LANCZOS)
# Outer tails use authored road mask, not colour key. Core upper edge remains original painted lip.
rooms=json.loads((ROOT/'game/art/whalebelly/rooms.json').read_text(encoding='utf8'));rooms=rooms if isinstance(rooms,list) else rooms['rooms']
topA=rooms[0]['surfaces'][0];topB=rooms[1]['surfaces'][0]
def sample(points,x):
 for a,b in zip(points,points[1:]):
  if a[0]<=x<=b[0]:return a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0])
 return points[0][1] if x<points[0][0] else points[-1][1]
# Preserve the thickness and pixels of the new bone painting; translate each vertical
# cross-section onto the authored contour (no rescale of old room artwork).
source=np.array(ground);out=np.zeros((430,1600,4),dtype=np.uint8)
profile=[]
for x in range(1600):
 world=x+1100;floor=sample(topA,world) if world<1645 else (sample(topB,world-2183)-86.153 if world>2209 else 631.847)
 offset=round(floor-531.847);profile.append(offset)
 out[offset:offset+265,x]=source[:,x]
ground=fade(Image.fromarray(out),190,230);save(ground,'ground')
(S/'masters/ground-contour.json').write_text(json.dumps({'origin':[1100,531.847],'top_per_column':profile,'method':'new artwork contour-conformed by column translation; local thickness unchanged'}),encoding='utf8')
arch=Image.open(S/'originals/arch.png').convert('RGBA').resize((1076,717),Image.Resampling.LANCZOS)
save(fade(arch,100,130),'arch')
# Joint ownership mask suppresses legacy pixels only in agreed repaint volume. Upper hub platforms retain ownership.
for rid,w,h,ox,oy in [('R1-01',1671,941,0,0),('R1-02',1672,941,2183,-86.153)]:
 yy,xx=np.mgrid[:h,:w];wx=xx+ox;wy=yy+oy
 f=np.clip((wx-1100)/190,0,1)*np.clip((2700-wx)/230,0,1)
 if rid=='R1-02':
  # Preserve all existing upper platforms, anchor gate route and supporting outer wall; their exact old art is outside this repaint.
  protect=Image.new('L',(w,h));d=ImageDraw.Draw(protect)
  d.polygon([(0,0),(385,0),(385,565),(220,605),(185,750),(0,750)],fill=255)
  keep=np.array(protect.filter(ImageFilter.GaussianBlur(5)))/255.;f*=1-keep
 keep=(255*(1-f)).astype('uint8');Image.fromarray(keep).save(S/'masters'/(rid+'-ownership-mask.png'));save(Image.fromarray(keep).convert('RGBA'),rid+'-ownership')
# Original hub slab: replace the left support with a clean generative extraction,
# then mask the adjacent hill's baked-water cap spatially.
im=Image.open(ROOT/'game/art/r1-chapter-scenes/R1-02/World.png').convert('RGBA')
# Clean regenerated cutout replaces old left support; untouched originals remain outside its ownership.
# Whole cutout uniformly scaled, local vertical alignment shifts follow original three surfaces.
cut=Image.open(S/'originals/hub-platform-extraction.png').convert('RGBA')
cut=cut.resize((425,771),Image.Resampling.LANCZOS)
# Per-platform registration onto the ORIGINAL sloping top. New art translated
# within each band, including root thickness; collision stays byte-identical.
old_cut=np.array(cut);new_cut=np.zeros_like(old_cut)
# Continuous inverse-coordinate registration avoids gaps at band boundaries.
for x in range(425):
 src=[0,sample([(0,184),(140,184),(175,184),(215,184),(265,186),(315,188),(355,188),(424,188)],x),sample([(0,350),(175,338),(215,336),(265,335),(315,334),(355,338),(424,338)],x),sample([(0,512),(175,493),(215,493),(265,492),(315,493),(355,496),(424,496)],x),734,770]
 dst=[0,sample([(0,200),(142,200),(226,202),(311,209),(373,219),(424,219)],x),sample([(0,359),(178,359),(248,355),(316,356),(374,363),(424,363)],x),sample([(0,514),(176,514),(246,511),(316,514),(374,518),(424,518)],x),734,770]
 lookup=np.interp(np.arange(771),dst,src)
 for c in range(4):new_cut[:,x,c]=np.interp(lookup,np.arange(771),old_cut[:,x,c]).astype('uint8')
cut=Image.fromarray(new_cut)
a=np.array(im);a[:,:430,3]=0
# Explicit contour of adjacent original hill: preserve sponges/ground; exclude
# its baked blue water cap. Pixel mask is editable and spatial, never chroma key.
m=Image.new('L',im.size,255);d=ImageDraw.Draw(m)
d.polygon([(430,0),(1000,0),(1000,610),(965,618),(945,628),(915,635),(890,639),(870,646),(850,656),(830,669),(810,680),(790,684),(760,686),(730,684),(710,680),(690,675),(670,661),(650,659),(630,651),(615,636),(605,628),(592,632),(585,647),(565,654),(545,655),(525,655),(500,662),(480,674),(460,678),(430,686)],fill=0)
m=m.filter(ImageFilter.GaussianBlur(.7));m.save(S/'masters/hub-hill-mask.png')
a[:,:,3]=(a[:,:,3].astype(float)*np.array(m)/255).astype('uint8')
im=Image.fromarray(a);im.alpha_composite(cut,(0,10))
save(im,'hub-world-clean')
front=Image.open(S/'originals/foreground.png').convert('RGBA')
front=front.resize((2164,round(front.height*2164/front.width)),Image.Resampling.LANCZOS)
save(front,'foreground')
# Middle ceiling/left-wall only, traced edge to exclude baked-water wedges.
im=Image.open(ROOT/'game/art/r1-chapter-scenes/R1-02/Middle.png').convert('RGBA')
m=Image.new('L',im.size);d=ImageDraw.Draw(m)
d.polygon([(0,0),(im.width,0),(im.width,120),(470,120),(390,125),(340,132),(305,144),(275,161),(250,178),(223,200),(203,227),(181,260),(163,298),(148,336),(130,378),(102,408),(72,427),(0,430)],fill=255)
d.rectangle((700,0,im.width,im.height),fill=255)
m=m.filter(ImageFilter.GaussianBlur(.7));m.save(S/'masters/hub-middle-mask.png')
a=np.array(im);a[:,:,3]=(a[:,:,3].astype(float)*np.array(m)/255).astype('uint8');save(Image.fromarray(a),'hub-middle-clean')
# OpenRaster layered editable full world canvas, exact placements retained in JSON + layer offsets.
placements=[('depth',0,0),('arch',544,244),('ground',255,796)]
import xml.etree.ElementTree as ET
root=ET.Element('image',w='2164',h='1536',name='E01 joint world master',version='0.0.3');stack=ET.SubElement(root,'stack')
merged=Image.new('RGBA',(2164,1536))
with zipfile.ZipFile(S/'masters/E01-joint.ora','w') as z:
 z.writestr('mimetype','image/openraster')
 for n,x,y in placements:
  im=Image.open(O/(n+'.png'));merged.alpha_composite(im,(x,y));buf=io.BytesIO();im.save(buf,format='PNG');z.writestr('data/'+n+'.png',buf.getvalue())
 for n,x,y in reversed(placements):ET.SubElement(stack,'layer',name=n,src='data/'+n+'.png',x=str(x),y=str(y),opacity='1.0',visibility='visible',**{'composite-op':'svg:src-over'})
 z.writestr('stack.xml',ET.tostring(root));buf=io.BytesIO();merged.save(buf,format='PNG');z.writestr('mergedimage.png',buf.getvalue())
merged.thumbnail((1082,768));merged.save(S/'review/joint-master.png')
meta={'worldCanvas':[845,-264.153,2164,1536],'scale':1,'groundOrigin':[1100,531.847],'archOrigin':[1389,-20.153],'core':[1645,631.847,564,38],'originalCollisionsChanged':False,'generation':'built-in imagegen; 5 actual generated bitmaps; clean ownership masks and equal-scale exports','sources':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (S/'originals').glob('*.png')},'exports':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.png')}}
(S/'masters/placement.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf8')
