"""Register this source-derived candidate after real engine checks."""
from pathlib import Path
import json, hashlib
base=Path(__file__).resolve().parent
repo=base.parents[2]
project=repo/'godot/WhalebellyRuins'
runtime=repo/'assets/runtime/sprites/tide-picker-run-v03'
checks=json.loads((project/'evidence/run-v03/checks.json').read_text(encoding='utf-8'))
assert checks['failures']==0 and len(checks['checks'])==16
manifest=json.loads((runtime/'manifest.json').read_text(encoding='utf-8'))
manifest.update(runtime_review='Godot 4.7.2 Compatibility: 16 main-scene checks passed',visual_review='Agent inspected transparent contact sheet, light/dark GPU captures, recorded consecutive poses and loop seam, and live main-scene left/right captures; source defects retained',user_art_approval=False)
for p in [runtime/'manifest.json',project/'assets/runtime/tide-picker-run-v03/manifest.json']:
    p.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
p=repo/'assets/catalog.json';catalog=json.loads(p.read_text(encoding='utf-8'))
asset={'id':'tide-picker-run-v03','name':'拾潮者 · 视频Run 12FPS','kind':'character-animation','region':'全局','tags':['2D','Run','视频动作','Godot'],'status':'candidate','target':'2d','file':'assets/runtime/sprites/tide-picker-run-v03/run-atlas.png','width':2048,'height':3696,'frameSize':[256,336],'frameCount':84,'fps':12,'duration':7,'pivot':[128,300],'source':'assets/source/tide-picker-run-v03/README.md','sha256':hashlib.sha256((runtime/'run-atlas.png').read_bytes()).hexdigest(),'integrationStatus':'integrated','runtimeScene':'godot/WhalebellyRuins/scenes/main.tscn','runtimeFile':'godot/WhalebellyRuins/assets/runtime/tide-picker-run-v03/run.tres','userArtApproval':False,'reviewer':'agent','notes':'主关卡地面移动使用Run v2源片制作的84帧/7秒/12FPS。完整源片重定时，无静止补尾。16项实机检查通过；源裁切、持叉漂移、形变、接缝与滑步保留，视觉candidate。'}
existing=next((i for i,a in enumerate(catalog['assets']) if a['id']==asset['id']),None)
if existing is None:catalog['assets'].append(asset)
else:catalog['assets'][existing]=asset
for item in catalog['assets']:
    if item['id']=='tide-picker-walk-v03':
        item['integrationStatus']='superseded'
        item['notes']='Walk资源、独立预览与显式选用回归保留；主关卡默认地面移动已由tide-picker-run-v03替代。源片重定时、持物恢复与原视觉限制见来源说明。'
catalog['revision']+=1;catalog['updatedAt']='2026-10-29'
p.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Registered Run:',len(checks['checks']),'checks passed')
