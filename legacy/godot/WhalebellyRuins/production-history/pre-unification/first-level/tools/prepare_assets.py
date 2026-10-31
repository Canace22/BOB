from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib,shutil
root=Path(__file__).resolve().parents[1]
src=root/'assets/source'; master=root/'assets/master'; runtime=root/'assets/runtime'
(runtime/'hero').mkdir(parents=True,exist_ok=True)
records=[]
def save(im,name,source,notes):
    im.save(master/name); shutil.copy2(master/name,runtime/name)
    records.append(dict(id=name,source=source,master='assets/master/'+name,runtime='assets/runtime/'+name,size=im.size,alpha=im.mode=='RGBA',notes=notes,sha256=hashlib.sha256((runtime/name).read_bytes()).hexdigest()))
for f in ['background','throat']:
    save(Image.open(src/(f+'.png')).convert('RGB'),f+'.png','assets/source/'+f+'.png','独立背景；不是完整截图。')
atlas=Image.open(src/'hero-atlas-r2.png').convert('RGBA')
boxes=[(0,70,380,520),(385,90,780,525),(775,80,1160,525),(1160,60,1536,520),(0,555,365,980),(365,555,825,980),(825,555,1135,980),(1135,555,1536,980)]
poses=[]
for i,box in enumerate(boxes):
    im=atlas.crop(box)
    # Separate neighboring sprite islands left in uneven atlas gutters; never modify the source.
    a=np.array(im.getchannel('A')); mask=a>80; seen=np.zeros(mask.shape,dtype=bool); components=[]
    for sy,sx in zip(*np.where(mask)):
        if seen[sy,sx]: continue
        stack=[(int(sy),int(sx))];seen[sy,sx]=True;component=[]
        while stack:
            yy,xx=stack.pop();component.append((yy,xx))
            for dy,dx in ((0,1),(0,-1),(1,0),(-1,0)):
                y2,x2=yy+dy,xx+dx
                if 0<=y2<mask.shape[0] and 0<=x2<mask.shape[1] and mask[y2,x2] and not seen[y2,x2]: seen[y2,x2]=True;stack.append((y2,x2))
        components.append(component)
    biggest=max(components,key=len);keep=np.zeros(mask.shape,dtype=bool)
    for yy,xx in biggest: keep[max(0,yy-2):yy+3,max(0,xx-2):xx+3]=True
    a[~keep]=0;im.putalpha(Image.fromarray(a));bb=im.getchannel('A').point(lambda v:255 if v>100 else 0).getbbox(); im=im.crop(bb)
    # Fixed canvas and stable foot baseline. Wider thrust keeps helmet scale; no per-frame arbitrary crop in engine.
    scale=0.64*([1,1.10,1.03,1.02,1.10,1.08,1.00,0.98][i])
    im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(384,288))
    canvas.alpha_composite(im,(round((384-im.width)/2),270-im.height))
    canvas.save(master/('pose-'+str(i)+'.png'));poses.append(canvas)
mapping={'idle':[0],'run':[1,2],'jump':[3],'attack':[4,5,0],'heavy':[4,5,0],'hit':[6],'dash':[7],'heal':[4]}
for state,indices in mapping.items():
    for i,idx in enumerate(indices):
        f='hero/'+state+'_'+str(i)+'.png'; poses[idx].save(runtime/f)
        records.append(dict(id=f,source='assets/source/hero-atlas-r2.png',master='assets/master/pose-'+str(idx)+'.png',runtime='assets/runtime/'+f,size=[384,288],alpha=True,notes='原画关键姿势切片；固定脚底270，状态程序曲线驱动。',sha256=hashlib.sha256((runtime/f).read_bytes()).hexdigest()))
sheet=Image.open(src/'modules.png').convert('RGBA')
boxes={'terrain.png':(45,165,1240,425),'checkpoint.png':(1280,20,1740,390),'crab.png':(20,540,580,875),'boss.png':(650,375,1765,880)}
for name,box in boxes.items():
    im=sheet.crop(box)
    if name=='terrain.png':
        # The bottom-right of the source gutter contains a disconnected boss shell.
        # Flood only the upper platform and retain its soft alpha edge.
        a=np.array(im.getchannel('A'));mask=a>80;seen=np.zeros(mask.shape,dtype=bool)
        ys,xs=np.where(mask[:80]);stack=[(int(ys[0]),int(xs[0]))];seen[stack[0]]=True
        while stack:
            yy,xx=stack.pop()
            for dy,dx in ((0,1),(0,-1),(1,0),(-1,0)):
                y2,x2=yy+dy,xx+dx
                if 0<=y2<mask.shape[0] and 0<=x2<mask.shape[1] and mask[y2,x2] and not seen[y2,x2]: seen[y2,x2]=True;stack.append((y2,x2))
        keep=seen.copy()
        for dy in (-1,0,1):
            for dx in (-1,0,1): keep|=np.roll(np.roll(seen,dy,0),dx,1)
        a[~keep]=0;im.putalpha(Image.fromarray(a))
    if name!='terrain.png':
        bb=im.getchannel('A').point(lambda v:255 if v>80 else 0).getbbox();im=im.crop(bb)
    save(im,name,'assets/source/modules.png','独立透明模块；物理碰撞另建。地形从直顶边切出。')
contact=Image.new('RGB',(1152,600),'#173742')
for i,im in enumerate(poses):
    thumb=im.copy();thumb.thumbnail((270,260));contact.paste(thumb,((i%4)*288,(i//4)*300),thumb)
contact.save(root/'evidence/hero-contact.png')
(root/'docs/production/assets.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'runtime_assets':len(records),'hero_alpha':True}))
