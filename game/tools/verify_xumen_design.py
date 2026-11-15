"""Read-only source, progression and physical-layout checks for preservation work."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
read = lambda p: json.loads(p.read_text(encoding='utf-8'))
contract = read(ROOT/'assets/source/xumen-outputs-preservation-v1/source-contract.json')
checks = []


def check(name, passed):
    checks.append({'name': name, 'pass': passed})


for source in contract['sources']:
    path = ROOT.parent/source['path']
    check('Original source bytes: '+source['path'], path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256'])
reuse = contract['library_reuse']
for key in ('source','runtime'):
    path = ROOT/reuse[key]
    check('Native bitmap bytes: '+key,hashlib.sha256(path.read_bytes()).hexdigest()==reuse['sha256'])
rooms = read(ROOT/'game/content/whalebelly/layout/rooms.json')['rooms']
prior = read(ROOT/'assets/source/xumen-original-style-v1/input-rooms.json')['rooms']
physics = read(ROOT/'game/content/whalebelly/layout/physics-v1.json')['rooms']
check('Seven original stable room IDs', [r['id'] for r in rooms]==[f'R1-{i:02}' for i in range(1,8)])
for current, frozen, previous in zip(rooms,physics,prior):
    check(current['id']+' exact surfaces',current['surfaces']==frozen['surfaces'])
    check(current['id']+' exact safe lanes',current['layout']['checkpoint_lanes']==frozen['checkpoint_lanes'])
    for field in ('doors','rings','camp','reward','enemies','size'):
        check(current['id']+' prior gameplay '+field,current.get(field)==previous.get(field))
gameplay = read(ROOT/'game/tests/fixtures/xumen-gameplay-v1.json')
check('Current campaign still describes nineteen rooms',len(gameplay['rooms'])==19)
core = ['tide_player.gd','campaign_player.gd','tide_skill_catalog.gd','tide_skill_input.gd','tide_skill_controller.gd','tide_input.gd','campaign_relics.gd','campaign_save_bridge.gd','crab_boss.gd','crab_shell.gd','crab_moves.gd','corpse_crab.gd','kit_encounter.gd','ui_save_access.gd']
for source in gameplay['source_hashes']:
    if Path(source['path']).name in core:
        path = ROOT/source['path']
        check('Gameplay bytes: '+source['path'],hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256'])
failed = sum(not item['pass'] for item in checks)
print(json.dumps({'checks':checks,'failures':failed,'scope':'Source originals, native bitmap, previous gameplay fields, frozen physical lookup and gameplay source bytes. This does not grant aesthetic approval.'},ensure_ascii=False,indent=2))
raise SystemExit(1 if failed else 0)
