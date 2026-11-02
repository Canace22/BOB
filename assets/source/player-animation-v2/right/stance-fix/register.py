from PIL import Image,ImageDraw
from pathlib import Path
import json,hashlib
P=Path(__file__).resolve().parent
s=.374
items=[('near-stance-mid','mid-late-v02.png',[0,0,887,887]),('far-stance-mid','mid-late-v01.png',[887,0,1774,887])]
records=[]
for name,source,rect in items:
 a=Image.open(P/'source'/source).convert('RGBA');c=a.crop(rect);c.save(P/'source'/f'{name}-crop.png');b=c.resize((round(887*s),round(887*s)),Image.Resampling.LANCZOS);out=Image.new('RGBA',(384,384));out.alpha_composite(b,(19,48));out.save(P/'registered'/f'{name}.png');alpha=out.getchannel('A');bbox=alpha.point(lambda a:255 if a>8 else 0).getbbox();records.append({'name':name,'source':source,'sourceSha256':hashlib.sha256((P/'source'/source).read_bytes()).hexdigest(),'sourceRect':rect,'scale':s,'offset':[19,48],'canvas':[384,384],'pivot':[192,342],'alpha8Bbox':bbox,'sourceHelmetWidthApprox':230,'outputHelmetWidthApprox':86,'sourceLanternWidthApprox':112,'outputLanternWidthApprox':42})
seq=[P.parent/'registered/run-01.png',P/'registered/near-stance-mid.png',P.parent/'registered/run-02.png',P.parent/'registered/run-05.png',P/'registered/far-stance-mid.png',P.parent/'registered/run-06.png']
sheet=Image.new('RGB',(1152,820),(38,43,48));d=ImageDraw.Draw(sheet)
for i,f in enumerate(seq):
 a=Image.open(f);x=(i%3)*384;y=(i//3)*410;sheet.paste(a,(x,y),a);d.text((x+5,y+390),f.stem,fill='white')
sheet.save(P/'review/contact.jpg',quality=92)
(P/'registration.json').write_text(json.dumps({'method':'Same source-group scale fixed from helmet and lamp size, same x/y registration for both new frames. Original gait frames unchanged. No bbox normalization or mirror.','records':records,'selection':'v02 first panel gives a more intermediate near-leg support pose. v02 second panel moved the support too far forward, so v01 second panel is retained. Both preserve correct near/far identity.','timingSuggestion':'Use visible planted toe x, not only requested midpoint. Near interval roughly100ms+60ms; far roughly120ms+100ms at50FPS. Owner should remeasure in assembled fullcycle and adjust stride/durations together.','notDone':['Framecraft export (right agent owns)','Runtime integration','User artistic acceptance']},indent=2)+'\n')
