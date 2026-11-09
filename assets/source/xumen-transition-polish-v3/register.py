"""Record four new paintings and two reused contour passes. No runtime edits."""
from pathlib import Path
import json,hashlib,re
from PIL import Image
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    specs=read(SRC/'specs.json');jobs={x['id']:x for x in read(SRC/'generation.json')};art=[]
    for s in specs:
        file=s.get('file',f'images/{s["id"]}.png');p=SRC/file;w,h=Image.open(p).size
        job=jobs.get('E02-fix' if s['id']=='E02' else s['id'])
        art.append({**s,'file':file,'width':w,'height':h,'sha256':sha(p),'generation':re.search(r'exec-[a-f0-9-]+',job['outputHint'])[0] if job else None,'status':'needs-review','runtimeIntegrated':False,'userArtApproval':False})
    save(SRC/'art-manifest.json',{'paintings':4,'reusedPaintings':2,'imagegenCalls':5,'runtimeChanged':False,'images':art})
    save(SRC/'input-manifest.json',[{'file':str(p.relative_to(SRC)).replace('\\','/'),'width':Image.open(p).width,'height':Image.open(p).height,'sha256':sha(p),'role':'rejected extra crossbar candidate' if 'candidate' in p.name else 'actual frozen V2 browser composition'} for p in sorted((SRC/'inputs').glob('*.png'))])
    catalog=ROOT/'assets/catalog.json';raw=catalog.read_text(encoding='utf-8');data=json.loads(raw);known={a['id'] for a in data['assets']};new=[]
    for a in art:
        if a['kind']!='new-paint':continue
        aid='xumen-transition-polish-v3-'+a['id'].lower()
        if aid in known:continue
        new.append({'id':aid,'name':'须门过渡结构精修 · '+a['name'],'kind':'environment-concept','region':'R1 须门遗港','tags':['局部结构补绘','概念候选','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-transition-polish-v3/'+a['file'],'width':a['width'],'height':a['height'],'sha256':a['sha256'],'notes':'仅在接口或非可玩结构带显示，核心七房源图保留；静态组合审核，非Godot验收。','source':{'batchId':'xumen-transition-polish-v3','method':'built-in imagegen local repaint; contour-constrained overlay','model':'not exposed','references':['assets/source/xumen-transition-polish-v3/inputs/'+a['id']+'-v2.png'],'prompts':['assets/source/xumen-transition-polish-v3/generation.json'],'generation':a['generation']},'qa':{'scope':'静态浏览器构图与版本切换；引擎未测试','report':'assets/source/xumen-transition-polish-v3/acceptance.md','userApproved':False}})
    if new:
        pos=raw.rfind('\n  ]');assert pos>0
        raw=raw[:pos]+',\n'+',\n'.join('\n'.join('    '+l for l in json.dumps(x,ensure_ascii=False,indent=2).splitlines()) for x in new)+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1);catalog.write_bytes(raw.encode('utf-8'))
    print(json.dumps({'newPaintings':4,'reused':2,'catalogAdded':len(new)}))
if __name__=='__main__':main()
