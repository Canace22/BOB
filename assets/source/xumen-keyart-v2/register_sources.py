"""Register concept sources without touching runtime manifests."""
from pathlib import Path
import json, re, hashlib

SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,x): p.write_bytes((json.dumps(x,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def main():
    snapshots=load(SRC/'input-manifest.json')
    p=SRC/'inputs/A02-style-candidate.png'
    if not any(x['file']=='inputs/A02-style-candidate.png' for x in snapshots):
        snapshots.append({'file':'inputs/A02-style-candidate.png','sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'role':'A02首次候选；A07的实际风格参考，非最终须筛图'})
    save(SRC/'input-manifest.json',snapshots)
    names=['776a82a2-c0c0-44fa-af5e-317c0d2bf68f','cd5d645d-a980-4069-953f-3e4170362a47','6090817e-6483-419a-8df9-a61a796a51ea','868b4325-aa8a-4477-80e2-97838e9b8443','1fde1ec6-63b1-4ed4-b32a-0f11be8d6b3b','ce1beb6c-aa62-4853-b29e-8ac89d42ac59','8c5f9a30-82af-41b2-960d-8658373c8593']
    sources=[{'snapshot':f'inputs/room{i:02}.png','original':f'C:/Users/Kingsoft/AppData/Local/Temp/codex-clipboard-{name}.png','role':'用户本轮提供的房间构图与风格参考；不是本轮新图'} for i,name in enumerate(names,1)]
    sources.extend([
        {'snapshot':'inputs/chapter.png','original':'assets/source/world-continuity-v1/images/02-r1-continuous.png','role':'既有整区地理参考'},
        {'snapshot':'inputs/T01.png','original':'assets/source/xumen-transition-style-v1/images/01-颌骨斜拱-主路过渡.png','role':'既有过渡样式'},
        {'snapshot':'inputs/T02.png','original':'assets/source/xumen-transition-style-v1/images/02-骨膜渐变-材质过渡.png','role':'既有过渡样式，原确切文件名见源目录'},
        {'snapshot':'inputs/T03.png','original':'assets/source/xumen-transition-style-v1/images/03-骨壁生台-上行过渡.png','role':'既有过渡样式'},
        {'snapshot':'inputs/runtime-layout.json','original':'assets/source/xumen-unified-v1/layout.json','role':'工程房间原点快照'},
        {'snapshot':'inputs/anatomy.json','original':'assets/source/world-continuity-v1/inputs/鲸体位置与连接.json','role':'解剖定位'},
        {'snapshot':'inputs/topology.json','original':'assets/source/world-continuity-v1/connections.json','role':'世界拓扑快照'}])
    # Resolve the second transition basename from the actual existing source.
    sources[9]['original']=str(next((ROOT/'assets/source/xumen-transition-style-v1/images').glob('02-*')).relative_to(ROOT)).replace('\\','/')
    save(SRC/'sources.json',{'rights':'用户指定并授权本项目设计制作；既有图不冒称本轮原创生成。新图工具为内置imagegen，模型名未公开。','inputs':sources})
    arts=load(SRC/'art-manifest.json')['images']; ps={p['id']:p for p in load(SRC/'prompts.json')['images']}
    cat=ROOT/'assets/catalog.json'; raw=cat.read_text(encoding='utf-8-sig'); data=json.loads(raw)
    existing={a['id'] for a in data['assets']}
    new=[]
    for a in arts:
        aid='xumen-keyart-v2-'+a['id'].lower()
        if aid in existing: continue
        p=ps[a['id']]
        refs=[r if r.startswith('assets/') else 'assets/source/xumen-keyart-v2/'+r for r in p['references']]
        new.append({'id':aid,'name':'须门遗港精修 · '+Path(a['file']).stem,'kind':'environment-concept','region':'R1 须门遗港','tags':['原画','概念候选','手绘','未接入'],'target':'2d','status':'candidate','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-keyart-v2/'+a['file'],'width':a['width'],'height':a['height'],'sha256':a['sha256'],'notes':'概念候选；非分层运行资产；七房六边保留。用户审美待反馈。','source':{'batchId':'xumen-keyart-v2','method':'built-in imagegen; reference-guided concept painting','model':'not exposed','references':refs,'prompts':['assets/source/xumen-keyart-v2/prompts.json'],'generation':a['generation']},'qa':{'scope':'概念图查看、文件与图册核对；非游戏实测','report':'assets/source/xumen-keyart-v2/acceptance.md','userApproved':False}})
    for entry in new:
        entry['status']='needs-review'
    if new:
        pos=raw.rfind('\n  ]')
        assert pos>0
        addition=',\n'+',\n'.join('\n'.join('    '+line for line in json.dumps(x,ensure_ascii=False,indent=2).splitlines()) for x in new)
        raw=raw[:pos]+addition+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1)
        json.loads(raw)
    raw=re.sub(r'("id": "xumen-keyart-v2-a0[0-7]"[\s\S]*?"status": )"candidate"',r'\1"needs-review"',raw)
    cat.write_bytes(raw.encode('utf-8'))
    print(json.dumps({'registered':len(new),'totalPrimaryArt':len(arts)},ensure_ascii=False))

if __name__=='__main__': main()
