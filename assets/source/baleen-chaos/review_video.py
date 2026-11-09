"""Inspect a generated sample; no regeneration, warping or engine replacement."""
import json
import math
import subprocess
from pathlib import Path

import cv2
import numpy as np
import imageio_ffmpeg
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
VIDEO = ROOT / 'seedance2-source.mp4'
cap = cv2.VideoCapture(str(VIDEO))
if not cap.isOpened():
    raise RuntimeError('Video could not be opened')
fps = cap.get(cv2.CAP_PROP_FPS)
frames = []
while True:
    ok, frame = cap.read()
    if not ok:
        break
    frames.append(frame)
cap.release()
if not frames or fps <= 0:
    raise RuntimeError('Video has no decodable frames or invalid FPS')
duration = len(frames) / fps
review = ROOT / 'review'
review.mkdir(exist_ok=True)
sheet = Image.new('RGB', (1280, 780), '#101820')
draw = ImageDraw.Draw(sheet)
for i, index in enumerate(np.linspace(0, len(frames)-1, 6).astype(int)):
    im = Image.fromarray(cv2.cvtColor(frames[index], cv2.COLOR_BGR2RGB))
    im.save(review / f'sample-{i:02d}.png')
    im.thumbnail((640, 360))
    x, y = (i % 2)*640, (i // 2)*260
    # Review composition keeps the entire reference aspect ratio.
    im.thumbnail((440, 247))
    sheet.paste(im, (x, y))
    draw.text((x+448, y+20), f'{index / fps:.3f}s', fill='white')
sheet.save(review / 'contact-sheet.jpg', quality=95)
stats = {
    'width': frames[0].shape[1], 'height': frames[0].shape[0],
    'source_fps': fps, 'decoded_frames': len(frames),
    'duration_seconds': duration,
    'required_export_frames': math.ceil(round(duration, 6))*12,
    'visual_acceptance': 'pending human/agent review',
    'seamless_loop_verified': False,
    'transparent_asset': False,
    'engine_integrated': False,
}
(review / 'technical.json').write_text(json.dumps(stats, indent=2), encoding='utf-8')
export = ROOT / 'frames-12fps'
export.mkdir(exist_ok=True)
count = stats['required_export_frames']
indices = np.rint(np.linspace(0, len(frames)-1, count)).astype(int)
for i, index in enumerate(indices):
    im = Image.fromarray(cv2.cvtColor(frames[index], cv2.COLOR_BGR2RGB))
    im.save(export / f'{i:04d}.png')
subprocess.run([
    imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-loglevel', 'error',
    '-framerate', '12', '-i', str(export / '%04d.png'),
    '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p',
    '-movflags', '+faststart', str(ROOT / 'preview-12fps.mp4'),
], check=True)
stats['export'] = {
    'frames': count, 'fps': 12, 'seconds': count/12,
    'source_frame_indices': indices.tolist(),
    'method': 'Uniform source-frame sampling, retimed to ceil duration. No flow warp or interpolated pixels.',
    'rgba': False, 'scope': 'Full-scene review frames, not isolated baleen sprites',
}
(review / 'technical.json').write_text(json.dumps(stats, indent=2), encoding='utf-8')
print(json.dumps(stats, indent=2))
