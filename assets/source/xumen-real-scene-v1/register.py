"""Register this concept; preserve LF and existing unrelated catalog entries."""
from pathlib import Path
import json,hashlib,re
SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def main():
    m=read(SRC/'art-manifest.json');gen=read(SRC/'generation.json')
    p=ROOT/'assets/catalog.json';raw=p.read_text(encoding='utf-8-sig');cat=json.loads(raw)
    reference_records=[]
    jobs=[read(SRC/'prompts/initial.json'),read(SRC/'prompts/refined.json'),read(SRC/'prompts/detail.json'),gen]
    for job in jobs:
        for ref in job['references']:
            f=(ROOT if ref['file'].startswith('assets/') else SRC)/ref['file']
            assert f.is_file(),f
            reference_records.append({'file':ref['file'],'role':ref['role'],'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
        assert (SRC/job['output']).is_file()
    (SRC/'reference-manifest.json').write_bytes((json.dumps({'files':reference_records,'sourceCommit':'727a48ac','rights':'用户指定原创IP与已交付素材，内置imagegen制作；旧图不冒充本批生成。'},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    assert hashlib.sha256((ROOT/m['file']).read_bytes()).hexdigest()==m['sha256']
    entry={'id':m['id'],'name':'须门遗港 · 总布局实景全景','kind':'environment-concept','region':'R1 须门遗港','tags':['连续实景原画','概念候选','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':m['file'],'width':m['width'],'height':m['height'],'sha256':m['sha256'],'notes':'七房六边的联合实景风格原画；不是Godot截图；精确碰撞仍以工程为准。','source':{'batchId':'xumen-real-scene-v1','method':'built-in imagegen; joint scene painting and targeted refinement','model':'not exposed','generation':m['generation'],'references':[r['file'] for r in jobs[0]['references']],'prompts':['assets/source/xumen-real-scene-v1/generation.json','assets/source/xumen-real-scene-v1/prompts/initial.json','assets/source/xumen-real-scene-v1/prompts/refined.json','assets/source/xumen-real-scene-v1/prompts/detail.json']},'qa':{'scope':'概念视觉与图册实际检查；无引擎验收','report':'assets/source/xumen-real-scene-v1/acceptance.md','userApproved':False}}
    added=False
    if not any(a['id']==m['id'] for a in cat['assets']):
        pos=raw.rfind('\n  ]');assert pos>0
        raw=raw[:pos]+',\n'+'\n'.join('    '+line for line in json.dumps(entry,ensure_ascii=False,indent=2).splitlines())+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {cat["revision"]+1}',raw,count=1)
        json.loads(raw);p.write_bytes(raw.encode('utf-8'));added=True
    print(json.dumps({'registered':added,'width':m['width'],'height':m['height'],'referenceRecords':len(reference_records),'runtimeChanged':False}))
if __name__=='__main__':main()
