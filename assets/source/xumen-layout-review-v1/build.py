"""Build a review atlas from authored layout data; never writes runtime resources."""
import json,html,math
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
PAGE=ROOT/'docs/鲸腹遗城原画集/须门遗港地图布局'
D=json.loads((HERE/'layout.json').read_text(encoding='utf-8'))
esc=lambda s:html.escape(str(s),quote=True)
COL={'main':'#f0ba69','optional':'#74c9ed','return':'#c29df4','catch':'#70c9a2'}

def section(r,standalone=True):
    rid=r['id']
    parts=[f'<defs><pattern id="grid-{rid}" width="100" height="100" patternUnits="userSpaceOnUse"><path d="M100 0H0V100" fill="none" stroke="#243c49" stroke-width="1"/></pattern>']
    for k,c in COL.items(): parts.append(f'<marker id="arrow-{rid}-{k}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M0 0L10 5L0 10Z" fill="{c}"/></marker>')
    parts.append(f'</defs><rect width="1600" height="1000" fill="#0b1c27"/><rect width="1600" height="1000" fill="url(#grid-{rid})"/>')
    for a in r['areas']:
        x,y,w,h=a['box']; k=a['kind']
        fill={'solid':'#817b65','wall':'#384c56','catch':'#264c42','membrane':'#6b4f61'}[k]
        stroke={'solid':'#d4cbb2','wall':'#708591','catch':'#70c9a2','membrane':'#daa0bd'}[k]
        dash=' stroke-dasharray="12 8"' if k=='catch' else ''
        parts.append(f'<rect class="area {k}" x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="{fill}" stroke="{stroke}" stroke-width="3"{dash}><title>{esc(a["name"])}</title></rect>')
        if k not in ['wall','catch']:
            parts.append(f'<path d="M{x+5} {y}H{x+w-5}" stroke="#e2d9c1" stroke-width="7"/>')
    # Dashed routes are diagrams of intended traversal, not verified ballistic arcs.
    for n,rt in enumerate(r['routes']):
        p=rt['points']; kind=rt['kind']; c=COL[kind]
        pts=' '.join(f'{x},{y-36}' for x,y in p)
        dash=' stroke-dasharray="16 10"' if kind!='main' else ''
        parts.append(f'<g class="route {kind}"><polyline points="{pts}" fill="none" stroke="#07131b" stroke-width="13" stroke-linejoin="round"/><polyline points="{pts}" fill="none" stroke="{c}" stroke-width="6" stroke-linejoin="round" marker-end="url(#arrow-{rid}-{kind})"{dash}><title>{esc(rt["name"])}</title></polyline>')
        if kind=='main':
            for i in range(5):
                x,y=p[round(i*(len(p)-1)/4)]
                parts.append(f'<circle cx="{x}" cy="{y-36}" r="17" fill="#0b1c27" stroke="{c}" stroke-width="3"/><text x="{x}" y="{y-30}" font-size="18" text-anchor="middle" fill="{c}">{i+1}</text>')
        parts.append('</g>')
    for m in r['markers']:
        x,y=m['at']; k=m['kind']; text=esc(m['text'])
        if k=='note':
            parts.append(f'<g class="note"><text x="{x}" y="{y}" text-anchor="middle" font-size="24" fill="#d7e4e6" paint-order="stroke" stroke="#0b1c27" stroke-width="7">{text}</text></g>')
        elif k=='ring':
            parts.append(f'<g class="marker ring"><circle cx="{x}" cy="{y}" r="20" fill="#0b1c27" stroke="#74c9ed" stroke-width="7"/><text x="{x}" y="{y-32}" text-anchor="middle" font-size="22" fill="#b7e6fa">{text}</text></g>')
        elif k in ['enemy','boss']:
            w=100 if k=='boss' else 50; hh=70 if k=='boss' else 38
            parts.append(f'<g class="marker {k}"><path d="M{x-w/2} {y-10}l10 -{hh}h{w-20}l10 {hh}Z" fill="#9b5360" stroke="#ffc0b3" stroke-width="3"/><text x="{x}" y="{y-hh-20}" text-anchor="middle" font-size="23" fill="#ffc0b3" paint-order="stroke" stroke="#0b1c27" stroke-width="6">{text}</text></g>')
        elif k=='reward':
            parts.append(f'<g class="marker reward"><path d="M{x} {y-65}l20 25 -20 25 -20 -25Z" fill="#edc978" stroke="#fff2c7" stroke-width="3"/><text x="{x}" y="{y-82}" text-anchor="middle" font-size="24" fill="#f6d68c" paint-order="stroke" stroke="#0b1c27" stroke-width="7">{text}</text></g>')
        else:
            c='#c29df4' if k=='locked' else '#70c9a2' if k=='camp' else '#e1d7be'
            parts.append(f'<g class="marker {k}"><path d="M{x-25} {y-5}v-62a25 25 0 0150 0v62Z" fill="#0b1c27" stroke="{c}" stroke-width="5"/><text x="{max(100,min(1490,x))}" y="{y-100}" text-anchor="middle" font-size="23" fill="{c}" paint-order="stroke" stroke="#0b1c27" stroke-width="7">{text}</text></g>')
    parts.append('<text x="20" y="35" font-size="18" fill="#9cb2bf">非比例布局剖面 · 路线箭头不代表跳跃轨迹</text>')
    body=''.join(parts)
    if not standalone:return body
    return '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" viewBox="0 0 1600 1000" role="img" aria-label="'+esc(r['title'])+'布局方案" style="font-family:Microsoft YaHei,Noto Sans CJK SC,sans-serif">'+body+'</svg>'

