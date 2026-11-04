"""Register authored transparent ground-ring sprite cells; no procedural artwork.
Requires Pillow, NumPy and OpenCV. Writes one runtime atlas and independent metadata.
Never edits animations.json or game/art.
"""
from pathlib import Path
import hashlib,json
import cv2,numpy as np
from PIL import Image,ImageDraw
BASE=Path(__file__).resolve().parent
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-action36'
SOURCE=BASE/'sprite-sheets/ground_ring-v2.png'
OUT=BASE/'review/pure-effects'
OUT.mkdir(parents=True,exist_ok=True)
SCALE=.8
CELL=(280,112)
PIVOT=(140,64)
FADES=[1,1,1,1,1,.75,.35,.08]
source=Image.open(SOURCE).convert('RGBA')
assert source.size==(2172,724),source.size
frames=[];centers=[];bounds=[]
for i in range(8):
 cell=source.crop((i%4*543,i//4*362,(i%4+1)*543,(i//4+1)*362))
 rgba=np.array(cell);mask=(rgba[:,:,3]>32).astype('uint8')
 n,labels,stats,_=cv2.connectedComponentsWithStats(mask)
 selected=1+np.argmax(stats[1:,4])
 contours,_=cv2.findContours((labels==selected).astype('uint8'),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
 ellipse=cv2.fitEllipse(max(contours,key=cv2.contourArea))
 center=ellipse[0];centers.append([round(x,4) for x in center]);bounds.append(stats[selected,:4].tolist())
 # Remove only nearly invisible isolated export debris; preserve authored RGB.
 rgba[rgba[:,:,3]<=4,3]=0
 cell=Image.fromarray(rgba)
 inverse=(1/SCALE,0,center[0]-PIVOT[0]/SCALE,0,1/SCALE,center[1]-PIVOT[1]/SCALE)
 registered=cell.transform(CELL,Image.Transform.AFFINE,inverse,Image.Resampling.BICUBIC)
 a=np.array(registered);a[:,:,3]=np.rint(a[:,:,3].astype(float)*FADES[i]).astype('uint8')
 frames.append(Image.fromarray(a))
atlas=Image.new('RGBA',(CELL[0]*4,CELL[1]*2))
rects=[]
for i,f in enumerate(frames):
 x=i%4*CELL[0];y=i//4*CELL[1];atlas.paste(f,(x,y));rects.append([x,y,*CELL])
dest=RUNTIME/'ground-ring-fx.png';atlas.save(dest)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
meta={'version':1,'effects':{'ground_ring':{
 'id':'ground_ring','source_kind':'AI-authored transparent 4x2 pure effect sprite sheet',
 'source':str(SOURCE),'source_sha256':sha(SOURCE),'reference_height':160,
 'frame_count':8,'fps':20,'event_frame':0,'loop':False,'space':'world','blend':'normal',
 'texture':'res://art/tide-picker-action36/ground-ring-fx.png','frames':rects,
 'pivot':list(PIVOT),'size':list(atlas.size),'sha256':sha(dest),
 'source_grid':[4,2],'source_cell':[543,362],'source_ellipse_centers':centers,
 'source_main_ring_bounds':bounds,'fixed_scale':SCALE,'maximum_ring_width_reference':240,
 'alpha_factors':FADES,'alpha_debris_cutoff':4,
 'method':'retain source RGB and authored alpha; largest ring component ellipse-center registration; one fixed scale; final three frames alpha fade; normal alpha blend',
 'status':'candidate_pending_composite_review',
 'recommended_instances':{'heavy':{'scale':1.0},'dive':{'scale':1.6},'dark_dive':{'scale':2.1,'tint':'deep teal, set by gameplay configuration'}},
 'known_limits':['Single authored ring design reused at configured scale; gameplay radius and lifetime require live verification.']}}}
(BASE/'pure-effects.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf8')
sheet=Image.new('RGB',(CELL[0]*4,(CELL[1]+24)*4))
for j,color in enumerate(['#122c38','#eee8dd']):
 for i,f in enumerate(frames):
  t=Image.new('RGBA',(CELL[0],CELL[1]+24),color);t.alpha_composite(f)
  ImageDraw.Draw(t).text((8,CELL[1]+5),f'ring {i}, alpha x{FADES[i]}',fill='white' if j==0 else 'black')
  sheet.paste(t.convert('RGB'),(i%4*CELL[0],(i//4+j*2)*(CELL[1]+24)))
sheet.save(OUT/'ground-ring-dark-light.png')
print(json.dumps({'texture':str(dest),'sha256':sha(dest),'size':atlas.size,'centers':centers}))
