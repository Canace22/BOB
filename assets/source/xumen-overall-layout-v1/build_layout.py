"""Editable technical layout from existing world coordinates, not new game art."""
from pathlib import Path
import json, hashlib
from html import escape as esc

ROOT=Path(__file__).resolve().parents[3]
SRC=Path(__file__).resolve().parent
IDS=['E01','E02','E03','E04','E33','E35']
MAIN='#f3c57c';FLOAT='#83d9ea';ANCHOR='#d1a6f2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def main():
    SRC.mkdir(parents=True,exist_ok=True)
    layout=read(ROOT/'assets/source/xumen-keyart-v2/inputs/runtime-layout.json')
    design=read(ROOT/'assets/source/xumen-keyart-v2/design.json')
    content=read(ROOT/'game/art/whalebelly/rooms.json')
    art=read(ROOT/'assets/source/xumen-keyart-v2/art-manifest.json')['images']
    byart={a['id']:a for a in art}
    surfaces=layout['surfaces']
    styles='''
    .overall-map{background:#071821;border:1px solid #45636c;border-radius:8px;font-family:system-ui,"Microsoft YaHei",sans-serif}.overall-map text{font-family:system-ui,"Microsoft YaHei",sans-serif;text-anchor:middle}.overall-map .room-mass{fill:#15343f;stroke:#5f8892;stroke-width:10}.overall-map .upper-mass{fill:#1b3346}.overall-map .surface{fill:none;stroke:#a5c4c9;stroke-width:16;stroke-linecap:round;stroke-linejoin:round}.overall-map .surface-fill{fill:#274955;stroke:none}.overall-map .support{stroke:#52747c;stroke-width:7;fill:none;opacity:.5}.overall-map .room-name{font-size:132px;font-weight:700;fill:#edf0de}.overall-map .room-id{font-size:86px;fill:#a8c5ca}.overall-map .zone-name{font-size:90px;fill:#99b8be}.overall-map .route{fill:none;stroke-width:29;stroke-linejoin:round;stroke-linecap:round}.overall-map .edge-route{fill:none;stroke-width:36;stroke-linecap:round;stroke-linejoin:round}.overall-map .main{stroke:'''+MAIN+'''}.overall-map .float{stroke:'''+FLOAT+'''}.overall-map .anchor{stroke:'''+ANCHOR+'''}.overall-map .edge-name{font-size:92px;fill:#ecdfbf;paint-order:stroke;stroke:#071821;stroke-width:26px;stroke-linejoin:round}.overall-map .badge rect{fill:#0c242f;stroke:#67838d;stroke-width:6;rx:22}.overall-map .badge text{font-size:96px;fill:#eef0dd}.overall-map .badge .detail{font-size:78px;fill:#abc4c8}.overall-map .symbol{stroke:#0b1821;stroke-width:7}.overall-map .exit-note{font-size:87px;fill:#c6d3d0}.overall-map .outside{stroke:#86a2aa;stroke-width:12;stroke-dasharray:30 28;fill:none}.overall-map .no-link{font-size:78px;fill:#b5b9bd}.overall-map .art-layer{opacity:.42}.overall-map .region-hit{fill:transparent;stroke:transparent;stroke-width:22}.overall-map a:hover .region-hit{stroke:#e9cc91}.overall-map .branch-off{opacity:.13}.overall-map .marker-label{font-size:78px;fill:#e9e5cf;paint-order:stroke;stroke:#071821;stroke-width:16}.overall-map .endwall{stroke:#d5c0a3;stroke-width:20}.overall-map .hint-line{stroke:#94aeb5;stroke-width:7;fill:none}.overall-map .hint-text{font-size:80px;fill:#9fb8bd}.overall-map .art-layer[hidden],.overall-map .info-layer[hidden]{display:none}
    '''
    svg=['<svg class="overall-map" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="-450 -2350 11450 4050" role="img" aria-labelledby="layout-title layout-description">',
         '<title id="layout-title">须门遗港总布局图：下层五房主路，上层两条独立回访线</title><desc id="layout-description">采用现有工程房间和51段台面坐标。金色主路由外伤坡通往流膜育窝，蓝色E33浮膜支路返回喷气孔上层，紫色E35锚定支路返回鲸须记忆袋。上层互不相通。示意图不是新增碰撞或正式场景美术。</desc>',f'<style>{styles}</style>',
         '<defs><marker id="map-arrow-main" markerWidth="7" markerHeight="7" refX="5" refY="3.5" orient="auto"><path d="M0 0 L6 3.5 L0 7" fill="none" stroke="'+MAIN+'" stroke-width="1.3"/></marker></defs>',
         '<text class="zone-name" x="700" y="-2020">上层：能力回访区域</text><text class="zone-name" x="700" y="-200">下层：第一次通关主路</text>']
    # Room bounds use world positions and sizes. Text sits above actual local floors.
    for i,(r,brief) in enumerate(zip(layout['rooms'],design['rooms'])):
        x,y=r['origin'];w,h=r['size'];a=byart[brief['art']]
        if i<5:
            yy=y+190
        else:
            yy=y+80
        cls=' upper-mass' if i>=5 else ''
        svg.append(f'<g data-layout-room="{r["id"]}"><rect class="room-mass{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="100"/>')
        svg.append(f'<image class="art-layer" hidden="hidden" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice" xlink:href="../../../assets/source/xumen-keyart-v2/{esc(a["file"])}"/>')
        svg.append(f'<a href="#{r["id"]}"><rect class="region-hit" x="{x}" y="{y}" width="{w}" height="{h}" rx="100"/></a>')
        svg.append(f'<text class="room-id" x="{x+w/2}" y="{yy}">{r["id"]}</text><text class="room-name" x="{x+w/2}" y="{yy+145}">{esc(brief["name"])}</text></g>')
    # Draw all 51 existing top surfaces without inventing additional collision.
    for s in surfaces:
        pts=s['points'];depth=s.get('depth',80)
        points=' '.join(f'{x},{y}' for x,y in pts)
        polygon=points+f' {pts[-1][0]},{pts[-1][1]+depth} {pts[0][0]},{pts[0][1]+depth}'
        svg.append(f'<g data-layout-surface="{s["id"]}"><polygon class="surface-fill" points="{polygon}"/><polyline class="surface" points="{points}"/></g>')
    # Main line follows actual main-floor samples; route is offset up to keep top surfaces readable.
    main=[s for s in surfaces if s['room'] in range(5) and (s['kind']=='main' or s['room']==4)]
    for s in main:
        points=' '.join(f'{x},{y-45}' for x,y in s['points'])
        svg.append(f'<polyline class="route main" points="{points}"/>')
    nursery=[s for s in surfaces if s['room']==4]
    for left,right in zip(nursery,nursery[1:]):
        x,y=left['points'][-1];xx,yy=right['points'][0]
        svg.append(f'<path class="route main" stroke-dasharray="22 17" d="M{x} {y-45} Q{(x+xx)/2} {min(y,yy)-150} {xx} {yy-45}"/>')
    positions={
        'E01':(1925,940),'E02':(4125,940),'E03':(6310,940),'E04':(8390,1030),
        'E33':(1790,-250),'E35':(4230,-330)}
    for eid in IDS:
        cls='main' if eid in IDS[:4] else ('float' if eid=='E33' else 'anchor')
        if eid in IDS[:4]:
            s=next(s for s in surfaces if s['id']==eid)
            pts=[[x,y-45] for x,y in s['points']]
        elif eid=='E33':
            # These paths describe traversal between existing floors, not new collision polygons.
            pts=[[2450,365],[2410,235],[2390,70],[2123,55],[2123,-681],[2420,-681],[2670,-725]]
        else:
            pts=[[3650,150],[3893,145],[3893,-911],[4200,-950],[4350,-950]]
        points=' '.join(f'{x},{y}' for x,y in pts)
        xx,yy=positions[eid]
        gate='' if eid in IDS[:4] else ('A2 浮膜' if eid=='E33' else 'A3 锚定')
        svg.append(f'<g data-layout-edge="{eid}" class="layout-{cls}"><a href="#{eid}"><polyline class="edge-route {cls}" points="{points}"/><text class="edge-name" x="{xx}" y="{yy}">{eid}</text>')
        if gate:svg.append(f'<text class="edge-name" x="{xx}" y="{yy+130}">{gate}</text>')
        svg.append('</a></g>')
    # Local room examples are schematic guide paths; they never alter world geometry.
    svg.append('<g class="layout-float"><polyline class="route float" points="2420,-730 2770,-875 3030,-1010 3430,-1180"/></g>')
    svg.append('<g class="layout-anchor"><polyline class="route anchor" points="4200,-960 4440,-1095 4670,-1100 4930,-1095 5200,-960"/></g>')
    # Stable narrative/route cues.
    def badge(x,y,w,title,detail):
        return f'<g class="badge"><rect x="{x}" y="{y}" width="{w}" height="250"/><text x="{x+w/2}" y="{y+95}">{title}</text><text class="detail" x="{x+w/2}" y="{y+195}">{detail}</text></g>'
    svg.append(badge(2370,-2200,1350,'06 喷气孔上层','从旧伤侧坡上来'))
    svg.append(badge(4090,-2200,1420,'07 鲸须记忆袋','盲端，原路返回'))
    svg.append('<path class="hint-line" d="M3045 -1950 L3045 -1560 M4800 -1950 L4800 -1560"/>')
    svg.append('<text class="no-link" x="3965" y="-1690">上层两处不相通</text>')
    svg.append(badge(-150,1250,1760,'01 从左侧进入','入鲸营地 → 走、跳'))
    svg.append(badge(2290,1250,1650,'02 须筛是分岔点','先走主路，后带能力回访'))
    svg.append(badge(4580,1250,1700,'03 舌台上下回路','下层只回本房'))
    svg.append(badge(6700,1250,1560,'04 首领与胜利门','先胜Boss，再取A1'))
    svg.append(badge(8760,1250,1720,'05 三段短冲','稳定台 → 缺口 → 软床'))
    svg.append('<path class="hint-line" d="M730 1230 L730 1000 M3100 1230 L3100 1000 M5400 1230 L5400 1070 M7460 1230 L7460 1070 M9600 1230 L9600 1160"/>')
    svg.append('<g data-layout-gate="BOSS_R1"><path d="M8325 590 L8325 790 M8390 590 L8390 790" stroke="#ec8f80" stroke-width="18"/><text class="marker-label" x="8355" y="490">胜利门</text></g>')
    # End wall of optional pouch and external chapter boundaries.
    svg.append('<path class="endwall" d="M5575 -1050 L5575 -760 M5550 -1030 L5600 -1080 M5550 -925 L5600 -975 M5550 -820 L5600 -870"/>')
    svg.append('<path class="outside" d="M10266 730 L10730 730"/><text class="exit-note" x="10600" y="520">章末出口</text><text class="exit-note" x="10600" y="1050">往胃枢（章外）</text>')
    svg.append('<path class="endwall" d="M3690 -1200 L3690 -1050"/><text class="no-link" x="3350" y="-490">章外侧闩封闭</text>')
    svg.append('<text class="hint-text" x="700" y="-1840">上下层位置取自工程</text>')
    # Markers are design guide symbols at source-room object coordinates, not runtime sprites.
    svg.append('<g class="info-layer">')
    for r,c in zip(layout['rooms'],content):
        ox,oy=r['origin']
        if c.get('camp'):
            x,y=c['camp'];x+=ox;y+=oy
            svg.append(f'<g><rect class="symbol" x="{x-48}" y="{y-48}" width="96" height="96" fill="{MAIN}"/><text class="marker-label" x="{x+60}" y="{y-80}" text-anchor="start">营地</text></g>')
        if c.get('reward'):
            x,y=c['reward'];x+=ox;y+=oy
            svg.append(f'<path class="symbol" d="M{x} {y-58} L{x+58} {y} L{x} {y+58} L{x-58} {y}Z" fill="#c9d5a5"/>')
        for en in c.get('enemies',[]):
            x,y=en['pos'];x+=ox;y+=oy
            if en.get('boss'):
                svg.append(f'<path class="symbol" d="M{x-80} {y+10} L{x-65} {y-65} L{x-15} {y-30} L{x} {y-85} L{x+20} {y-30} L{x+65} {y-65} L{x+80} {y+10}Z" fill="#ec8f80"/><text class="marker-label" x="{x}" y="{y-130}">Boss</text>')
            else:svg.append(f'<circle class="symbol" cx="{x}" cy="{y-35}" r="46" fill="#ec8f80"/>')
        for ring in c.get('rings',[]):
            x,y=ring;x+=ox;y+=oy
            svg.append(f'<circle class="symbol" cx="{x}" cy="{y}" r="38" fill="none" stroke="{ANCHOR}" stroke-width="14"/>')
    svg.append('<circle class="symbol" cx="240" cy="590" r="45" fill="#b7dec6"/><text class="marker-label" x="300" y="410">起点</text>')
    svg.append('</g></svg>')
    text=''.join(svg)
    standalone=text.replace('href="#','href="../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html#')
    (SRC/'总布局.svg').write_bytes(standalone.encode('utf-8'))
    records={'title':'须门遗港总布局','type':'editable technical diagram, not new scene art','roomCount':7,'edgeCount':6,'surfaceCount':len(surfaces),'runtimeChanged':False,'sources':[{'file':'assets/source/xumen-keyart-v2/inputs/runtime-layout.json','sha256':hashlib.sha256((ROOT/'assets/source/xumen-keyart-v2/inputs/runtime-layout.json').read_bytes()).hexdigest()},{'file':'game/art/whalebelly/rooms.json','sha256':hashlib.sha256((ROOT/'game/art/whalebelly/rooms.json').read_bytes()).hexdigest()}],'limitations':['工程展开示意，不等同鲸体解剖比例。','三色路线是阅读指引，未把路线线段新增为碰撞。','物件标记表示原设计位置，不表示本轮实机重新验收。','可选原画底图只作区域对应参考，不是已接入场景拼贴。']}
    save(SRC/'manifest.json',records)
    # Inline SVG in the main atlas uses document-relative images and anchors.
    fragment=f'''<section id="overall-layout"><span class="eyebrow">START HERE / MAP LAYOUT</span><h2>先看这张：整关怎么走</h2><p class="lead">下层五房从左向右连续推进；须筛向上分出两条独立回访线。上层没有横向通道，记忆袋到头后原路返回。</p><div class="map-legend"><span style="--swatch:{MAIN}">金色：首次主路</span><span style="--swatch:{FLOAT}">蓝色：浮膜回访</span><span style="--swatch:{ANCHOR}">紫色：锚定回访</span></div><div class="map-tools"><button data-map-action="zoom-in">放大＋</button><button data-map-action="zoom-out">缩小－</button><button data-map-action="fit">全图</button><button data-map-action="art" aria-pressed="false">原画底图</button><button data-map-action="markers" aria-pressed="true">物件标记</button><button data-map-action="float" aria-pressed="true">浮膜路线</button><button data-map-action="anchor" aria-pressed="true">锚定路线</button></div><div class="map-scroll" tabindex="0" aria-label="总布局图，可横向滚动放大查看"><div class="map-canvas">{text}</div></div><p class="map-caption">点击区域看房间原画，点击连接编号看接续原画。窄屏可横向拖动；方块＝营地，菱形＝收集品，圆点＝普通敌人，冠形＝Boss，空心环＝固定锚环。</p><div class="grid"><div><h3>第一次游玩的走法</h3><p>起点 → 外伤坡 → E01 → 须筛 → E02 → 舌台 → E03 → 蟹前室与首领 → E04 → 流膜育窝 → 章末出口。</p><p>舌台下层只是本房回路；Boss下方没有绕行通道。育窝的三道缺口使用战后获得的A1练习短冲。</p></div><div><h3>后续带能力回来</h3><p>回到须筛：左上沿E33旧伤坡用A2浮膜，上到喷气孔；右上沿E35须根用A3锚定，进入记忆袋。两条线互不合流。</p><p>喷气孔远侧闩连章外，现有工程只作提示；此侧不能穿过。记忆袋是可选盲端。</p></div></div><p class="notice">本图采用现有工程的七房原点和51段台面，其中26段属于六条连接。它是地图布局图，不按鲸体解剖比例，也不是新的场景美术或碰撞改动。可选原画底图只帮助对应区域。</p><p><a href="../../../assets/source/xumen-overall-layout-v1/总布局.svg" target="_blank">单独打开可编辑SVG</a> · <a href="../../../assets/source/xumen-overall-layout-v1/manifest.json">坐标来源与范围</a></p></section>'''
    (SRC/'section.html').write_bytes(fragment.encode('utf-8'))
    print(json.dumps(records,ensure_ascii=True))

