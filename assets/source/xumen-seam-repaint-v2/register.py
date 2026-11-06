"""Register conceptual repaint sources; no runtime resources are changed."""
from pathlib import Path
import json,hashlib,re
from PIL import Image
SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    specs=read(SRC/'specs.json');jobs={r['id']:r for r in read(SRC/'generation.json')}
    art=[];inputs=[]
    for s in specs:
        f=SRC/'images'/f'{s["id"]}.png';w,h=Image.open(f).size
        art.append({**s,'file':f'images/{s["id"]}.png','width':w,'height':h,'sha256':sha(f),'generation':re.search(r'exec-[0-9a-f-]+',jobs[s['id']]['outputHint'])[0],'status':'needs-review','runtimeIntegrated':False,'sourceRoomsLocked':True,'borderPixelsOverlaid':True})
        p=SRC/'inputs'/f'{s["id"]}-before.png'
        inputs.append({'id':s['id'],'file':f'inputs/{p.name}','sha256':sha(p),'worldViewBox':s['context'],'role':'actual pre-repair browser composition; both adjacent rooms at their existing world coordinates'})
    (SRC/'art-manifest.json').write_bytes((json.dumps({'images':art,'runtimeChanged':False},ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    (SRC/'input-manifest.json').write_bytes((json.dumps(inputs,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    catalog=ROOT/'assets/catalog.json';raw=catalog.read_text(encoding='utf-8');data=json.loads(raw);known={a['id'] for a in data['assets']};new=[]
    for a in art:
        aid='xumen-seam-repaint-v2-'+a['id'].lower()
        if aid in known:continue
        new.append({'id':aid,'name':'须门接缝精修 · '+a['name'],'kind':'environment-concept','region':'R1 须门遗港','tags':['接口补绘','概念候选','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-seam-repaint-v2/'+a['file'],'width':a['width'],'height':a['height'],'sha256':a['sha256'],'notes':'基于实际两端房图局部补绘，SVG蒙版覆盖接口边缘；原房结构与源文件保留。静态图册已复核，非Godot验收，用户审美待反馈。','source':{'batchId':'xumen-seam-repaint-v2','method':'built-in imagegen contextual repaint + SVG overlap masks','model':'not exposed','references':['assets/source/xumen-seam-repaint-v2/inputs/'+a['id']+'-before.png'],'prompts':['assets/source/xumen-seam-repaint-v2/generation.json'],'generation':a['generation']},'qa':{'scope':'实际浏览器拼接、六处放大与切换；非引擎测试','report':'assets/source/xumen-seam-repaint-v2/acceptance.md','userApproved':False}})
    if new:
        pos=raw.rfind('\n  ]');assert pos>0
        raw=raw[:pos]+',\n'+',\n'.join('\n'.join('    '+line for line in json.dumps(x,ensure_ascii=False,indent=2).splitlines()) for x in new)+raw[pos:]
        raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1)
    catalog.write_bytes(raw.encode('utf-8'))
    print(json.dumps({'paintedSeams':len(art),'newCatalogEntries':len(new),'runtimeChanged':False}))
if __name__=='__main__':main()
