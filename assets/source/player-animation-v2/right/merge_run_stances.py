"""Merge two independently painted stance drawings and preserve measured full-stride timing."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,shutil
P=Path(__file__).resolve().parent
for name in ['near-stance-mid','far-stance-mid']:shutil.copyfile(P/'stance-fix/registered'/f'{name}.png',P/'registered'/f'run-{name}.png')
clips=json.loads((P/'clips-source.json').read_text())
c={'loop':True,'poses':['run-00','run-01','run-near-stance-mid','run-02','run-03','run-04','run-05','run-far-stance-mid','run-06','run-07'],'durations':[120,80,40,20,20,140,100,80,20,20],'stridePixels':86.0}
clips['run']=c;(P/'clips-source.json').write_text(json.dumps(clips,indent=2)+'\n')
stride={'method':'Manual ankle-to-ground x projection through full support, not bbox or only contact-to-mid-support. Approximate point placement ±3 output pixels; refine in gameplay.','canvas':[384,384],'gameScale':.275,'cycleDurationMs':640,'durationsMs':c['durations'],'near':{'frames':[0,1,2,3],'ankleProjectionXApprox':[230,174,137,112],'supportStartMs':0,'supportEndMs':240,'deltaOutputPxApprox':118,'deltaPhase':240/640,'strideWorldPxApprox':118/(240/640)*.275},'far':{'frames':[5,6,7,8],'ankleProjectionXApprox':[238,165,121,82],'supportStartMs':280,'supportEndMs':600,'deltaOutputPxApprox':156,'deltaPhase':320/640,'strideWorldPxApprox':156/(320/640)*.275},'selectedStrideWorldPx':86.0,'stanceSupplement':'stance-fix/README.md','reason':'The 8-pose first draft used only early support intervals and overestimated stride at123.8. Two new drawings divide the later support; complete support measurements agree near86.','limits':['Ankle projection is approximate; toes roll during push-off.','Near/far contact intervals remain asymmetric; do not claim final gameplay foot-lock approval.','Airborne poses impose no ground contact constraint.']}
(P/'review/stride.json').write_text(json.dumps(stride,indent=2)+'\n')
imgs=[Image.open(P/'registered'/f'{pose}.png').convert('RGBA') for pose in c['poses']]
imgs[0].save(P/'review/run.webp',save_all=True,append_images=imgs[1:],duration=c['durations'],loop=0,lossless=True)
sheet=Image.new('RGB',(384*5,410*2),(38,43,48));d=ImageDraw.Draw(sheet)
for i,im in enumerate(imgs):
 x=(i%5)*384;y=(i//5)*410;sheet.paste(im,(x,y),im);d.line((x,y+342,x+384,y+342),fill='#617385');d.text((x+8,y+390),f'run {i} {c["durations"][i]}ms',fill='white')
sheet.save(P/'review/run-contact.jpg',quality=92)
