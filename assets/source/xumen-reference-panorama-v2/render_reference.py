"""Native original-image placement plus optional versioned scene-redesign overlays."""
from pathlib import Path
from html import escape as e
import json,hashlib
from PIL import Image
SRC=Path(__file__).resolve().parent
ROOT=SRC.parents[2]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
def build():
    refs=read(SRC/'inputs.json');coverage=read(SRC/'coverage.json')
    layout=read(ROOT/'assets/source/xumen-keyart-v2/inputs/runtime-layout.json')
    edges=read(ROOT/'assets/source/xumen-seam-keyart-v1/art-manifest.json')['images']
    base='../../../assets/source/xumen-reference-panorama-v2/'
    byfile={Path(r['file']).name:r for r in refs}
    bits=['<svg class="faithful-world" xmlns="http://www.w3.org/2000/svg" viewBox="-640 -1880 11584 3520" role="img" aria-label="七房原尺寸布局与可切换进阶地形，保留六条连接"><defs>']
    plans=[]
    for a in edges:
        eid=a['id'];src='../../../assets/source/xumen-seam-keyart-v1/'+a['file']
        if eid in ['E01','E02','E03','E04']:
            s=next(s for s in layout['surfaces'] if s['id']==eid);x=s['points'][0][0];right=s['points'][-1][0];y=s['points'][0][1]
            floor={'E01':560,'E02':570,'E03':590,'E04':550}[eid]
            clip=[x,y-650,right-x,1050];place=[(x+right)/2-a['width']/2,y-floor,a['width'],a['height']]
        elif eid=='E33':
            clip=[1850,-790,465,1070];scale=.714;place=[2123-260*scale,103.847-1310*scale,a['width']*scale,a['height']*scale]
        else:
            clip=[3690,-1040,500,1390];place=[3893-650,190.847-1280,a['width'],a['height']]
        x,y,w,h=clip
        bits.append(f'<clipPath id="clip-{eid}"><rect x="{x}" y="{y}" width="{w}" height="{h}"/></clipPath>')
        plans.append({'id':eid,'source':src,'clip':clip,'placement':place,'scalePurpose':'connection-only crop; no room pixels changed'})
    bits.append('</defs>')
    for p in plans:
        x,y,w,h=p['placement']
        bits.append(f'<g data-reference-edge="{p["id"]}" clip-path="url(#clip-{p["id"]})"><image href="{e(p["source"])}" x="{x}" y="{y}" width="{w}" height="{h}"/></g>')
    manifest=[]
    for room,c in zip(layout['rooms'],coverage['rooms']):
        r=byfile[c['file']];f=SRC/r['file'];assert hashlib.sha256(f.read_bytes()).hexdigest()==r['sha256']
        x,y=room['origin'];w,h=r['width'],r['height']
        bits.append(f'<image class="locked-room" id="locked-{c["id"]}" data-reference-room="{c["id"]}" data-source-sha="{r["sha256"]}" href="{base}{r["file"]}" x="{x}" y="{y}" width="{w}" height="{h}" preserveAspectRatio="xMinYMin meet"/>')
        manifest.append({'id':c['id'],'source':r['file'],'worldOrigin':[x,y],'intrinsicSize':[w,h],'displaySize':[w,h],'sha256':r['sha256'],'preserved':'entire source image, byte-identical file, native-size image element','mustKeep':c['mustKeep']})
    # Original files stay unchanged; seam and challenge proposals use separate layers.
    import sys
    sys.path.insert(0,str(ROOT/'assets/source/xumen-seam-repaint-v2'))
    from render_seams import build as build_seams, controls as seam_controls, notes as seam_notes
    bits.append(build_seams())
    sys.path.insert(0,str(ROOT/'assets/source/xumen-transition-polish-v3'))
    from render_polish import build as build_polish, controls as polish_controls
    bits.append(build_polish())
    sys.path.insert(0,str(ROOT/'assets/source/xumen-challenge-v1'))
    from render_challenge import build as build_challenge, controls as challenge_controls, section as challenge_section
    bits.append(build_challenge())
    # Notes outside the artwork; a separate layer can be hidden.
    bits.append('<g class="reference-room-notes" aria-hidden="true">')
    for room,c in zip(layout['rooms'],coverage['rooms']):
        x,y=room['origin'];r=byfile[c['file']];cx=x+r['width']/2;yy=y-42
        bits.append(f'<g><rect x="{cx-430}" y="{yy-130}" width="860" height="140" rx="25" fill="#061b25e8"/><text x="{cx}" y="{yy-35}" fill="#ecd8ac" font-size="90" text-anchor="middle">{c["id"]} {e(c["name"])}</text></g>')
    bits.append('</g></svg>')
    world=''.join(bits)
    # A standalone editable composition links back to the chapter atlas.
    standalone=world.replace('</defs>','</defs><style>.reference-room-notes{font-family:system-ui,"Microsoft YaHei",sans-serif}.challenge-route-guide{display:none}</style>')
    (SRC/'原图保真全景.svg').write_bytes(standalone.encode('utf-8'))
    repaints=read(ROOT/'assets/source/xumen-seam-repaint-v2/specs.json')
    save(SRC/'assembly.json',{'type':'native room sources with contextual boundary repaint layers; static concept assembly','canvas':layout['canvas'],'rooms':manifest,'connections':plans,'boundaryRepaints':repaints,'structuralPolish':read(ROOT/'assets/source/xumen-transition-polish-v3/specs.json'),'ecologyDetails':read(ROOT/'assets/source/xumen-ecology-niches-v1/design.json'),'challengeProposal':{'source':'../xumen-challenge-v1/design.json','paintings':7,'enemySheet':'../xumen-challenge-v1/images/enemy-lanternfin.png','defaultVisible':True,'originalSourcesUnchanged':True,'roomOriginsUnchanged':True,'edgesUnchanged':True,'status':'static concept, not runtime collision or AI'},'referenceCount':8,'activeRoomCount':7,'roomInteriorResampling':False,'borderOverlays':True,'runtimeChanged':False,'seamStatus':'V3 plus coral niches and one solid-root glow object; static browser review; user art and engine acceptance pending'})
    buttons=''.join(f'<button data-reference-focus="{c["id"]}">{c["name"]}</button>' for c in coverage['rooms'])
    cards=''
    for c in coverage['rooms']:
        r=byfile[c['file']]
        cards+=f'<article class="preservation-card" id="preserved-{c["id"]}"><h3>{c["id"]} {e(c["name"])}</h3><button data-reference-focus="{c["id"]}">在总览中定位此房</button><a href="{base}{r["file"]}" target="_blank"><img src="{base}{r["file"]}" alt="{e(c["name"])}本轮锁定原图" width="{r["width"]}" height="{r["height"]}" loading="lazy"></a><ul>'+''.join('<li>'+e(s)+'</li>' for s in c['mustKeep'])+'</ul></article>'
    html=f'''<section id="real-scene"><span class="eyebrow">REFERENCE-LOCKED PANORAMA / ROOM COMPOSITIONS PRESERVED</span><h2>实景总览 · 完整原图保留版</h2><p class="lead">你提供的房间构图直接进入这张总览：拱路、四环横渡、舌台下层、宽战台、短冲断岛和升高大平台都保留。全图可缩放，点击房名可直接聚焦原尺寸细节。</p><p class="notice">上一版概括全景把房间简化成地形符号，不能代表这些完整设计，已降为历史稿。本版锁定七房原图；六段接续使用独立过渡原画放在连接区，原房内部不重新生成。当前是保真排布母版，接续像素接缝与引擎效果仍需后续验收。</p><div class="reference-tools"><button data-reference-action="fit">全区总览</button><button data-reference-action="native">原尺寸查看</button><button data-reference-action="notes" aria-pressed="true">房名标记</button><button data-reference-action="entry" aria-pressed="false">切换外伤坡版本</button><a href="{base}原图保真全景.svg" target="_blank">独立打开母版 ↗</a></div><div class="reference-focus-tools">{buttons}</div><div class="reference-scroll" tabindex="0"><div class="reference-canvas">{world}</div></div><p class="reference-status" role="status">全区总览 · 七房完整原图 / 六条接续</p><p class="scene-caption">全区缩小只影响浏览显示；原图仍按原尺寸保存在母版中。按“原尺寸查看”或点击房名，即可检查这些场景有没有被省略。两条上行支路仍只从须筛出发，上层两房不新增横向连接。</p><details><summary>本轮八张附件如何对应七个房间</summary><p>图1和图3是外伤坡的两版同构图。本版默认使用图3（与现有房间尺寸一致），可切换图1，其余图分别锁定为六房；两版没有被当作两个新房。</p><img src="{base}inputs/01-entry-alt.png" alt="图1外伤坡备选原图" loading="lazy"><p><a href="{base}assembly.json">排布与尺寸</a> · <a href="{base}inputs.json">来源及哈希</a> · <a href="{base}coverage.json">设计保留清单</a> · <a href="{base}acceptance.md">审核记录</a></p></details><h3>逐房核对：以下内容均在上方总览中</h3><div class="preservation-grid">{cards}</div><p class="notice">奖励簇、角色姿势和装饰按你本轮原图保留，不据画面新增玩法实例。器官适配与像素接缝另行处理，不再通过改写房间内部来“统一风格”。本轮未修改Godot工程。</p></section>'''
    html=html.replace('实景总览 · 完整原图保留版','实景总览 · 七房保留＋六处接缝精修')
    html=html.replace('当前是保真排布母版，接续像素接缝与引擎效果仍需后续验收。','六处接口已有独立局部重绘与可编辑叠合蒙版；当前只作静态原画接续，不代表引擎接入。')
    html=html.replace('<div class="reference-focus-tools">',seam_notes()+seam_controls()+'<div class="reference-focus-tools">',1)
    html=html.replace('<div class="reference-focus-tools seam-focus-tools">',polish_controls()+'<div class="reference-focus-tools seam-focus-tools">',1)
    html=html.replace('实景总览 · 七房保留＋六处接缝精修','实景总览 · 过渡结构再精修')
    html=html.replace('实景总览 · 过渡结构再精修','实景总览 · 进阶跳跃与飞怪设计')
    html=html.replace('你提供的房间构图直接进入这张总览：拱路、四环横渡、舌台下层、宽战台、短冲断岛和升高大平台都保留。全图可缩放，点击房名可直接聚焦原尺寸细节。','当前默认展示本轮进阶方案：七房世界位置、六条连接和原能力门保持，房内地形改为错台、断沟与连续跳跃。关闭“进阶地形”可查看此前完整原图与接缝。')
    html=html.replace('本版锁定七房原图；六段接续使用独立过渡原画放在连接区，原房内部不重新生成。','旧版七房源文件不变；本轮另绘七房地形候选，用独立可切换图层覆盖房内。六段接续和生态装饰沿用前版。')
    html=html.replace('全区总览 · 七房完整原图 / 六条接续','全区总览 · 进阶设计候选 / 七房六边')
    html=html.replace('全区缩小只影响浏览显示；原图仍按原尺寸保存在母版中。按“原尺寸查看”或点击房名，即可检查这些场景有没有被省略。','全区缩小只影响浏览显示；房位和旧源图尺寸保持。点击房名检查新地形，打开“候选落点／跳线”查看拟定坐标；绘景轮廓与候选线仍需引擎阶段对齐。')
    html=html.replace('奖励簇、角色姿势和装饰按你本轮原图保留，不据画面新增玩法实例。','奖励数量与六边关系沿旧设计保留；本轮明确新增8只拟定飞怪，原画姿态不代表已制作动作。')
    html=html.replace('</h2>','</h2>'+challenge_controls(),1)
    html=html.replace('<h3>逐房核对：以下内容均在上方总览中</h3>',challenge_section()+'<h3>原房原画对照 · 关闭进阶地形后查看</h3>')
    html=html.replace('器官适配与像素接缝另行处理，不再通过改写房间内部来“统一风格”。','六处边界沿用精修；进阶层按本轮授权调整房内地形，旧源图完整保留；引擎适配与用户审美验收另行记录。')
    return html
