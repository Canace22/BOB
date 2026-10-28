"""Record completed checks and register only this asset; does not generate or run the game."""
from pathlib import Path
import hashlib
import json
import numpy as np

base = Path(__file__).resolve().parent
repo = base.parents[2]
project = repo/'godot/WhalebellyRuins'
runtime = repo/'assets/runtime/sprites/tide-picker-idle-v03'
checks = json.loads((project/'evidence/idle-v03/results.json').read_text(encoding='utf-8'))
assert checks['failed'] == 0 and len(checks['checks']) == 17
fields = np.load(base/'motion-fields.npz')
if 'inverse_flow' in fields:
    flow = np.round(fields['inverse_flow']*256).astype(np.int16)
    indices = fields['source_indices'].copy()
    fields.close()
    np.savez_compressed(base/'motion-fields.npz',inverse_flow_q256=flow,source_indices=indices,quantization_scale=256)
else:
    fields.close()
manifest = json.loads((runtime/'manifest.json').read_text(encoding='utf-8'))
manifest.update(visual_review='agent: transparent master, key poses, light/dark renderer captures and live-level left/right contact inspected',runtime_review='pass: 17 main-scene checks; Godot4.7.2 Compatibility',user_art_approval=False)
for path in [runtime/'manifest.json',project/'assets/runtime/tide-picker-idle-v03/manifest.json']:
    path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
catalog_path = repo/'assets/catalog.json'
catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
asset = {
    'id':'tide-picker-idle-v03', 'name':'拾潮者 · 提灯守望 Idle',
    'kind':'character-animation','region':'全局','tags':['2D','Idle','视频运动烘焙','Godot'],
    'status':'accepted','target':'2d','file':'assets/runtime/sprites/tide-picker-idle-v03/idle-atlas.png',
    'width':2048,'height':2880,'frameSize':[256,320],'frameCount':manifest['frames'],
    'fps':12,'duration':6,'pivot':[128,300],
    'source':'assets/source/tide-picker-idle-v03/README.md',
    'sha256':hashlib.sha256((runtime/'idle-atlas.png').read_bytes()).hexdigest(),
    'integrationStatus':'integrated','runtimeScene':'godot/WhalebellyRuins/scenes/main.tscn',
    'runtimeFile':'godot/WhalebellyRuins/assets/runtime/tide-picker-idle-v03/idle.tres',
    'userArtApproval':False,'reviewer':'agent',
    'notes':'Agent技术与实景检查通过，用户审美待确认。完整原画按视频运动烘焙；70帧含时长保持，6秒循环；脚部固定、头盔/双叉/灯具刚性约束。仅替换主角Idle，非逐帧手绘，左向沿用控制器翻转。'
}
existing = next((i for i,a in enumerate(catalog['assets']) if a['id']==asset['id']),None)
if existing is None: catalog['assets'].append(asset)
else: catalog['assets'][existing] = asset
catalog['revision'] += 1
catalog['updatedAt'] = '2026-10-29'
catalog_path.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
state={'task':'idle-v03','scope':'existing Godot player idle only','status':'complete','reviewer':'agent','user_art_approval':False,'engine':checks['engine'],'stages':{'source':'pass','bake':'pass','integration':'pass','runtime_checks':'pass','documentation':'pass'},'checks':checks['checks'],'source':str(base),'runtime':'res://assets/runtime/tide-picker-idle-v03/idle.tres','evidence':'res://evidence/idle-v03','limitations':['2D video-derived warping is visible in close-ups','left facing follows existing flip convention','other action art and published binaries unchanged']}
(project/'.production/idle-v03.json').write_text(json.dumps(state,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Registered idle V03:',manifest['frames'],'frames;',len(checks['checks']),'checks passed')
