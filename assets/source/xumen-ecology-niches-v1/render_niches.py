"""Two small masked illustration edits; unchanged original layers remain below."""
from pathlib import Path
import json
SRC=Path(__file__).resolve().parent
def design():return json.loads((SRC/'design.json').read_text(encoding='utf-8'))
def build():
    d=design();x,y,w,h=d['context']
    bits=['<g class="ecology-detail-layer"><defs><filter id="niche-soft" filterUnits="userSpaceOnUse" x="3300" y="200" width="1400" height="600"><feGaussianBlur stdDeviation="5"/></filter>']
    for f in d['features']:
        bits.append(f'<mask id="niche-{f["id"]}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><path d="{f["path"]}" style="fill:white;stroke:none" filter="url(#niche-soft)"/></mask>')
    bits.append('</defs>')
    for f in d['features']:
        bits.append(f'<image data-ecology-detail="{f["id"]}" href="../../../assets/source/xumen-ecology-niches-v1/{d["file"]}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" mask="url(#niche-{f["id"]})"/>')
    bits.append('</g>');return ''.join(bits)
def controls():
    return '<div class="reference-tools"><button data-niche-compare aria-pressed="true">珊瑚浅窝：开（点击看修改前）</button><span class="polish-indicator">两处封闭浅凹 · 珊瑚／贴壁藤蔓 · 低位主路贯通</span><a href="../../../assets/source/xumen-ecology-niches-v1/README.md">本批原件与提示词</a></div>'
STYLE='.hide-niches .ecology-detail-layer{display:none}'
SCRIPT='''(()=>{const root=document.querySelector('#real-scene');if(!root)return;root.querySelector('[data-niche-compare]').addEventListener('click',e=>{root.classList.remove('hide-painted-seams','hide-polish');const hidden=root.classList.toggle('hide-niches');e.currentTarget.setAttribute('aria-pressed',String(!hidden));e.currentTarget.textContent=hidden?'珊瑚浅窝：关（点击看修改后）':'珊瑚浅窝：开（点击看修改前）';root.querySelector('[data-seam-compare]').setAttribute('aria-pressed','true');root.querySelector('[data-polish-compare]').setAttribute('aria-pressed','true');root.querySelector('[data-seam-compare]').textContent='接缝：精修后（点击对照原拼接）';root.querySelector('[data-polish-compare]').textContent='本轮结构精修：开（点击对照上一版）';});})();'''
