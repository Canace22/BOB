from pathlib import Path
import json
from PIL import Image
R=Path(__file__).resolve().parents[3]; S=Path(__file__).resolve().parent
O=R/'assets/runtime/scenes/xumen-transitions-v2'
def write(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
p=R/'game/art/manifest.json'; manifest=json.loads(p.read_text(encoding='utf8'))
for file in O.glob('*.png'):
    dest='xumen-transitions/'+file.name
    manifest['entries']=[x for x in manifest['entries'] if x['dest']!=dest]
    manifest['entries'].append({'src':file.relative_to(R).as_posix(),'dest':dest})
write(p,manifest)
p=R/'assets/catalog.json'; catalog=json.loads(p.read_text(encoding='utf8'))
for file in O.glob('*.png'):
    if 'owner' in file.name:continue
    id='xumen-transitions-'+file.stem
    catalog['assets']=[x for x in catalog['assets'] if x['id']!=id]
    im=Image.open(file)
    catalog['assets'].append({'id':id,'name':file.stem+' 联合过渡','kind':'environment','region':'R1','status':'candidate','target':'2d','file':file.relative_to(R).as_posix(),'width':im.width,'height':im.height,'integrationStatus':'awaiting-runtime-verification','source':{'method':'built-in imagegen; contour registration and OpenRaster layers','model':'not exposed','references':['assets/source/xumen-transition-style-v1/images/02-骨膜渐变-深腔过渡.png']},'metadata':'assets/source/xumen-transitions-v2/elements.json','notes':'User aesthetic separate; collision unchanged.'})
catalog['revision']+=1;catalog['updatedAt']='2026-11-05';write(p,catalog)
