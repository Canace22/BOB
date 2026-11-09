"""Archive completed Chaos CLI results; never submits generation jobs.

Usage: python collect-mini.py mini-upper mini-pogo
Requires OpenCV and Pillow; adjust FFMPEG to the local installed binary.
Existing visual review and quota observations are preserved on repeated runs.
"""
import hashlib
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

import cv2
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parent
FFMPEG = Path(r'C:\Users\Kingsoft\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe')

def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')

for variant in sys.argv[1:]:
    folder = BASE / variant
    brief = json.loads((folder / 'brief.json').read_text(encoding='utf-8-sig'))
    result = json.loads((folder / 'result.json').read_text(encoding='utf-8-sig'))
    task = result['data']
    assert task['status'] == 'completed', task
    url = next(x['url'] for x in task['data'] if x.get('role') == 'primary')
    source = folder / 'source.mp4'
    output = folder / (variant.replace('mini-', '') + '-mini.mp4')
    if not source.exists():
        urllib.request.urlretrieve(url, source)
    if not output.exists():
        subprocess.run([str(FFMPEG), '-y', '-i', str(source), '-map', '0:v:0', '-c:v', 'copy', '-an', '-movflags', '+faststart', str(output), '-loglevel', 'error'], check=True)
    cap = cv2.VideoCapture(str(output))
    fps = cap.get(cv2.CAP_PROP_FPS)
    frames = []
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        frames.append(frame)
    cap.release()
    assert len(frames) > 0 and fps > 0
    h, w = frames[0].shape[:2]
    times = [0, .5, .8, 1.0, 1.2, 1.5, 1.8, 2.1, 2.5, 2.9, 3.4, 3.9]
    sheet = Image.new('RGB', (1200, 612), '#dddddd')
    draw = ImageDraw.Draw(sheet)
    for k, t in enumerate(times):
        frame = frames[min(len(frames) - 1, round(t * fps))]
        im = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        im.thumbnail((300, 172))
        x, y = k % 4 * 300, k // 4 * 204
        sheet.paste(im, (x, y))
        draw.text((x + 4, y + 177), f'{t:g}s', fill='black')
    (folder / 'review').mkdir(exist_ok=True)
    sheet.save(folder / 'review' / 'contact.jpg', quality=93)
    poster = frames[min(len(frames)-1, round(1.5 * fps))]
    Image.fromarray(cv2.cvtColor(poster, cv2.COLOR_BGR2RGB)).save(folder / 'poster.jpg', quality=93)
    review_path = folder / 'review.json'
    review = json.loads(review_path.read_text(encoding='utf-8-sig')) if review_path.exists() else {}
    review.update({
        'taskId': task['task_id'], 'nodeId': task['node_id'], 'url': url,
        'frames': len(frames), 'decodedFrames': len(frames), 'fps': fps,
        'duration': len(frames) / fps, 'size': [w, h],
        'requestedDuration': 4, 'requestedResolution': '480P', 'requestedAspectRatio': '16:9',
        'source': source.name, 'file': output.name,
        'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
        'processing': 'Video stream copied, audio removed; no retiming or frame interpolation',
        'status': 'candidate', 'integrationStatus': 'not-integrated', 'userArtApproval': False,
        'sampleTimes': times
    })
    review.setdefault('visualReviewMethod', '12 timestamp samples; visual inspection pending')
    write_json(review_path, review)
    brief.update(status='generated-candidate', taskId=task['task_id'], nodeId=task['node_id'], videoFile=output.name, reviewFile='review.json')
    write_json(folder / 'brief.json', brief)
    for name in ['submit.json', 'result.json']:
        path = folder / name
        write_json(path, json.loads(path.read_text(encoding='utf-8-sig')))
    print(json.dumps(review, ensure_ascii=False))