STYLE='''
.reference-tools,.reference-focus-tools{display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin:14px 0}.reference-tools button[aria-pressed="true"]{border-color:#d4b97d}.reference-scroll{overflow:auto;max-height:76vh;min-height:240px;background:#071923;border:1px solid #45616a;border-radius:6px;overscroll-behavior:contain}.reference-canvas{width:100%;position:relative}.faithful-world{display:block;width:100%;height:auto;background:none;border-radius:0}.faithful-world text{font-family:system-ui,"Microsoft YaHei",sans-serif;font-size:90px;fill:#ecd8ac}.reference-room-notes{pointer-events:none}.hide-reference-notes .reference-room-notes{display:none}.reference-status{font-size:14px;color:#d6c393}.preservation-grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}.preservation-card{background:#102630;border:1px solid #34515a;padding:16px;border-radius:7px}.preservation-card img{margin-top:12px}.preservation-card h3{margin-top:0}@media(max-width:800px){.preservation-grid{grid-template-columns:1fr}.reference-tools,.reference-focus-tools{gap:7px;font-size:13px}.reference-focus-tools button{font-size:12px;padding:6px 9px}}
'''
SCRIPT='''(()=>{const root=document.querySelector('#real-scene');if(!root)return;const canvas=root.querySelector('.reference-canvas'),scroller=root.querySelector('.reference-scroll'),status=root.querySelector('.reference-status');const rooms=JSON.parse(root.querySelector('.reference-data').textContent);let alternate=false;const fit=()=>{canvas.style.width='100%';scroller.scrollTo(0,0);status.textContent='全区总览 · 七房六边 / 设计对照'};root.querySelectorAll('[data-reference-action]').forEach(button=>button.addEventListener('click',()=>{const a=button.dataset.referenceAction;if(a==='fit')fit();else if(a==='native'){canvas.style.width='11584px';status.textContent='原尺寸查看 · 可在图内横向、纵向滚动'}else if(a==='notes'){const hidden=root.classList.toggle('hide-reference-notes');button.setAttribute('aria-pressed',String(!hidden))}else if(a==='entry'){root.classList.add('hide-challenge');alternate=!alternate;const im=root.querySelector('#locked-R1-01');im.setAttribute('href',alternate?'../../../assets/source/xumen-reference-panorama-v2/inputs/01-entry-alt.png':'../../../assets/source/xumen-reference-panorama-v2/inputs/03-entry.png');button.setAttribute('aria-pressed',String(alternate));status.textContent=alternate?'外伤坡：图1原图版本':'外伤坡：图3原图版本'}}));root.querySelectorAll('[data-reference-focus]').forEach(button=>button.addEventListener('click',()=>{const r=rooms.find(x=>x.id===button.dataset.referenceFocus);const width=Math.max(6000,scroller.clientWidth/r.intrinsicSize[0]*11584*.84);canvas.style.width=width+'px';requestAnimationFrame(()=>{const scale=width/11584;scroller.scrollLeft=(r.worldOrigin[0]+640)*scale-35;scroller.scrollTop=(r.worldOrigin[1]+1880)*scale-25;scroller.scrollIntoView({block:'center',behavior:'instant'});status.textContent=r.id+' '+button.textContent+(root.classList.contains('hide-challenge')||root.classList.contains('hide-polish')||root.classList.contains('hide-painted-seams')?' · 原方案聚焦':' · 进阶候选聚焦（未接入）')})}));})();'''
def data_script():
    return '<script type="application/json" class="reference-data">'+json.dumps(read(SRC/'assembly.json')['rooms'],ensure_ascii=False)+'</script>'
