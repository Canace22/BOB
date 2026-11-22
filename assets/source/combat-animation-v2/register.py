"""合并动作分片并登记实际存在的资产；保留其他工作项的清单条目。"""
from pathlib import Path
import hashlib
import json
import math
from PIL import Image
from humanoid_timing import apply as apply_humanoid_timing

ROOT = Path(__file__).resolve().parents[3]
RUNTIME = ROOT / 'assets/runtime/sprites/combat-animation-v2'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def save(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def merge_enemies():
    merged = {'schema_version': 1, 'enemies': {}}
    for name in ['animations-normal.json', 'animations-special.json']:
        for identity, value in read(RUNTIME / 'enemies' / name)['enemies'].items():
            target = merged['enemies'].setdefault(identity, {'clips': [], 'windups': []})
            for kind in ['clips', 'windups']:
                target[kind].extend(value.get(kind, []))
    # 返修分片按同一action/state/pulse精确替换，避免旧弱前摇抢先命中新候选。
    followup = RUNTIME / 'enemies/animations-followup.json'
    if followup.exists():
        for identity, value in read(followup)['enemies'].items():
            target = merged['enemies'].setdefault(identity, {'clips': [], 'windups': []})
            for kind in ['clips', 'windups']:
                for clip in value.get(kind, []):
                    key = (clip['action'], clip['state'], clip.get('pulse'))
                    target[kind] = [item for item in target[kind]
                                    if (item['action'], item['state'], item.get('pulse')) != key]
                    target[kind].append(clip)
    calibration_path = ROOT / 'assets/source/combat-animation-v2/scale-registration.json'
    if calibration_path.exists():
        calibration = read(calibration_path)
        for record in calibration['records']:
            bitmap = RUNTIME / 'enemies' / Path(record['texture']).name
            assert sha(bitmap) == record['texture_sha256'], 'Recheck anatomy after source change: ' + str(bitmap)
            reference = ROOT / 'game/art' / record['reference_texture']
            assert sha(reference) == record['reference_sha256'], 'Idle baseline changed; recalibrate anatomy'
            height = float(record['calibrated_reference_height'])
            assert math.isfinite(height) and height > 0
            matches = 0
            for clip in merged['enemies'][record['profile']]['clips']:
                if clip['texture'] != record['texture']:
                    continue
                assert clip['reference_height'] == record['reference_height_before'], 'Author scale changed; recalibrate'
                clip['source_reference_height'] = clip['reference_height']
                if 'chapter_height' in clip:
                    # 首章使用另一张旧图的已配准高度，不能把试验场的待机单位套进该入口。
                    clip['chapter_reference_height'] = clip['reference_height']
                clip['reference_height'] = height
                clip['scale_basis'] = 'fixed anatomical landmark matched to original idle; whole atlas only'
                matches += 1
            assert matches > 0, record['texture']
    apply_humanoid_timing(merged)
    for identity, value in merged['enemies'].items():
        for kind, clips in value.items():
            keys = [(c['action'], c['state'], c.get('pulse')) for c in clips]
            assert len(keys) == len(set(keys)), (identity, kind, 'duplicate clips')
            for clip in clips:
                texture = ROOT / 'game' / clip['texture'].removeprefix('res://')
                source = RUNTIME / 'enemies' / texture.name
                assert source.is_file(), source
    save(RUNTIME / 'enemies/animations.json', merged)
    return merged


def update_manifest():
    path = ROOT / 'game/art/manifest.json'
    before = path.read_bytes()
    manifest = json.loads(before)
    known = {x['dest'] for x in manifest['entries']}
    entries = []
    for family in ['player', 'enemies']:
        for source in sorted((RUNTIME / family).iterdir()):
            if source.suffix not in ['.png', '.json']:
                continue
            entries.append({'src': source.relative_to(ROOT).as_posix(),
                            'dest': 'combat-animation-v2/' + family + '/' + source.name})
    entries += read(ROOT / 'assets/source/chapter-characters-v1/manifest-entries.json')
    for entry in entries:
        if entry['dest'] not in known:
            manifest['entries'].append(entry)
            known.add(entry['dest'])
    # 若另一工作项正在写共享清单，保留其现场，重新读最新版本后再执行。
    assert path.read_bytes() == before, 'Manifest changed concurrently; retry registration'
    save(path, manifest)
    return entries


def update_catalog(enemies):
    path = ROOT / 'assets/catalog.json'
    before = path.read_bytes()
    catalog = json.loads(before)
    staged = []
    for npc in read(ROOT / 'assets/source/chapter-characters-v1/assets.json'):
        staged.append({
            'id': 'chapter-characters-v1-' + npc['id'], 'name': npc['id'],
            'kind': 'character', 'region': '章节人物', 'tags': ['2D', '静态人物', '候选'],
            'status': 'candidate', 'userArtApproval': False, 'target': '2d',
            'file': npc['file'], 'source': npc['source'], 'runtimeFile': npc['runtimeFile'],
            'width': npc['size'][0], 'height': npc['size'][1], 'sha256': npc['sha256'],
            'sourceSha256': npc['sourceSha256'], 'pivot': npc['pivot'],
            'notes': '身份、出场状态及精确生成来源见 assets/source/chapter-characters-v1/roster.json。静态形象，不计为行走或救援动画。'})
    player = read(RUNTIME / 'player/animations.json')['actions']
    seen_player_textures = set()
    for key, action in player.items():
        texture = action['body']['texture']
        if texture in seen_player_textures:
            continue
        seen_player_textures.add(texture)
        source = RUNTIME / 'player' / Path(texture).name
        staged.append(animation_entry('player-' + key, source, texture,
                                      len(action['body']['frames']), '主角'))
    textures = {}
    for identity, value in enemies['enemies'].items():
        for kind, clips in value.items():
            for clip in clips:
                textures.setdefault(clip['texture'], {'identity': identity, 'fx': kind == 'windups', 'frames': set()})
                textures[clip['texture']]['frames'].update(tuple(f['rect']) for f in clip['frames'])
    for texture, details in textures.items():
        source = RUNTIME / 'enemies' / Path(texture).name
        entry = animation_entry('enemies-' + source.stem, source, texture,
                                len(details['frames']), details['identity'])
        if details['fx']:
            entry['kind'] = 'effect'
            entry['notes'] += ' 独立逐帧前摇FX；不驱动伤害、位移或红色预警规则。'
        staged.append(entry)
    by_id = {x['id']: i for i, x in enumerate(catalog['assets'])}
    for entry in staged:
        if entry['id'] in by_id:
            catalog['assets'][by_id[entry['id']]] = entry
        else:
            by_id[entry['id']] = len(catalog['assets'])
            catalog['assets'].append(entry)
    catalog['updatedAt'] = '2026-11-22'
    assert path.read_bytes() == before, 'Catalog changed concurrently; retry registration'
    save(path, catalog)
    return staged


def animation_entry(key, source, texture, frames, identity):
    with Image.open(source) as image:
        width, height = image.size
    return {'id': 'combat-animation-v2-' + key, 'name': identity + ' · ' + source.stem,
            'kind': 'character-animation', 'region': '全章动作',
            'tags': ['2D', '真实绘制帧', '前摇', '候选'], 'status': 'candidate',
            'userArtApproval': False, 'target': '2d',
            'file': source.relative_to(ROOT).as_posix(),
            'source': 'assets/source/combat-animation-v2/README.md',
            'runtimeFile': 'game/' + texture.removeprefix('res://'),
            'width': width, 'height': height, 'frameCount': frames, 'sha256': sha(source),
            'notes': '内置image_gen创作；生成原件、精确请求、裁片和固定根注册记录在同批源目录。独立绘图数与实际60Hz可见采样数分开；技术检查不等于用户美术认可。'}


if __name__ == '__main__':
    enemies = merge_enemies()
    entries = update_manifest()
    registered = update_catalog(enemies)
    report = {'sync_entries': [x['dest'] for x in entries],
              'registered_ids': [x['id'] for x in registered]}
    save(ROOT / 'game/build/qa/animation-v2-registration.json', report)
    print('registered', len(registered), 'assets;', len(entries), 'sync entries')
