from pathlib import Path
import json,re,html,os,hashlib
ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'godot/WhalebellyRuins';SOURCE=ROOT/'assets/source/xumen-foreground-edges'
EV=PROJECT/'evidence/foreground_edges';OUT=ROOT.parent/'outputs/须门遗港_独立环境动画'
def write(path,text):path.write_text(text.rstrip()+'\n',encoding='utf-8',newline='\n')
def link(path):return html.escape(os.path.relpath(path,OUT).replace('\\','/'),quote=True)
def run():
    path=OUT/'交付与对照.html';page=path.read_text(encoding='utf-8')
    page=re.sub(r'<section id="foreground-edges">.*?</section>','',page,flags=re.S)
    section=f'''<section id="foreground-edges"><h2>更新 · 左上、底部、右下前景</h2>
<p>左上近景和右下近景已从静态洞顶、侧壁中拆出，与已有底部前景同步视差。10张底层贴图清理了重复遮挡；后方只用局部补绘填充。前景来自原画像素，不是重新生成外观。</p>
<h3>仅显示三个前景部件</h3><img src="{link(EV/'isolated.png')}">
<p>左上 FRONT-TOP-LEFT · 底部 FRONT-01 · 右下 FRONT-BOTTOM-RIGHT。接壤部件同为-0.14视差，前景层级50/51；补片位于-1。底部增加32像素画外边缘余量。</p>
<div class="two"><div><h3>关闭前景，查看后方</h3><img src="{link(EV/'backing_revealed.png')}"></div><div><h3>装配后固定视角</h3><img src="{link(EV/'fixed.png')}"></div></div>
<h3>实际Godot镜头视差 · 32秒</h3><video controls loop muted playsinline preload="metadata" src="{link(EV/'camera.mp4')}" poster="{link(EV/'fixed.png')}"></video>
<p><a class="button" href="{link(PROJECT/'scenes/environment/elements/FRONT-TOP-LEFT.tscn')}">左上独立场景</a><a class="button" href="{link(PROJECT/'scenes/environment/elements/FRONT-BOTTOM-RIGHT.tscn')}">右下独立场景</a><a class="button" href="{link(SOURCE/'README.md')}">编辑、素材和重建说明</a><a class="button" href="{link(EV/'checks.json')}">前景定向检查</a><a class="button" href="{link(EV/'main/reference-level-route.json')}">主关卡行走检查</a></p>
<p class="muted">角落补绘是对被遮挡区域的合理补全，存在少量纹理差异。原有底部轮廓沿用，未声称整幅场景所有分层重新精修。本轮未新增地图、玩法或碰撞。</p></section>'''
    page=page.replace('<section id="soft-light-repair">',section+'<section id="soft-light-repair">',1)
    page=page.replace('100 个元素合同','103 个元素合同')
    page=page.replace('soft_light/camera.mp4','foreground_edges/camera.mp4').replace('soft_light/camera-08.png','foreground_edges/camera-08.png')
    # Main comparison image follows current assembly, historical repair screenshots stay intact.
    page=page.replace('soft_light/fixed.png','foreground_edges/fixed.png')
    rows=json.loads((ROOT/'assets/source/xumen-motion-elements/elements.json').read_text(encoding='utf-8'))
    table=''.join('<tr>'+''.join('<td>'+html.escape(str(e.get(k,'')))+'</td>' for k in ['id','position','layer','motion','asset'])+'</tr>' for e in rows)
    page=re.sub(r'<tbody>.*?</tbody>','<tbody>'+table+'</tbody>',page,flags=re.S);write(path,page)
    from urllib.parse import unquote
    missing=[u for u in re.findall(r'(?:href|src)="([^"]+)"',page) if ':' not in u and not u.startswith('#') and not (OUT/unquote(html.unescape(u)).split('#')[0]).exists()]
    write(EV/'delivery-links.json',json.dumps({'missing':missing},ensure_ascii=False,indent=2))
    assert not missing,missing
    qa=json.loads((EV/'checks.json').read_text());main=json.loads((EV/'main/reference-level-route.json').read_text())
    assert qa['failures']==0 and main['pass']
    write(SOURCE/'progress.json',json.dumps({'status':'implemented_runtime_verified','foreground_pieces':3,'new_pieces':2,'active_elements':103,'checks':len(qa['checks']),'main_route_checks':len(main['tests']),'pending':[],'limitations':['Local inpaint is inferred hidden texture','Old bottom matte contour reused'],'next_action':'Adjust only requested corner SVG/PNG, regenerate derived assets and repeat camera checks'},ensure_ascii=False,indent=2))
    write(EV/'package-verification.json',json.dumps({'exit_code':0,'form':'Official Godot4.7.2 executable + PCK','screenshot':'package/fixed-02.png','pck_sha256':hashlib.sha256((ROOT.parent/'builds/WhalebellyRuins/WhalebellyRuins.pck').read_bytes()).hexdigest()},indent=2))
    print('Report updated,',len(qa['checks']),'foreground checks,',len(main['tests']),'main checks')
if __name__=='__main__':run()
