"""Register this batch without altering unrelated asset entries."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8'))
def save(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
manifest=read('game/art/manifest.json')
for name in ['attack.png','walk.png','life.png','animations.json']:
    dest='enemies/corpse_crab/'+name
    entry={'src':'assets/runtime/sprites/corpse-crab-actions-v1/'+name,'dest':dest}
    if not any(x['dest']==dest for x in manifest['entries']): manifest['entries'].append(entry)
save('game/art/manifest.json',manifest)
rooms=read('assets/runtime/godot-support/whalebelly/rooms.json')
for room in rooms:
    for enemy in room.get('enemies',[]):
        if not enemy.get('boss',False): enemy['type']='corpse-crab'
save('assets/runtime/godot-support/whalebelly/rooms.json',rooms)
catalog=read('assets/catalog.json')
entry={'id':'corpse-crab-actions-v1','name':'尸蟹 · 七状态动作','kind':'character','region':'R1',
       'tags':['R1','尸蟹','逐帧动作'],'status':'candidate','target':'2d',
       'file':'assets/runtime/sprites/corpse-crab-actions-v1/attack.png','width':1024,'height':512,
       'spriteType':'animation-atlas','integrationStatus':'verified',
       'notes':'24个原始姿势、7种游戏状态；整体镜像。本地主场景与12项键盘测试通过，用户审美未签收；详见docs/corpse-crab-integration.md。',
       'source':{'method':'内置image_gen姿势表；确定性裁片配准，非视频提帧','model':'未暴露',
                 'references':['assets/runtime/sprites/corpse-crab/idle.png'],
                 'prompts':['assets/source/corpse-crab-actions-v1/prompts/'+n+'.txt' for n in ['attack','walk','life']]},
       'metadata':'assets/runtime/sprites/corpse-crab-actions-v1/animations.json'}
if not any(x['id']==entry['id'] for x in catalog['assets']):
    catalog['assets'].append(entry);catalog['revision']+=1
save('assets/catalog.json',catalog)
print('Registered 4 runtime resources and 3 typed enemy spawns; existing entries preserved.')
