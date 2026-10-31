from pathlib import Path
import json,re
R=Path(__file__).resolve().parents[1];P=R/'godot/WhalebellyRuins'
new=P.as_posix()
def rewrite(text):
    for prefix in ['G:/鲸落万物生/BOB/godot/first-level-artmatch','G:/鲸落万物生/godot/first-level-artmatch']:
        text=text.replace(prefix,new)
        text=text.replace(prefix.replace('/','\\\\'),new.replace('/','\\\\'))
        text=text.replace(prefix.replace('/','\\'),new.replace('/','\\'))
    text=text.replace("ROOT/'godot/first-level-artmatch'","ROOT/'BOB/godot/WhalebellyRuins'")
    text=text.replace("root/'godot/first-level-artmatch'","root/'BOB/godot/WhalebellyRuins'")
    text=text.replace('../../godot/first-level-artmatch/','../../BOB/godot/WhalebellyRuins/')
    text=text.replace('../../BOB/godot/first-level-artmatch/','../../BOB/godot/WhalebellyRuins/')
    return text
changed=[]
live=[R/'work'/n for n in ['r1_v05_capture.py','r1_v05_package.py','r1_v05_delivery.py','r1_v05_finalize.py','refine_audio_v05.py','verify_package_normal_close.ps1']]
live+=list(P.glob('*.md'))+list((P/'docs').glob('*.md'))+list((P/'docs').glob('*.py'))+list((P/'tools').glob('*.gd'))
live += [R.parent/'outputs/须门遗港_v0.5_参考图可玩关卡/交付与验收.html']
for f in live:
    if not f.exists():continue
    old=f.read_text('utf8');txt=rewrite(old)
    if txt!=old:f.write_text(txt,encoding='utf8');changed.append(str(f))
cfg=P/'project.godot';txt=cfg.read_text('utf8');txt=re.sub(r'^config/name=.*$', 'config/name="Whalebelly Ruins · 鲸腹遗城"',txt,flags=re.M)
cfg.write_text(txt,encoding='utf8')
statefile=P/'.production/state.json';state=json.loads(statefile.read_text('utf8'))
state['project']=str(P/'project.godot');state['evidence_root']=str(P/'evidence')
state['project_consolidation']={'single_active_project':str(P),'report':'../../docs/godot-consolidation.json','save_directory_preserved':'WhalefallArtmatchV05','status':'validation_pending'}
state['next_instruction']='只在WhalebellyRuins工程继续开发。先读RESUME.md及最新合并记录；旧运行证据保留原时间，分层素材待精修。音频用户已反馈新版明显改善、可以保留，详见progress.md。'
statefile.write_text(json.dumps(state,ensure_ascii=False,indent=2),encoding='utf8')
# Do not rewrite historical evidence/hashes: these document their original locations.
ignore=R/'.gitignore';txt=ignore.read_text('utf8')
if '/godot/**/.godot/' not in txt:txt+='\n# Godot generated editor/import caches; rebuild locally.\n/godot/**/.godot/\n'
ignore.write_text(txt,encoding='utf8')
attrs=R/'.gitattributes';lines=attrs.read_text('utf8').splitlines()
lines=[s for s in lines if not any('godot/'+n+'/' in s for n in ['first-level','first-level-artmatch','first-level-v02-graybox'])]
for ext in ['png','jpg','jpeg','wav','mp4','webm','zip','pck','exe','glb','blend','psd']:
    lines.append('godot/WhalebellyRuins/**/*.'+ext+' filter=lfs diff=lfs merge=lfs -text')
attrs.write_text('\n'.join(lines)+'\n',encoding='utf8')
readme=R/'README.md';txt=readme.read_text('utf8')
txt=txt.replace('原同级 `godot/`、`work/` 已完整迁入本仓库。Godot 工程入口为\n`godot/first-level/project.godot`、`godot/first-level-artmatch/project.godot`\n和 `godot/first-level-v02-graybox/project.godot`；制作脚本位于 `work/`。','Godot 唯一开发工程为 [`godot/WhalebellyRuins/project.godot`](godot/WhalebellyRuins/project.godot)（鲸腹遗城 / Whalebelly Ruins）。\n首关七房、最新动作/音频和旧工程资源已合并；不再创建独立版本工程。制作脚本位于 `work/`。\n运行及归档见 [统一工程说明](docs/godot-project.md)。')
txt=txt.replace('# 三个 Godot 工程，含资源、制作记录与缓存','# 唯一 Godot 工程 WhalebellyRuins，缓存不入库')
readme.write_text(txt,encoding='utf8')
(R/'docs/godot-path-updates.json').write_text(json.dumps(changed,ensure_ascii=False,indent=2),encoding='utf8')
print('Updated',len(changed),'live path references, metadata and root docs')
