"""Compare complete world data against the pre-animation Git revision."""
import copy, hashlib, json, subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
relative='game/content/whalebelly/world/rooms.json'
baseline=json.loads(subprocess.check_output(['git','show','a6c8b07:'+relative],cwd=ROOT))
current=json.loads((ROOT/relative).read_text(encoding='utf-8'))
def gameplay(data):
    data=copy.deepcopy(data)
    for room in data['rooms']:
        if room['id']=='R2-04':
            for enemy in room['enemies']:
                enemy['config'].pop('sprites',None)
                enemy['config'].pop('swarm_visual',None)
    return data
assert gameplay(baseline)==gameplay(current),'Gameplay data changed outside Boss sprite presentation'
entries=json.loads((ROOT/'assets/source/bloodnest-animation-v5/assets.json').read_text(encoding='utf-8'))
from PIL import Image
for item in entries:
    assert hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest()==item['sha256']
    with Image.open(ROOT/item['integration']['runtimeFile']) as im:
        assert max(im.size)<=512 and im.mode=='RGBA'
out=ROOT/'game/build/qa/bloodnest-animation-v5/gameplay-and-assets.json'
out.write_text(json.dumps({'baseline':'a6c8b07','world_gameplay_equal':True,'asset_sources_verified':2,'runtime_max_side':512},indent=2)+'\n',encoding='utf-8')
print('PASS full world gameplay equals a6c8b07 outside R2-04 sprites/swarm_visual; 2 asset sources and exports verified')
