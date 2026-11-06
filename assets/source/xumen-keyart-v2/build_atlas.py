"""Build concept-only atlas and source records. Does not write game/."""
from pathlib import Path
from html import escape as e
import json, hashlib, re, sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SRC = Path(__file__).resolve().parent
OUT = ROOT / 'docs/鲸腹遗城原画集/须门遗港精修设计'

def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

def write(p, data):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes((json.dumps(data, ensure_ascii=False, indent=2)+'\n').encode('utf-8'))

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    sys.path.insert(0,str(ROOT/'assets/source/xumen-reference-panorama-v2'))
    from render_reference import build as build_reference_world, data_script, STYLE as REFERENCE_STYLE, SCRIPT as REFERENCE_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-seam-repaint-v2'))
    from render_seams import STYLE as SEAM_REPAINT_STYLE, SCRIPT as SEAM_REPAINT_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-transition-polish-v3'))
    from render_polish import STYLE as POLISH_STYLE, SCRIPT as POLISH_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-ecology-niches-v1'))
    from render_niches import STYLE as NICHE_STYLE, SCRIPT as NICHE_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-challenge-v1'))
    from render_challenge import STYLE as CHALLENGE_STYLE, SCRIPT as CHALLENGE_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-real-scene-v1'))
    from render_scene import build as build_real_scene, STYLE as SCENE_STYLE, SCRIPT as SCENE_SCRIPT
    sys.path.insert(0,str(ROOT/'assets/source/xumen-overall-layout-v1'))
    from build_layout import main as build_overall_layout, STYLE as MAP_STYLE, SCRIPT as MAP_SCRIPT
    build_overall_layout()
    sys.path.insert(0,str(ROOT/'assets/source/xumen-seam-keyart-v1'))
    from render_atlas import build as build_connections, STYLE as CONNECTION_STYLE, SCRIPT as CONNECTION_SCRIPT
    d = read(SRC/'design.json')
    prompts = read(SRC/'prompts.json')['images'][:1]
    prompts += [read(p) for p in sorted((SRC/'prompts').glob('*.json'))]
    for p in prompts:
        if p['id']=='A00':
            p.update(generation='exec-e5a145a2-5443-4983-9b1c-0087e6c0f4d6', output='images/A00-须门遗港-鲸头连续空间.png')
    write(SRC/'prompts.json', {'tool':'built-in image_gen','scope':'concept only', 'images':prompts})
    art=[]
    for p in prompts:
        f=SRC/p['output']
        if not f.exists():
            raise FileNotFoundError(f)
        with Image.open(f) as im:
            im.verify()
        with Image.open(f) as im:
            size=list(im.size)
        art.append({'id':p['id'],'file':p['output'],'width':size[0],'height':size[1],
                    'sha256':sha(f),'generation':p['generation'],'status':'concept_candidate',
                    'runtimeIntegrated':False,'userReview':'pending'})
    write(SRC/'art-manifest.json', {'schemaVersion':1, 'images':art})
    OUT.mkdir(parents=True,exist_ok=True)
    base='../../../assets/source/xumen-keyart-v2/'
    byid={a['id']:a for a in art}
    pb={p['id']:p for p in prompts}
    def image(a,alt):
        return f'<a href="{base}{e(a["file"])}" target="_blank"><img src="{base}{e(a["file"])}" alt="{e(alt)}" width="{a["width"]}" height="{a["height"]}" loading="lazy"></a>'
    def prompt(pid):
        return f'<details><summary>实际英文绘图提示词 · {pid}</summary><pre>{e(pb[pid]["prompt"])}</pre><p>生成编号：{e(pb[pid]["generation"])} · 内置 imagegen</p></details>'
    def li(items):
        return '<ul>'+''.join('<li>'+e(s)+'</li>' for s in items)+'</ul>'
    hero=byid['A00']
    # Overlay shows compressed anatomical positions, NOT exact collision coordinates.
    tags=[('R1-01 外伤坡',10,65),('R1-02 须筛',23,64),('R1-03 舌台',44,64),('R1-04 负壳蟹',65,65),('R1-05 流膜育窝',87,59),('R1-06 喷气孔上层',59,9),('R1-07 鲸须记忆袋',51,36)]
    labels=''.join(f'<a class="tag" href="#R1-{s[0][3:5]}" style="left:{s[1]}%;top:{s[2]}%">{e(s[0])}</a>' for s in tags)
    rooms=''
    for r in d['rooms']:
        a=byid[r['art']]
        rooms+=f'''<article id="{r['id']}" class="room">
        <div class="sectiontitle"><div><span class="eyebrow">{r['id']} / {e(r['stage'])}</span><h2>{e(r['name'])}</h2></div><a href="#geography">回总图 ↑</a></div>
        {image(a,r['name']+'精修概念原画')}
        <div class="grid"><div><h3>部位与主路线</h3><p>{e(r['part'])} · {e(r['axial'])}</p><p class="route">{e(r['route'])}</p><p>{e(r['content'])}</p><h3>画面要解决什么</h3><p>{e(r['theme'])}</p><p>{e(r['composition'])}</p><h3>环境叙事</h3><p>{e(r['story'])}</p></div>
        <div><h3>远 · 中 · 可玩 · 前景</h3>{li(r['layers'])}<p>动件方案：{', '.join(r['motion'])}，详见下方分层制作表。图中鱼、泡和光仅为概念示意。</p><details><summary>查看本轮用户参考原图</summary><img src="{base}inputs/room{r['id'][-2:]}.png" alt="{e(r['name'])}原参考" loading="lazy"></details></div></div>{prompt(r['art'])}</article>'''
    edgecards=build_connections(ROOT)
    motionrows=''.join(f'<tr><td>{m["id"]}<br>{e(m["element"])}</td><td>{e(m["decision"])}</td><td>{e(m["method"])}<br><small>备选：{e(m["alternative"])}</small></td><td>{e(m["reason"])}</td><td>{e(m["test"])}<br><small>{e(m["state"])}</small></td></tr>' for m in d['motion'])
    # Exact seven-node/six-edge graph. Its position is topology only, not anatomy.
    nodes={'R1-01':(75,260),'R1-02':(285,260),'R1-03':(495,260),'R1-04':(705,260),'R1-05':(915,260),'R1-06':(235,70),'R1-07':(465,70)}
    graph='<svg viewBox="0 0 1030 355" role="img" aria-label="七房六边精确拓扑，非比例非解剖位置">'
    for b in d['edges']:
        x,y=nodes[b['from']]; xx,yy=nodes[b['to']]
        graph+=f'<g class="graph-edge" data-edge="{b["id"]}"><path d="M{x+40} {y} L{xx+40} {yy}"/><a href="#{b["id"]}"><text x="{(x+xx)/2+40}" y="{(y+yy)/2-12}">{b["id"]}</text></a></g>'
    for r in d['rooms']:
        x,y=nodes[r['id']]
        graph+=f'<a class="graph-node" data-room="{r["id"]}" href="#{r["id"]}"><rect x="{x-35}" y="{y-27}" width="150" height="54" rx="10"/><text x="{x+40}" y="{y-4}">{r["id"]}</text><text x="{x+40}" y="{y+17}">{e(r["name"])}</text></a>'
    graph+='</svg>'
    layout=read(SRC/'inputs/runtime-layout.json')
    layoutsvg='<svg viewBox="-100 -1700 10700 3200" role="img" aria-label="沿用工程原点的房间分布">'
    coords=''
    for r in layout['rooms']:
        x,y=r['origin'];w,h=r['size']; rid=r['id']
        layoutsvg+=f'<a href="#{rid}"><rect x="{x}" y="{y}" width="{w}" height="{h}"/><text x="{x+w/2}" y="{y+h/2}" text-anchor="middle">{rid}</text></a>'
        coords+=f'<tr><td>{rid}</td><td>{x:.3f}, {y:.3f}</td><td>{w:.3f} × {h:.3f}</td></tr>'
    layoutsvg+='</svg>'
    style='''
    :root{color-scheme:dark;--bg:#081923;--card:#102630;--line:#31505a;--ink:#e4e1d3;--muted:#9bb6bb;--gold:#deb375}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:68px}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.8 system-ui,"Microsoft YaHei",sans-serif}a{color:var(--gold);text-decoration:none}a:hover{text-decoration:underline}nav{position:sticky;top:0;background:#081923ed;border-bottom:1px solid var(--line);z-index:10;display:flex;gap:22px;padding:12px 4vw;overflow:auto;white-space:nowrap}main{max-width:1510px;margin:auto;padding:0 3vw 70px}header{padding:65px 0 35px}h1{font-size:clamp(32px,4vw,60px);margin:8px 0 10px;letter-spacing:.08em}h2{font-size:30px;margin:6px 0 18px}h3{font-size:18px;margin:20px 0 8px}.eyebrow{font-size:12px;letter-spacing:.14em;color:var(--muted)}.lead{font-size:20px;max-width:1000px}.notice{border-left:3px solid var(--gold);padding:14px 20px;background:var(--card)}section,.room{margin-top:50px;padding-top:20px;border-top:1px solid var(--line)}img{display:block;width:100%;height:auto;border-radius:4px}.hero{position:relative;margin:20px 0}.tag{position:absolute;transform:translate(-50%,-50%);background:#06141edf;padding:3px 8px;border:1px solid #caa97b88;border-radius:4px;font-size:clamp(8px,1vw,14px);white-space:nowrap}.hero.hide .tag{display:none}.grid{display:grid;grid-template-columns:1.2fr 1fr;gap:36px}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.edge{padding:20px;background:var(--card);border:1px solid var(--line);border-radius:7px}.sectiontitle{display:flex;justify-content:space-between;align-items:center}.route{color:#bcd6d7}.gate{color:var(--gold)}ul{padding-left:20px}details{border:1px solid var(--line);border-radius:5px;margin:16px 0;padding:10px 15px}summary{cursor:pointer;color:var(--gold)}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:13px/1.75 ui-monospace,monospace;color:var(--muted)}.scroll{overflow-x:auto}table{border-collapse:collapse;width:100%;min-width:760px;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid var(--line);padding:14px}th{color:var(--gold)}small{color:var(--muted)}button{background:var(--card);border:1px solid var(--line);color:var(--ink);padding:8px 14px;border-radius:5px;cursor:pointer}svg{width:100%;background:#0d222b;border-radius:6px}svg path{stroke:#8eaeb8;stroke-width:3;fill:none}svg rect{fill:#183944;stroke:#8eaeb8;stroke-width:1.5}svg text{fill:var(--ink);text-anchor:middle;font:15px system-ui}.graph-edge text{fill:var(--gold)}.layout svg text{font-size:155px}.layout svg rect{stroke-width:10}footer{color:var(--muted);font-size:13px;margin-top:50px}.room img{background:#06131c}@media(max-width:800px){main{padding:0 16px 40px}header{padding-top:35px}.grid,.cards{grid-template-columns:1fr;gap:15px}.tag{padding:1px 3px}nav{gap:17px;font-size:14px}.lead{font-size:17px}.sectiontitle{align-items:start;gap:15px}h2{font-size:25px}}
    '''
    style+=CONNECTION_STYLE+MAP_STYLE+SCENE_STYLE+REFERENCE_STYLE+SEAM_REPAINT_STYLE+POLISH_STYLE+NICHE_STYLE+CHALLENGE_STYLE
    html=f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 原画精修设计</title><style>{style}</style></head><body>
    <nav><a href="#top">须门遗港</a><a href="#geography">鲸头全景</a><a href="#topology">七房六边</a><a href="#R1-01">逐房原画</a><a href="#connections">过渡合同</a><a href="#motion">分层与动态</a><a href="#review">审核与来源</a></nav>
    <main id="top"><header><div class="eyebrow">WHALEBELLY RUINS / XUMEN LOST HARBOR / CONCEPT V2 · 2026.11.05</div><h1>须门遗港 · 原画精修</h1><p class="lead">一个巨大的口腔，七段不同的探索空间。用同一根颌骨、连续的舌背和逐渐变化的组织，让玩家看见自己正在深入鲸体。</p><p class="notice">8张新概念原画：整区鲸头剖面＋七房。本轮未改游戏。概念像素不代表跳距或碰撞，画中孔洞不自动增加连接。用户审美评审待反馈。</p></header>
    <section id="geography"><h2>鲸头与整体空间</h2><p>头左、咽右；下方依次是外伤坡—须筛—舌台—负壳蟹—流膜育窝。上方两条回访线从须筛分别进入鼻道上层和须根侧袋。硬腭保持实体，Boss下方封底。巨鲸120m、角色约0.3m为既有幻想设定。</p><button id="labels" aria-pressed="true">显示 / 隐藏部位注记</button><div class="hero">{image(hero,'须门遗港鲸头整体连续剖面')}{labels}</div><p><small>上图是压缩解剖投影。注记标识空间归属，不定义跨屏像素位置或可直接行走的路径。上层并排不表示彼此连通。</small></p>{prompt('A00')}<h3>本轮精修方向</h3>{li(d['artDirection'])}</section>
    <section id="topology"><h2>固定的七房与六条连接</h2><p>以下是精确拓扑，非比例、非器官位置图。点击房间看原画，点击边编号看过渡合同。只有这里登记的六条连接属于本批范围。</p>{graph}<p>A1在Boss后获得；E33需A2浮膜；E35需A3锚定。R1-05的右向章外出口和R1-06的远侧闩只说明既有边界，不新增本章房间。</p><details class="layout"><summary>工程房间位置分布（实际像素，非本轮重排）</summary>{layoutsvg}<div class="scroll"><table><thead><tr><th>房间</th><th>世界原点 X,Y</th><th>尺寸 W×H</th></tr></thead><tbody>{coords}</tbody></table></div><p>数据快照：inputs/runtime-layout.json。Y向下为正。房间原点之间的空段由既有连接几何承担；新原画没有重新定义这些间距。</p></details></section>
    {rooms}<section id="connections"><h2>六条连接如何接续</h2><p>跨屏两侧不再各画一套门框。共同地标、光向和路面趋势延续，器官材质沿行进方向渐变。以下是设计合同，仍需后续在引擎做同镜头样板。</p><div class="cards">{edgecards}</div><details><summary>对照既有三种过渡样式</summary><div class="cards">{''.join('<figure><img src="'+base+'inputs/T0'+str(i)+'.png" alt="既有过渡T0'+str(i)+'" loading="lazy"><figcaption>'+s+'</figcaption></figure>' for i,s in [(1,'T01 颌骨斜拱：沿骨弧连主路'),(2,'T02 骨膜渐变：材质变而路线不断'),(3,'T03 骨壁生台：有附着根的上行')])}</div><p>以上三图为此前原画，本轮未重新生成；新七房使用其形状语言。</p></details></section>
    <section id="motion"><h2>独立分层与动态制作计划</h2><p>本轮先确定原画。表中方法根据已有成功机制选型，新构图尚未拆分、动画化或实机验证。后续须先清掉背景中烘焙的鱼、泡、角色和动须，再补绘隐藏面；不能在原图上重复叠同一动件。</p><div class="scroll"><table><thead><tr><th>ID / 元素</th><th>判断</th><th>首选 / 备选</th><th>选择理由</th><th>验收与状态</th></tr></thead><tbody>{motionrows}</tbody></table></div><p>后续制作顺序：①固定镜头分层重构 → ②E01双房联合母版与共同远景 → ③柔性物/生物/粒子单件样板 → ④接入既有碰撞，检查起跳、遮挡和边缘 → ⑤其余五边逐条扩展。概念图不能直接横向拼接成运行地图。</p></section>
    <section id="review"><h2>审核边界与来源</h2>{li(d['knownLimits'])}<p>已核对：8张位图可解码、七房六边合同、各房部位和过渡说明、来源提示词、图册图片与窄屏。审美认可、精确分件和引擎效果需要后续阶段。</p><p><a href="{base}art-manifest.json">原画台账与哈希</a> · <a href="{base}design.json">机器可读设计</a> · <a href="{base}prompts.json">完整提示词</a> · <a href="{base}acceptance.md">审核记录</a> · <a href="../连续世界设计/原画册.html">连续世界设计</a> · <a href="../过渡样式设计/原画册.html">过渡样式设计</a></p></section>
    <footer>概念来源：本轮用户七房图片、三张既有过渡图、V5.2地图规范与现工程路线。新原画使用内置imagegen，原始生成文件与输入快照保留。原创鲸体生态世界，参考互联探索与空间可读性，不借用任何已有游戏的角色、建筑或界面造型。</footer></main><script>document.querySelector('#labels').addEventListener('click',function(){{const hide=document.querySelector('.hero').classList.toggle('hide');this.setAttribute('aria-pressed',String(!hide))}});</script></body></html>'''
    html=html.replace('<div class="cards">'+edgecards+'</div>','<div class="edge-gallery">'+edgecards+'</div>')
    html=html.replace('8张新概念原画：整区鲸头剖面＋七房。','14张概念原画：整区鲸头剖面＋七房＋六条接续。')
    html=html.replace('已核对：8张位图可解码','已核对：14张位图可解码')
    controls='<div class="seam-tools"><button id="seam-notes" aria-pressed="true">显示 / 隐藏接续注记</button><span>6张专用联合原画 · 四条水平主路 / 两条上行回访线</span></div>'
    html=html.replace('<h2>六条连接如何接续</h2>','<h2>六条连接如何接续</h2>'+controls)
    html=html.replace('</script></body>','</script><script>'+CONNECTION_SCRIPT+'</script></body>')
    html=html.replace('<a href="#geography">鲸头全景</a>','<a href="#overall-layout">总布局图</a><a href="#geography">鲸头全景</a>')
    overall=(ROOT/'assets/source/xumen-overall-layout-v1/section.html').read_text(encoding='utf-8')
    condensed_scene=build_real_scene().replace('id="real-scene"','id="real-scene-condensed"')
    real_scene=build_reference_world()
    real_scene=real_scene.replace('</section>',data_script()+'</section>')
    real_scene+='<details id="condensed-history"><summary>历史概括稿（未完整保留原房设计，已撤出主展示）</summary>'+condensed_scene+'</details>'
    html=html.replace('<section id="geography">',real_scene+overall+'<section id="geography">')
    html=html.replace('<a href="#overall-layout">总布局图</a>','<a href="#real-scene">实景总览</a><a href="#overall-layout">总布局图</a>')
    html=html.replace('14张概念原画：整区鲸头剖面＋七房＋六条接续。','15张概念原画：实景总览＋鲸头剖面＋七房＋六条接续。')
    html=html.replace('已核对：14张位图可解码','已核对：15张位图可解码')
    html=html.replace('15张概念原画：实景总览＋鲸头剖面＋七房＋六条接续。','七房完整原图总览＋六处接缝局部精修；旧概括全景保留为历史稿。')
    html=html.replace('CONCEPT V2 · 2026.11.05','CONCEPT V2 / SEAM REPAINT · 2026.11.06')
    html=html.replace('</script></body>','</script><script>'+MAP_SCRIPT+'</script></body>')
    html=html.replace('</script></body>','</script><script>'+SCENE_SCRIPT.replace("#real-scene","#real-scene-condensed")+REFERENCE_SCRIPT+SEAM_REPAINT_SCRIPT+POLISH_SCRIPT+NICHE_SCRIPT+CHALLENGE_SCRIPT+'</script></body>')
    html='\n'.join(line.rstrip() for line in html.splitlines())+'\n'
    (OUT/'原画册.html').write_bytes(html.encode('utf-8'))
    write(SRC/'production.json', {'scope':d['scope'],'stage':'concept_delivered','runtime':'unchanged','user_art_review':'pending','latestSupplement':'../xumen-challenge-v1/progress.json','supplementScope':'7 revised room concepts + 1 enemy concept sheet; proposed terrain and AI not integrated','atlas':str(OUT.relative_to(ROOT)/'原画册.html'),'images':len(art),'rooms':7,'edges':6,'next':'用户确认视觉方向后，按既有六边做联合母版和分层接入，不直接拼接概念图。'})
    print(json.dumps({'images':len(art),'atlas':str(OUT)},ensure_ascii=False))

if __name__=='__main__':
    main()
