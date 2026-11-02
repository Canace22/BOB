"""Crop authored poses, run existing Framecraft packaging, verify and pack game strips.

Usage: python3 export.py /path/to/installed/sprite-workbench
No image synthesis, per-frame scaling, matting or redraw is performed here.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import zipfile
from PIL import Image

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
OUTPUT = ROOT / 'assets/runtime/fx/combo-v1'
GROUPS = {'player': ['short1', 'short2', 'heavy', 'hit'],
          'crab': ['sweep', 'slam', 'charge', 'resonance']}
FPS = {'short1': 20, 'short2': 20, 'heavy': 20, 'hit': 20,
       'sweep': 10, 'slam': 10, 'charge': 10, 'resonance': 5}


def build(platform):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    records = {}
    for sheet, clips in GROUPS.items():
        original = SOURCE / 'originals' / f'{sheet}.png'
        image = Image.open(original).convert('RGBA')
        assert image.size == (1254, 1254)
        # Inspected source uses four equal cells, with a half-pixel boundary.
        boundaries = [0, 314, 627, 941, 1254]
        for row, name in enumerate(clips):
            folder = SOURCE / name
            frames = folder / 'input/frames'
            frames.mkdir(parents=True, exist_ok=True)
            rects = []
            for column in range(4):
                rect = (boundaries[column], boundaries[row],
                        boundaries[column + 1], boundaries[row + 1])
                frame = Image.new('RGBA', (320, 320))
                frame.paste(image.crop(rect), (3, 3))
                frame.save(frames / f'frame-{column + 1:03}.png')
                rects.append(list(rect))
            options = {'name': f'BOB_combo_v1_{name}', 'output': str(folder / 'platform'),
                       'framesDirectory': 'frames', 'fps': FPS[name], 'loop': False,
                       'pivot': [160, 160], 'direction': 'effect-only-right',
                       'exportName': name, 'copySourceFrames': False,
                       'settings': {'scale': 1, 'alphaThreshold': 0, 'sharpen': 0},
                       'limitations': ['Four authored poses; game duration is metadata, not platform loop flag.',
                                       'Runtime visual review and user acceptance are separate.']}
            (folder / 'options.json').write_text(json.dumps(options, indent=2) + '\n')
            subprocess.run(['node', str(ROOT / 'assets/source/crab-animation-platform-v1/process.mjs'),
                            platform, str(folder / 'input'), str(folder / 'options.json')], check=True)
            strip = Image.new('RGBA', (1280, 320))
            bounds = []
            with zipfile.ZipFile(folder / 'platform/exports' / f'{name}.zip') as archive:
                pngs = sorted(n for n in archive.namelist() if n.endswith('.png'))
                assert len(pngs) == 4
                for index, entry in enumerate(pngs):
                    processed = folder / 'platform/processed' / f'frame-{index + 1:03}.png'
                    assert archive.read(entry) == processed.read_bytes()
                    frame = Image.open(processed).convert('RGBA')
                    assert frame.size == (320, 320)
                    low, high = frame.getchannel('A').getextrema()
                    assert low == 0 and high > 100
                    strip.paste(frame, (320 * index, 0))
                    bounds.append(frame.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox())
            strip.save(OUTPUT / f'{name}.png')
            records[name] = {'source': f'originals/{sheet}.png', 'rects': rects,
                             'registration': [3, 3], 'canvas': [320, 320], 'pivot': [160, 160],
                             'poses': 4, 'loop': False, 'previewFps': FPS[name],
                             'alpha32Bounds': bounds, 'sha256': hashlib.sha256(strip.tobytes()).hexdigest()}
    (SOURCE / 'export-checks.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    build(sys.argv[1])
