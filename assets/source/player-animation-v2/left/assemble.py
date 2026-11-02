from PIL import Image, ImageDraw
from pathlib import Path
import json, shutil
P=Path(__file__).resolve().parent
OUT=P/'registered';OUT.mkdir(exist_ok=True)
records=[]
def place(name,source,scale,anchor,target):
 a=Image.open(P/source).convert('RGBA');b=a.resize((round(a.width*scale),round(a.height*scale)),Image.Resampling.LANCZOS)
 offset=tuple(round(target[i]-anchor[i]*scale) for i in range(2));o=Image.new('RGBA',(384,384));o.alpha_composite(b,offset);o.save(OUT/f'{name}.png')
 records.append(dict(name=name,source=source,sourceSize=list(a.size),scale=scale,sourceAnchor=anchor,targetAnchor=target,offset=offset,canvas=[384,384],pivot=[192,342]))
 return o
landscale=240/587
for i,x in enumerate([521,472,449]):place(f'land-{i}',f'jump/source/landing-panel-{i+1}.png',landscale,[x,664],[224,342])
# The source was regenerated at 1254 px from a 724 px reference; use that shared scale, no bbox fit.
place('idle-1','idle/source/breathe-v01.png',landscale*724/1254,[779,1151],[224,342])
shutil.copyfile(OUT/'land-2.png',OUT/'idle-0.png')
# Airborne batch common helmet/neck scale; source body's movement is kept relative to a fixed root.
for i,x in enumerate([435,365,280]):place(f'air-{i}',f'jump/source/air-panel-{i+1}.png',0.338,[x,797],[192,342])
place('air-2','jump/source/fall-ready-v02.png',0.338*627/1086,[485,1274],[192,342])
# Four hand-drawn key poses plus two new midstances. Stable helmet chord sets source-group scale.
run=[('key-1.png',.355,[375,584]),('mid-1.png',.25,[540,854]),('key-2.png',.355,[380,595]),('key-3.png',.355,[360,578]),('mid-2.png',.25,[475,854]),('key-4.png',.355,[380,595])]
for i,(file,scale,anchor) in enumerate(run):place(f'run-{i}',f'run/source/{file}',scale,anchor,[192,342])
(P/'review/registration.json').write_text(json.dumps({'method':'Manual anatomical pelvis x / named stance sole y; common scale per source-resolution group; no per-frame bbox normalization. Landing registered to the same near ankle and contact baseline.','records':records},indent=2)+'\n')
clips={
'idle': {'loop':True,'poses':['idle-0','idle-1'],'durations':[500,500]},
'run': {'loop':True,'poses':[f'run-{i}' for i in range(6)],'durations':[60,60,20,80,40,20],'stridePixels':61.7},
'jump_rise':{'loop':False,'poses':['air-0','air-1'],'durations':[80,100]},
'jump_fall':{'loop':False,'poses':['air-1','air-2'],'durations':[80,100]},
'land':{'loop':False,'poses':['land-1','land-0','land-1','land-2'],'durations':[20,40,40,40]}}
(P/'clips-source.json').write_text(json.dumps(clips,indent=2)+'\n')
for clip,c in clips.items():
 imgs=[Image.open(OUT/f'{pose}.png').convert('RGBA') for pose in c['poses']]
 imgs[0].save(P/'review'/f'{clip}.webp',save_all=True,append_images=imgs[1:],duration=c['durations'],loop=0 if c['loop'] else 1,lossless=True)
 sheet=Image.new('RGB',(384*len(imgs),410),(38,43,48));d=ImageDraw.Draw(sheet)
 for i,im in enumerate(imgs):sheet.paste(im,(i*384,0),im);d.text((384*i+8,390),f'{clip} {i}: {c["durations"][i]}ms',fill='white')
 sheet.save(P/'review'/f'{clip}-contact.jpg',quality=92)
# Remaining clips: each source pair shares one scale; manual near-ankle/sole registration.
combat={
 'attack':(.325,[[714,803],[694,803]]),
 'attack2':(.31,[[764,846],[630,846]]),
 'heavy':(.318,[[695,858],[695,858]]),
 'hurt':(.312,[[695,822],[514,817]]),
 'heal':(.318,[[726,823],[584,823]])}
for clip,(scale,points) in combat.items():
 for i,anchor in enumerate(points):place(f'{clip}-{i}',f'{clip}/source/pose-{i}.png',scale,anchor,[226 if clip=='attack' else 224,342])
place('dash-0','dash/source/pose-0.png',.308,[580,840],[192,342])
place('dash-1','dash/source/recovery-v02.png',landscale*724/1254,[844,1115],[224,342])
clips.update({
'attack':{'loop':False,'poses':['attack-0','attack-1','attack-0','idle-0'],'durations':[120,80,100,100],'activeWindowMs':[120,200]},
'attack2':{'loop':False,'poses':['attack2-0','attack2-1','attack2-0','idle-0'],'durations':[160,80,120,140],'activeWindowMs':[160,240]},
'heavy':{'loop':False,'poses':['heavy-0','heavy-1','land-1','idle-0'],'durations':[300,120,200,200],'activeWindowMs':[300,420]},
'hurt':{'loop':False,'poses':['hurt-0','hurt-1','idle-0'],'durations':[80,100,100]},
'dash':{'loop':False,'poses':['land-0','dash-0','dash-1'],'durations':[40,120,60]},
'heal':{'loop':False,'poses':['heal-0','heal-1','heal-0','idle-0'],'durations':[200,240,240,120]}})
(P/'clips-source.json').write_text(json.dumps(clips,indent=2)+'\n')
(P/'review/registration.json').write_text(json.dumps({'method':'Manual anatomical pelvis x / named stance sole y; common scale per source-resolution group; no per-frame bbox normalization. Landing registered to the same near ankle and contact baseline.','records':records},indent=2)+'\n')
for clip,c in list(clips.items())[5:]:
 imgs=[Image.open(OUT/f'{pose}.png').convert('RGBA') for pose in c['poses']]
 imgs[0].save(P/'review'/f'{clip}.webp',save_all=True,append_images=imgs[1:],duration=c['durations'],loop=1,lossless=True)
 sheet=Image.new('RGB',(384*len(imgs),410),(38,43,48));d=ImageDraw.Draw(sheet)
 for i,im in enumerate(imgs):sheet.paste(im,(i*384,0),im);d.text((384*i+8,390),f'{clip} {i}: {c["durations"][i]}ms',fill='white')
 sheet.save(P/'review'/f'{clip}-contact.jpg',quality=92)
