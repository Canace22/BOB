from pathlib import Path
import zipfile,json,hashlib
BASE=Path(__file__).resolve().parent;REPO=BASE.parents[2]
out=REPO.parent/'outputs/拾潮者_视频动作_V02';out.mkdir(parents=True,exist_ok=True)
dest=out/'拾潮者_IDLE_Walk_Run_视频动作V02_评审包.zip'
selected=json.loads((BASE/'selection.json').read_text())
files=[]
for p in BASE.rglob('*'):
    if not p.is_file():continue
    rel=p.relative_to(BASE)
    if rel.parts[0] in ('transparent','__pycache__'):continue
    if p.suffix in ('.blend1','.log'):continue
    if p.name=='own-doc-additions.json':continue
    if rel.parts[0]=='raw' and rel.parts[1] not in [a['source'] for a in selected.values()]:continue
    files.append(p)
files+=list((REPO/'assets/runtime/sprites/tide-picker-locomotion-v02-video').rglob('*.png'))
files.append(REPO/'assets/runtime/sprites/tide-picker-locomotion-v02-video/manifest.json')
for folder in ['assets/runtime/tide-picker-locomotion-v02-video','evidence/locomotion-v02-video']:
    files += [p for p in (REPO/'godot/WhalebellyRuins'/folder).rglob('*') if p.is_file() and p.suffix!='.import']
for name in ['scenes/characters/locomotion_video_preview.tscn','scripts/locomotion_video_preview.gd','tests/locomotion_video_assets.gd']:
    files.append(REPO/'godot/WhalebellyRuins'/name)
with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED,compresslevel=4) as z:
    for p in files:z.write(p,p.relative_to(REPO).as_posix())
    z.writestr('START_HERE.txt','V02 REVIEW CANDIDATE / 214 processed transparent frames\nOpen assets/source/tide-picker-locomotion-v02-video/review/combined-preview.mp4 directly.\nFor interactive preview: start a local HTTP server in this extracted root, then open assets/source/tide-picker-locomotion-v02-video/preview-loop.html.\nThe Godot folder contains review integration files, not a standalone full project. Use the existing WhalebellyRuins project.\nSee README.md for provenance, source indices and known visual issues.\n')
with zipfile.ZipFile(dest) as z:
    assert z.testzip() is None
    assert sum('/raw/' in n and n.endswith('.png') for n in z.namelist())==243
    entries=len(z.namelist())
info={'file':dest.name,'bytes':dest.stat().st_size,'entries':entries,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'crc_check':'pass','native_pngs':243,'runtime_png_frames':214}
(out/'package-check.json').write_text(json.dumps(info,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(info,ensure_ascii=False))
