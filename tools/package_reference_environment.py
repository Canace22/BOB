"""Build the local review page from actual Godot evidence, without image edits."""
from pathlib import Path
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/source/xumen-reference-environment'
EVIDENCE = ROOT / 'godot/WhalebellyRuins/evidence/reference_environment'
OUT = ROOT.parent / 'outputs/须门遗港_参考图环境场景'
OUT.mkdir(parents=True, exist_ok=True)
for path in EVIDENCE.glob('*.png'):
    if path.name.startswith(('layer-', 'pan-', 'static-final', 'motion-')):
        shutil.copy2(path, OUT / path.name)
shutil.copy2(SOURCE / 'original/reference.png', OUT / 'reference.png')
for filename in ['runtime-report.json', 'asset-audit.json']:
    shutil.copy2(EVIDENCE / filename, OUT / filename)
elements = json.loads((SOURCE / 'elements.json').read_text(encoding='utf8'))['elements']
report = json.loads((EVIDENCE / 'runtime-report.json').read_text(encoding='utf8'))
rows = []
for e in elements:
    file = 'bubble.png' if e['id'].startswith('BUBBLE') else e['id'] + '.png'
    link = '../../BOB/assets/runtime/xumen-reference-environment/' + file
    box = ', '.join(map(str, e.get('actual_source_rect', e['reference_box'])))
    rows.append(f'<tr><td><a href="{link}">{html.escape(e["id"])}</a></td><td>{html.escape(e["name"])}</td><td>{box}</td><td>{e["layer"]}</td><td>{e["instances"]}</td><td>{html.escape(e["motion_description"])}</td></tr>')
