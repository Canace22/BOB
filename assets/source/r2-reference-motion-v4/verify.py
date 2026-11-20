from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];BATCH=Path(__file__).resolve().parent
hash=lambda p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
checks=[]
def check(name,value):checks.append({'name':name,'pass':bool(value)});print(('PASS ' if value else 'FAIL ')+name)
for asset in json.loads((BATCH/'source-contract.json').read_text(encoding='utf-8'))['assets']:
 for label,p in [('original',asset['original']),('library',asset['library']),('runtime','game/art/world-kit/'+asset['id']+'.png')]:check(asset['id']+' '+label+' source bytes',hash(p)==asset['sha256'])
for id in ['R2-03','R2-04']:
 p=ROOT/f'game/content/whalebelly/world/recipes/{id}.json';recipe=json.loads(p.read_text(encoding='utf-8'));scene=(ROOT/f'game/content/whalebelly/r2/{id}.tscn').read_text(encoding='utf-8')
 check(id+' reference depth selected',recipe['reference_background']['art']+'.png' in scene)
 check(id+' no duplicate old broken heart landmark',not any(a['art']=='r2-heart-rupture' for a in recipe.get('landmarks',[])))
 check(id+' new motion is decoration only',all(a.get('hide_flag','') in ['', 'pressure'] for a in recipe['background_schools']))
 check(id+' membrane and pearl layers animated',any(a.get('motion')=='membrane' for a in recipe['framing']) and any(a.get('motion')=='glow' for a in recipe['framing']))
 record=Image.open(ROOT/f'game/build/qa/r2-reference-motion-v4/current/{id}-motion.webp')
 check(id+' complete actual-renderer preview',record.n_frames==160)
failures=sum(not c['pass'] for c in checks)
(ROOT/'game/build/qa/r2-reference-motion-v4/source-audit.json').write_bytes((json.dumps({'checks':checks,'failures':failures},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
raise SystemExit(1 if failures else 0)
