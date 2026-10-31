"""Validate the pending portable PCK before replacing the existing package."""
from pathlib import Path
import json, hashlib, subprocess, os
from integrate_baleen_loop_v3 import ROOT, PROJECT, OUT, dump, digest

ENGINE=Path(os.environ['LOCALAPPDATA'])/'Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
BUILD=ROOT.parent/'builds/WhalebellyRuins'
EV=PROJECT/'evidence/baleen_loop_v3'

def execute(label,args,timeout=180):
    file=EV/(label+'.log')
    with file.open('w',encoding='utf-8',newline='\n') as log:
        result=subprocess.run([str(a) for a in args],cwd=BUILD,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
    content=file.read_text(encoding='utf-8',errors='replace')
    if result.returncode or 'ERROR:' in content or 'SCRIPT ERROR' in content:
        raise RuntimeError(f'{label} failed ({result.returncode}): {content[-2000:]}')
    return {'exit_code':result.returncode,'log':str(file.relative_to(PROJECT)).replace('\\','/')}

def run():
    for mode in ['environment','main']:
        assert json.loads((EV/(mode+'-checks.json')).read_text())['failures']==0
    protected=json.loads((OUT/'protected-before.json').read_text())
    checks={p:digest(PROJECT/p)==sha for p,sha in protected.items()}
    assert all(checks.values()),checks
    pending=BUILD/'WhalebellyRuins.pending.pck'
    export=execute('package-export',[ENGINE,'--headless','--path',PROJECT,'--export-pack','Windows Portable',pending])
    package=execute('package-main',[BUILD/'WhalebellyRuins.exe','--main-pack',pending,'--audio-driver','Dummy','--script','res://tests/baleen_loop_v3.gd','--','--baleen-mode=main','--baleen-out='+str(EV/'package')])
    result=json.loads((EV/'package/main-checks.json').read_text())
    assert result['failures']==0
    before=digest(BUILD/'WhalebellyRuins.pck')
    os.replace(pending,BUILD/'WhalebellyRuins.pck')
    report={'export':export,'independent_executable':package,'package_checks':len(result['checks']),'package_failures':result['failures'],'protected_file_hashes_unchanged':checks,'replaced_existing_package':str(BUILD/'WhalebellyRuins.pck'),'previous_pck_sha256':before,'pck_sha256':digest(BUILD/'WhalebellyRuins.pck'),'bytes':(BUILD/'WhalebellyRuins.pck').stat().st_size,'distribution':'Existing official Godot4.7.2 executable plus newly exported PCK; not a release-template export','physical_audio_tested':False}
    dump(EV/'package-verification.json',report)
    print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)

if __name__=='__main__':run()
