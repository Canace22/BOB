"""保留原件与固定网格，用每动作一个尺度导出主角连续帧候选。"""
from pathlib import Path
from PIL import Image
import hashlib
import json

ROOT = Path(__file__).resolve().parents[4]
SOURCE = Path(__file__).resolve().parent
OUT = ROOT / 'assets/runtime/sprites/combat-animation-v2/player'
SETTINGS = {
    'strike2': (4, [296, 295, 293, 293], 272, .125),
    'abyss_scream': (4, [288, 288, 289, 288], 263, .19402985074626866),
    'interact': (4, [272, 272, 273, 274], 255, .46153846153846156),
    'parry': (2, [401, 402], 375, 1 / 3),
    'strike1': (4, [297, 296, 296, 297], 272, .3953488372093023),
    'upper': (4, [288, 288, 289, 291], 266, .18032786885245902),
    'heavy': (4, [282, 278, 278, 282], 256, .5),
    'orb': (4, [293, 291, 287, 288], 271, .7056737588652482),
    'up_spell': (4, [289, 289, 290, 289], 273, .19402985074626866),
    'great_slash': (4, [289, 291, 291, 294], 264, .5384615384615384),
    'cyclone': (4, [284, 284, 283, 285], 262, .5),
    'dive': (4, [288, 285, 285, 285], 253, .5),
}
# 生成器的举手/伸叉跨过名义网格；在完整源图的透明间隙裁切，不截断武器或混入邻帧。
CUTS = {'upper': {'rows': [0, 311, 610, 934, 1246]},
        'up_spell': {'rows': [0, 300, 615, 945, 1261]},
        'orb': {'columns': [0, 330, 642, 954, 1247]}}
CONTACTS = {'dive': {10: 267, 11: 269, 12: 282, 13: 283, 14: 284, 15: 285}}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    actions = {}
    evidence = {}
    base = json.loads((ROOT / 'assets/runtime/sprites/tide-picker-action36/animations.json').read_text(encoding='utf8'))['actions']
    for key, (rows, grounds, standing_height, event_phase) in SETTINGS.items():
        path = SOURCE / key / 'original.png'
        original = Image.open(path).convert('RGBA')
        width, height = original.size
        scale = 160 / standing_height
        frames, records = [], []
        for index in range(rows * 4):
            col, row = index % 4, index // 4
            columns = CUTS.get(key, {}).get('columns', [i * width // 4 for i in range(5)])
            bands = CUTS.get(key, {}).get('rows', [i * height // rows for i in range(rows + 1)])
            rect = (columns[col], bands[row], columns[col + 1], bands[row + 1])
            crop = original.crop(rect)
            resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
            target = Image.new('RGBA', (256, 256))
            source_root = (col + .5) * width / 4 if key in CUTS else rect[0] + crop.width / 2
            ground = row * height // rows + CONTACTS.get(key, {}).get(index, grounds[row])
            shift = (128 - round((source_root - rect[0]) * scale), 224 - round((ground - rect[1]) * scale))
            target.alpha_composite(resized, shift)
            frames.append(target)
            target.save(SOURCE / key / f'frame-{index:02}.png')
            records.append({'source_rect': list(rect), 'translation': list(shift),
                            'alpha_bounds': target.getbbox(), 'rgba_sha256': digest(target.tobytes())})
        hashes = {record['rgba_sha256'] for record in records}
        if len(hashes) != len(frames):
            raise ValueError(f'{key}: duplicate frames {len(hashes)}/{len(frames)}')
        if any(not r['alpha_bounds'] or min(r['alpha_bounds'][:2]) < 4
               or max(r['alpha_bounds'][2:]) > 252 for r in records):
            raise ValueError(f'{key}: insufficient runtime padding')
        atlas = Image.new('RGBA', (1024, rows * 256))
        for index, frame in enumerate(frames):
            atlas.alpha_composite(frame, ((index % 4) * 256, (index // 4) * 256))
        atlas.save(OUT / f'{key}-body.png')
        preview = []
        for frame in frames:
            bg = Image.new('RGBA', frame.size, '#657781')
            bg.alpha_composite(frame)
            preview.append(bg.convert('RGB'))
        preview[0].save(SOURCE / key / 'preview.gif', save_all=True, append_images=preview[1:],
                        duration=85, loop=0, disposal=2)
        actions[key] = {
            'frame_count': len(frames), 'fps': 24, 'reference_height': 160,
            'event_phase': event_phase, 'authored_pivot': True,
            'fx_frame_count': len(base[key].get('fx', {}).get('frames', [])) if base[key].get('fx') else int(base[key]['frame_count']),
            'body': {'texture': f'res://art/combat-animation-v2/player/{key}-body.png',
                     'sha256': digest((OUT / f'{key}-body.png').read_bytes()),
                     'pivot': [128, 224],
                     'frames': [[(i % 4) * 256, (i // 4) * 256, 256, 256] for i in range(len(frames))]},
        }
        evidence[key] = {'status': 'candidate_pending_runtime_and_user_art_review',
                         'source_sha256': digest(path.read_bytes()), 'source_size': [width, height],
                         'one_global_scale': scale, 'source_row_ground': grounds,
                         'source_cuts': CUTS.get(key, {}), 'grounded_foot_contacts': CONTACTS.get(key, {}),
                         'common_pivot': [128, 224], 'unique_rgba_frames': len(hashes),
                         'frames': records, 'preview_timing': '85ms per frame, slow review only'}
    actions['dark_dive'] = dict(actions['dive'], event_phase=float(base['dark_dive']['event_phase']))
    evidence['dark_dive'] = {'status': 'explicit_body_reuse', 'source_action': 'dive', 'unique_additional_frames': 0}
    (OUT / 'animations.json').write_text(json.dumps({'version': 2, 'merge_over': 'tide-picker-action36',
                                                    'actions': actions}, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    (SOURCE / 'extraction.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + '\n', encoding='utf8')
    print(f'Packed {len(SETTINGS)} authored actions / {sum(rows * 4 for rows, *_ in SETTINGS.values())} unique frames; fixed scale, pivots and alpha padding passed')


if __name__ == '__main__':
    build()
