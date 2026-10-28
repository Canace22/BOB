import json, hashlib, zipfile
from pathlib import Path
root=Path('G:/鲸落万物生/BOB/godot/first-level')
build=Path('G:/鲸落万物生/builds/须门遗港-v0.2')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=[]
for folder in ['scripts','scenes','assets/runtime']:
    for p in sorted((root/folder).rglob('*')):
        if p.is_file() and not p.name.endswith('.import'):source.append({'path':p.relative_to(root).as_posix(),'sha256':sha(p)})
for name in ['project.godot','export_presets.cfg','assets/rooms.json']:
    p=root/name;source.append({'path':name,'sha256':sha(p)})
archive=root/'production-history/v02-release2-code.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for entry in source:
        if not entry['path'].startswith('assets/runtime'):z.write(root/entry['path'],entry['path'])
zip_path=build.parent/'须门遗港-v0.2.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(build.iterdir()):
        if p.is_file():z.write(p,build.name+'/'+p.name)
with zipfile.ZipFile(zip_path) as z:
    corrupt=z.testzip()
    if corrupt:raise RuntimeError(corrupt)
manifest={'version':'0.2','runtime':'Godot4.7.2.stable.official.ed1daf0bf / exact runtime plus PCK','package_directory':str(build),'zip':str(zip_path),'zip_bytes':zip_path.stat().st_size,'zip_sha256':sha(zip_path),'zip_crc':'pass','files':[{'name':p.name,'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(build.iterdir()) if p.is_file()],'source':source,'snapshot':{'path':str(archive),'sha256':sha(archive)}}
(root/'evidence/v02/build-manifest-release2.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'zip':str(zip_path),'MB':round(zip_path.stat().st_size/1024**2,1),'crc':'pass','source_files':len(source)},ensure_ascii=False))

