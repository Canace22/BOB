"""Register concept paintings and verify provenance; no game mutation."""
from pathlib import Path
import json, hashlib, re

SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
EXPECTED=['E01','E02','E03','E04','E33','E35']
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def main():
    arts=load(SRC/'art-manifest.json')['images']
    prompts={p['id']:p for p in load(SRC/'prompts.json')['images']}
    d=load(SRC/'connections.json')
    assert [a['id'] for a in arts]==EXPECTED
    cat=ROOT/'assets/catalog.json';raw=cat.read_text(encoding='utf-8-sig');c=json.loads(raw)
    oldids={a['id'] for a in c['assets']};new=[]
    for a,b in zip(arts,d['edges']):
        assert hashlib.sha256((SRC/a['file']).read_bytes()).hexdigest()==a['sha256']
        p=prompts[a['id']];aid='xumen-seam-keyart-v1-'+a['id'].lower()
        if aid not in oldids:
            new.append({'id':aid,'name':'须门接续 · '+b['title'],'kind':'environment-concept','region':'R1 须门遗港','tags':['接续原画','概念候选','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-seam-keyart-v1/'+a['file'],'width':a['width'],'height':a['height'],'sha256':a['sha256'],'notes':'六边既有关系的专用接续原画。无新增房间、玩法或运行变更。','source':{'batchId':'xumen-seam-keyart-v1','method':'built-in imagegen; reference-guided joined-space concept','model':'not exposed','references':p['references'],'prompts':['assets/source/xumen-seam-keyart-v1/prompts.json'],'generation':p['generation']},'qa':{'scope':'概念文件、六边合同与图册；非引擎验证','report':'assets/source/xumen-seam-keyart-v1/acceptance.md','userApproved':False}})
    if new:
        pos=raw.rfind('\n  ]');assert pos>0
        add=',\n'+',\n'.join('\n'.join('    '+s for s in json.dumps(a,ensure_ascii=False,indent=2).splitlines()) for a in new)
        raw=raw[:pos]+add+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {c["revision"]+1}',raw,count=1)
        json.loads(raw);cat.write_bytes(raw.encode('utf-8'))
    for ref in load(SRC/'reference-manifest.json')['files']:
        assert hashlib.sha256((ROOT/ref['file']).read_bytes()).hexdigest()==ref['sha256']
    layout=load(ROOT/'assets/source/xumen-keyart-v2/inputs/runtime-layout.json')
    for b,n in zip(d['edges'],[1,1,1,1,10,12]):
        assert len(b['existingSurfaces'])==n,(b['id'],len(b['existingSurfaces']))
        assert all(s in layout['surfaces'] for s in b['existingSurfaces'])
    result={'passed':True,'newArt':6,'referenceImages':7,'edges':6,'existingCollisionInstances':26,'registered':len(new),'runtimeChanged':False}
    (SRC/'review').mkdir(exist_ok=True)
    (SRC/'review/data-results.json').write_bytes((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print(json.dumps(result))

if __name__=='__main__':main()
