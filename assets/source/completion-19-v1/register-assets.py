"""Register generated atlases without modifying their pixels or per-frame scale."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
catalog_path = ROOT / 'assets/catalog.json'
catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
reports = []
for key, name, reference, kind, units in [
    ('clam-spit-cycle-v1', '鸣贝 · 开合吐珠八帧', 'spine-resonant-clams', 'enemy', 4.2),
    ('sea-larva-swim-v1', '归海幼体 · 尾膜游动八帧', 'sea-larva', 'ecology', 1.1),
]:
    file = ROOT / 'assets/runtime/sprites/completion-19-v1' / (key+'.png')
    image = Image.open(file).convert('RGBA')
    assert image.size == (1536,1024)
    alpha = image.getchannel('A')
    assert alpha.getextrema()[0] == 0
    boxes = []
    for frame in range(8):
        cell = alpha.crop((frame%4*384,frame//4*512,(frame%4+1)*384,(frame//4+1)*512))
        box = cell.point(lambda a: 255 if a >= 32 else 0).getbbox()
        assert box and box[0] > 0 and box[2] < 384 and box[1] > 0 and box[3] < 512
        boxes.append(box)
    sha = hashlib.sha256(file.read_bytes()).hexdigest()
    record = {
        'id': key, 'name': name, 'kind': kind, 'region': '鸣肋断脊' if kind=='enemy' else '耳海归墟',
        'tags':['19房补齐','逐帧','原画衍生'], 'status':'candidate', 'target':'2d',
        'file':file.relative_to(ROOT).as_posix(), 'width':1536, 'height':1024,
        'bbox':[0,0,1536,1024], 'pivot':[192,393] if kind=='enemy' else [192,256],
        'world':{'axis':'width','units':units,'basis':'图集按单格和可见轮廓换算，整图不是单个精灵'},
        'sha256':sha,'spriteType':'animated','frameCount':8,
        'animation':{'columns':4,'rows':2,'cell':[384,512],'order':'row-major','loop':kind=='ecology','nominalFps':8},
        'source':{'method':'built-in image_gen; reference-guided authored pose atlas','referenceId':reference,'batchId':'completion-19-v1','prompts':['assets/source/completion-19-v1/prompts.md']},
        'integrationStatus':'integrated','notes':'原件保留；身体帧与运行逻辑分离。2026-11-14真实场景/连续帧技术复核通过，美术仍为candidate。',
        'qa':{'scope':'atlas bounds/alpha and native-engine scene/motion; not artistic approval','passed':True,'validatedAt':'2026-11-14','sourceReport':'assets/source/completion-19-v1/README.md','localEvidence':['game/build/qa/completion-20261114/runtime/checks.json','game/build/qa/completion-20261114/runtime/motion/clips.json'],'limitations':['无用户美术签收','幼体外缘仍有轻微柔光，90px运行尺度已复核'] if kind=='ecology' else ['无用户美术签收','路线测试不证明Boss最终难度']},
    }
    old = next((i for i,a in enumerate(catalog['assets']) if a['id']==key),None)
    if old is None: catalog['assets'].append(record)
    else: catalog['assets'][old] = record
    reports.append({'id':key,'sha256':sha,'alphaRange':alpha.getextrema(),'frameBboxesAlpha32':boxes,'review':'native-engine technical validation recorded; candidate art awaiting user feedback'})
catalog['updatedAt']='2026-11-14'
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
(SOURCE/'atlas-checks.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'registered':len(reports),'frames':16}))
