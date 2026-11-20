from pathlib import Path
import json,re,shutil,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];BATCH=Path(__file__).resolve().parent
p=ROOT/'assets/catalog.json';catalog=json.loads(p.read_text(encoding='utf-8'));records=[]
for job in json.loads((BATCH/'generation.json').read_text(encoding='utf-8'))['assets']:
 id=job['id'];origin=Path(re.search(r'as (C:.*?\.png) by default',job['output_hint']).group(1));original=BATCH/'originals'/f'{id}.png';original.parent.mkdir(parents=True,exist_ok=True)
 if origin.exists():
  if original.exists() and original.read_bytes()!=origin.read_bytes():raise RuntimeError('Refusing overwrite '+str(original))
  shutil.copyfile(origin,original)
 elif not original.exists():raise FileNotFoundError(str(original))
 im=Image.open(original).convert('RGBA');a=im.getchannel('A');bbox=a.point(lambda n:255 if n>=32 else 0).getbbox();sha=hashlib.sha256(original.read_bytes()).hexdigest()
 dest=ROOT/'assets/runtime/scenes/r2-reference-motion-v4'/f'{id}.png';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(original,dest)
 kind='background' if 'depth' in id else 'creature' if 'amphipod' in id else 'prop'
 asset={'id':id,'name':id,'kind':kind,'region':'R2','status':'candidate','integrationStatus':'candidate','file':dest.relative_to(ROOT).as_posix(),'width':im.width,'height':im.height,'bbox':list(bbox),'pivot':[(bbox[0]+bbox[2])/2,bbox[3]],'world':{'axis':'width','units':30 if kind=='background' else 1,'space':'canvas'},'sha256':sha,'source':'assets/source/r2-reference-motion-v4/generation.json','notes':'原画参考引导补绘/隐藏面补全；背景已清除群体、气泡、演员和游戏几何；动态与静态所有权分开。整体审美待审阅。'}
 existing=next((i for i,x in enumerate(catalog['assets']) if x['id']==id),None)
 if existing is None:catalog['assets'].append(asset)
 else:catalog['assets'][existing]=asset
 records.append({'id':id,'original':original.relative_to(ROOT).as_posix(),'library':dest.relative_to(ROOT).as_posix(),'size':list(im.size),'bbox':list(bbox),'sha256':sha,'alpha':list(a.getextrema())})
catalog['revision']=max(catalog['revision'],86);catalog['updatedAt']='2026-11-16';p.write_bytes((json.dumps(catalog,ensure_ascii=False,indent=2)+'\n').encode('utf-8'));(BATCH/'source-contract.json').write_bytes((json.dumps({'assets':records},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(records,ensure_ascii=False))
