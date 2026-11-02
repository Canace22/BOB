"""Deterministic atlas extraction/registration; never generates or redraws poses."""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).parent
OUT = ROOT / 'assets/runtime/sprites/chapter-guard-v2'
OUT.mkdir(parents=True, exist_ok=True)
# Whole-action registration against sweep neutral: rigid shell width and eye-to-buckle.
# One scale per action, never normalize each frame's visible bounding box.
LAYOUT = {
    'sweep': (1.0, 280, 376),
    'walk': (0.90, 275, 395),
    'slam': (0.86, 282, 394),
    'breath-hit': (0.88, 282, 400),
    'retire': (0.84, 272, 402),
}
CLIPS = {
    'idle': ('breath-hit', list(range(4)), [240, 240, 300, 240], True),
    'hit': ('breath-hit', list(range(4, 8)), [100, 120, 120, 140], False),
    'walk': ('walk', list(range(8)), [120] * 8, True),
    'sweep': ('sweep', list(range(8)), [160, 200, 220, 160, 80, 120, 440, 440], False),
    'slam': ('slam', list(range(8)), [200, 260, 280, 200, 120, 160, 560, 560], False),
    'retire': ('retire', list(range(8)), [160, 160, 180, 180, 180, 220, 220, 320], False),
}
manifest = {'canvas': [512, 512], 'pivot': [256, 440], 'facing': 'left',
            'walk_stride': 88, 'clips': {}}
checks = []
for name, (source, indices, durations, loop) in CLIPS.items():
    sheet = Image.open(SOURCE / f'{source}.png').convert('RGBA')
    scale, px, py = LAYOUT[source]
    frames = []
    for n, index in enumerate(indices):
        # Actual source is 1774x887, so alternate cells differ by one pixel.
        x0, x1 = round(index % 4 * sheet.width / 4), round((index % 4 + 1) * sheet.width / 4)
        y0, y1 = round(index // 4 * sheet.height / 2), round((index // 4 + 1) * sheet.height / 2)
        crop = sheet.crop((x0, y0, x1, y1))
        crop = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
        frame = Image.new('RGBA', (512, 512))
        offset = (round(256 - px * scale), round(440 - py * scale))
        frame.alpha_composite(crop, offset)
        filename = f'{name}-{n:02}.png'
        frame.save(OUT / filename)
        frames.append(filename)
        visible = frame.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
        checks.append({'clip': name, 'frame': n, 'source_rect': [x0, y0, x1, y1],
                       'scale': scale, 'offset': offset, 'visible_alpha32': visible})
    manifest['clips'][name] = {'files': frames, 'durations_ms': durations, 'loop': loop}
(OUT / 'animations.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
(SOURCE / 'registration.json').write_text(json.dumps(checks, indent=2), encoding='utf-8')
print('Extracted', len(checks), 'distinct drawn poses. Playback QA still required.')
