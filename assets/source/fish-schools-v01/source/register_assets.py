"""Register only this batch; preserve unrelated catalog entries."""
from pathlib import Path
import json, shutil, hashlib, sys
ROOT=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
BOB=ROOT.parents[1]/'BOB'
source=BOB/'assets/source/fish-schools-v01'
runtime=BOB/'assets/runtime/sprites/fish-schools-v01'
source.mkdir(parents=True,exist_ok=True)
shutil.copytree(ROOT/'source',source/'source',dirs_exist_ok=True,ignore=shutil.ignore_patterns('reference.png','__pycache__'))
shutil.copytree(ROOT/'runtime',runtime,dirs_exist_ok=True)
shutil.copy2(ROOT/'预览.html',source/'preview-template.html')
if not (source/'README.md').exists():
    shutil.copy2(ROOT/'设计与使用说明.md',source/'README.md')
shutil.copytree(ROOT/'evidence',source/'review',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.avi','*.log'))
manifest=json.loads((runtime/'manifest.json').read_text(encoding='utf-8'))
path=BOB/'assets/catalog.json'
catalog=json.loads(path.read_text(encoding='utf-8'))
for spec in manifest['species']:
    identifier='ambient-'+spec['id']+'-school-v01'
    file=runtime/spec['id']/'swim_00.png'
    item={'id':identifier,'name':spec['name']+' · '+spec['school'],'kind':'creature','region':'R1 / 环境通用','tags':['鱼群','2D','循环动画','v01'],'status':'accepted','target':'2d','file':file.relative_to(BOB).as_posix(),'width':320,'height':224,'pivot':[160,112],'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'source':'assets/source/fish-schools-v01/README.md','notes':'AI技术与视觉复核通过；用户审美未确认。原画变形烘焙32相位，群体16秒循环；仅接入独立Godot样板，主关卡未修改。','integrationStatus':'preview-scene-only','userArtApproval':False,'animation':{'frames':32,'fps':24,'loop':True,'atlas':(runtime/spec['id']/'swim_atlas.png').relative_to(BOB).as_posix(),'columns':8,'rows':4,'schoolCount':spec['count']}}
    found=next((i for i,a in enumerate(catalog['assets']) if a['id']==identifier),None)
    if found is None:catalog['assets'].append(item)
    else:
        previous=catalog['assets'][found]
        for key in ['integrationStatus','userArtApproval','integrationEvidence','notes']:
            if key in previous:item[key]=previous[key]
        catalog['assets'][found]=item
catalog['revision']+=1
catalog['updatedAt']='2026-10-29'
path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Registered 3 species, 96 swim frames and 3 school recipes.')
