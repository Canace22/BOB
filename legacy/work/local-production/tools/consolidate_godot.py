"""One-time consolidation helper; deletion is a separate verified PowerShell step."""
from pathlib import Path
import argparse,os,hashlib,json,zipfile,shutil,datetime
REPO=Path(__file__).resolve().parents[1]
ROOT=REPO/'godot'; NAMES=['first-level','first-level-artmatch','first-level-v02-graybox']
TARGET=ROOT/'WhalebellyRuins'
REPORT=REPO/'docs/godot-consolidation.json'
SKIP={'.godot','.git','__pycache__'}
def files(folder):
    result={}
    for base,dirs,names in os.walk(folder):
        dirs[:]=[d for d in dirs if d not in SKIP]
        for d in dirs:
            if (Path(base)/d).is_symlink():raise RuntimeError('Unexpected link '+str(Path(base)/d))
        for name in names:
            f=Path(base)/name
            if f.is_symlink():raise RuntimeError('Unexpected link '+str(f))
            result[f.relative_to(folder).as_posix()]=f
    return result
def digest(f):return hashlib.file_digest(f.open('rb'),'sha256').hexdigest()
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args()
    assert all((ROOT/n/'project.godot').is_file() for n in NAMES)
    catalog={n:files(ROOT/n) for n in NAMES}
    first,art=catalog[NAMES[0]],catalog[NAMES[1]]
    shared=set(first)&set(art)
    conflicts=[s for s in sorted(shared) if first[s].stat().st_size!=art[s].stat().st_size or digest(first[s])!=digest(art[s])]
    summary={n:{'files':len(v),'bytes':sum(f.stat().st_size for f in v.values())} for n,v in catalog.items()}
    report={'at':datetime.datetime.now().astimezone().isoformat(),'target':str(TARGET),'inputs':summary,'conflicts_artmatch_wins':conflicts,'first_unique':sorted(set(first)-set(art)),'policy':'Latest artmatch runtime; first-level-only assets retained at original relative path; older code/docs/tools isolated under ignored history; all original source projects backed up without caches; current artmatch save directory unchanged.'}
    print(json.dumps({'inputs':summary,'conflicts':len(conflicts),'first_unique':len(report['first_unique'])},ensure_ascii=False),flush=True)
    if not args.apply:return
    assert not TARGET.exists(),'Target already exists; review saved report before resuming'
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup=REPO.parent/'backups'/('godot-before-consolidation-'+stamp+'.zip')
    backup.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(backup,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as z:
        for name,entries in catalog.items():
            for rel,f in entries.items():z.write(f,name+'/'+rel)
    with zipfile.ZipFile(backup) as z:
        assert len(z.infolist())==sum(len(v) for v in catalog.values())
        assert z.testzip() is None
    report['backup']={'path':str(backup),'sha256':digest(backup),'bytes':backup.stat().st_size,'crc_test':'pass','excludes':['.godot','.git','__pycache__']}
    print('BACKUP_VERIFIED',str(backup),flush=True)
    TARGET.mkdir()
    copied=[]
    for rel,f in art.items():
        dest=TARGET/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,dest)
        copied.append({'source':str(f),'target':str(dest),'sha256':digest(f),'type':'active'})
    history=TARGET/'production-history/pre-unification/first-level'
    for rel,f in first.items():
        if rel in shared and rel not in conflicts:continue
        if rel.startswith('assets/') and rel not in shared:
            dest=TARGET/rel;kind='retained_asset'
        else:
            # No second project.godot remains discoverable even in history.
            dest=history/(rel+'.archived' if rel=='project.godot' else rel);kind='historical'
        dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,dest)
        copied.append({'source':str(f),'target':str(dest),'sha256':digest(f),'type':kind})
    history.parent.mkdir(parents=True,exist_ok=True)
    (history.parent/'.gdignore').write_text('Archived reference only. Not an active Godot project.\n',encoding='utf8')
    (history.parent/'README.md').write_text('# 合并前记录\n\n旧 first-level 的非重复制作记录、冲突版本与旧运行脚本保留在此。`.gdignore` 阻止导入；不得作为第二个工程继续开发。完整原件含灰盒在 docs/godot-consolidation.json 指定的外部ZIP中。\n',encoding='utf8')
    for row in copied:assert digest(Path(row['target']))==row['sha256'],row['target']
    report['copied']=copied
    report['copied_integrity']='all_sha256_match_before_path_updates'
    report['status']='merged_pending_validation_and_old_directory_removal'
    REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    print('MERGED',len(copied),'files',flush=True)
if __name__=='__main__':main()
