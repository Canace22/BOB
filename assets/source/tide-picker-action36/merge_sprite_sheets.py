"""Apply only reviewed replacement sheets, preserving source-video provenance."""
import json
from pathlib import Path
BASE=Path(__file__).resolve().parent
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-action36'
path=RUNTIME/'animations.json'
data=json.loads(path.read_text(encoding='utf-8'))
replacement=json.loads((BASE/'sprite-sheet-actions.json').read_text(encoding='utf-8'))
for key,meta in replacement['actions'].items():
    if meta.get('body') is None or meta.get('status','').startswith('rejected'):
        print('Skipped unaccepted source',key)
        continue
    previous=data['actions'].get(key,{})
    meta['superseded_video']=previous.get('superseded_video',{'source':previous.get('source'),'sha256':previous.get('source_sha256'),'reason':'source video anatomy/pose defects; key-pose replacement requires independent runtime review'})
    if key=='parry':
        meta['event_phase']=2/6
        meta['sockets']={'guard':[85.33,-114.02]}
        meta['sockets_source']={'guard':[482,150],'cell':2,'root':[250,460],'scale':160/435}
    data['actions'][key]=meta
    print('Merged',key,meta['frame_count'],meta['status'])
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