layers = [('background','远景与中景'),('structure','洞顶／侧壁／道路／静态装饰'),('foliage','垂须与软植物（含固定附着像素）'),('atmosphere','光束、灯、鱼群、气泡'),('foreground','深色前景'),('character','独立展示角色')]
cards = ''.join(f'<figure><a href="layer-{key}.png"><img loading="lazy" src="layer-{key}.png"></a><figcaption>{name}</figcaption></figure>' for key,name in layers)
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>须门遗港 · 本轮参考图环境场景</title>
<style>body{margin:0;background:#07151d;color:#d7e8eb;font:16px/1.7 system-ui}main{max-width:1280px;margin:auto;padding:32px}h1{font-size:36px;line-height:1.3}h2{margin-top:48px}a{color:#9bdad7}p{max-width:1000px}nav{display:flex;gap:24px;flex-wrap:wrap;padding:18px 0}.tag{color:#e9c891;letter-spacing:.15em}.compare{position:relative;aspect-ratio:16/9;background:#000}.compare img{position:absolute;width:100%;height:100%;object-fit:contain}#overlay{clip-path:inset(0 50% 0 0)}input{width:100%;accent-color:#e2bd7b}video{width:100%;background:#000}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0;background:#102630}figure img{width:100%}figcaption{padding:12px}table{border-collapse:collapse;width:100%;font-size:13px}th,td{text-align:left;padding:10px;border-bottom:1px solid #29424a}th{background:#122d38;position:sticky;top:0}.scroll{overflow:auto}.note{padding:20px;background:#162c34;border-left:3px solid #e2bd7b}code{color:#e8c794}footer{margin:60px 0;color:#8eaab5}@media(max-width:800px){main{padding:16px}.grid{grid-template-columns:1fr}h1{font-size:28px}}</style>
<main><div class="tag">REFERENCE ENVIRONMENT · GODOT 4.7.2</div><h1>须门遗港<br>单屏环境重构</h1><p>只使用本轮参考图制作。独立环境场景：46个贴图节点、4区36个气泡；静态展示角色，轻微环境动态。未新增玩法、碰撞或角色控制。</p>
<nav><a href="#compare">原图对照</a><a href="#video">动态录像</a><a href="#layers">拆层实机图</a><a href="#elements">元素清单</a><a href="../../BOB/godot/WhalebellyRuins/scenes/environment/xumen_reference.tscn">Godot场景</a><a href="../../BOB/assets/source/xumen-reference-environment/README.md">母版与操作说明</a></nav>
<h2 id="compare">同机位对照</h2><p>拖动滑块：左侧为Godot实际截图，右侧为用户原图。画幅1280×720。</p><div class="compare"><img src="reference.png" alt="用户原图"><img id="overlay" src="static-final.png" alt="Godot实际截图"></div><input aria-label="实机与原图分隔位置" type="range" min="0" max="100" value="50" oninput="document.getElementById('overlay').style.clipPath='inset(0 '+(100-this.value)+'% 0 0)'"><p><a href="static-final.png">打开完整实机截图</a> · <a href="reference.png">打开原图</a></p>
<h2 id="video">24秒环境动态</h2><video controls loop muted playsinline preload="metadata" poster="static-final.png" src="环境动态演示.mp4"></video><p>Godot原生帧录制，1280×720、30fps。垂须/软植物微摆、鱼群慢漂、分区气泡、克制光变和小幅视差。动作故意很轻；角色保持原姿态。此视频没有音轨。</p>
<h2>运行与编辑</h2><p>打开唯一工程 <a href="../../BOB/godot/WhalebellyRuins/project.godot">project.godot</a>，打开 <code>scenes/environment/xumen_reference.tscn</code>，按 <b>F6</b> 运行当前场景。F5仍进入既有游戏。也可运行 <a href="../../BOB/godot/WhalebellyRuins/preview-reference-environment.ps1">预览脚本</a>，加 <code>-Pan</code> 查看微量视差。</p><p>根节点可调 Animate Environment、Camera Drift、Motion Strength。原件＋SVG选区＋补绘PNG＋布局JSON＋Godot节点/材质构成可编辑母版。</p>
<div class="note"><b>实际验收与边界</b><p>PERFORMANCE</p><p>无空纹理，物理碰撞节点为0；四个微移机位已检查。主要构图与原位置保留，但不是逐像素复原：顶部水体和细部轮廓存在补绘差异；垂须裁片保留固定的附着组织，尚非可随意移植到另一房间的通用精修单件。没有验收大幅镜头运动、不同GPU或低配机。</p><a href="runtime-report.json">性能报告</a> · <a href="asset-audit.json">素材与节点审计</a> · <a href="../../BOB/assets/source/xumen-reference-environment/review/acceptance.md">完整验收记录</a></div>
<h2 id="layers">六组图层实机独显</h2><p>以下由Godot实际隐藏/显示节点输出，底色用于检查透明边缘。</p><div class="grid">CARDS</div>
<h2 id="elements">50个元素与装饰簇</h2><p>点击ID打开独立透明素材；坐标为原图坐标，或导出裁片实际边界。静态细碎硬壳按簇组织，不逐像素虚构节点。</p><div class="scroll"><table><thead><tr><th>ID／素材</th><th>名称</th><th>x,y,w,h</th><th>层级</th><th>数量</th><th>运动／保持</th></tr></thead><tbody>ROWS</tbody></table></div>
<footer>2026-10-28 · 原件、来源、返修与执行指令均保存在 assets/source/xumen-reference-environment。美术审查为AI自检，保留用户后续视觉反馈入口。</footer></main></html>'''
perf = f'本机 {report["renderer"]}，连续 {report["seconds"]:.1f}秒；实测帧间隔中位数 {report["frame_ms_p50"]:.2f}ms、P95 {report["frame_ms_p95"]:.2f}ms。36个气泡共回收{report["bubble_recycles"]}次，约{report["texture_memory_bytes"]/1048576:.1f}MiB纹理占用。'
page = page.replace('PERFORMANCE',perf).replace('CARDS',cards).replace('ROWS',''.join(rows))
(OUT / '交付与对照.html').write_text(page, encoding='utf8')
print(OUT / '交付与对照.html')
