from pathlib import Path
import subprocess,json,time
p=Path('G:/鲸落万物生/BOB/godot/first-level');b=Path('G:/鲸落万物生/builds/须门遗港-v0.3-场景还原');exe=b/'Whalefall.exe'
results=[]
for name,args in [('play-final',['--','--qa-render']),('reload-final',['--headless','--','--qa-load']),('normal-final',['--quit-after','90'])]:
 dest=p/'evidence/v03'/name;dest.mkdir(parents=True,exist_ok=True);cmd=[str(exe),*args]
 if '--'in args:cmd+=['--evidence-dir='+str(dest)]
 t=time.time();r=subprocess.run(cmd,cwd=b,capture_output=True,timeout=280)
 log=(r.stdout+r.stderr).decode('utf8',errors='replace');(dest/'run.log').write_text(log,encoding='utf8')
 row={'name':name,'exit_code':r.returncode,'error_in_log':'ERROR:'in log or 'SCRIPT ERROR'in log,'seconds':time.time()-t,'log':str(dest/'run.log')}
 results.append(row);(p/'docs/v03/final-qa-processes.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf8');print(row,flush=True)
 if row['exit_code']!=0 or row['error_in_log']:break