for r in D['rooms']:(HERE/'diagrams'/f"{r['id']}.svg").write_text(section(r),encoding='utf-8')

# The overview is a stable topology atlas, never an anatomical or seamless-world claim.
positions={'R1-01':(25,690),'R1-02':(465,690),'R1-03':(905,690),'R1-04':(1345,690),'R1-05':(1785,690),'R1-06':(245,120),'R1-07':(685,120)}
overview=['<svg xmlns="http://www.w3.org/2000/svg" width="2240" height="1160" viewBox="0 0 2240 1160" style="font-family:Microsoft YaHei,sans-serif"><rect width="2240" height="1160" fill="#081821"/><text x="30" y="48" fill="#f0ddba" font-size="30">须门遗港 V1 · 七房内部空间重排</text><text x="30" y="86" fill="#9bb4c1" font-size="21">七房六连接保持 · 拓扑排版非比例 · 局部剖面为方案，未接入引擎</text>']
for e in D['edges']:
    x1,y1=positions[e['a']];x2,y2=positions[e['b']]
    if y1==y2:
        p=f'M{x1+410} {y1+170}H{x2}'
        lx=(x1+410+x2)/2;ly=y1+145
    else:
        p=f'M{x1+205} {y1}V{y2+350+50}H{x2+205}V{y2+350}'
        lx=x2+205;ly=y2+395
    overview.append(f'<path d="{p}" fill="none" stroke="#6ba4b5" stroke-width="4"/>')
    if y1!=y2: overview.append(f'<text x="{lx}" y="{ly}" text-anchor="middle" fill="#9cb9c9" font-size="15">{esc(e["condition"])}</text>')
for r in D['rooms']:
    x,y=positions[r['id']]
    overview.append(f'<g transform="translate({x},{y})"><rect width="410" height="350" rx="12" fill="#102732" stroke="#47616e"/><text x="15" y="30" fill="#f0ddba" font-size="23">{r["id"]} {esc(r["title"])}</text><svg x="5" y="42" width="400" height="250" viewBox="0 0 1600 1000">{section(r,False)}</svg><text x="15" y="325" fill="#9cb9c9" font-size="16">{esc(r["idea"])}</text></g>')
