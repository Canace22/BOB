"""Independent local illustration edits with per-feature viewport and artwork."""
from pathlib import Path
import json
SRC=Path(__file__).resolve().parent
def design():return json.loads((SRC/'design.json').read_text(encoding='utf-8'))
def build():
    d=design()
    bits=['<g class="ecology-detail-layer"><defs><filter id="niche-soft" filterUnits="userSpaceOnUse" x="-640" y="-1880" width="11584" height="3520"><feGaussianBlur stdDeviation="5"/></filter>']
    for f in d['features']:
        x,y,w,h=f.get('context',d['context'])
        bits.append(f'<mask id="niche-{f["id"]}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><path d="{f["path"]}" style="fill:white;stroke:none" filter="url(#niche-soft)"/></mask>')
    bits.append('</defs>')
    for f in d['features']:
        x,y,w,h=f.get('context',d['context']);file=f.get('file',d['file'])
        bits.append(f'<image data-ecology-detail="{f["id"]}" href="../../../assets/source/xumen-ecology-niches-v1/{file}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid meet" mask="url(#niche-{f["id"]})"/>')
    bits.append('</g>');return ''.join(bits)
def controls():
    return '<div class="reference-tools"><button data-niche-compare aria-pressed="true">生态装饰：开（点击看修改前）</button><span class="polish-indicator">两处浅凹＋骨根发光珊瑚 · 低位主路贯通</span><a href="../../../assets/source/xumen-root-glow-v1/README.md">发光物替换与提示词</a></div>'
STYLE='.hide-niches .ecology-detail-layer{display:none}'
SCRIPT='''(()=>{const root=document.querySelector('#real-scene');if(!root)return;root.querySelector('[data-niche-compare]').addEventListener('click',e=>{root.classList.remove('hide-painted-seams','hide-polish');const hidden=root.classList.toggle('hide-niches');e.currentTarget.setAttribute('aria-pressed',String(!hidden));e.currentTarget.textContent=hidden?'生态装饰：关（点击看修改后）':'生态装饰：开（点击看修改前）';root.querySelector('[data-seam-compare]').setAttribute('aria-pressed','true');root.querySelector('[data-polish-compare]').setAttribute('aria-pressed','true');root.querySelector('[data-seam-compare]').textContent='接缝：精修后（点击对照原拼接）';root.querySelector('[data-polish-compare]').textContent='本轮结构精修：开（点击对照上一版）';});})();'''
