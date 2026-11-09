"""Batch registration and hash-bound reviews; --prune is a dry listing by default."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
from PIL import Image

BASE = Path(__file__).resolve().parents[1]
REPO = BASE.parents[2]
PREFIX = 'tide-picker-action36'
URI = f'res://art/{PREFIX}/'
ATLAS = re.compile(r'^[A-Za-z0-9_-]+-(?:body|fx)\.png$')
STAGES = ('technical', 'runtime', 'art')
EXTRAS = {'projectile.png': '叉鸣弹', 'shadow_projectile.png': '深鸣弹', 'tether.png': '红索位图'}


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write_json(path, data):
    temporary = path.with_name(path.name + '.action36.tmp')
    temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    temporary.replace(path)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def linked(path):
    return path.is_symlink() or (hasattr(path, 'is_junction') and path.is_junction())


def safe_directory(repo, relative):
    """Reject symlinks/junctions even when they redirect to other assets inside repo."""
    repo = repo.resolve(strict=True)
    candidate = repo
    for part in Path(relative).parts:
        if part in ('..', '.'):
            raise ValueError('Unsafe directory component')
        candidate = candidate / part
        if linked(candidate):
            raise ValueError(f'Redirected directory is not eligible: {candidate}')
    resolved = candidate.resolve()
    if not resolved.is_relative_to(repo):
        raise ValueError('Target leaves repository')
    return resolved


def atlas_name(texture):
    if not isinstance(texture, str) or not texture.startswith(URI):
        raise ValueError(f'Unexpected atlas URI: {texture!r}')
    name = texture[len(URI):]
    if not ATLAS.fullmatch(name):
        raise ValueError(f'Atlas must be a direct task-directory PNG: {name!r}')
    return name


def referenced_files(data):
    names = {'animations.json'}
    for action in data['actions'].values():
        if not action.get('body'):
            raise ValueError('Every action needs a body atlas')
        for layer in ('body', 'fx'):
            if action.get(layer):
                names.add(atlas_name(action[layer]['texture']))
    return names


def current_hashes(action, runtime):
    hashes = {}
    for layer in ('body', 'fx'):
        spec = action.get(layer)
        if spec is None:
            hashes[layer] = None
            continue
        path = runtime / atlas_name(spec['texture'])
        if linked(path) or not path.is_file() or path.resolve().parent != runtime:
            raise ValueError(f'Unsafe/missing atlas: {path}')
        digest = sha256(path)
        if str(spec.get('sha256', '')).lower() != digest:
            raise ValueError(f'Atlas bytes do not match animations.json: {path.name}')
        hashes[layer] = digest
    return hashes


def review_state(validation, key, hashes):
    record = validation.get('actions', {}).get(key, {})
    bound = record.get('hashes', {})
    # Null fx is explicit: a review made before FX existed must not bless new FX.
    matched = all(layer in bound and bound[layer] == hashes[layer] for layer in ('body', 'fx'))
    stages = {}
    for name in STAGES:
        value = record.get(name, {})
        complete = (isinstance(value, dict) and bool(value.get('reviewer')) and
                    bool(value.get('reviewed_at')) and isinstance(value.get('evidence'), list) and
                    bool(value['evidence']) and all(isinstance(e, str) and e.strip() for e in value['evidence']))
        status = value.get('status', 'pending') if isinstance(value, dict) else 'pending'
        if not matched or not complete or status not in ('passed', 'failed', 'pending'):
            status = 'pending'
        stages[name] = {**value, 'status': status} if matched and isinstance(value, dict) else {'status': status}
    integrated = all(stages[s]['status'] == 'passed' for s in ('technical', 'runtime'))
    accepted = integrated and stages['art']['status'] == 'passed'
    user_approved = (accepted and stages['art'].get('reviewer_kind') == 'user' and
                     stages['art'].get('user_approved') is True)
    return {'hashMatched': matched, 'hashes': hashes, 'stages': stages,
            'status': 'accepted' if accepted else 'candidate',
            'integrationStatus': 'main-level-integrated' if integrated else 'pending-verification',
            'userArtApproval': user_approved}


def source_tags(action, layer):
    spec = action[layer]
    kind = str(spec.get('source_kind', action.get('source_kind', ''))).lower()
    if 'sheet' in kind:
        return ['AI补制', '精灵表'], 'sprite-sheet-ai'
    if 'video' in kind:
        return ['视频提取'], 'video-extraction'
    if action.get('source_grid'):
        return ['AI补制', '精灵表'], 'sprite-sheet-ai'
    source = str(spec.get('source', action.get('source', ''))).lower()
    if 'video' in kind or source.endswith(('.mp4', '.webm', '.mov', '.mkv')):
        return ['视频提取'], 'video-extraction'
    return ['来源待核验'], 'unclassified'


def register(repo=REPO, validation_path=None, dry_run=False):
    repo = Path(repo).resolve(strict=True)
    runtime = safe_directory(repo, f'assets/runtime/sprites/{PREFIX}')
    source = safe_directory(repo, f'assets/source/{PREFIX}')
    validation_path = Path(validation_path).resolve() if validation_path else source / 'validation.json'
    validation = read_json(validation_path) if validation_path.exists() else {'actions': {}}
    if validation.get('version', 1) != 1:
        raise ValueError('Unsupported validation.json version')
    data = read_json(runtime / 'animations.json')
    files = referenced_files(data)
    manifest_path, catalog_path = repo / 'game/art/manifest.json', repo / 'assets/catalog.json'
    manifest, catalog = read_json(manifest_path), read_json(catalog_path)
    assets = [a for a in catalog['assets'] if not a['id'].startswith(PREFIX + '-')]
    summaries = {}
    for key, action in data['actions'].items():
        hashes = current_hashes(action, runtime)
        review = review_state(validation, key, hashes)
        summaries[key] = {k: review[k] for k in ('hashMatched', 'status', 'integrationStatus')}
        for layer in ('body', 'fx'):
            spec = action.get(layer)
            if spec is None:
                continue
            name = atlas_name(spec['texture'])
            tags, source_kind = source_tags(action, layer)
            entry = {'id': PREFIX + '-' + key + ('-fx' if layer == 'fx' else ''),
                     'name': '拾潮者 · ' + action['title'] + ('效果层' if layer == 'fx' else ''),
                     'kind': 'effect-animation' if layer == 'fx' else 'character-animation',
                     'region': '全局', 'tags': ['2D', '特效' if layer == 'fx' else '动作', *tags],
                     'target': '2d', 'file': f'assets/runtime/sprites/{PREFIX}/{name}',
                     'width': spec['size'][0], 'height': spec['size'][1],
                     'frameCount': spec.get('frame_count', action['frame_count']),
                     'fps': spec.get('fps', action['fps']), 'pivot': spec['pivot'],
                     'source': f'assets/source/{PREFIX}/README.md', 'sourceKind': source_kind,
                     'sourceFile': spec.get('source', action.get('source')),
                     'sourceSha256': spec.get('source_sha256', action.get('source_sha256')),
                     'sha256': hashes[layer], 'runtimeScene': 'game/content/whalebelly/main.tscn',
                     'runtimeFile': f'game/art/{PREFIX}/{name}',
                     'status': review['status'], 'integrationStatus': review['integrationStatus'],
                     'userArtApproval': review['userArtApproval'],
                     'validation': {'file': str(validation_path.relative_to(repo)) if validation_path.is_relative_to(repo) else str(validation_path),
                                    'hashMatched': review['hashMatched'], 'hashes': hashes, 'stages': review['stages']}}
            assets.append(entry)
    for name, label in EXTRAS.items():
        path = runtime / name
        if not path.exists():
            continue
        if linked(path):
            raise ValueError(f'Redirected extra bitmap: {name}')
        files.add(name)
        with Image.open(path) as image:
            width, height = image.size
        extra_hashes = {'body': sha256(path), 'fx': None}
        extra_review = review_state(validation, 'extra:' + name, extra_hashes)
        assets.append({'id': PREFIX + '-' + path.stem, 'name': '拾潮者 · ' + label,
                       'kind': 'effect', 'region': '全局', 'tags': ['2D', '特效', '源像素提取'],
                       'status': extra_review['status'], 'target': '2d', 'file': f'assets/runtime/sprites/{PREFIX}/{name}',
                       'width': width, 'height': height, 'source': f'assets/source/{PREFIX}/effects-sources.json',
                       'sha256': extra_hashes['body'], 'integrationStatus': extra_review['integrationStatus'],
                       'runtimeFile': f'game/art/{PREFIX}/{name}', 'userArtApproval': extra_review['userArtApproval'],
                       'validation': {'hashMatched': extra_review['hashMatched'], 'hashes': extra_hashes, 'stages': extra_review['stages']}})
    manifest['entries'] = [e for e in manifest['entries'] if not e['dest'].startswith(PREFIX + '/')]
    manifest['entries'] += [{'src': f'assets/runtime/sprites/{PREFIX}/{name}', 'dest': f'{PREFIX}/{name}'} for name in sorted(files)]
    catalog['assets'] = assets
    catalog['revision'] = catalog.get('revision', 0) + 1
    catalog['updatedAt'] = datetime.now(timezone.utc).date().isoformat()
    if not dry_run:
        write_json(manifest_path, manifest)
        write_json(catalog_path, catalog)
    return {'dryRun': dry_run, 'actions': summaries, 'files': len(files)}


def prune(repo=REPO, apply=False):
    repo = Path(repo).resolve(strict=True)
    runtime = safe_directory(repo, f'assets/runtime/sprites/{PREFIX}')
    game = safe_directory(repo, f'game/art/{PREFIX}')
    referenced = referenced_files(read_json(runtime / 'animations.json'))
    # Protect the previous synced batch too; prune only after sync for full cleanup.
    game_manifest = game / 'animations.json'
    if game_manifest.exists():
        referenced |= referenced_files(read_json(game_manifest))
    sync_manifest = repo / 'game/art/manifest.json'
    if sync_manifest.exists():
        for entry in read_json(sync_manifest).get('entries', []):
            for field, prefix in (('dest', PREFIX + '/'), ('src', f'assets/runtime/sprites/{PREFIX}/')):
                value = str(entry.get(field, ''))
                if value.startswith(prefix) and ATLAS.fullmatch(value[len(prefix):]):
                    referenced.add(value[len(prefix):])
    targets = []
    for folder in (runtime, game):
        if not folder.exists():
            continue
        for path in folder.iterdir():
            basename = path.name[:-7] if folder == game and path.name.endswith('.import') else path.name
            if not ATLAS.fullmatch(basename) or basename in referenced:
                continue
            if linked(path) or not path.is_file() or path.resolve().parent != folder:
                raise ValueError(f'Unsafe prune candidate: {path}')
            targets.append(path)
    # Resolve and check the entire target list before the first non-recursive delete.
    for path in targets:
        if path.resolve().parent not in (runtime, game):
            raise ValueError('Prune target changed scope')
    if apply:
        for path in targets:
            if linked(path) or path.resolve().parent not in (runtime, game):
                raise ValueError('Prune target changed after preflight')
            path.unlink()
    return {'dryRun': not apply, 'files': [str(p.relative_to(repo)) for p in sorted(targets)]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validation', type=Path, help='Default: source/validation.json')
    parser.add_argument('--dry-run', action='store_true', help='Preview registration; no catalog/manifest changes')
    parser.add_argument('--prune', action='store_true', help='Only list unused task atlases; does not register/sync')
    parser.add_argument('--apply', action='store_true', help='With --prune only: delete listed obsolete files')
    args = parser.parse_args()
    if args.apply and (not args.prune or args.dry_run):
        parser.error('--apply requires --prune and cannot be combined with --dry-run')
    result = prune(apply=args.apply) if args.prune else register(validation_path=args.validation, dry_run=args.dry_run)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
