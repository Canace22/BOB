from pathlib import Path
from PIL import Image
import json,hashlib,re
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=SRC/'images/E01-glow-coral.png';w,h=Image.open(p).size;job=json.loads((SRC/'generation.json').read_text(encoding='utf-8'));feature=next(f for f in json.loads((SRC.parent/'xumen-ecology-niches-v1/design.json').read_text(encoding='utf-8'))['features'] if f['id']=='G01-ROOT')
    manifest={'file':'images/E01-glow-coral.png','width':w,'height':h,'sha256':sha(p),'source':'inputs/E01-before.png','sourceSha256':sha(SRC/'inputs/E01-before.png'),'annotationSha256':sha(SRC/'inputs/user-markup.png'),'feature':feature,'runtimeChanged':False,'status':'needs-review','userApproved':False}
    (SRC/'manifest.json').write_bytes((json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    catalog=ROOT/'assets/catalog.json';raw=catalog.read_text(encoding='utf-8');data=json.loads(raw);aid='xumen-root-glow-v1-e01'
    if any(a['id']==aid for a in data['assets']):return
    entry={'id':aid,'name':'骨根琥珀灯蕊珊瑚','kind':'environment-concept','region':'R1 须门遗港','tags':['发光珊瑚','实心骨根','非交互装饰','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-root-glow-v1/images/E01-glow-coral.png','width':w,'height':h,'sha256':sha(p),'notes':'替换用户圈中的低位壳洞，删除椭圆门框与低位红绳，实心骨根附着暖光珊瑚；上方圆形开口、三层平台、角色与主路保留。纯原画光色。','source':{'batchId':'xumen-root-glow-v1','method':'built-in imagegen; one local masked object replacement','model':'not exposed','references':['assets/source/xumen-root-glow-v1/inputs/E01-before.png'],'prompts':['assets/source/xumen-root-glow-v1/generation.json'],'generation':re.search(r'exec-[a-f0-9-]+',job['outputHint'])[0]},'qa':{'scope':'实际图册单区域像素差异与视觉检查；非Godot验收','report':'assets/source/xumen-root-glow-v1/acceptance.md','userApproved':False}}
    pos=raw.rfind('\n  ]');assert pos>0;raw=raw[:pos]+',\n'+'\n'.join('    '+l for l in json.dumps(entry,ensure_ascii=False,indent=2).splitlines())+raw[pos:];raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1);catalog.write_bytes(raw.encode('utf-8'))
if __name__=='__main__':main()
