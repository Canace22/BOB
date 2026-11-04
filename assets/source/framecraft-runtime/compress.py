"""Compress Godot runtime images with Framecraft's real local API; keep source projects.

Run with Framecraft's Python environment after starting python -m backend.app:
python assets/source/framecraft-runtime/compress.py --url http://127.0.0.1:8765
"""
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
from threading import Lock
import urllib.parse
import urllib.request
import uuid
import zipfile

import numpy as np
from PIL import Image, UnidentifiedImageError

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RUNTIME = ROOT / 'assets/runtime/sprites/framecraft-runtime'
ARCHIVE = 'codex/archive-legacy-20261103'
SETTINGS = dict(scale=1, algorithm='lanczos', resizeMode='soft', alphaThreshold=0, sharpen=0, colors=256)
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
CACHE_LOCKS = {}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def post(url, fields, field, filename, payload):
    boundary = uuid.uuid4().hex
    parts = [f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode() for key, value in fields.items()]
    parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{field}"; filename="{filename}"\r\nContent-Type: application/octet-stream\r\n\r\n'.encode())
    body = b''.join(parts) + payload + f'\r\n--{boundary}--\r\n'.encode()
    request = urllib.request.Request(url, body, headers={'Content-Type': f'multipart/form-data; boundary={boundary}', 'Origin': args.url})
    with opener.open(request, timeout=240) as response:
        return response.read()


def compress(path):
    relative = path.relative_to(ROOT / 'game/art').as_posix()
    source = path.read_bytes()
    output = RUNTIME / relative
    cache = ROOT / 'game/build/qa/framecraft-compression/cache' / (sha(source) + '.png')
    with CACHE_LOCKS.setdefault(sha(source), Lock()):
        result = cache.read_bytes() if cache.is_file() else b''
        try:
            with Image.open(BytesIO(result)) as image:
                image.verify()
        except (UnidentifiedImageError, OSError):
            result = post(args.url + '/api/compression/frame', dict(scale=1, algorithm='lanczos', resize_mode='soft', alpha_threshold=0, sharpen=0, colors=256), 'image', 'frame.png', source)
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(result)
    with Image.open(BytesIO(source)) as image:
        original = np.asarray(image.convert('RGBA'))
    with Image.open(BytesIO(result)) as image:
        processed = np.asarray(image.convert('RGBA'))
    assert original.shape == processed.shape, relative + ': changed canvas'
    assert np.array_equal(original[:, :, 3], processed[:, :, 3]), relative + ': changed alpha'
    visible = original[:, :, 3] > 0
    assert np.array_equal(original[visible], processed[visible]), relative + ': changed visible pixels'
    # Some already optimized PNGs are smaller. Retain them after verifying the platform result.
    chosen = result if len(result) < len(source) else source
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(chosen)
    return dict(dest=relative, width=original.shape[1], height=original.shape[0], before=len(source), after=len(chosen), sourceSha256=sha(source), sha256=sha(chosen), platformSha256=sha(result), selected='framecraft' if chosen is result else 'original-smaller')


