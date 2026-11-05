"""Display the painted chapter as a single panorama; annotations are optional."""
from pathlib import Path
from html import escape as e
import json, hashlib
from PIL import Image
SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def build():
    m=read(SRC/'generation.json');f=SRC/m['output']
    with Image.open(f) as im:
        im.verify()
    with Image.open(f) as im:w,h=im.size
    entry={'id':'xumen-real-scene-v1-panorama','file':'assets/source/xumen-real-scene-v1/'+m['output'],'width':w,'height':h,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'generation':m['generation'],'type':'painted environment concept','runtimeIntegrated':False,'userArtReview':'pending'}
    save(SRC/'art-manifest.json',entry)
    base='../../../assets/source/xumen-real-scene-v1/'
    roomtags=[('R1-01','外伤坡',9,84),('R1-02','须筛',29,85),('R1-03','舌台',49,85),('R1-04','负壳蟹',71,85),('R1-05','流膜育窝',91,84),('R1-06','喷气孔上层',29,11),('R1-07','鲸须记忆袋',49,16)]
    edgetags=[('E01','颌骨斜拱',18,72),('E02','骨膜渐变',39,72),('E03','蟹前室转折',61,71),('E04','胜利软帘',80,72),('E33','浮膜旧伤上行',22,43),('E35','锚定须根上行',37,48)]
    tags=''.join(f'<a class="scene-tag room-tag" href="#{rid}" data-scene-room="{rid}" style="left:{x}%;top:{y}%">{rid} {e(name)}</a>' for rid,name,x,y in roomtags)
    tags+=''.join(f'<a class="scene-tag edge-tag" href="#{eid}" data-scene-edge="{eid}" style="left:{x}%;top:{y}%">{eid} {e(name)}</a>' for eid,name,x,y in edgetags)
    html=f'''<section id="real-scene"><span class="eyebrow">PAINTED WORLD PANORAMA / XUMEN LOST HARBOR</span><h2>总布局 · 实景样式</h2><p class="lead">把整关画成同一片空间：低处沿颌骨与舌背向右深入，高处两条回访线分别进入鼻道和须根侧袋。</p><div class="real-scene-tools"><button data-scene-action="fit">完整全景</button><button data-scene-action="zoom">放大查看</button><button data-scene-action="rooms" aria-pressed="false">房间注记</button><button data-scene-action="edges" aria-pressed="false">连接注记</button><a href="{base}{e(m['output'])}" target="_blank">打开原尺寸图 ↗</a></div><div class="real-scene-scroll"><div class="real-scene-canvas"><img class="real-scene-image" src="{base}{e(m['output'])}" alt="须门遗港七房六边连续实景风格全景原画" width="{w}" height="{h}" loading="eager">{tags}</div></div><p class="scene-caption">默认展示无注记原画。放大后可在图内横向滚动；注记可点击查看对应房间或连接原画。</p><div class="grid"><div><h3>画面里的连续关系</h3><p>左侧创伤口与暖光营地 → 下颌须筛 → 厚舌背与承重膜 → 舌根前室与首领 → 软帘后的咽褶和育窝。颌骨、路面与水体在区域间延续，前景与中远景统一绘制。</p></div><div><h3>上下两层</h3><p>须筛左侧沿旧伤绕硬腭上行到鼻道；右侧沿固定环抵达须根记忆袋。上层两处保持独立，首领下方无通行绕路，咽后不继续铺鲸须。</p></div></div><p class="notice">这是一张展示游戏场景整体观感的概念原画，尚未接入Godot。局部比例和落点需后续按工程校准，精确连通仍以七房六边及下方总布局图为准。</p><details><summary>本图制作、提示词与审核</summary><p><a href="{base}generation.json">实际英文提示词与生成记录</a> · <a href="{base}art-manifest.json">原图尺寸与哈希</a> · <a href="{base}acceptance.md">视觉审核与边界</a></p><pre>{e(m['prompt'])}</pre></details></section>'''
    return html
STYLE='''
.real-scene-tools{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin:18px 0}.real-scene-tools button[aria-pressed="true"]{border-color:#d5bb87}.real-scene-scroll{overflow:auto;border:1px solid #45616a;border-radius:6px;background:#07141c;overscroll-behavior-x:contain}.real-scene-canvas{position:relative;width:100%;min-width:0}.real-scene-image{width:100%;height:auto;display:block}.scene-tag{position:absolute;transform:translate(-50%,-50%);padding:3px 8px;background:#071b25ed;border:1px solid #afbdad88;border-radius:4px;font-size:clamp(8px,1vw,14px);white-space:nowrap;color:#f1dcc0;display:none}.edge-tag{color:#9bd2dc}.show-scene-rooms .room-tag,.show-scene-edges .edge-tag{display:block}.scene-caption{color:var(--muted);font-size:13px}@media(max-width:800px){.scene-tag{padding:1px 3px}.real-scene-tools{gap:8px;font-size:13px}}
'''
SCRIPT='''(()=>{const root=document.querySelector('#real-scene');if(!root)return;const canvas=root.querySelector('.real-scene-canvas');root.querySelectorAll('[data-scene-action]').forEach(button=>button.addEventListener('click',()=>{const a=button.dataset.sceneAction;if(a==='fit'||a==='zoom'){canvas.style.width=a==='fit'?'100%':'240%';if(a==='fit')root.querySelector('.real-scene-scroll').scrollLeft=0;return}const enabled=root.classList.toggle(a==='rooms'?'show-scene-rooms':'show-scene-edges');button.setAttribute('aria-pressed',String(enabled))}));})();'''
