"""Render six concept connectors inside the existing room atlas."""
from pathlib import Path
from html import escape as e
import hashlib, json
from PIL import Image

EXPECTED=['E01','E02','E03','E04','E33','E35']
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,data): p.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def build(root):
    src=root/'assets/source/xumen-seam-keyart-v1'
    d=read(src/'connections.json')
    old=read(root/'assets/source/xumen-keyart-v2/design.json')
    roomart={r['id']:r for r in old['rooms']}
    manifest=read(root/'assets/source/xumen-keyart-v2/art-manifest.json')
    byid={a['id']:a for a in manifest['images']}
    layout=read(root/'assets/source/xumen-keyart-v2/inputs/runtime-layout.json')
    prompts=[read(src/'prompts'/f'{eid}.json') for eid in EXPECTED]
    assert [b['id'] for b in d['edges']]==EXPECTED
    assert [(b['from'],b['to']) for b in d['edges']]==[(b['from'],b['to']) for b in old['edges']]
    art=[]; refs={}; html=''
    base='../../../assets/source/xumen-seam-keyart-v1/'
    oldbase='../../../assets/source/xumen-keyart-v2/'
    for b,p in zip(d['edges'],prompts):
        f=src/b['output']
        with Image.open(f) as im:
            im.verify()
        with Image.open(f) as im:
            w,h=im.size
        art.append({'id':b['id'],'file':b['output'],'width':w,'height':h,'sha256':sha(f),'generation':p['generation'],'status':'concept_candidate','runtimeIntegrated':False,'userReview':'pending'})
        for r in p['references']:
            assert (root/r).is_file(),r
            refs[r]=sha(root/r)
        # Copy exact existing connector surfaces. This is a contract snapshot, not art-derived collision.
        b['existingSurfaces']=[s for s in layout['surfaces'] if s['id']==b['id'] or s['id'].startswith('Floor_'+b['id']+'_') or s['id'] in [b['id']+'-lower',b['id']+'-upper']]
        floors=[s for s in b['existingSurfaces'] if s['id'].startswith('Floor_') or s['id']==b['id']]
        contract=f'{len(floors)}段主连接碰撞；沿用原顶点。本图不规定跳距。'
        if b['orientation']=='vertical':
            contract+='另有上下端接台；详见JSON快照。'
        labels=''.join(f'<span class="seam-tag" style="left:{s["at"][0]}%;top:{s["at"][1]}%"><b>{i+1:02}</b> {e(s["title"])}</span>' for i,s in enumerate(b['stages']))
        route=b.get('readingPath',[s['at'] for s in b['stages']])
        points=' '.join(f'{point[0]},{point[1]}' for point in route)
        path=f'<svg class="seam-route" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"><polyline points="{points}"/></svg>'
        stages=''.join(f'<div><span class="eyebrow">{i+1:02}</span><h4>{e(s["title"])}</h4><p>{e(s["text"])}</p></div>' for i,s in enumerate(b['stages']))
        refshtml=''
        for rid,role in [(b['from'],'离开端'),(b['to'],'抵达端')]:
            r=roomart[rid];a=byid[r['art']]
            refshtml+=f'<figure><a href="#{rid}"><img src="{oldbase}{e(a["file"])}" alt="{e(r["name"])}接续参考" loading="lazy"></a><figcaption>{role} · <a href="#{rid}">{rid} {e(r["name"])}</a></figcaption></figure>'
        layers='<ul>'+''.join('<li>'+e(s)+'</li>' for s in b['layers'])+'</ul>'
        state=''
        if b['id']=='E04':
            state='<p class="notice">原画为胜利后开放状态。关闭态沿同一软帘附着根封住通口；先保留入口侧稳定台，禁止帘下和两侧绕行。此处仅规定状态，未另绘关闭态原画或制作开门动画。</p>'
        html+=f'''<article class="edge seam" id="{b['id']}" data-seam="{b['id']}">
        <div class="sectiontitle"><div><span class="eyebrow">{b['id']} / DEDICATED CONTINUITY KEYART</span><h3>{e(b['title'])}</h3></div><a href="#topology">查看拓扑 ↑</a></div>
        <p class="gate">{e(b['gate'])}</p><p>{e(b['anatomy'])}</p>
        <div class="seam-board {b['orientation']}"><a href="{base}{e(b['output'])}" target="_blank"><img src="{base}{e(b['output'])}" alt="{e(b['title'])}专用接续原画" width="{w}" height="{h}" loading="lazy"></a>{path}{labels}</div>
        <p class="seam-caption"><a href="{base}{e(b['output'])}" target="_blank">打开无注记原尺寸图 ↗</a> · 01→02→03是阅读次序，不是碰撞折线或精确比例。</p>
        <div class="seam-stages">{stages}</div>{state}
        <div class="grid"><div><h4>共同地标与光照</h4><p>{e(b['landmark'])}</p><p>{e(b['light'])}</p><h4>材质与遮挡接续</h4><p>{e(b['material'])}</p><p>{e(b['occlusion'])}</p></div><div><h4>分层交付方向</h4>{layers}<h4>动态候选</h4><p>{e(b['motion'])}</p><p><small>新原画尚未分件或制动画。{e(contract)}</small></p></div></div>
        <p class="notice">{e(b['guard'])}</p><details><summary>两端房间原画对照</summary><div class="seam-refs">{refshtml}</div><p>两端图是造型、材质与地标参考。中间接续为联合重绘，仍需后续按工程坐标制成分层母版。</p></details>
        <details><summary>{b['id']} 实际英文绘图提示词</summary><pre>{e(p['prompt'])}</pre><p>内置 imagegen · {e(p['generation'])}</p></details></article>'''
    write(src/'connections.json',d)
    write(src/'prompts.json',{'tool':'built-in image_gen','scope':'six connector concepts only','images':prompts})
    write(src/'art-manifest.json',{'schemaVersion':1,'images':art})
    write(src/'reference-manifest.json',{'files':[{'file':f,'sha256':s} for f,s in refs.items()]})
    write(src/'production.json',{'stage':'concept_delivered','scope':d['scope'],'images':len(art),'edges':EXPECTED,'runtime':'unchanged','userArtReview':'pending','atlas':'docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html','next':'根据反馈精修；方向确认后先制E01联合分层母版，不直接拼贴概念图。'})
    return html