def save_project(batch, index):
    frames, results = [], []
    archive = BytesIO()
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_STORED) as bundle:
        for i, item in enumerate(batch):
            name = f'{i + 1:04}.png'
            frame = dict(id=f'input-{i}', name=item['dest'], sourceIndex=i + 1, time=i / 12, width=item['width'], height=item['height'], selected=True, file='frames/' + name)
            frames.append(frame)
            results.append(dict(frame, id=f'output-{i}', file='compression/results/' + name))
            bundle.write(ROOT / 'game/art' / item['dest'], frame['file'])
            bundle.write(RUNTIME / item['dest'], results[-1]['file'])
        manifest = dict(format='framecraft-project-v1', name=f'BOB runtime compression {index:03}', fps=12, source=None, frames=frames,
                        workspace=dict(options=dict(removeBackground=False, targetHeight=720, padding=0, layout='original', alignment='center', cleanup='none'), start=1, end=len(frames), cursor=1, stride=1, loopMode='once', sheetColumns=8, sheetRows=(len(frames)+7)//8, background='checker', sequenceMode=True),
                        compression=dict(settings=SETTINGS, lastSettings=SETTINGS, sourceLabel='Runtime image compression batch; game timing unchanged', fps=12, sources=frames, results=results))
        bundle.writestr('project.json', json.dumps(manifest, ensure_ascii=False))
    query = '?' + urllib.parse.urlencode({'directory': str(HERE / 'projects')})
    saved = json.loads(post(args.url + '/api/projects' + query, {}, 'archive', 'project.zip', archive.getvalue()))
    reopened = json.load(opener.open(args.url + '/api/projects/' + saved['id'] + query))
    assert len(reopened['compression']['results']) == len(batch)
    assert reopened['compression']['settings'] == SETTINGS
    return dict(id=saved['id'], path=Path(saved['path']).relative_to(ROOT).as_posix(), count=len(batch), reopened=True)


def repoint_manifest(records):
    path = ROOT / 'game/art/manifest.json'
    manifest = json.loads(path.read_text(encoding='utf-8'))
    images = {item['dest']: item for item in records}
    entries = []
    for entry in manifest['entries']:
        source = ROOT / entry['src']
        pairs = [(p, entry['dest'] + p.name) for p in sorted(source.iterdir()) if p.suffix.lower() in ('.png', '.ogg', '.wav')] if entry['src'].endswith('/') else [(source, entry['dest'])]
        for original, destination in pairs:
            if destination in images:
                entries.append(dict(src=(RUNTIME / destination).relative_to(ROOT).as_posix(), dest=destination))
            elif entry['src'].startswith('legacy/'):
                target = ROOT / 'assets/runtime/godot-support' / destination
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(original, target)
                entries.append(dict(entry, src=target.relative_to(ROOT).as_posix(), dest=destination))
            else:
                entries.append(dict(entry, src=original.relative_to(ROOT).as_posix(), dest=destination))
    assert images.keys() <= {entry['dest'] for entry in entries}, 'Unmapped runtime images'
    manifest['entries'] = entries
    manifest['_doc'] = 'Runtime files sync from assets/. PNG derivatives use Framecraft; original bytes remain in its source projects and codex/archive-legacy-20261103. Do not edit game/art files manually.'
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def verify():
    provenance = json.loads((HERE / 'provenance.json').read_text(encoding='utf-8'))
    originals = {}
    for project in provenance['projects']:
        directory = ROOT / project['path']
        stored = json.loads((directory / 'project.json').read_text(encoding='utf-8'))
        assert stored['compression']['settings'] == SETTINGS
        assert len(stored['compression']['results']) == project['count']
        for frame in stored['frames']:
            originals[frame['name']] = directory / frame['file']
    for item in provenance['images']:
        source = originals[item['dest']].read_bytes()
        output = (RUNTIME / item['dest']).read_bytes()
        assert sha(source) == item['sourceSha256'], item['dest'] + ': changed source'
        assert sha(output) == item['sha256'], item['dest'] + ': changed output'
        with Image.open(BytesIO(source)) as image:
            a = np.asarray(image.convert('RGBA'))
        with Image.open(BytesIO(output)) as image:
            b = np.asarray(image.convert('RGBA'))
        assert a.shape == b.shape and np.array_equal(a[:, :, 3], b[:, :, 3])
        assert np.array_equal(a[a[:, :, 3] > 0], b[a[:, :, 3] > 0])
    print(f"Verified {len(originals)} original/output pairs and {len(provenance['projects'])} portable projects", flush=True)


def main():
    if args.verify:
        verify()
        return
    if (HERE / 'provenance.json').exists():
        raise SystemExit('This batch is already saved. Use --verify; create a new batch for new sources.')
    assert json.load(opener.open(args.url + '/api/health'))['status'] == 'ok'
    if args.batch:
        manifest = json.loads((ROOT / 'game/art/manifest.json').read_text(encoding='utf-8'))
        paths = sorted(ROOT / 'game/art' / entry['dest'] for entry in manifest['entries']
                       if entry['dest'].endswith('.png') and not entry['src'].startswith('assets/runtime/sprites/framecraft-runtime'))
        if not paths:
            raise SystemExit('No new PNGs outside existing Framecraft batches.')
        HERE.mkdir(parents=True, exist_ok=True)
    else:
        paths = sorted(path for path in (ROOT / 'game/art').rglob('*') if path.suffix.lower() in ('.png', '.jpg', '.webp'))
    assert all(path.suffix == '.png' for path in paths), 'Handle non-PNG paths explicitly before converting formats'
    print(f'Processing {len(paths)} PNGs through Framecraft', flush=True)
    records = []
    with ThreadPoolExecutor(max_workers=3) as pool:
        for i, record in enumerate(pool.map(compress, paths)):
            records.append(record)
            if (i + 1) % 100 == 0:
                print(f'compressed {i + 1}/{len(paths)}', flush=True)
    projects, batch, pixels = [], [], 0
    for record in records:
        count = record['width'] * record['height']
        if batch and (len(batch) >= 96 or pixels + count > 100_000_000):
            projects.append(save_project(batch, len(projects) + 1))
            print(f'saved/reopened project {len(projects)}', flush=True)
            batch, pixels = [], 0
        batch.append(record)
        pixels += count
    if batch:
        projects.append(save_project(batch, len(projects) + 1))
    provenance = dict(tool='Framecraft e5dc68902bdd1e86402bfbeafe27e5ed301b539c', endpoint='/api/compression/frame', archiveBranch=ARCHIVE, settings=SETTINGS,
                      inputBytes=sum(x['before'] for x in records), outputBytes=sum(x['after'] for x in records), imageCount=len(records), projects=projects, images=records)
    if args.batch:
        provenance.pop('archiveBranch')
        provenance['sourceCommit'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    (HERE / 'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    repoint_manifest(records)
    print(json.dumps({key: provenance[key] for key in ('imageCount', 'inputBytes', 'outputBytes')}), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://127.0.0.1:8765')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--batch', help='New incremental batch name; existing batches are never overwritten')
    args = parser.parse_args()
    if args.batch:
        if not args.batch or any(char not in 'abcdefghijklmnopqrstuvwxyz0123456789-' for char in args.batch):
            parser.error('--batch accepts lowercase letters, digits and hyphens only')
        HERE = HERE / 'batches' / args.batch
        RUNTIME = ROOT / 'assets/runtime/sprites/framecraft-runtime-batches' / args.batch
    main()
