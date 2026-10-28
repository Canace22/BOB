import json, hashlib, zipfile
from pathlib import Path
p=Path('G:/鲸落万物生/BOB/godot/first-level')
m=json.loads((p/'evidence/v02/build-manifest-release2.json').read_text('utf8'))
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
checks=[]
for e in m['files']:
    f=Path(m['package_directory'])/e['name'];checks.append({'id':e['name'],'passed':sha(f)==e['sha256']})
for e in m['source']:checks.append({'id':e['path'],'passed':sha(p/e['path'])==e['sha256']})
with zipfile.ZipFile(m['zip']) as z:checks.append({'id':'zip_crc','passed':z.testzip() is None})
checks.append({'id':'zip_sha256','passed':sha(Path(m['zip']))==m['zip_sha256']})
result={'passed':all(c['passed'] for c in checks),'checks':checks,'runtime_evidence':'evidence/v02/release2-run/prototype.json','reload_evidence':'evidence/v02/release2-run/persistence.json'}
(p/'evidence/v02/package-verification-release2.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
assert result['passed']
print('Package/source hash and ZIP CRC checks passed:',len(checks))

