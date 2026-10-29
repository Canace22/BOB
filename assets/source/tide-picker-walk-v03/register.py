"""Register the reviewed candidate only after the actual main-scene checks pass."""
from pathlib import Path
import json
import hashlib

base=Path(__file__).resolve().parent
repo=base.parents[2]
project=repo/'godot/WhalebellyRuins'
runtime=repo/'assets/runtime/sprites/tide-picker-walk-v03'
checks=json.loads((project/'evidence/walk-v03/checks.json').read_text(encoding='utf-8'))
assert checks['failures']==0 and len(checks['checks'])>=16
manifest=json.loads((runtime/'manifest.json').read_text(encoding='utf-8'))
manifest.update(runtime_review='Godot 4.7.2 Compatibility: 16 main-scene checks passed',visual_review='Agent inspected transparent poses, light/dark GPU preview and live main-scene left/right captures; candidate limitations retained',user_art_approval=False)
for p in [runtime/'manifest.json',project/'assets/runtime/tide-picker-walk-v03/manifest.json']:
    p.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
p=repo/'assets/catalog.json'
catalog=json.loads(p.read_text(encoding='utf-8'))
asset={'id':'tide-picker-walk-v03','name':'拾潮者 · 视频Walk 12FPS','kind':'character-animation','region':'全局','tags':['2D','Walk','视频动作','Godot'],'status':'candidate','target':'2d','file':'assets/runtime/sprites/tide-picker-walk-v03/walk-atlas.png','width':2048,'height':3520,'frameSize':[256,320],'frameCount':84,'fps':12,'duration':7,'pivot':[128,300],'source':'assets/source/tide-picker-walk-v03/README.md','sha256':hashlib.sha256((runtime/'walk-atlas.png').read_bytes()).hexdigest(),'integrationStatus':'integrated','runtimeScene':'godot/WhalebellyRuins/scenes/main.tscn','runtimeFile':'godot/WhalebellyRuins/assets/runtime/tide-picker-walk-v03/walk.tres','userArtApproval':False,'reviewer':'agent','notes':'当前主关卡地面移动使用84帧/7秒/12FPS；源视频相位匹配区间重定时，骨叉用完整参考恢复。16项主关卡检查通过；仍有源片变形、接缝与固定帧率下滑步，保持视觉candidate。'}
old=next((i for i,a in enumerate(catalog['assets']) if a['id']==asset['id']),None)
if old is None:catalog['assets'].append(asset)
else:catalog['assets'][old]=asset
catalog['revision']+=1;catalog['updatedAt']='2026-10-29'
p.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Registered Walk:',len(checks['checks']),'checks passed')