if __name__=='__main__':main()

STYLE='''
.map-legend,.map-tools{display:flex;gap:14px;flex-wrap:wrap;align-items:center;margin:15px 0}.map-legend span{font-size:14px}.map-legend span:before{content:"";display:inline-block;width:25px;height:4px;background:var(--swatch);vertical-align:middle;margin-right:8px}.map-scroll{overflow:auto;max-width:100%;border-radius:8px;border:1px solid #34545d;overscroll-behavior-x:contain}.map-canvas{width:100%;min-width:1100px}.map-canvas svg{display:block;width:100%;height:auto;max-width:none}.map-caption{font-size:13px;color:var(--muted)}.map-tools button[aria-pressed="true"]{border-color:#c9b27d}.map-tools button{font-size:13px}.map-tools{gap:8px}
'''
SCRIPT='''(()=>{const root=document.querySelector('#overall-layout');if(!root)return;let scale=1;const canvas=root.querySelector('.map-canvas');root.querySelectorAll('[data-map-action]').forEach(button=>button.addEventListener('click',()=>{const action=button.dataset.mapAction;if(action==='zoom-in'||action==='zoom-out'||action==='fit'){scale=action==='fit'?1:Math.max(1,Math.min(2.5,scale+(action==='zoom-in'?.4:-.4)));canvas.style.width=(scale*100)+'%';if(action==='fit')root.querySelector('.map-scroll').scrollLeft=0;return}const pressed=button.getAttribute('aria-pressed')==='true';button.setAttribute('aria-pressed',String(!pressed));if(action==='art')root.querySelectorAll('.art-layer').forEach(el=>pressed?el.setAttribute('hidden','hidden'):el.removeAttribute('hidden'));else if(action==='markers')root.querySelector('.info-layer').toggleAttribute('hidden',pressed);else root.querySelectorAll('.layout-'+action).forEach(el=>el.classList.toggle('branch-off',pressed))}));})();'''
