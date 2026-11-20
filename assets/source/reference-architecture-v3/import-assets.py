from pathlib import Path
import json,re,hashlib,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
BATCH=Path(__file__).resolve().parent
catalog_path=ROOT/'assets/catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
records=[]
for job in json.loads((BATCH/'generation.json').read_text(encoding='utf-8'))['assets']:
    origin=Path(re.search(r'as (C:.*?\.png) by default',job['output_hint']).group(1))
    asset_id=job['id']; source=BATCH/'originals'/f'{asset_id}.png'
    source.parent.mkdir(parents=True,exist_ok=True)
    if source.exists() and source.read_bytes()!=origin.read_bytes(): raise RuntimeError('Refusing overwrite '+str(source))
    shutil.copyfile(origin,source)
    image=Image.open(source).convert('RGBA'); alpha=image.getchannel('A')
    core=alpha.point(lambda n:255 if n>=32 else 0).getbbox()
    if not core: raise RuntimeError('Empty image')
    sha=hashlib.sha256(source.read_bytes()).hexdigest()
    record={'id':asset_id,'source':source.relative_to(ROOT).as_posix(),'sha256':sha,'size':list(image.size),'bbox':list(core),'selected':job['selected']}
    records.append(record)
    if not job['selected']: continue
    dest=ROOT/'assets/runtime/scenes/reference-architecture-v3'/f'{asset_id}.png';dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,dest)
    frame='frame' in asset_id
    pivot=[image.width/2,0] if frame else [(core[0]+core[2])/2,core[3]]
    asset={'id':asset_id,'name':asset_id,'kind':'scenery' if frame else 'prop','region':'R2' if asset_id.startswith('r2') else 'R3' if asset_id.startswith('r3') else 'R4/R5','status':'candidate','integrationStatus':'candidate','target':'2d','file':dest.relative_to(ROOT).as_posix(),'width':image.width,'height':image.height,'bbox':list(core),'pivot':pivot,'world':{'axis':'width','units':30 if frame else 10,'space':'canvas'},'sha256':sha,'source':'assets/source/reference-architecture-v3/generation.json','notes':'参考原画引导补绘，内置image_gen；原图未修改，非原像素分离。建筑静态／无碰撞，技术与整体审美分别验收。'}
    existing=next((i for i,a in enumerate(catalog['assets']) if a['id']==asset_id),None)
    if existing is None:catalog['assets'].append(asset)
    else:catalog['assets'][existing]=asset
catalog['revision']=max(85,catalog['revision']);catalog['updatedAt']='2026-11-16'
catalog_path.write_bytes((json.dumps(catalog,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(BATCH/'source-contract.json').write_bytes((json.dumps({'assets':records},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print('Imported',sum(r['selected'] for r in records),'new native-size assets;',sum(not r['selected'] for r in records),'rejected candidates retained.')
