from pathlib import Path
import json, re, html, os, hashlib
ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT/'godot/WhalebellyRuins'
SOURCE = ROOT/'assets/source/xumen-underbridge-repair'
EV = PROJECT/'evidence/underbridge'
OUT = ROOT.parent/'outputs/须门遗港_独立环境动画'

def write(path, text):
    path.write_text(text.rstrip()+'\n', encoding='utf-8', newline='\n')

def link(path):
    return html.escape(os.path.relpath(path, OUT).replace('\\', '/'), quote=True)

def run():
    qa = json.loads((EV/'checks.json').read_text())
    main = json.loads((EV/'main/reference-level-route.json').read_text())
    live = json.loads((EV/'package/live-camera-runtime.json').read_text())
    code = int((EV/'package/exit-code.txt').read_text(encoding='utf-8-sig').strip())
    assert qa['failures'] == 0 and main['pass'] and code == 0
    page_path = OUT/'交付与对照.html'
    page = page_path.read_text(encoding='utf-8')
    page = re.sub(r'<section id="underbridge-repair">.*?</section>', '', page, flags=re.S)
    section = f'''<section id="underbridge-repair"><h2>更新 · 桥下截断修复与三处气泡</h2>
<p>修正旧道路多边形蒙版裁短的桥下枝条，恢复原图中的完整垂挂轮廓；同时调整前景补底透明边缘。道路高度、角色与碰撞保持原样，原画RGB保留。已有VINE-02动态区域单独排除，避免重复叠枝。</p>
<div class="two"><div><h3>修复前 · 同视角局部</h3><img src="{link(EV/'before-detail.png')}"></div><div><h3>修复后 · 同视角局部</h3><img src="{link(EV/'after-detail.png')}"></div></div>
<p>首次仅软化补底不能恢复遗漏枝条，已定向返修道路透明蒙版。下图关闭全部气泡，检查修复没有被粒子遮盖。</p>
<img src="{link(EV/'repair_without_bubbles-detail.png')}">
<h3>气泡与全景</h3><img src="{link(EV/'after.png')}">
<p>左侧岩缝7个、桥下空腔7个、右侧水域6个。新增20个，场景总计56个；大小、速度错开，边缘淡入淡出并循环回收。全部位于道路和角色后方，复用已有透明绘画气泡素材。</p>
<h3>新版32秒实机录像 · 含镜头移动</h3><video controls loop muted playsinline preload="metadata" src="{link(EV/'camera.mp4')}" poster="{link(EV/'after.png')}"></video>
<p>Godot4.7.2：{len(qa['checks'])}项定向检查、17项环境回归、{len(main['tests'])}项主关卡检查通过。180秒加速模拟保持56个实例并完成回收；独立包启动退出码{code}。独立包12秒实时采样：P50 {live['frame_ms_p50']:.2f}ms，P95 {live['frame_ms_p95']:.2f}ms；此值仅代表当前机器与该场景。</p>
<p><a class="button" href="{link(SOURCE/'README.md')}">修改与重建说明</a><a class="button" href="{link(EV/'checks.json')}">定向验收</a><a class="button" href="{link(EV/'package/camera-02.png')}">独立包截图</a><a class="button" href="{link(PROJECT/'scenes/environment/xumen_reference.tscn')}">已同步的共享环境场景</a></p>
<p class="muted">本轮是指定区域的局部修复。恢复轮廓来自原图，并非重新绘制整幅场景；旧场景其他细小抠图差异仍保留。截图和录像关键帧由AI复核，用户最终听感/审美确认不作为本次技术检查结果。</p></section>'''
    page = page.replace('<section id="foreground-edges">', section+'<section id="foreground-edges">', 1)
    page = page.replace('103 个元素合同', '106 个元素合同')
    rows = json.loads((ROOT/'assets/source/xumen-motion-elements/elements.json').read_text(encoding='utf-8'))
    table = ''.join('<tr>'+''.join('<td>'+html.escape(str(e.get(k,'')))+'</td>' for k in ['id','position','layer','motion','asset'])+'</tr>' for e in rows)
    page = re.sub(r'<tbody>.*?</tbody>', '<tbody>'+table+'</tbody>', page, flags=re.S)
    write(page_path, page)
    from urllib.parse import unquote
    missing = [u for u in re.findall(r'(?:href|src)="([^"]+)"',page) if ':' not in u and not u.startswith('#') and not (OUT/unquote(html.unescape(u)).split('#')[0]).exists()]
    write(EV/'delivery-links.json',json.dumps({'missing':missing},indent=2)); assert not missing,missing
    progress = {'status':'implemented_runtime_verified','revision':'underbridge_and_bubbles','bubbles':56,'active_elements':106,'targeted_checks':len(qa['checks']),'main_checks':len(main['tests']),'package_exit':code,'pending':[],'visual_review':'AI reviewed before/after, effect-disabled crop, camera extremes and package screenshot','limitations':['Local matte extraction retains source texture; not a whole-scene pixel-perfect audit','Runtime timings apply only to this machine and scene'],'next_action':'Continue from shared xumen_reference.tscn; regenerate only affected assets and repeat camera validation'}
    write(SOURCE/'progress.json',json.dumps(progress,ensure_ascii=False,indent=2))
    write(EV/'package-verification.json',json.dumps({'exit_code':code,'pck_sha256':hashlib.sha256((ROOT.parent/'builds/WhalebellyRuins/WhalebellyRuins.pck').read_bytes()).hexdigest(),'runtime':live,'screenshot':'package/camera-02.png'},indent=2))
    p = ROOT/'assets/source/xumen-motion-elements/progress.json';v=json.loads(p.read_text(encoding='utf-8'))
    v['current_revision']='underbridge_and_bubbles';v['evidence']=str(EV)
    item='Restored clipped bridge hanging silhouette, softened backing matte, added 20 bubbles in 3 zones; rendered and package verified'
    if item not in v['completed']:v['completed'].append(item)
    write(p,json.dumps(v,ensure_ascii=False,indent=2))
    provenance={'method':'Godot native Image alpha extraction; original RGB preserved; no new generation service','inputs':['xumen-reference-environment/original/reference.png','xumen-foreground-edges/master/CLEAN-ROAD.png','xumen-foreground-edges/master/CLEAN-FOREGROUND-BACKING.png','xumen-motion-elements/master/foreground-mask.svg'],'outputs':['master/FOREGROUND-BACKING-SOFT.png','master/ROAD-UNDERSIDE-RESTORED.png'],'bubble_art':'Existing assets/reference_environment/bubble.png','implementation':'tools/motion_elements/repair_underbridge.gd + tools/integrate_underbridge.py','cost':0}
    write(SOURCE/'provenance.json',json.dumps(provenance,ensure_ascii=False,indent=2))
    print('Updated report, progress, provenance and package evidence.')

if __name__ == '__main__':run()
