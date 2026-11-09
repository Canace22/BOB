from pathlib import Path
from PIL import Image
import json,hashlib,re
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[2]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def main():
    art=SRC/'images/E02-coral-niches.png';w,h=Image.open(art).size;job=json.loads((SRC/'generation.json').read_text(encoding='utf-8'))
    save(SRC/'manifest.json',{'file':'images/E02-coral-niches.png','width':w,'height':h,'sha256':sha(art),'source':'inputs/E02-before.png','sourceSha256':sha(SRC/'inputs/E02-before.png'),'userMarkupSha256':sha(SRC/'inputs/user-markup.png'),'overlays':2,'newPaintings':1,'runtimeChanged':False,'status':'needs-review','userApproved':False})
    catalog=ROOT/'assets/catalog.json';raw=catalog.read_text(encoding='utf-8');data=json.loads(raw);aid='xumen-ecology-niches-v1-e02'
    if any(a['id']==aid for a in data['assets']):return
    entry={'id':aid,'name':'须筛接续 · 珊瑚与藤蔓浅窝','kind':'environment-concept','region':'R1 须门遗港','tags':['珊瑚','海生藤蔓','浅凹装饰','未接入'],'target':'2d','status':'needs-review','integrationStatus':'not-integrated','userArtApproval':False,'file':'assets/source/xumen-ecology-niches-v1/images/E02-coral-niches.png','width':w,'height':h,'sha256':sha(art),'notes':'两处低位门状洞口变为封闭浅凹，珊瑚和贴壁藤蔓，右侧克制暖光；只在两块局部蒙版显示，非新增门、营地或可交互地点。','source':{'batchId':'xumen-ecology-niches-v1','method':'built-in imagegen local edit; two local SVG masks','model':'not exposed','references':['assets/source/xumen-ecology-niches-v1/inputs/E02-before.png'],'prompts':['assets/source/xumen-ecology-niches-v1/generation.json'],'generation':re.search(r'exec-[a-f0-9-]+',job['outputHint'])[0]},'qa':{'scope':'实际图册局部和像素差异；非Godot验收','report':'assets/source/xumen-ecology-niches-v1/acceptance.md','userApproved':False}}
    pos=raw.rfind('\n  ]');assert pos>0;raw=raw[:pos]+',\n'+'\n'.join('    '+l for l in json.dumps(entry,ensure_ascii=False,indent=2).splitlines())+raw[pos:];raw=re.sub(r'"revision": \d+',f'"revision": {data["revision"]+1}',raw,count=1);catalog.write_bytes(raw.encode('utf-8'))
if __name__=='__main__':main()
