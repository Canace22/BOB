from pathlib import Path
import subprocess,json,sys,time
p=Path('G:/鲸落万物生/BOB/godot/first-level');b=Path('G:/鲸落万物生/builds/须门遗港-v0.3-场景还原');exe=b/'Whalefall.exe'
jobs=[('latch-reload',['--headless','--','--qa-latch-load']),('recover',['--headless','--','--qa-combat']),('scenery-pack',['--','--qa-scenery']),('play-pack',['--','--qa-render']),('reload-pack',['--headless','--','--qa-load']),('normal-pack',['--quit-after','90'])]
results=[]
for name,args in jobs:
 dest=p/'evidence/v03'/name;dest.mkdir(parents=True,exist_ok=True)
 cmd=[str(exe),*args]
 if '--'in args:cmd+=['--evidence-dir='+str(dest)]
 t=time.time()
 try:
  r=subprocess.run(cmd,cwd=b,capture_output=True,timeout=280)
  log=(r.stdout+r.stderr).decode('utf8',errors='replace');(dest/'run.log').write_text(log,encoding='utf8')
  fail='SCRIPT ERROR' in log or 'ERROR:' in log
  row={'name':name,'exit_code':r.returncode,'error_in_log':fail,'seconds':time.time()-t,'log':str(dest/'run.log')}
 except subprocess.TimeoutExpired as e:
  row={'name':name,'timeout':True,'seconds':time.time()-t}
 results.append(row)
 (p/'docs/v03/pack-qa-processes.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8')
 print(name,row,flush=True)
 if row.get('exit_code',1)!=0 or row.get('error_in_log',False):break