overview.append('<text x="1820" y="1100" fill="#9cb9c9" font-size="23">R1-05 → 原胃枢连接保留</text><text x="30" y="1125" fill="#9cb9c9" font-size="21">金：主路　蓝：原能力 / 奖励支路　紫：自然返程　绿：失误回收（非捷径）　灰：刚性洞壁</text></svg>')
(HERE/'diagrams/overview.svg').write_text(''.join(overview),encoding='utf-8')

relative='../../../assets/source/xumen-layout-review-v1/'
roomhtml=[]
for r in D['rooms']:
    items=''.join(f'<li><b>{i+1:02}</b>{esc(s)}</li>' for i,s in enumerate(r['steps']))
    checks=''.join('<li>'+esc(s)+'</li>' for s in r['reviewChecks'])
    roomhtml.append(f'''<article class="room" id="{r['id']}" data-room="{r['id']}">
      <header class="roomhead"><span class="eyebrow">{r['id']} / 布局提案</span><h2>{esc(r['title'])}</h2><p class="idea">{esc(r['idea'])}</p><p>{esc(r['change'])}</p></header>
      <div class="compare"><figure><figcaption>当前工程 · 2026-11-14 GPU 全景</figcaption><img class="baseline" src="{relative}inputs/overview-{r['id']}.png" alt="{esc(r['title'])}当前工程全景" loading="lazy"></figure>
      <figure><figcaption>提案 V1 · 可审阅剖面 / 非比例 <button class="zoom" data-zoom="{r['id']}">放大布局 ↗</button></figcaption><div class="section">{section(r)}</div></figure></div>
      <div class="detail"><div><h3>顺着这条路看</h3><ol class="steps">{items}</ol></div><div><h3>本房重点复核</h3><ul>{checks}</ul><p class="small">保留：原门 {len(r['baselineDoors'])} 个 · {'原奖励' if r['rewardId'] else '无新增奖励'} · {'营地保留' if r['campRetained'] else '无新增营地'} · 原敌人数 {r['enemyCount']}</p></div></div>
      </article>''')
