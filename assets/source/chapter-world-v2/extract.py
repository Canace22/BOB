"""Extract purpose-made chapter kit without stretching or procedural painting."""
from pathlib import Path
from PIL import Image
import json
ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).parent
OUT = ROOT / 'assets/runtime/sprites/chapter-world-v2'
OUT.mkdir(parents=True, exist_ok=True)
for name in ['garden', 'well']:
    Image.open(SOURCE / f'{name}.png').save(OUT / f'{name}.png')
sheet = Image.open(SOURCE / 'kit.png').convert('RGBA')
names = ['ground-a', 'ground-b', 'ledge', 'pier', 'arch', 'lamp', 'nest', 'lever']
rects = {}
for i, name in enumerate(names):
    rect = [round(i % 4 * sheet.width / 4), round(i // 4 * sheet.height / 2),
            round((i % 4 + 1) * sheet.width / 4), round((i // 4 + 1) * sheet.height / 2)]
    crop = sheet.crop(rect)
    crop.save(OUT / f'{name}.png')
    rects[name] = {'rect': rect, 'size': crop.size, 'alpha32': crop.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()}
sheet = Image.open(SOURCE / 'scavenger.png').convert('RGBA')
for i in range(8):
    rect = (round(i % 4 * sheet.width / 4), round(i // 4 * sheet.height / 2),
            round((i % 4 + 1) * sheet.width / 4), round((i // 4 + 1) * sheet.height / 2))
    crop = sheet.crop(rect)
    frame = Image.new('RGBA', (448, 448))
    frame.alpha_composite(crop, (-12, 30))
    frame.save(OUT / f'scavenger-{i}.png')
(SOURCE / 'extraction.json').write_text(json.dumps(rects, indent=2), encoding='utf-8')
if (SOURCE / 'residents.png').exists():
    sheet = Image.open(SOURCE / 'residents.png').convert('RGBA')
    for i in range(8):
        rect = (round(i % 4 * sheet.width / 4), round(i // 4 * sheet.height / 2),
                round((i % 4 + 1) * sheet.width / 4), round((i // 4 + 1) * sheet.height / 2))
        sheet.crop(rect).save(OUT / f'resident-{i}.png')
print('Exported chapter kit, two backdrops, eight scavenger poses.')
