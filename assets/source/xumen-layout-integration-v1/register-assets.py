"""Register new bitmap pieces and a narrow, reproducible runtime sync batch."""
import hashlib,json,shutil
from pathlib import Path
from PIL import Image
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
catalog_path=ROOT/'assets/catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
manifest_path=ROOT/'game/art/manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
entries=[]
for name,label,kind in [('bone-wall','实体竖骨壁','wall'),('thick-platform','厚骨膜台','platform'),('low-roof','厚骨膜低顶','roof')]:
    source=HERE/'images'/(name+'-original.png')
    runtime=ROOT/'assets/runtime/scenes/xumen-layout-v1'/(name+'.png')
    runtime.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,runtime)
    im=Image.open(runtime).convert('RGBA');a=im.getchannel('A');bbox=a.point(lambda v:255 if v>=32 else 0).getbbox()
    key='xumen-layout-'+name+'-v1'
    record={'id':key,'name':label,'kind':'environment','region':'须门遗港','tags':['房内布局重排','实体结构','程序摆放'],
      'status':'candidate','target':'2d','file':runtime.relative_to(ROOT).as_posix(),'width':im.width,'height':im.height,
      'bbox':list(bbox),'pivot':[(bbox[0]+bbox[2])/2,bbox[1]],'world':{'axis':'height' if kind=='wall' else 'width','units':4,'basis':'实际地形等比摆放；alpha32轮廓与碰撞保守配准'},
      'sha256':hashlib.sha256(runtime.read_bytes()).hexdigest(),'spriteType':'static','integrationStatus':'candidate',
      'source':{'method':'built-in image_gen','batchId':'xumen-layout-integration-v1','reference':['assets/source/xumen-layout-review-v1/inputs/overview-R1-02.png','assets/runtime/scenes/xumen-vertical-v1/E35-spine.png' if kind=='wall' else 'assets/runtime/sprites/r4-bone-platform/base.png']},
      'notes':'原生竖向或横向结构，不拉伸。外部低alpha柔光由运行cutout shader丢弃；非用户美术签收。'}
    old=next((i for i,v in enumerate(catalog['assets']) if v['id']==key),None)
    if old is None:catalog['assets'].append(record)
    else:catalog['assets'][old]=record
    entries.append({'src':runtime.relative_to(ROOT).as_posix(),'dest':'xumen-layout-v1/'+name+'.png'})
for name in ['arch','support-0','support-2','ring','memory']:
    entries.append({'src':'assets/runtime/scenes/xumen-unified-v1/'+name+'.png','dest':'xumen-layout-v1/'+name+'.png'})
entries.append({'src':'assets/runtime/scenes/xumen-vertical-v1/E35-spine.png','dest':'xumen-layout-v1/background-spine.png'})
for entry in entries:
    dest=ROOT/'game/art'/entry['dest'];dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/entry['src'],dest)
    old=next((i for i,v in enumerate(manifest['entries']) if v['dest']==entry['dest']),None)
    if old is None:manifest['entries'].append(entry)
    else:manifest['entries'][old]=entry
catalog['updatedAt']='2026-11-15'
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
(HERE/'sync-manifest.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8')
print('Registered 3 candidate bitmap pieces; synced 9 targeted runtime files without touching old PNGs.')
