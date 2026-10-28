from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib
root=Path(__file__).resolve().parents[1]
src=root/'assets/source/v02/environment-sheet.png'
sheet=Image.open(src).convert('RGBA')
boxes={'plant':(30,120,500,540),'lamp':(540,0,1000,530),'gate':(1000,0,1536,540),'water':(0,600,540,940),'baleen':(600,540,980,1024),'cargo':(1025,550,1515,1000)}
records=[];contact=Image.new('RGB',(1200,800),'#18333e');draw=ImageDraw.Draw(contact)
for i,(name,box) in enumerate(boxes.items()):
    im=sheet.crop(box);a=np.array(im.getchannel('A'));a[a<70]=0;im.putalpha(Image.fromarray(a))
    bb=im.getchannel('A').getbbox();im=im.crop(bb)
    anchor=[im.width/2,0] if name in ['lamp','baleen'] else [im.width/2,im.height]
    if name=='water':anchor=[0,im.height/2]
    for folder in ['master','runtime']:im.save(root/f'assets/{folder}/v02/{name}.png')
    p=root/f'assets/runtime/v02/{name}.png'
    records.append({'id':name,'source':str(src.relative_to(root)),'crop':box,'master':f'assets/master/v02/{name}.png','runtime':str(p.relative_to(root)),'size':im.size,'anchor':anchor,'alpha_zero':float(np.mean(np.array(im.getchannel('A'))==0)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'notes':'Independent alpha component; low-opacity atlas halo below70 removed; runtime size controlled in Godot.'})
    thumb=im.copy();thumb.thumbnail((350,335));contact.paste(thumb,(i%3*400+25,i//3*400+35),thumb);draw.text((i%3*400+25,i//3*400+8),name,fill='white')
contact.save(root/'evidence/v02/asset-contact.png')
(root/'docs/v02/asset-delivery.json').write_text(json.dumps({'generated':records,'reused':'v0.1 assets/runtime and original provenance retained','engine_status':'awaiting sample validation'},ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps([(r['id'],r['size'],r['alpha_zero']) for r in records]))
