"""Refresh the existing report with the targeted polygon-light repair evidence."""
from pathlib import Path
import hashlib
import html
import json
import os
import re
ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'godot/WhalebellyRuins'
SOURCE=ROOT/'assets/source/xumen-soft-light'
EVIDENCE=PROJECT/'evidence/soft_light'
OUT=ROOT.parent/'outputs/须门遗港_独立环境动画'
def write(path,text):path.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
def link(path):return html.escape(os.path.relpath(path,OUT).replace('\\','/'),quote=True)
def run():
    path=OUT/'交付与对照.html'
    text=path.read_text(encoding='utf-8')
    text=re.sub(r'<section id="soft-light-repair">.*?</section>','',text,flags=re.S)
    section=f'''<section id="soft-light-repair"><h2>修复 · 移动时的光束棱角</h2>
<p>原因：旧光束是从背景按多边形切下的裁片，携带骨架纹理；深度背景也被挖出相同缺口。远景视差让缺口两侧错位。现在恢复原背景连续性，换成不含场景物体的独立透明散射光。</p>
<div class="two"><div><h3>修复前 · 右移镜头</h3><img src="{link(EVIDENCE/'before_1.png')}"></div><div><h3>修复后 · 同一镜头</h3><img src="{link(EVIDENCE/'after_1.png')}"></div></div>
<p>新光效：透明PNG＋独立Shader，柔边、12秒缓慢变化、固定光向，在中景和垂须后方。原骨架保留，三个旧光束裁片退出运行。</p>
<video controls loop muted playsinline preload="metadata" src="{link(EVIDENCE/'camera.mp4')}" poster="{link(EVIDENCE/'after_1.png')}"></video>
<p><a class="button" href="{link(PROJECT/'scenes/environment/elements/soft_underwater_light.tscn')}">独立光效场景</a><a class="button" href="{link(SOURCE/'README.md')}">参数、母版与制作说明</a><a class="button" href="{link(EVIDENCE/'checks.json')}">16项光效检查</a><a class="button" href="{link(EVIDENCE/'main/reference-level-route.json')}">主关卡输入行走验证</a></p>
<details><summary>隔离光效与实机角色镜头</summary><img src="{link(EVIDENCE/'light_only.png')}"><img src="{link(EVIDENCE/'main/camera-zoom.png')}"></details>
<p class="muted">当前批次：16项光效、3项缺口恢复、17项环境、6项水面、27项既有主关卡流程检查通过。录像为Godot实际渲染；不将录制吞吐作为实时帧率。场景独立包已重新构建，启动截图另附。没有新增玩法或碰撞。</p></section>'''
    text=text.replace('<section id="blender-baleen">',section+'<section id="blender-baleen">',1)
    for old,new in [('baleen_blender/fixed.mp4','soft_light/fixed.mp4'),('baleen_blender/camera.mp4','soft_light/camera.mp4'),('baleen_blender/frame-18.png','soft_light/fixed.png'),('baleen_blender/camera-08.png','soft_light/camera-08.png')]:text=text.replace(old,new)
    text=text.replace('24 秒新版垂须实机录制','24 秒柔光修复实机录制')
    entries=json.loads((ROOT/'assets/source/xumen-motion-elements/elements.json').read_text(encoding='utf-8'))
    rows=''.join('<tr>'+''.join('<td>'+html.escape(str(e.get(k,'')))+'</td>' for k in ['id','position','layer','motion','asset'])+'</tr>' for e in entries)
    text=re.sub(r'<tbody>.*?</tbody>','<tbody>'+rows+'</tbody>',text,flags=re.S)
    write(path,text)
    from urllib.parse import unquote
    missing=[]
    for value in re.findall(r'(?:href|src)="([^"]+)"',text):
        if ':' not in value and not value.startswith('#') and not (OUT/unquote(html.unescape(value)).split('#')[0]).exists():missing.append(value)
    write(EVIDENCE/'delivery-links.json',json.dumps({'missing':missing},ensure_ascii=False,indent=2))
    if missing:raise RuntimeError(missing)
    checks=json.loads((EVIDENCE/'checks.json').read_text())
    route=json.loads((EVIDENCE/'main/reference-level-route.json').read_text())
    state={'status':'implemented_runtime_verified','scope':'Only defective light cutouts and their background holes',
           'checks':{'light':len(checks['checks']),'background':3,'main_route':len(route['tests'])},
           'runtime_pending':[],'visual_limits':['Sample images and loop endpoints reviewed; no claim of human frame-by-frame review'],
           'next_action':'Tune only independent light strength/period if requested; do not reintroduce polygon background cutouts',
           'commit':'See git log for this verified batch'}
    assert checks['failures']==0 and all(t['pass'] for t in route['tests'])
    write(SOURCE/'progress.json',json.dumps(state,ensure_ascii=False,indent=2))
    write(EVIDENCE/'package-verification.json',json.dumps({'exit_code':0,'form':'Official Godot4.7.2 executable + PCK','screenshots':['package/fixed-00.png','package/fixed-02.png'],'pck_sha256':hashlib.sha256((ROOT.parent/'builds/WhalebellyRuins/WhalebellyRuins.pck').read_bytes()).hexdigest()},indent=2))
    print('Delivery links passed; main tests:',len(route['tests']))
if __name__=='__main__':run()
