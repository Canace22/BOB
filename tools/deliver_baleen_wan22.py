from pathlib import Path
import json,re,html,os,zipfile,hashlib
from xml.etree import ElementTree as ET
ROOT=Path(__file__).resolve().parents[1];BASE=ROOT/'assets/source/baleen-wan22';P=ROOT/'godot/WhalebellyRuins';EV=P/'evidence/baleen_wan22'
OUT=ROOT.parent/'outputs/须门遗港_独立环境动画'
def write(p,s):p.write_text(s.rstrip()+'\n',encoding='utf-8',newline='\n')
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2))
def link(p):return html.escape(os.path.relpath(p,OUT).replace('\\','/'),quote=True)
def main():
    manifest=json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    checks=[]
    for j in manifest:
        with zipfile.ZipFile(BASE/'krita'/f'{j["id"]}.kra') as z:
            doc=ET.fromstring(z.read('maindoc.xml'))
            fps=next(e for e in doc.iter() if e.tag.split('}')[-1]=='framerate').attrib['value']
            keyfiles=[x for x in z.namelist() if x.endswith('.keyframes.xml')]
            times=[]
            for f in keyfiles:
                xml=ET.fromstring(z.read(f));times += [int(e.attrib['time']) for e in xml.iter() if e.tag.split('}')[-1]=='keyframe']
            checks.append({'id':j['id'],'native_kra_fps':int(fps),'keyframes':len(times),'pass':int(fps)==12 and sorted(times)==list(range(36))})
    dump(BASE/'metadata/krita-file-checks.json',checks);assert all(c['pass'] for c in checks)
    qa=json.loads((EV/'checks.json').read_text());mainqa=json.loads((EV/'main-current/checks.json').read_text())
    env=json.loads((P/'evidence/motion_elements/checks.json').read_text());loop=json.loads((P/'evidence/motion_elements/loop-render.json').read_text())
    assert not any(x['failures'] for x in [qa,mainqa,env,loop])
    package=json.loads((EV/'package/live-camera-runtime.json').read_text());code=int((EV/'package/exit-code.txt').read_text())
    assert code==0
    dump(EV/'package-verification.json',{'exit_code':code,'pck_sha256':hashlib.sha256((ROOT.parent/'builds/WhalebellyRuins/WhalebellyRuins.pck').read_bytes()).hexdigest(),'runtime':package})
    rows=''.join(f'<tr><td>{j["id"]}</td><td>{j["width"]}×{j["height"]}</td><td>36 / 12 FPS / 3秒</td><td>{j["max_displacement"]:.2f}px</td><td><a href="{link(BASE/"krita"/(j["id"]+".kra"))}">Krita母版</a> · <a href="{link(BASE/"videos"/(j["id"]+"-12fps.mp4"))}">独立动画</a></td></tr>' for j in manifest)
    body=f'''<h2>四处垂须 · ComfyUI + Wan2.2 5B + Krita</h2>
<p>四组独立动画，合计144张RGBA PNG。每组36张互不相同的帧，固定12 FPS、3秒播放。49帧/24 FPS源视频实际2.041667秒，按ceil(时长)×12取36张；将完整源运动重定时至3秒，加入柔和回位，不复制末帧凑数量。</p>
<h3>当前游戏效果 · 32秒实机录像</h3><video controls loop muted playsinline preload="metadata" src="{link(EV/'camera.mp4')}" poster="{link(EV/'frame-18.png')}"></video>
<p>左、中央、右侧乳白垂须固定根部、末端轻摆；远景蓝色垂帘保持外沿，内部轻微运动。四组分别接入现有BALEEN节点，主关卡与环境预览共用。</p>
<table><thead><tr><th>元素</th><th>帧尺寸</th><th>播放规格</th><th>最大位移</th><th>文件</th></tr></thead><tbody>{rows}</tbody></table>
<h3>生成来源与处理边界</h3><video controls muted loop playsinline preload="metadata" src="{link(BASE/'videos/CONTEXT-MOTION-source.mp4')}"></video>
<p>实际本地ComfyUI 0.42.0调用Wan2.2 TI2V 5B，FP16模型文件以FP8加载，未使用付费服务。第一份孤立垂须样片出现彩色条纹与形体融化，已拒绝。第二份完整场景片可提供运动，但包含轻微整体漂移，因此最终使用视频光流驱动原画RGBA、锁定根部并修正循环。最终帧属于“视频运动派生原画动画”，不是直接逐帧抠出生成画面，也不是Krita逐帧手绘。</p>
<p>Krita 5.3.4.1实际导入每组36关键帧，保存12 FPS、0–35时间轴，可编辑KRA；新增手绘修正层目前为空。原始视频、工作流、prompt ID、运动场与帧映射均保留。</p>
<div class="two"><div><h3>Krita母版预览</h3><img src="{link(BASE/'review/BALEEN-CENTER-krita.png')}"></div><div><h3>主关卡实际移动</h3><img src="{link(EV/'main-current/walk.png')}"></div></div>
<h3>验证</h3><p>{len(qa['checks'])}项垂须定向、{len(env['checks'])}项环境、{len(loop['checks'])}项循环和{len(mainqa['checks'])}项当前主场景检查通过。四组固定根部像素变化0；道路及前景在仅推进垂须时变化0。独立包退出码0，12秒实时采样P50 {package['frame_ms_p50']:.2f}ms、P95 {package['frame_ms_p95']:.2f}ms。</p>
<p class="muted">旧qa_reference_level脚本因当前角色已切换campaign_player而失败，保留失败记录；改用当前tp_*输入验证移动、跳跃、暂停与重新载入环境。本轮没有重验全部关卡玩法。视觉以原片及游戏关键帧复核，用户最终动画观感尚未确认；细丝抠图沿用原资产边缘，远景为内嵌局部形变。</p>
<p><a class="button" href="{link(BASE/'README.md')}">文件与重建说明</a><a class="button" href="{link(BASE/'manifest.json')}">144帧清单</a><a class="button" href="{link(EV/'checks.json')}">实机验收</a></p>'''
    page_path=OUT/'交付与对照.html';page=page_path.read_text(encoding='utf-8')
    page=re.sub(r'<section id="baleen-wan22">.*?</section>','',page,flags=re.S)
    page=page.replace('<section id="underbridge-repair">','<section id="baleen-wan22">'+body+'</section><section id="underbridge-repair">',1)
    write(page_path,page)
    write(OUT/'垂须_Wan22_12FPS.html','<!doctype html><meta charset="utf-8"><title>垂须 · Wan2.2 / 12 FPS</title><style>body{max-width:1120px;margin:40px auto;background:#0b1720;color:#cedde4;font:17px/1.7 system-ui}a{color:#83d9e9}video,img{max-width:100%}table{width:100%;border-collapse:collapse}td,th{border-bottom:1px solid #345;padding:12px}.two{display:grid;grid-template-columns:1fr 1fr;gap:24px}.muted{color:#94a9b4}</style>'+body)
    from urllib.parse import unquote
    missing=[u for u in re.findall(r'(?:href|src)="([^"]+)"',body) if not (OUT/unquote(html.unescape(u)).split('#')[0]).exists()]
    dump(EV/'delivery-links.json',{'missing':missing});assert not missing
    dump(BASE/'progress.json',{'status':'integrated_runtime_verified','frames':144,'groups':4,'fps':12,'seconds_per_group':3,'pending':[],'user_visual_approval':False,'evidence':str(EV),'known_limits':['Video motion reprojected, not direct generated pixels','Fine alpha edge inherited','Legacy controller test incompatible; targeted current-controller tests passed'],'next_action':'Review current movie; tune group motion field gain if requested. Reopen existing KRA, not another project.'})
    p=ROOT/'assets/source/xumen-motion-elements/progress.json';v=json.loads(p.read_text(encoding='utf-8'));v['current_revision']='baleen_wan22_12fps';v['evidence']=str(EV);v['completed'].append('Four Wan2.2 video-derived groups, 36 frames each, 12FPS, native Krita masters and runtime verified');dump(p,v)
    print('Krita keyframes, report links, runtime checks and package verified.')
if __name__=='__main__':main()
