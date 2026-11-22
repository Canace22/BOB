"""离线匹配只输出候选；不修改认可登记，倾斜姿态必须人工核对。"""
import cv2, numpy as np, json
from PIL import Image, ImageDraw
from pathlib import Path
r = Path(__file__).resolve().parents[3]
meta = json.loads((r / 'game/art/enemy-lab-readability-v1/atlas.json').read_text(encoding='utf-8'))
cfg = json.loads((r / 'assets/runtime/sprites/combat-animation-v2/enemies/animations.json').read_text(encoding='utf-8'))['enemies']
paths = {'forager': 'enemy-lab-readability-v1/forager.png', 'mudback': 'enemy-lab-readability-v1/mudback.png', 'shell_guard': 'enemy-lab-readability-v1/shell_guard.png', 'membrane_hunter': 'enemy-lab-predator-squid-jelly-v1/membrane_hunter.png', 'nest_eel': 'enemy-lab-eel-v1/nest_eel.png', 'pump_warden': 'enemy-lab-warden-v1/pump_warden.png', 'beam_guard': 'enemy-lab-beam-guard-v1/beam_guard.png', 'elder_guardian': 'enemy-lab-elder-idle-fix-v1/elder_idle_fixed.png'}
boxes = {'forager': [120, 35, 150, 45], 'mudback': [45, 30, 180, 115], 'shell_guard': [135, 20, 100, 155], 'membrane_hunter': [55, 35, 165, 140], 'nest_eel': [45, 150, 95, 55], 'pump_warden': [142, 4, 83, 52], 'beam_guard': [85, 0, 157, 57], 'elder_guardian': [100, 5, 105, 85]}

def gray(im):
    bg = Image.new('RGBA', im.size, (34, 48, 57, 255))
    bg.alpha_composite(im)
    return cv2.GaussianBlur(cv2.cvtColor(np.array(bg), cv2.COLOR_RGBA2GRAY), (3, 3), 0)
records = []
for profile, entry in cfg.items():
    m = meta[profile]
    cell = m['regions'][22 if profile == 'elder_guardian' else 0]
    rect = cell['rect']
    old = Image.open(r / 'game/art' / paths[profile]).convert('RGBA')
    if profile != 'elder_guardian':
        old = old.crop((rect[0], rect[1], rect[0] + rect[2], rect[1] + rect[3]))
    x, y, w, h = boxes[profile]
    tpl = gray(old.crop((x, y, x + w, y + h)))
    textures = {}
    for c in entry['clips']:
        a = textures.setdefault(c['texture'], {'ref': c.get('source_reference_height', c['reference_height']), 'action': c['action'], 'frames': {}})
        for f in c['frames']:
            a['frames'][tuple(f['rect'])] = f
    board = Image.new('RGB', (400 * len(textures), 430), (34, 48, 57))
    draw = ImageDraw.Draw(board)
    for col, (path, a) in enumerate(textures.items()):
        frames = sorted(a['frames'].items(), key=lambda q: (q[0][1], q[0][0]))
        rect, f = frames[-1] if 'reground' in path else frames[0]
        x, y, w, h = rect
        im = Image.open(r / 'game' / path.removeprefix('res://')).convert('RGBA').crop((x, y, x + w, y + h))
        tgt = gray(im)
        best = (-1, 0, None)
        for scale in np.arange(0.35, 1.801, 0.005):
            t = cv2.resize(tpl, None, fx=float(scale), fy=float(scale))
            if t.shape[0] > tgt.shape[0] or t.shape[1] > tgt.shape[1]:
                continue
            _, v, _, pos = cv2.minMaxLoc(cv2.matchTemplate(tgt, t, cv2.TM_CCOEFF_NORMED))
            if v > best[0]:
                best = (v, float(scale), pos)
        score, s, pos = best
        measured = round(m['reference_height'] * s, 3)
        ratio = round(measured / a['ref'], 4)
        rec = {'profile': profile, 'action': a['action'], 'texture': path, 'reference_texture': paths[profile], 'reference_rect': cell['rect'], 'reference_landmark': boxes[profile], 'source_frame_rect': list(rect), 'source_frame_index': len(frames) - 1 if 'reground' in path else 0, 'source_landmark': [pos[0], pos[1], round(tpl.shape[1] * s), round(tpl.shape[0] * s)], 'match_score': round(score, 5), 'source_scale_to_idle': round(s, 5), 'old_reference_height': a['ref'], 'calibrated_reference_height': measured, 'visible_scale_ratio_before': ratio}
        records.append(rec)
        bg = Image.new('RGBA', im.size, '#223039')
        bg.alpha_composite(im)
        dd = ImageDraw.Draw(bg)
        xx, yy, ww, hh = rec['source_landmark']
        dd.rectangle((xx, yy, xx + ww, yy + hh), outline='magenta', width=2)
        bg.thumbnail((390, 360))
        board.paste(bg.convert('RGB'), (col * 400, 65))
        draw.text((col * 400 + 8, 7), a['action'], fill='white')
        draw.text((col * 400 + 8, 24), f'score={score:.3f} before={ratio:.3f}', fill='white')
        print(profile, a['action'], 'score', round(score, 3), 'before', ratio, 'ref', a['ref'], '=>', measured)
    board.save(r / 'game/build/qa' / ('scale-' + profile + '-landmarks.jpg'))
(r / 'game/build/qa/enemy-scale-diagnosis.json').write_text(json.dumps({'method': 'offline rigid anatomy matching of neutral entry/exit; requires visual approval; no runtime detector or frame scaling', 'profiles': boxes, 'records': records}, ensure_ascii=False, indent=2), encoding='utf-8')
