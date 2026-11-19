"""Read-only verification of selected generated PNGs and their painted cores."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
DATA = Path(__file__).with_name('selected-assets.json')
checks = []
for name, item in json.loads(DATA.read_text(encoding='utf-8'))['assets'].items():
    source = ROOT/item['source']
    bitmap = Image.open(source).convert('RGBA')
    alpha = bitmap.getchannel('A')
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    core = item['core']
    actual = {
        'name': name,
        'size_matches': list(bitmap.size)==item['size'],
        'bbox_matches': list(alpha.point(lambda v:255 if v>=32 else 0).getbbox())==item['bbox32'],
        'hash_matches': digest==item['sha256'],
        'core_alpha_min': alpha.crop(core).getextrema()[0],
        'current_scene_status': item['integration_status'],
    }
    runtime = ROOT/'assets/runtime/scenes/xumen-structure-redesign-v1'/(name+'.png')
    game = ROOT/item['runtime'].replace('res://','game/')
    actual['copies_match'] = all(hashlib.sha256(path.read_bytes()).hexdigest()==digest for path in [runtime,game])
    actual['pass'] = all(actual[k] for k in ['size_matches','bbox_matches','hash_matches','copies_match']) and actual['core_alpha_min']>=240
    checks.append(actual)
failures = sum(not row['pass'] for row in checks)
print(json.dumps({'checks':checks,'failures':failures,'scope':'Source/copy bytes, dimensions, alpha bounds and opaque rectangle; not aesthetic approval.'},ensure_ascii=False,indent=2))
raise SystemExit(1 if failures else 0)
