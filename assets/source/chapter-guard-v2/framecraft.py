"""Save/reopen registered action timelines through Framecraft's actual local API."""
from pathlib import Path
from io import BytesIO
import json, zipfile, urllib.request, urllib.parse, uuid

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
RUNTIME=ROOT/'assets/runtime/sprites/chapter-guard-v2'
API='http://127.0.0.1:8765/api/projects'
DIRECTORY=str(HERE/'projects')
opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
data=json.loads((RUNTIME/'animations.json').read_text(encoding='utf-8'))
result=[]
for clip, animation in data['clips'].items():
    frames=[]
    for i,(filename,ms) in enumerate(zip(animation['files'],animation['durations_ms'])):
        assert ms%20==0
        for tick in range(ms//20):
            frames.append({'id':f'{clip}-{i}-{tick}','name':filename,'sourceIndex':i,
                'time':len(frames)/50,'width':512,'height':512,'selected':True,'file':f'frames/{filename}'})
    manifest={'format':'framecraft-project-v1','name':'负壳守卫V2_'+clip,'fps':50,'source':None,'frames':frames,
        'workspace':{'options':{'removeBackground':False,'targetHeight':512,'padding':0,
            'layout':'original','alignment':'center','cleanup':'none'},'start':0,'end':len(frames)-1,
            'cursor':0,'stride':1,'loopMode':'loop' if animation['loop'] else 'once',
            'sheetColumns':10,'sheetRows':(len(frames)+9)//10,'background':'dark','sequenceMode':True}}
    blob=BytesIO()
    with zipfile.ZipFile(blob,'w',zipfile.ZIP_STORED) as z:
        z.writestr('project.json',json.dumps(manifest,ensure_ascii=False))
        for filename in animation['files']:z.write(RUNTIME/filename,'frames/'+filename)
    boundary=uuid.uuid4().hex
    body=(f'--{boundary}\r\nContent-Disposition: form-data; name="archive"; filename="project.zip"\r\nContent-Type: application/zip\r\n\r\n').encode()+blob.getvalue()+f'\r\n--{boundary}--\r\n'.encode()
    request=urllib.request.Request(API+'?'+urllib.parse.urlencode({'directory':DIRECTORY}),data=body,
        headers={'Content-Type':f'multipart/form-data; boundary={boundary}','Origin':'http://127.0.0.1:8765'})
    saved=json.load(opener.open(request))
    reopened=json.load(opener.open(API+'/'+saved['id']+'?'+urllib.parse.urlencode({'directory':DIRECTORY})))
    assert len(reopened['frames'])==len(frames)
    assert reopened['workspace']['loopMode']==manifest['workspace']['loopMode']
    result.append({'clip':clip,'id':saved['id'],'unique_poses':len(animation['files']),
        'playback_ticks':len(frames),'fps':50,'duration_ms':sum(animation['durations_ms']),
        'reopened':True,'game_pivot':[256,440],'loop':animation['loop']})
(HERE/'framecraft-projects.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
