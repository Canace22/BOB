"""Check actual PNG delivery, platform archive bytes and the declared runtime timing."""
from pathlib import Path
from PIL import Image
import json,hashlib,zipfile
P=Path(__file__).resolve().parent;D=P/'delivery';m=json.loads((D/'manifest.json').read_text())
expected={'idle','run','jump_rise','jump_fall','land','attack','attack2','heavy','hurt','dash','heal'}
assert set(m['clips'])==expected
assert m['canvas']==[384,384] and m['pivot']==[192,342] and m['scale']==.275
rows=[]
for name,c in m['clips'].items():
 boundaries=[0];images=[]
 for frame in c['frames']:
  f=D/Path(frame['file']).name;im=Image.open(f).convert('RGBA');assert im.size==(384,384)
  a=im.getchannel('A');assert a.getextrema()==(0,255);bbox=a.getbbox();assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<384 and bbox[3]<384,(f.name,bbox)
  assert frame['file']==f'right/{f.name}' and frame['durationMs']%20==0
  boundaries.append(boundaries[-1]+frame['durationMs']);images.append({'file':f.name,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'alphaBBox':bbox})
 if 'activeWindowMs' in c:
  a,b=c['activeWindowMs'];assert a in boundaries and b in boundaries and 0<a<b<boundaries[-1]
 folder=P/name/'platform'
 if not folder.exists():folder=P/'extra'/name/'platform'
 if folder.exists():
  report=json.loads((folder/'review/platform-run.json').read_text());assert report['fps']==50 and report['reopened']['resultBytesVerified']
  assert report['durationMs']==boundaries[-1]
  archive=next((folder/'exports').glob('*.zip'))
  with zipfile.ZipFile(archive) as z:
   pngs=sorted(n for n in z.namelist() if n.endswith('.png'));assert len(pngs)==report['frameCount']
   for member,record in zip(pngs,report['records']):assert hashlib.sha256(z.read(member)).hexdigest()==record['outputSha256']
  platform={'frameCount':report['frameCount'],'fps':report['fps'],'project':str((folder/report['projectPath']).relative_to(P)),'zipBytesMatch':True}
 else:platform={'externalPackage':'extra/','verification':'extra/review/final-checks.json'}
 rows.append({'clip':name,'poses':len(images),'durationMs':boundaries[-1],'loop':c['loop'],'frames':images,'platform':platform})
(P/'review/delivery-checks.json').write_text(json.dumps({'canvas':[384,384],'pivot':[192,342],'clips':rows,'artAcceptance':'Technical integrity only. Root performs real gameplay and further artistic review.'},indent=2)+'\n')
print('PASS',len(rows),'clips',sum(len(r['frames']) for r in rows),'poses')
