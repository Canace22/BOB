"""Painted challenge proposal and optional coordinate guide; never runtime collision."""
from pathlib import Path
from html import escape as e
import json
SRC=Path(__file__).resolve().parent;ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def build():
    d=read(SRC/'design.json');layout=read(ROOT/'assets/source/xumen-reference-panorama-v2/assembly.json')['rooms'];rooms={r['id']:r for r in layout};eco=read(ROOT/'assets/source/xumen-ecology-niches-v1/design.json')['features']
    bits=['<g class="challenge-layer"><defs>']
    for r in d['rooms']:
        old=rooms[r['id']];x,y=old['worldOrigin'];w,h=old['intrinsicSize'];left=400 if r['id']=='R1-01' else 115
        bits.append(f'<linearGradient id="ch-x-{r["id"]}"><stop offset="0" stop-color="black"/><stop offset="0.035" stop-color="white"/><stop offset="0.965" stop-color="white"/><stop offset="1" stop-color="black"/></linearGradient>')
        bits.append(f'<mask id="ch-{r["id"]}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{w}" height="{h}"><rect x="{x+left}" y="{y+65}" width="{w-left-80}" height="{h-110}" rx="28" style="fill:url(#ch-x-{r["id"]});stroke:none"/>')
        for f in eco:bits.append(f'<path d="{f["path"]}" style="fill:black;stroke:black;stroke-width:22"/>')
        bits.append('</mask>')
    bits.append('</defs>')
    for r in d['rooms']:
        old=rooms[r['id']];x,y=old['worldOrigin'];w,h=old['intrinsicSize'];assert (SRC/r['image']).exists()
        bits.append(f'<image data-challenge-room="{r["id"]}" href="../../../assets/source/xumen-challenge-v1/{r["image"]}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" mask="url(#ch-{r["id"]})"/>')
    bits.append('<g class="challenge-route-guide">')
    for r in d['rooms']:
        x,y=rooms[r['id']]['worldOrigin'];land=r['landings']
        bits.append(f'<g transform="translate({x} {y})">')
        for i,(l,rr,yy) in enumerate(land):
            bits.append(f'<line x1="{l}" y1="{yy}" x2="{rr}" y2="{yy}" style="stroke:#a7eff0;stroke-width:7"/><text x="{(l+rr)/2}" y="{yy+35}" style="font-size:26px;fill:#d8ffff">P{i}</text>')
        for i in range(len(land)-1):
            a,b=land[i],land[i+1];sx=a[1]-14;ex=b[0]+14;peak=min(a[2],b[2])-115
            bits.append(f'<path data-jump-segment="{r["id"]}-{i}" d="M {sx} {a[2]} Q {(sx+ex)/2} {peak} {ex} {b[2]}" style="fill:none;stroke:#e6bf77;stroke-width:5;stroke-dasharray:12 8"/>')
        for i,(fx,fy) in enumerate(r['flies']):bits.append(f'<ellipse data-planned-fly="{r["flyIds"][i]}" cx="{fx}" cy="{fy}" rx="65" ry="36" style="fill:#cf7c4c22;stroke:#eaa97a;stroke-width:4"/>')
        bits.append('</g>')
    bits.append('</g></g>');return ''.join(bits)

def controls():
    return '<div class="notice challenge-notice"><strong>新增：七房跳跃挑战＋低伤害飞怪（设计方案，未接入游戏）</strong><p>断台、高低落点、短跳限高、跳冲与四环释放；新增一种逆流灯鳍，共拟定8只。保留七房六边、原生态装饰与旧版对照。图中小怪为设计表现，伤害和AI尚未运行。</p><div class="reference-tools"><button data-challenge-toggle aria-pressed="true">进阶地形：开（点击看原方案）</button><button data-challenge-guide aria-pressed="false">显示候选落点／跳线</button><a href="#challenge-design">逐房玩法与飞怪规格 ↓</a></div><small>落点线是候选制作坐标；绘景不是碰撞图。当前只通过解析筛查和静态审核，难度平衡需Godot试玩。</small></div>'

