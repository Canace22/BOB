"""Register eight concept paintings without changing any runtime manifest."""
from pathlib import Path
from PIL import Image
import hashlib,json,re

SRC=Path(__file__).resolve().parent; ROOT=SRC.parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def main():
    d=json.loads((SRC/'design.json').read_text(encoding='utf-8'))
    jobs=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
    entries=[];arts=[]
    for ident,name in [(r['id'],r['name']) for r in d['rooms']]+[('enemy-lanternfin','逆流灯鳍动作概念板')]:
        p=SRC/'images'/f'{ident}.png'; w,h=Image.open(p).size
        jobid='enemy' if ident=='enemy-lanternfin' else 'R1-02-fix' if ident=='R1-02' else ident
        job=next(j for j in jobs if j['id']==jobid)
        generation=re.search(r'exec-[a-f0-9-]+',job['outputHint'])[0]
        a={'id':ident,'file':p.relative_to(SRC).as_posix(),'width':w,'height':h,'sha256':sha(p),'generation':generation,'references':job['references'],'status':'needs-review','runtimeIntegrated':False,'userApproved':False}
        arts.append(a)
        entries.append({'id':'xumen-challenge-v1-'+ident.lower(),'name':name+' · 进阶跳跃候选' if ident!='enemy-lanternfin' else name,'kind':'enemy-concept' if ident=='enemy-lanternfin' else 'environment-concept','region':'R1 须门遗港','tags':['跳跃挑战','原画设计','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':p.relative_to(ROOT).as_posix(),'width':w,'height':h,'sha256':sha(p),'notes':'七房六边保留；房内地形获本轮授权重设计。概念画与候选坐标不等于碰撞或动画。','source':{'batchId':'xumen-challenge-v1','method':'built-in imagegen; referenced scene redesign','model':'not exposed','references':['assets/source/xumen-challenge-v1/'+x for x in job['references']],'prompts':['assets/source/xumen-challenge-v1/generation.json'],'generation':generation},'qa':{'scope':'静态原画与图册浏览器；非Godot验收','report':'assets/source/xumen-challenge-v1/acceptance.md','userApproved':False}})
    save(SRC/'art-manifest.json',{'scope':'concept only','paintings':8,'generationCalls':9,'images':arts})
    save(SRC/'input-manifest.json',[{'file':p.relative_to(SRC).as_posix(),'sha256':sha(p)} for p in sorted((SRC/'inputs').iterdir()) if p.is_file()])
    cp=ROOT/'assets/catalog.json';raw=cp.read_text(encoding='utf-8');data=json.loads(raw)
    additions=[a for a in entries if not any(old['id']==a['id'] for old in data['assets'])]
    if additions:
        pos=raw.rfind('\n  ]');assert pos>0
        raw=raw[:pos]+''.join(',\n'+'\n'.join('    '+line for line in json.dumps(a,ensure_ascii=False,indent=2).splitlines()) for a in additions)+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1);cp.write_bytes(raw.encode('utf-8'))
    assembly=ROOT/'assets/source/xumen-reference-panorama-v2/assembly.json'
    a=json.loads(assembly.read_text(encoding='utf-8'));a['challengeProposal']={'source':'../xumen-challenge-v1/design.json','paintings':7,'enemySheet':'../xumen-challenge-v1/images/enemy-lanternfin.png','defaultVisible':True,'originalSourcesUnchanged':True,'roomOriginsUnchanged':True,'edgesUnchanged':True,'status':'static concept, not runtime collision or AI'};save(assembly,a)
    print(f'Registered 8 concept images; appended {len(additions)} catalog entries.')
if __name__=='__main__':main()
