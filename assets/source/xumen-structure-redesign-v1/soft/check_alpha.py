from PIL import Image
from pathlib import Path
import hashlib, json
root=Path(__file__).parent
refs=[Path('G:/鲸落万物生/outputs/鲸落万物生_V5.2_简明设计文档/images/11_R1-05.png'),Path('G:/鲸落万物生/BOB/game/build/qa/xumen-source-style-v2/visual-R1-05-overview.png')]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
items=[]
for stem in ['tissue-ridge','tissue-vault']:
 p=root/(stem+'.png')
 im=Image.open(p).convert('RGBA'); a=im.getchannel('A'); w,h=im.size
 bounds={str(t):a.point(lambda v:255 if v>=t else 0).getbbox() for t in [1,8,32,240,250]}
 x,y,X,Y=bounds['32']
 r=[round(x+(X-x)*.15),round(y+(Y-y)*.1),round(x+(X-x)*.85),round(y+(Y-y)*.9)]
 vals=list(a.crop(r).getdata())
 canvas_r=[round(w*.15),round(h*.1),round(w*.85),round(h*.9)]
 items.append(dict(id=stem,path=str(p),size=[w,h],sha256=sha(p),alpha_bounds=bounds,padding_percent=[round(100*x/w,3),round(100*y/h,3),round(100*(w-X)/w,3),round(100*(h-Y)/h,3)],core_definition='central 70% width / 80% height of alpha>=32 visible bbox',core_rect=r,core_alpha_extrema=[min(vals),max(vals)],core_pixels_below_240=sum(v<240 for v in vals),core_pixels_below_32=sum(v<32 for v in vals),canvas_center_rect=canvas_r,canvas_center_alpha_extrema=a.crop(canvas_r).getextrema(),pivot='center of visible bbox',review_status='candidate; visual and alpha reviewed; no runtime or user approval'))
report=dict(schema='xumen-structure-redesign-v1.soft.qa.v1',items=items,references=[dict(path=str(p),sha256=sha(p),role='material/style reference' if i==0 else 'negative structure reference; existing placement only') for i,p in enumerate(refs)],limitations=['Generated interiors are near opaque alpha252..254 rather than strictly255. No holes in recorded usable cores.','Do not fit whole padded canvas directly to collider; use opaque-core mapping with uniform scaling.','No engine placement, collision coverage, route or user-art approval has been performed by this asset-only worker.'])
(root/'qa.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