nav=''.join(f'<a href="#{r["id"]}">{r["id"][-2:]} {esc(r["title"])}</a>' for r in D['rooms'])
data=json.dumps(D,ensure_ascii=False).replace('</','<\\/')
page='''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 地图布局审阅 V1</title><style>
:root{color-scheme:dark;--bg:#091820;--panel:#112832;--line:#35525f;--ink:#e4e9e8;--muted:#a6bcc5;--gold:#efbd76}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:155px}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.7 "Microsoft YaHei","Noto Sans CJK SC",sans-serif}a{color:#a7d6e9;text-decoration:none}a:hover{text-decoration:underline}button{font:inherit;color:inherit;background:#193642;border:1px solid #52717f;border-radius:7px;padding:5px 11px;cursor:pointer}button:hover{border-color:var(--gold)}main{max-width:1540px;margin:auto;padding:36px 34px 80px}.eyebrow{color:var(--gold);letter-spacing:.13em;font-size:13px}h1{font-size:clamp(28px,3.2vw,48px);line-height:1.3;margin:14px 0}h2{font-size:28px;margin:4px 0}h3{font-size:17px;margin:0 0 10px}.lead{font-size:19px;color:#cad8dc;max-width:1100px}.facts{display:flex;flex-wrap:wrap;gap:10px}.facts span{border:1px solid var(--line);padding:5px 12px;border-radius:50px;color:#b9ccd2}.notice{border-left:3px solid var(--gold);padding:10px 18px;background:#172e35;color:#d8e1e3;margin:22px 0}.toolbar{position:sticky;top:0;z-index:5;background:#0a1c25f5;border-block:1px solid var(--line);padding:12px 0;backdrop-filter:blur(10px)}nav{display:flex;flex-wrap:wrap;gap:8px}nav a{border:1px solid #35525f;padding:4px 9px;border-radius:5px;font-size:14px}.toggles{display:flex;gap:18px;flex-wrap:wrap;font-size:14px;margin-top:10px;color:var(--muted)}label{cursor:pointer}input{accent-color:var(--gold)}.overview{margin:28px 0}.overview img{width:100%;display:block;border:1px solid var(--line);border-radius:10px}.legend{display:flex;flex-wrap:wrap;gap:16px;color:var(--muted);font-size:14px;margin:14px 0}.legend i{display:inline-block;width:25px;height:4px;vertical-align:middle;margin-right:5px;background:var(--c)}.room{border-top:1px solid var(--line);padding:34px 0;scroll-margin-top:160px}.roomhead>p{max-width:1120px;color:var(--muted);margin:8px 0}.roomhead .idea{color:#e6d5b7;font-size:20px}.compare{display:grid;grid-template-columns:1fr 1fr;gap:18px;margin:22px 0}figure{margin:0;min-width:0;border:1px solid var(--line);border-radius:9px;overflow:hidden;background:#0a1c26}figcaption{padding:8px 12px;color:#b8cbd2;font-size:13px;background:#17313b;display:flex;align-items:center;justify-content:space-between;gap:6px}.compare img{display:block;width:100%;aspect-ratio:1.6;object-fit:contain;background:#081720}.section{aspect-ratio:1.6;overflow:hidden}.section svg{width:100%;height:100%;display:block}.zoom{font-size:12px;padding:2px 7px;white-space:nowrap}.detail{display:grid;grid-template-columns:1fr 1fr;gap:30px}.detail ul{padding-left:22px;margin:0;color:var(--muted)}.steps{list-style:none;padding:0;margin:0;display:flex;gap:8px;flex-wrap:wrap}.steps li{background:#142f39;border:1px solid var(--line);border-radius:6px;padding:6px 10px;color:#cfdbdf;font-size:14px}.steps b{color:var(--gold);margin-right:8px;font-size:12px}.small{font-size:13px;color:var(--muted)}.boundaries{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin:24px 0}.boundaries>div{padding:18px;border:1px solid var(--line);border-radius:8px}.boundaries p{color:var(--muted);margin:0}body.hide-route .route{display:none}body.hide-marker .marker,body.hide-marker .note{display:none}body.hide-catch .route.catch,body.hide-catch .area.catch{display:none}dialog{width:min(1450px,96vw);max-height:94vh;overflow:auto;background:#0b1c27;color:var(--ink);border:1px solid #577481;border-radius:10px;padding:16px}dialog::backdrop{background:#000c}.dialoghead{display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:#0b1c27;z-index:1}.dialogmap svg{width:100%;height:auto;display:block}footer{border-top:1px solid var(--line);padding-top:24px;color:var(--muted)}@media(max-width:900px){main{padding:22px 16px 50px}.compare,.detail,.boundaries{grid-template-columns:1fr}.toolbar{position:static}html{scroll-padding-top:20px}.room{scroll-margin-top:20px}.lead{font-size:16px}.toggles{gap:10px}.detail{gap:20px}}
</style></head><body><main>
<span class="eyebrow">鲸腹遗城 / 须门遗港 / 2026.11.15 / REVIEW V1</span><h1>把七房变成值得辨认的空间</h1><p class="lead">沿用现有动作与战斗，用洞壁、错层、上下交叉、折返和局部回程改变走法。先审阅房内空间，再进入碰撞与美术制作。</p>
<div class="facts"><span>7 房 / 6 条原连接</span><span>原普通蟹 3 只 / Boss 1 场</span><span>能力与奖励语义保持</span><span>布局草案 · 未修改游戏</span></div>
<div class="notice"><b>阅读方式：</b>下方左侧为当前实机全景，右侧为本轮新布局剖面。剖面<b>非比例</b>，路线是行走顺序，不是弹道；标注、几何和颜色仅用于设计审阅，不代表正式场景美术或已经可玩。</div>
<div class="toolbar"><nav><a href="#overview">整区总览</a>__NAV__</nav><div class="toggles"><label><input type="checkbox" id="routeToggle" checked> 显示路线</label><label><input type="checkbox" id="markerToggle" checked> 显示门 / 环 / 奖励 / 注记</label><label><input type="checkbox" id="catchToggle" checked> 显示失误回收</label><span>点击“放大布局”查看每房细节</span></div></div>
<section class="overview" id="overview"><h2>七房关系与房内方向</h2><p class="small">总览仅表达原连接与七房内部结构，不表示鲸体解剖比例、实际场景尺寸或无缝地图。</p><img src="__REL__diagrams/overview.svg" alt="七房六连接与七个布局剖面总览"></section>
<div class="legend"><span><i style="--c:#f0ba69"></i>主路</span><span><i style="--c:#74c9ed"></i>能力 / 奖励支路</span><span><i style="--c:#c29df4"></i>自然返程</span><span><i style="--c:#70c9a2"></i>失误回收 / 非可走捷径</span><span><i style="--c:#708591"></i>刚性洞壁 / 骨柱</span><span><i style="--c:#daa0bd"></i>原膜形变包络</span></div>
__ROOMS__
<section><h2>审阅时只看这三件事</h2><div class="boundaries"><div><h3>① 路线是否有辨识度</h3><p>每房能否用一句话描述独特走法，尤其须筛的下槽上行、舌台的上下折返和记忆袋的绕柱。</p></div><div><h3>② 去程与回程是否清楚</h3><p>返程沿静态落点和既有动作，不引入新开关或解谜。绿色回收仅表达失误处理，不应变成贯通捷径。</p></div><div><h3>③ 目标能否提前看见</h3><p>奖励、出口和下一落点应被骨壁分隔却有视线提示；现有跟随镜头需在样板中复验。</p></div></div></section>
<footer><p><b>保持：</b>移动/跳跃/冲刺/牵引/浮游、原战斗、七房六连接、原能力与奖励关系。<br><b>本轮产物：</b>7房布局剖面、整区关系总览、原实机对照、可编辑JSON与SVG；尚无正式引擎碰撞和可达性验收。</p><p><a href="__REL__README.md">制作与约束说明</a> · <a href="__REL__layout.json">可编辑布局数据</a> · <a href="__REL__diagrams/overview.svg" target="_blank">单独查看总览</a></p></footer>
<dialog id="zoomDialog"><div class="dialoghead"><h3 id="zoomTitle"></h3><button id="closeDialog">关闭 Esc</button></div><div class="dialogmap" id="dialogMap"></div><p class="small">非比例结构剖面；正式尺寸、跳跃余量、顶障与镜头待Godot样板验证。</p></dialog>
</main><script>const layout=__DATA__;const toggle=(id,cls)=>document.getElementById(id).addEventListener('change',e=>document.body.classList.toggle(cls,!e.target.checked));toggle('routeToggle','hide-route');toggle('markerToggle','hide-marker');toggle('catchToggle','hide-catch');const dialog=document.getElementById('zoomDialog');document.querySelectorAll('[data-zoom]').forEach(b=>b.addEventListener('click',()=>{const id=b.dataset.zoom;document.getElementById('zoomTitle').textContent=id+' '+layout.rooms.find(r=>r.id===id).title+' · 布局 V1';document.getElementById('dialogMap').innerHTML=document.querySelector('#'+id+' .section').innerHTML;dialog.showModal()}));document.getElementById('closeDialog').onclick=()=>dialog.close();dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close()});</script></body></html>'''
page=page.replace('__NAV__',nav).replace('__REL__',relative).replace('__ROOMS__',''.join(roomhtml)).replace('__DATA__',data)
PAGE.mkdir(parents=True,exist_ok=True)
(PAGE/'地图布局.html').write_text(page,encoding='utf-8')
print('Built seven SVG sections, topology overview and responsive local review atlas.')
