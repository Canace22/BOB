"""Copy explicitly reviewed static outputs into BOB without replacing existing art."""
from pathlib import Path
from urllib.parse import urlparse,unquote
import argparse,datetime,hashlib,json,shutil,os
p=argparse.ArgumentParser();p.add_argument('--candidates',required=True);p.add_argument('--review',required=True);p.add_argument('--refresh-metadata',action='store_true');args=p.parse_args()
root=Path(__file__).resolve().parents[4];batch=root/'assets/source/whalefall-v5-2-complete';catalog_file=root/'assets/catalog.json'
catalog=json.loads(catalog_file.read_text());candidates=json.loads(Path(args.candidates).read_text())['assets'];reviews=json.loads(Path(args.review).read_text())['assets'];approved={a['id']:a for a in reviews if a.get('passed')}
existing={a['id']:a for a in catalog['assets']};new=[];refreshed=[]
def project_path(p):return str(p.relative_to(root))
def strings(value):return value if isinstance(value,list) else [value] if value else []
for a in candidates:
 if a['id'] not in approved:continue
 review=approved[a['id']];src=Path(a['file']);sha=hashlib.sha256(src.read_bytes()).hexdigest()
 assert sha==a['sha256']==review['sha256'],f"Review hash changed: {a['id']}"
 if a['id'] in existing:
  assert existing[a['id']]['sha256']==sha,f"Existing art differs; save a reviewed variant instead: {a['id']}"
  if args.refresh_metadata:
   item=existing[a['id']]
   for key in ['world','pivot','parts','attachments','attachmentPoints','staticFamilyRegistration','animationNote','material','rooms','parallax','layer','atlasEligible','familyId','variant','state']:
    if key in a:item[key]=a[key]
   (root/'assets/source'/a['id']/'provenance.json').write_text(json.dumps(item,ensure_ascii=False,indent=2)+'\n')
   (root/'assets/source'/a['id']/'generation-record.json').write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n')
   refreshed.append(a['id'])
  continue
 assert a['id'].replace('-','').isalnum() and '/' not in a['id']
 kind=a.get('kind');kind=kind if kind in ['background','scenery','effect','ui'] else 'character' if a['productionGroup']=='actors' else 'scenery' if a['productionGroup']=='terrain-props' else 'prop'
 runtime=root/'assets/runtime/sprites'/a['id'];source=root/'assets/source'/a['id'];runtime.mkdir(parents=True,exist_ok=True);source.mkdir(parents=True,exist_ok=True)
 dst=runtime/('background.png' if kind=='background' else 'base.png')
 if dst.exists():assert hashlib.sha256(dst.read_bytes()).hexdigest()==sha,f'Would overwrite {dst}'
 else:shutil.copy2(src,dst)
 prompt_paths=[]
 for f in dict.fromkeys(strings(a.get('promptFiles'))+strings(a.get('promptFile'))+strings(a.get('prompt'))+strings(a.get('promptChain'))):
  f=Path(f)
  if f.is_file():
   target=source/f.name;shutil.copy2(f,target);prompt_paths.append(project_path(target))
 source_files=[]
 for f in strings(a.get('sourceFile')):
  f=Path(f);target=source/f.name;shutil.copy2(f,target);source_files.append(project_path(target))
 refs=[]
 for f in a.get('referenceFiles',a.get('references',[])):
  f=str(f);local=Path(f)
  if local.is_file() and local.is_relative_to(root):target=local
  else:target=batch/'references'/Path(unquote(urlparse(f).path)).name
  if not target.is_file() and local.is_file():
   reference_dir=source/'references';reference_dir.mkdir(exist_ok=True)
   digest=hashlib.sha256(local.read_bytes()).hexdigest()[:12]
   target=reference_dir/f'{local.stem}-{digest}{local.suffix}';shutil.copy2(local,target)
  assert target.is_file(),f'Missing reference {target}'
  refs.append(project_path(target))
 qa=a.get('qa',{});findings=[f for f in strings(qa.get('findings'))+strings(a.get('qaFindings')) if '需root完成' not in f];notes=strings(a.get('notes'))+strings(a.get('purpose'))
 item={'id':a['id'],'name':a['name'],'kind':kind,'region':a.get('region','共享'),'tags':[a.get('region','共享'),'V5.2','全量静态',a.get('state',a.get('variant','基础'))],
  'status':'accepted','notes':'；'.join(notes),'target':'2d','file':project_path(dst),'width':a['width'],'height':a['height'],'bbox':a['bbox'],'pivot':a['pivot'],'world':a.get('world'),
  'sha256':sha,'alphaRange':a['alphaRange'],'alphaBboxes':a['alphaBboxes'],'source':{'batchId':batch.name,'method':a.get('method',a.get('generation','内置imagegen；按指定设计参考重绘')),'references':list(dict.fromkeys(refs)),'prompts':prompt_paths,'sourceFiles':source_files,'designUrls':['http://10.11.140.20:8765/simple/','http://10.11.140.20:8765/full/'],'rights':'用户指定设计并要求用于BOB；原文未明确的造型适配另行注明。'},
  'qa':{'scope':review['scope'],'passed':True,'report':project_path(batch/'acceptance.md'),'evidence':review.get('evidence',[]),'limitations':notes+findings+['静态技术与视觉检查通过；用户美术确认、动作动画和游戏内接入未完成。']},
  'integrationStatus':'not-integrated','spriteType':kind if kind in ['background','ui','effect'] else 'static','coversRequirementIds':a.get('coversRequirementIds',[a.get('familyId',a['id'])])}
 for key in ['nineSlice','parts','staticFamilyRegistration','attachments','attachmentPoints','animationNote','material','rooms','parallax','layer','canvasSpace','scaleSpace','atlasEligible','familyId','variant','state']:
  if key in a:item[key]=a[key]
 (source/'provenance.json').write_text(json.dumps(item,ensure_ascii=False,indent=2)+'\n')
 (source/'generation-record.json').write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n')
 catalog['assets'].append(item);new.append(a['id'])
if new or refreshed:
 catalog['revision']+=1;catalog['updatedAt']=datetime.datetime.now(datetime.timezone.utc).isoformat()
 temporary=catalog_file.with_suffix('.json.importing');temporary.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n');os.replace(temporary,catalog_file)
print(json.dumps({'imported':len(new),'refreshed':len(refreshed),'ids':new,'catalogCount':len(catalog['assets']),'revision':catalog['revision']},ensure_ascii=False))
