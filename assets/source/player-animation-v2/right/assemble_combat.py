"""Register the three separately drawn combat clips, preserving common source-group scales."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,sys
P=Path(__file__).resolve().parent;O=P/'registered';O.mkdir(exist_ok=True)
clips=json.loads((P/'clips-source.json').read_text());records=[]
def place(name,source,box,scale,anchor,target=[167,342]):
 a=Image.open(P/source).convert('RGBA');a=a.crop(box) if box else a
 b=a.resize((round(a.width*scale),round(a.height*scale)),Image.Resampling.LANCZOS)
 offset=[round(target[i]-anchor[i]*scale) for i in range(2)]
 o=Image.new('RGBA',(384,384));o.alpha_composite(b,offset);o.save(O/f'{name}.png')
 records.append(dict(name=name,source=source,crop=box,scale=scale,sourceAnchor=anchor,targetAnchor=target,offset=offset));return o
A=[(0,0,630,627),(630,0,1254,627),(0,627,675,1254),(675,627,1254,1254)]
for i,(box,anchor) in enumerate(zip(A,[[185,573],[85,576],[160,510],[160,517]])):place(f'attack-{i:02}','raw/attack-v01.png',box,.52,anchor,[115 if i<3 else 167,342])
B=[(0,0,635,595),(635,0,1254,595),(0,595,635,1254),(635,595,1254,1254)]
for i,(box,anchor) in enumerate(zip(B,[[220,577],[135,583],[300,608],[200,605]])):place(f'attack2-{i:02}','raw/attack2-v01.png',box,.52,anchor,[140 if i<3 else 167,342])
clips.update({'attack':{'loop':False,'poses':[f'attack-{i:02}' for i in range(4)],'durations':[120,80,80,120],'activeWindowMs':[120,200]},'attack2':{'loop':False,'poses':[f'attack2-{i:02}' for i in range(4)],'durations':[160,80,100,160],'activeWindowMs':[160,240]}})
if all((P/f'heavy/matting/pose-{i:02}.png').exists() for i in range(4)):
 for i,anchor in enumerate([[365,558],[180,551],[385,421],[200,423]]):place(f'heavy-{i:02}',f'heavy/matting/pose-{i:02}.png',None,.60,anchor,[115 if i<3 else 167,342])
 clips['heavy']={'loop':False,'poses':[f'heavy-{i:02}' for i in range(4)],'durations':[300,120,180,220],'activeWindowMs':[300,420]}
(P/'clips-source.json').write_text(json.dumps(clips,indent=2)+'\n')
(P/'review/combat-registration.json').write_text(json.dumps({'method':'Mechanical crop and one shared group scale, grounded near ankle/sole registration; no nonuniform scale or pixel paint.','records':records},indent=2)+'\n')
for clip in ['attack','attack2','heavy']:
 if clip not in clips:continue
 c=clips[clip];imgs=[Image.open(O/f'{pose}.png').convert('RGBA') for pose in c['poses']]
 imgs[0].save(P/'review'/f'{clip}.webp',save_all=True,append_images=imgs[1:],duration=c['durations'],loop=1,lossless=True)
 sheet=Image.new('RGB',(384*len(imgs),410),(38,43,48));d=ImageDraw.Draw(sheet)
 for i,im in enumerate(imgs):sheet.paste(im,(i*384,0),im);d.line((i*384,342,(i+1)*384,342),fill='#617385');d.text((i*384+8,390),f'{clip} {i} {c["durations"][i]}ms',fill='white')
 sheet.save(P/'review'/f'{clip}-contact.jpg',quality=92)
