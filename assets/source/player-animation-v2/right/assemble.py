"""Mechanical crop/register of generated poses; never paints or changes anatomy/alpha."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
P=Path(__file__).resolve().parent
O=P/'registered';O.mkdir(exist_ok=True)
records=[]
def place(name,source,box,scale,anchor,target,phase):
 a=Image.open(P/'raw'/source).convert('RGBA').crop(box)
 b=a.resize((round(a.width*scale),round(a.height*scale)),Image.Resampling.LANCZOS)
 offset=[round(target[i]-anchor[i]*scale) for i in range(2)]
 o=Image.new('RGBA',(384,384));o.alpha_composite(b,offset);o.save(O/f'{name}.png')
 records.append(dict(name=name,source=f'raw/{source}',crop=box,sourceScale=scale,sourceAnchor=anchor,targetAnchor=target,offset=offset,phase=phase))
 return o
idleboxes=[(0,0,645,609),(645,0,1290,609),(0,609,645,1219),(645,609,1290,1219)]
for i,(box,anklex,sole) in enumerate(zip(idleboxes,[250,235,250,235],[594,594,573,573])):
 place(f'idle-{i:02}','idle-v01.png',box,240/563,[anklex,sole],[167,342],'grounded breathing; near ankle and sole registered')
A=[(0,0,627,627),(627,0,1254,627),(0,627,627,1254),(627,627,1254,1254)]
B=[(0,0,745,528),(745,0,1490,528),(0,528,745,1055),(745,528,1490,1055)]
run=[('run-near-half-v04.png',B[0],[420,496],'near contact'),('run-near-half-v04.png',B[1],[380,496],'near support'),('run-half-a-v01.png',A[2],[315,562],'near push, far knee forward'),('run-half-a-v01.png',A[3],[310,562],'flight, far leg reaches'),('run-half-a-v01.png',A[0],[320,585],'far contact'),('run-half-a-v01.png',A[1],[324,588],'far support'),('run-near-half-v04.png',B[2],[420,490],'far push, near knee forward'),('run-near-half-v04.png',B[3],[384,490],'flight, near leg reaches')]
for i,(src,box,anchor,phase) in enumerate(run):place(f'run-{i:02}',src,box,.48,anchor,[192,342],phase)
jumpboxes=[(0,0,690,636),(690,0,1290,636),(0,640,690,1219),(690,640,1290,1219)]
for i,(box,hip) in enumerate(zip(jumpboxes,[[340,440],[290,467],[285,370],[270,370]])):
 place(f'air-{i:02}','jump-air-v01.png',box,.4,hip,[192,266],['rise extended','rise tuck','fall opens','fall feet ready'][i])
for i,x in enumerate([275,245,245]):
 place(f'land-{i:02}','land-v01.png',(i*724,0,(i+1)*724,724),240/624,[x,663],[167,342],['first contact','knee compression','standing recovery'][i])
clips={
'idle':{'loop':True,'poses':[f'idle-{i:02}' for i in range(4)],'durations':[200,200,200,200]},
'run':{'loop':True,'poses':[f'run-{i:02}' for i in range(8)],'durations':[80,60,80,80,100,60,80,100],'stridePixels':123.8},
'jump_rise':{'loop':False,'poses':['air-00','air-01'],'durations':[80,100]},
'jump_fall':{'loop':False,'poses':['air-02','air-03'],'durations':[80,100]},
'land':{'loop':False,'poses':['land-00','land-01','land-02'],'durations':[40,40,60]}}
(P/'clips-source.json').write_text(json.dumps(clips,indent=2)+'\n')
(P/'review/registration.json').write_text(json.dumps({'method':'Manual anatomical anchors. Shared scale for each generated source group based on rigid helmet and lamp size, not per-frame bbox. Two complete hand-drawn gait halves reordered by actual limb phase. Landing near ankle and sole fixed; far-foot residual placement is visible in contact sheet.','canvas':[384,384],'pivot':[192,342],'records':records},indent=2)+'\n')
(P/'review/stride.json').write_text(json.dumps({'method':'Same support ankle displacement / cycle phase difference × game scale. Distances measured after crop registration.','cycleDurationMs':640,'gameScale':.275,'near':{'frames':[0,1],'sourceAnkleX':[500,343],'sourceHipX':[420,380],'sourceScale':.48,'deltaOutputPx':56.16,'deltaPhase':80/640,'strideWorldPx':56.16/(80/640)*.275},'far':{'frames':[4,5],'sourceAnkleX':[415,268],'sourceHipX':[320,324],'sourceScale':.48,'deltaOutputPx':72.48,'deltaPhase':100/640,'strideWorldPx':72.48/(100/640)*.275},'selectedStrideWorldPx':123.8,'limitation':'Initial stride calibration from two stance intervals, requires real in-game foot-slip review; airborne frames impose no ground constraint.'},indent=2)+'\n')
for clip,c in clips.items():
 imgs=[Image.open(O/f'{pose}.png').convert('RGBA') for pose in c['poses']]
 imgs[0].save(P/'review'/f'{clip}.webp',save_all=True,append_images=imgs[1:],duration=c['durations'],loop=0 if c['loop'] else 1,lossless=True)
 sheet=Image.new('RGB',(384*len(imgs),410),(38,43,48));d=ImageDraw.Draw(sheet)
 for i,im in enumerate(imgs):
  sheet.paste(im,(i*384,0),im);d.line((i*384,342,(i+1)*384,342),fill='#617385');d.text((384*i+8,390),f'{clip} {i}: {c["durations"][i]}ms',fill='white')
 sheet.save(P/'review'/f'{clip}-contact.jpg',quality=92)
