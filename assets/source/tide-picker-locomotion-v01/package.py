"""Package local candidate artwork and reusable Godot resources, without project caches."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
base=Path(__file__).resolve().parent
root=base.parents[2]
out=root.parent/'outputs'/'拾潮者_IDLE_Walk_Run_v01'
out.mkdir(parents=True,exist_ok=True)
folders=[base,root/'assets/runtime/sprites/tide-picker-locomotion-v01',root/'godot/WhalebellyRuins/assets/runtime/tide-picker-locomotion-v01',root/'godot/WhalebellyRuins/evidence/locomotion-v01']
files=[root/'godot/WhalebellyRuins/scenes/characters/locomotion_preview.tscn',root/'godot/WhalebellyRuins/scripts/locomotion_preview.gd',root/'godot/WhalebellyRuins/tests/locomotion_assets.gd']
for folder in folders:files.extend(p for p in folder.rglob('*') if p.is_file() and p.suffix not in ['.blend1'])
target=out/'拾潮者_基础动作_候选包.zip'
with ZipFile(target,'w',ZIP_DEFLATED) as archive:
    for file in files:archive.write(file,file.relative_to(root))
with ZipFile(target) as archive:
    assert archive.testzip() is None
    print('ZIP_OK',len(archive.namelist()),target.stat().st_size,str(target))
(out/'打开预览.url').write_text('[InternetShortcut]\nURL=http://127.0.0.1:4187/assets/source/tide-picker-locomotion-v01/preview.html\n',encoding='utf-8')
