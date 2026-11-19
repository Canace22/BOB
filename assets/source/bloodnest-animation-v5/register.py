"""Register original imagegen exports; engine copies are resized by sync-art only."""
import hashlib, json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
catalog_path=ROOT/'assets/catalog.json'
catalog=json.loads(catalog_path.read_text(encoding='utf-8'))
records=[]
for slug,name,kind in [('glass-shrimp','血巢玻璃虾 V5','creature'),('water-filament','血巢水丝 V5','effect')]:
    relative=f'assets/runtime/sprites/bloodnest-animation-v5/{slug}.png'
    source=ROOT/relative
    im=Image.open(source).convert('RGBA')
    bbox=im.getchannel('A').getbbox()
    record={'id':f'bloodnest-{slug}-v5','name':name,'kind':kind,'region':'R2','status':'candidate',
      'integrationStatus':'integrated','target':'2d','file':relative,'width':im.width,'height':im.height,
      'bbox':list(bbox),'pivot':[(bbox[0]+bbox[2])/2,(bbox[1]+bbox[3])/2],
      'world':{'axis':'width','units':0.7 if kind=='creature' else 1,'space':'canvas'},
      'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
      'source':'assets/source/bloodnest-animation-v5/README.md',
      'notes':'内置imagegen参考补绘；透明原件未覆盖。程序驱动群体/局部Shader或水丝路径；非逐帧动画。审美待用户审阅。',
      'integration':{'runtimeFile':f'game/art/world-kit/bloodnest-{slug}-v5.png','evidence':'assets/source/bloodnest-animation-v5/README.md',
                     'scope':'R2-04 Boss视觉专用；生成器按max=512同步，不改变战斗。'}}
    catalog['assets']=[item for item in catalog['assets'] if item['id']!=record['id']]+[record]
    records.append(record)
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
(Path(__file__).parent/'assets.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps([{'id':r['id'],'size':[r['width'],r['height']],'bbox':r['bbox']} for r in records]))
