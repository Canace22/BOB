"""Publish local previews and the current painted-baleen asset manifest."""
from pathlib import Path
import html
import json
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'godot/WhalebellyRuins'
SOURCE = ROOT / 'assets/source/baleen-blender'
EVIDENCE = PROJECT / 'evidence/baleen_blender'
OUT = ROOT.parent / 'outputs/须门遗港_独立环境动画'
JOBS = json.loads((SOURCE / 'jobs.json').read_text(encoding='utf-8'))


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + '\n', encoding='utf-8', newline='\n')


def link(path):
    return html.escape(os.path.relpath(path, OUT).replace('\\', '/'), quote=True)


def encode(ffmpeg):
    for job in JOBS:
        width, height = job['rect'][2:]
        args = ['-f', 'lavfi', '-i', f'color=c=0x0b2638:s={width}x{height}:r=12:d=6',
                '-framerate', '12', '-i', str(SOURCE / 'frames' / job['id'] / '%03d.png'),
                '-filter_complex', '[0:v][1:v]overlay=shortest=1:format=auto,format=yuv420p',
                '-frames:v', '72']
        subprocess.run([ffmpeg, '-y', '-loglevel', 'error', *args, '-c:v', 'libx264', '-crf', '17',
                        '-movflags', '+faststart', str(EVIDENCE / (job['id'] + '.mp4'))], check=True)
    for name in ['fixed', 'camera']:
        capture = EVIDENCE / (name + '-capture.avi')
        if capture.exists():
            subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-i', str(capture), '-an',
                            '-c:v', 'libx264', '-crf', '19', '-pix_fmt', 'yuv420p',
                            '-movflags', '+faststart', str(EVIDENCE / (name + '.mp4'))], check=True)


def update_layout():
    path = ROOT / 'assets/source/xumen-motion-elements/master/editable-layout.svg'
    text = path.read_text(encoding='utf-8')
    text = re.sub(r'<g id="BALEEN-(?:0[1-6]|LEFT|CENTER|RIGHT|DISTANT)">.*?</g>\n?', '', text)
    for job in JOBS:
        x, y, width, height = job['rect']
        node = (f'<g id="{job["id"]}"><title>Blender frame 000; z={job["z"]}</title>'
                f'<image x="{x}" y="{y}" width="{width}" height="{height}" '
                f'xlink:href="../../baleen-blender/frames/{job["id"]}/000.png"/></g>\n')
        anchor = '<g id="FISH-02-01">' if job['z'] < 0 else '<g id="PLANT-01">'
        if anchor in text:
            text = text.replace(anchor, node + anchor, 1)
        else:
            raise RuntimeError('Missing layer anchor: ' + anchor)
    write(path, text)


def publish():
    names = ['左侧近景垂须', '中央近景垂须', '右侧近景垂须', '右侧远景蓝色垂须']
    perf = json.loads((EVIDENCE / 'live-fixed-runtime.json').read_text(encoding='utf-8'))
    cards = ''
    for job, name in zip(JOBS, names):
        cards += (f'<article class="card"><h3>{name}</h3><video controls loop muted playsinline '
                  f'preload="metadata" src="{link(EVIDENCE / (job["id"] + ".mp4"))}"></video>'
                  f'<p>{job["id"]} · {job["rect"][2]} × {job["rect"][3]} · 72帧 / 12FPS / 6秒</p>'
                  f'<a href="{link(SOURCE / "frames" / job["id"] / "000.png")}">透明首帧</a> · '
                  f'<a href="{link(PROJECT / "scenes/environment/elements" / (job["id"] + ".tscn"))}">独立Godot元素</a></article>')
    block = (f'<section id="blender-baleen"><h2>更新 · 四处垂须独立动画帧</h2>'
             '<p>采用 Blender 4.2 的贴图网格与形态键制作，保留原有绘画材质。根部固定、末端错相摆动，远景幅度更小。'
             '不是逐帧手绘重画；四组共288张透明PNG，Godot只播放烘焙帧。原有6组实时变形动片已退出场景，固定根片保留。</p>'
             f'<p><a class="button" href="{link(SOURCE / "blend/baleen-painted-animation.blend")}">下载可编辑 Blender 母版</a>'
             f'<a class="button" href="{link(SOURCE / "README.md")}">制作与修改说明</a>'
             f'<a class="button" href="{link(EVIDENCE / "checks.json")}">Godot检查结果</a></p>'
             f'<div class="two">{cards}</div>'
             f'<p>本轮无录制、无视频编码并行的20秒运行：P50 {perf["frame_ms_p50"]:.3f}ms / '
             f'P95 {perf["frame_ms_p95"]:.3f}ms，纹理约{perf["texture_bytes"] / 1048576:.1f}MiB，'
             'RTX5060 / 1280×720。帧图集增加纹理占用，低配适配可继续压缩图集。'
             '已在更新后的独立包中启动并截图；其形式为官方Godot引擎+PCK。</p>'
             '<p class="muted">单组视频蓝底仅为观看透明边缘。远景使用原蓝色垂帘的内嵌裁片、固定边缘和轻微内部形变，未逐根重绘。'
             '已经检查抽样画面、几何固定点与循环接缝；尚未获得用户最终动态观感确认。</p></section>')
    path = OUT / '交付与对照.html'
    text = path.read_text(encoding='utf-8')
    text = re.sub(r'<section id="blender-baleen">.*?</section>', '', text, flags=re.S)
    text = text.replace('<h2>01 · 固定镜头动态</h2>', block + '<h2>01 · 固定镜头动态</h2>', 1)
    text = text.replace('102 个', '100 个').replace('20 秒水面实机录制', '24 秒新版垂须实机录制')
    text = text.replace('motion_elements/water-surface/顶部水面_实机20秒.mp4', 'baleen_blender/fixed.mp4')
    text = text.replace('motion_elements/water-surface/composite.png', 'baleen_blender/frame-18.png')
    if (EVIDENCE / 'camera.mp4').exists():
        text = text.replace('motion_elements/water-surface/顶部水面_视差32秒.mp4', 'baleen_blender/camera.mp4')
        text = text.replace('motion_elements/water-surface/camera-08.png', 'baleen_blender/camera-08.png')
    text = text.replace('本轮6项水面定向检查、17项环境检查、4项渲染循环检查通过；主场景27项为上一批基线',
                        '本轮17项垂须检查、17项环境检查、6项水面检查、4项循环检查通过；主场景27项为历史基线')
    inventory = json.loads((ROOT / 'assets/source/xumen-motion-elements/elements.json').read_text(encoding='utf-8'))
    rows = ''.join('<tr>' + ''.join('<td>' + html.escape(str(e.get(k, ''))) + '</td>'
                   for k in ['id', 'position', 'layer', 'motion', 'asset']) + '</tr>' for e in inventory)
    text = re.sub(r'<tbody>.*?</tbody>', '<tbody>' + rows + '</tbody>', text, flags=re.S)
    write(path, text)
    missing = []
    from urllib.parse import unquote
    for href in re.findall(r'(?:href|src)="([^"]+)"', text):
        if ':' not in href and not href.startswith('#'):
            target = OUT / unquote(html.unescape(href)).split('#')[0]
            if not target.exists():
                missing.append(str(target))
    write(EVIDENCE / 'delivery-links.json', json.dumps({'missing': missing}, ensure_ascii=False, indent=2))
    if missing:
        raise RuntimeError(missing)
    print('Updated delivery, SVG master and links.')


if __name__ == '__main__':
    if len(sys.argv) > 1:
        encode(sys.argv[1])
    update_layout()
    publish()
