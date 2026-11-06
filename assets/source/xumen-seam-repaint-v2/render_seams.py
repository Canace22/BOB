"""Place painted contextual seam crops with editable SVG overlap masks."""
from pathlib import Path
import json
SRC=Path(__file__).resolve().parent

def build():
    specs=json.loads((SRC/'specs.json').read_text(encoding='utf-8'))
    bits=['<g class="painted-seam-layer"><defs>']
    available=[]
    for s in specs:
        f=SRC/'images'/f'{s["id"]}.png'
        if not f.exists():continue
        available.append(s)
        sid=s['id'];x,y,w,h=s['patch'];fx=80/w;fy=70/h
        bits.append(f'<linearGradient id="sx-{sid}"><stop offset="0" stop-color="black"/><stop offset="{fx}" stop-color="white"/><stop offset="{1-fx}" stop-color="white"/><stop offset="1" stop-color="black"/></linearGradient>')
        bits.append(f'<linearGradient id="sy-{sid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="black"/><stop offset="{fy}" stop-color="white"/><stop offset="{1-fy}" stop-color="white"/><stop offset="1" stop-color="black"/></linearGradient>')
        bits.append(f'<mask id="my-{sid}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><rect x="{x}" y="{y}" width="{w}" height="{h}" style="fill:url(#sy-{sid});stroke:none"/></mask>')
        bits.append(f'<mask id="seam-{sid}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><rect x="{x}" y="{y}" width="{w}" height="{h}" style="fill:url(#sx-{sid});stroke:none" mask="url(#my-{sid})"/></mask>')
    bits.append('</defs>')
    for s in available:
        sid=s['id'];x,y,w,h=s['context']
        bits.append(f'<image data-repaint-edge="{sid}" href="../../../assets/source/xumen-seam-repaint-v2/images/{sid}.png" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" mask="url(#seam-{sid})"/>')
    bits.append('</g>')
    return ''.join(bits)

def controls():
    specs=json.loads((SRC/'specs.json').read_text(encoding='utf-8'))
    buttons=''.join(f'<button data-seam-focus="{s["id"]}">{s["id"]} {s["name"]}</button>' for s in specs)
    data=json.dumps(specs,ensure_ascii=False)
    return f'<div class="reference-tools"><button data-seam-compare aria-pressed="true">接缝：精修后（点击对照原拼接）</button></div><div class="reference-focus-tools seam-focus-tools">{buttons}</div><script type="application/json" class="seam-focus-data">{data}</script>'

def notes():
    return '<p class="notice">六条接缝已按左右／上下房图局部重绘：主路连续缓坡、骨拱和膜拱，上行支路连接原落脚台。原房源文件完整保留，仅接口边缘由补绘层覆盖。可点击六个连接按钮放大，或切换精修前后。当前为设计图册中的静态接续评审，未修改Godot关卡；100%放大仍可评审局部笔触与边缘。<br><a href="../../../assets/source/xumen-seam-repaint-v2/generation.json">本批英文提示词</a> · <a href="../../../assets/source/xumen-seam-repaint-v2/art-manifest.json">六处补绘原件与坐标</a> · <a href="../../../assets/source/xumen-seam-repaint-v2/acceptance.md">静态审核与限制</a></p>'

STYLE='''
.hide-painted-seams .painted-seam-layer{display:none}.seam-focus-tools button{border-color:#786849;color:#e4cf9d}
'''
SCRIPT='''(()=>{
const root=document.querySelector('#real-scene');if(!root)return;
const data=JSON.parse(root.querySelector('.seam-focus-data').textContent);
root.querySelector('[data-seam-compare]').addEventListener('click',e=>{const hidden=root.classList.toggle('hide-painted-seams');e.currentTarget.setAttribute('aria-pressed',String(!hidden));e.currentTarget.textContent=hidden?'接缝：原拼接（点击查看精修）':'接缝：精修后（点击对照原拼接）';});
root.querySelectorAll('[data-seam-focus]').forEach(button=>button.addEventListener('click',()=>{const s=data.find(s=>s.id===button.dataset.seamFocus);const [x,y,w,h]=s.context;const scroller=root.querySelector('.reference-scroll'),canvas=root.querySelector('.reference-canvas');const width=Math.max(6000,scroller.clientWidth/w*11584*.9);canvas.style.width=width+'px';requestAnimationFrame(()=>{const scale=width/11584;scroller.scrollLeft=(x+640)*scale-20;scroller.scrollTop=(y+1880)*scale-20;scroller.scrollIntoView({block:'center',behavior:'instant'});root.querySelector('.reference-status').textContent=s.id+' '+s.name+' · 局部接续精修';});}));
})();'''
