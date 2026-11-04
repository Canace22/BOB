"""Repack the two-arm replacement sheet; preserve 20 time slots and video FX.

The image itself is authored by image_gen. This script only extracts, registers,
and packs its reviewed cells. It does not generate or repaint character pixels.
"""
import copy
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw
from build_sprite_sheets import keep_main_alpha, make_atlas

BASE = Path(__file__).resolve().parent
RUNTIME = BASE.parents[2] / 'assets/runtime/sprites/tide-picker-action36'
SOURCE = BASE / 'sprite-sheets/abyss_scream-v2.png'
OUT = BASE / 'review/abyss-anatomy'
# Source cell 3 touches the upper edge; omit it rather than use clipped fingers.
# Three spell pulses retain the fully raised hand. Repeated cells are held poses,
# not independent generated frames or interpolated motion.
ORDER = [0, 0, 1, 2, 2, 2, 2, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 7, 7]
SCALE = 160 / 362
ROOT_X = 213
BASELINES = [414, 414, 414, 414, 421, 421, 421, 421]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = Image.open(SOURCE).convert('RGBA')
    frames, cells, reviews = [], [], []
    for index, cell in enumerate(ORDER):
        col, row = cell % 4, cell // 4
        bounds = [round(col * src.width / 4), round(row * src.height / 2),
                  round((col + 1) * src.width / 4), round((row + 1) * src.height / 2)]
        tile = keep_main_alpha(src.crop(bounds))
        a = np.asarray(tile).astype(np.float32) / 255
        a[:, :, :3] *= a[:, :, 3, None]
        transform = np.array([[SCALE, 0, 192 - ROOT_X * SCALE],
                              [0, SCALE, 256 - BASELINES[cell] * SCALE]], np.float32)
        registered = cv2.warpAffine(a, transform, (384, 384), flags=cv2.INTER_LANCZOS4).clip(0, 1)
        registered[:, :, :3] /= np.maximum(registered[:, :, 3, None], 1e-6)
        registered[registered[:, :, 3] < 1/255] = 0
        frame = Image.fromarray((registered.clip(0, 1) * 255).astype('uint8'))
        frame.save(OUT / f'body-{index:02}.png')
        frames.append(frame)
        cells.append(bounds)
        reviews.append({'frame': index, 'source_cell': cell, 'bbox': frame.getbbox()})
    body = make_atlas(frames, 'abyss_scream')
    path = RUNTIME / 'animations.json'
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    before = json.loads((BASE / 'anatomy-fix/metadata-before.json').read_text(encoding='utf-8-sig'))
    action = copy.deepcopy(before)
    action.pop('source_seconds', None)
    action.pop('semantic_model', None)
    action.update(body=body, source=str(SOURCE), source_sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                  source_kind='AI-authored replacement anatomy key-pose sheet; not video-extracted body',
                  source_grid=[4, 2], source_cells=cells, source_cell_order=ORDER,
                  reference_height=160, frame_count=20, fps=24,
                  scale=SCALE, root_source=[ROOT_X, 414],
                  method='image_gen two-arm key poses; original source alpha; detached speckle cleanup; fixed-scale premultiplied-alpha registration; 7 authored poses held over 20 existing timeline slots',
                  hand_roles={'weapon_arm': 'reference fork-gripping arm; continuously holds fork',
                              'casting_arm': 'reference free low arm; rises, casts, then lowers; no duplicate low hand',
                              'direction': 'whole-body 2D mirror; screen side reverses, functional arm identity does not'},
                  superseded_video={'source': before['source'], 'sha256': before['source_sha256'],
                                    'reason': 'User identified third hand during overhead casting; prior visual approval revoked'},
                  known_limits=['Seven distinct authored key poses held over 20 timeline slots; no interpolation.',
                                'Source cell 3 omitted because raised fingertips touch image edge.',
                                'Original video retained for provenance and independent FX only.'],
                  status='candidate_pending_anatomy_and_runtime_review')
    action['fx'].update(frame_count=20, source=before['source'], source_sha256=before['source_sha256'],
                        source_kind='video-extracted independent effect layer')
    action['fx_source'] = {'source': before['source'], 'source_sha256': before['source_sha256'],
                           'source_kind': 'video-extracted independent effect layer'}
    data['actions']['abyss_scream'] = action
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8', newline='\n')
    sheet = Image.new('RGB', (384*7, 384*2))
    for row, background in enumerate(['#122c38', '#eee8dd']):
        for col, cell in enumerate([0, 1, 2, 4, 5, 6, 7]):
            frame = frames[ORDER.index(cell)]
            tile = Image.new('RGBA', frame.size, background)
            tile.alpha_composite(frame)
            ImageDraw.Draw(tile).text((8, 8), f'cell {cell} / two arm review', fill='white' if row==0 else 'black')
            sheet.paste(tile.convert('RGB'), (col*384, row*384))
    sheet.save(OUT/'registered.jpg', quality=95)
    (OUT/'registration.json').write_text(json.dumps({'source': str(SOURCE), 'order': ORDER, 'frames': reviews}, indent=2), encoding='utf-8')
    print('Packed 20 timeline slots from 7 two-arm poses; independent 20-frame FX retained')


if __name__ == '__main__':
    main()