def section():
    d=read(SRC/'design.json');base='../../../assets/source/xumen-challenge-v1/'
    cards=''
    for r in d['rooms']:
        gaps=[max(0,b[0]-a[1]) for a,b in zip(r['landings'],r['landings'][1:])]
        stats=' / '.join(map(str,gaps))
        cards+=f'<article class="challenge-card" id="challenge-{r["id"]}"><h3>{r["id"]} {e(r["name"])} · 难度 {r["difficulty"]}/5</h3><a href="{base}{r["image"]}" target="_blank"><img src="{base}{r["image"]}" alt="{e(r["name"])}进阶地形与飞怪设计" loading="lazy"></a><p><strong>{e(r["focus"])}</strong></p><p>{e(r["route"])}</p><p>候选间距：{stats}px；飞怪：{len(r["flies"])}只。{e(r["enemyRule"])}</p><p>回收：{e(r["catch"])}。</p><p>保留：{e(r["preserve"])}。</p><small>{e(r["gate"])}</small></article>'
    return f'''<div id="challenge-design" class="challenge-details"><h2>逐房进阶玩法与小怪设计</h2><p>本轮授权改变房内地形，原版保留供切换；首段安全、首次飞怪可预判、复杂跳跃后有宽台停顿。原六条跨房连接不新增也不删除。</p><div class="challenge-grid">{cards}</div><article class="challenge-enemy"><h3>逆流灯鳍 · 飞行小怪</h3><img src="{base}images/enemy-lanternfin.png" alt="逆流灯鳍造型、巡航、预告、横掠与恢复概念板" loading="lazy"><p>当前整数生命制为5HP，飞掠伤害1HP，2次短击或1次叉鸣弹可处理；不增加伤害型远景鱼。小体型、低击退、同屏最多2只，最多1只攻击。</p><p>巡航（不伤害）→收鳍＋喉光预告0.65秒→固定走廊横掠0.55秒→展鳍恢复0.75秒→冷却2.8秒。攻击期间不追踪改线；平台边缘、锚定释放和首次落地设保护窗口。</p><p>拟定巡航48px/s，横掠160px/s，击退位移不超过24px，受伤无敌沿现有1.2秒。跌至回收面不应叠加同次环境扣血；这与当前软床规则存在差异，需工程阶段统一，尚未实现。</p><p>动作制作首选：身体与柔性双鳍分层、固定鳍根并逐段弯曲，再独立驱动巡航/横掠路径；备选Krita关键帧。此板只有动作设计姿态，不是已完成动画。</p></article><p><a href="{base}design.json">坐标与敌人参数</a> · <a href="{base}generation.json">英文绘图提示词</a> · <a href="{base}acceptance.md">检查与未完成项</a></p></div>'''

STYLE='''
.hide-challenge .challenge-layer,.hide-polish .challenge-layer,.hide-painted-seams .challenge-layer{display:none}.challenge-route-guide{display:none}.show-challenge-guide .challenge-route-guide{display:inline}.challenge-notice{border-color:#8dc1b0}.challenge-notice p{margin:8px 0}.challenge-grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.challenge-card,.challenge-enemy{padding:18px;background:#102630;border:1px solid #31505a;border-radius:6px}.challenge-card p{margin:10px 0}.challenge-details{margin:50px 0}.challenge-enemy{margin-top:26px}.challenge-enemy img{max-width:1100px;margin:auto}@media(max-width:800px){.challenge-grid{grid-template-columns:1fr}}
'''
SCRIPT='''(()=>{
const root=document.querySelector('#real-scene');if(!root)return;
const button=root.querySelector('[data-challenge-toggle]');
const hidden=()=>['hide-challenge','hide-polish','hide-painted-seams'].some(c=>root.classList.contains(c));
const sync=()=>{const active=!hidden();button.setAttribute('aria-pressed',String(active));button.textContent=active?'进阶地形：开（点击看原方案）':'进阶地形：关（点击看新方案）';};
button.addEventListener('click',()=>{
 const enable=hidden();root.classList.toggle('hide-challenge',!enable);
 if(enable){root.classList.remove('hide-polish','hide-painted-seams');const polish=root.querySelector('[data-polish-compare]'),seam=root.querySelector('[data-seam-compare]');polish.setAttribute('aria-pressed','true');polish.textContent='本轮结构精修：开（点击对照上一版）';seam.setAttribute('aria-pressed','true');seam.textContent='接缝：精修后（点击对照原拼接）';}
 sync();
});
new MutationObserver(sync).observe(root,{attributes:true,attributeFilter:['class']});sync();
root.querySelector('[data-challenge-guide]').addEventListener('click',e=>{const show=root.classList.toggle('show-challenge-guide');e.currentTarget.setAttribute('aria-pressed',String(show));e.currentTarget.textContent=show?'隐藏候选落点／跳线':'显示候选落点／跳线';});
})();'''