STYLE='''
.edge-gallery{display:block}.seam{margin:28px 0;padding:24px}.seam h3{font-size:26px;margin:5px 0 0}.seam h4{font-size:18px;margin:18px 0 5px}.seam-board{position:relative;isolation:isolate}.seam-board img{width:100%;height:auto}.seam-board.vertical{max-width:860px;margin:auto}.seam-route{position:absolute;inset:0;width:100%;height:100%;background:none!important;pointer-events:none;overflow:visible}.seam-route polyline{fill:none;stroke:#f5cf8f;stroke-width:.23;stroke-dasharray:1.4 1.1;opacity:.8}.seam-tag{position:absolute;transform:translate(-50%,-50%);background:#081923ed;color:#f1d6ae;border:1px solid #bba47599;border-radius:5px;padding:4px 9px;font-size:clamp(8px,1vw,14px);white-space:nowrap;pointer-events:none}.seam-tag b{color:#8ec8d3;margin-right:4px}.hide-seam-notes .seam-route,.hide-seam-notes .seam-tag{display:none}.seam-stages{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin-top:20px}.seam-stages p{margin-top:6px}.seam-refs{display:grid;grid-template-columns:1fr 1fr;gap:20px}.seam-refs figure{margin:0}.seam-caption{font-size:13px;color:var(--muted)}.seam-tools{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin:20px 0}@media(max-width:800px){.seam{padding:12px}.seam-stages,.seam-refs{grid-template-columns:1fr;gap:5px}.seam h3{font-size:22px}.seam-tag{padding:2px 4px}.seam-board.vertical{max-width:100%}}
'''
SCRIPT='''document.querySelector('#seam-notes')?.addEventListener('click',function(){const hidden=document.querySelector('#connections').classList.toggle('hide-seam-notes');this.setAttribute('aria-pressed',String(!hidden))});'''
