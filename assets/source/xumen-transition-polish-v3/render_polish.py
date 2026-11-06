"""Contour-constrained structural repaint. Static concepts, not runtime terrain."""
from pathlib import Path
import json
SRC=Path(__file__).resolve().parent
def specs():return json.loads((SRC/'specs.json').read_text(encoding='utf-8'))
def build():
    bits=['<g class="polished-seam-layer"><defs><filter id="polish-soft" filterUnits="userSpaceOnUse" x="-640" y="-1880" width="11584" height="3520"><feGaussianBlur stdDeviation="10"/></filter>']
    for s in specs():
        x,y,w,h=s['context'];sid=s['id']
        bits.append(f'<mask id="polish-{sid}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><g filter="url(#polish-soft)">')
        bits.extend(f'<path d="{d}" style="fill:white;stroke:none"/>' for d in s['paths'])
        bits.append('</g></mask>')
    bits.append('</defs>')
    for s in specs():
        x,y,w,h=s['context'];sid=s['id'];file=s.get('file',f'images/{sid}.png')
        assert (SRC/file).exists(),f'Missing paint: {sid}'
        bits.append(f'<image data-polish-edge="{sid}" data-polish-kind="{s["kind"]}" href="../../../assets/source/xumen-transition-polish-v3/{file}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" mask="url(#polish-{sid})"/>')
    import sys
    sys.path.insert(0,str(SRC.parent/'xumen-ecology-niches-v1'))
    from render_niches import build as build_niches
    bits.append(build_niches())
    bits.append('</g>');return ''.join(bits)

def controls():
    from render_niches import controls as niche_controls
    return '<div class="reference-tools"><button data-polish-compare aria-pressed="true">本轮结构精修：开（点击对照上一版）</button><span class="polish-indicator">本轮：实接骨梁／封闭承重带／随形收边</span></div><p class="polish-note">两处上下层间的矩形空白补成封闭骨壁，四个关键交汇补绘，另两处沿原拱口收边；没有新增可走房间或捷径。原图文件完整保留。<a href="../../../assets/source/xumen-transition-polish-v3/README.md">本轮原件、提示词与审核</a></p>'+niche_controls()

STYLE='''
.hide-painted-seams .polished-seam-layer,.hide-polish .polished-seam-layer{display:none}.polish-note,.polish-indicator{font-size:14px;color:#c8b99d}
'''
SCRIPT='''(()=>{const root=document.querySelector('#real-scene');if(!root)return;root.querySelector('[data-polish-compare]').addEventListener('click',e=>{root.classList.remove('hide-painted-seams');const previous=root.classList.toggle('hide-polish');e.currentTarget.setAttribute('aria-pressed',String(!previous));e.currentTarget.textContent=previous?'本轮结构精修：关（点击回到本轮）':'本轮结构精修：开（点击对照上一版）';const original=root.querySelector('[data-seam-compare]');original.setAttribute('aria-pressed','true');original.textContent='接缝：精修后（点击对照原拼接）';});})();'''
