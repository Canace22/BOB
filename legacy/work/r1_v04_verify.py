from pathlib import Path
import subprocess,json,sys,time
p=Path('G:/鲸落万物生/BOB/godot/first-level')
exe='C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
tasks={'mechanisms':['--','--qa-mechanisms'],'import':['--headless','--editor','--import'],'art':['--','--qa-v04-art'],'routes':['--','--qa-routes'],'play':['--','--qa-render'],'branch':['--','--qa-branch'],'reload':['--headless','--','--qa-load'],'death':['--','--qa-combat'],'latch':['--headless','--','--qa-latch-load'],'normal':['--quit-after','100']}
for name in sys.argv[1:]:
 d=p/'evidence/v04'/name;d.mkdir(parents=True,exist_ok=True)
 args=tasks[name].copy()
 if '--' in args:args+=['--evidence-dir='+str(d)]
 start=time.time()
 try:
  with (d/'run.log').open('w',encoding='utf8') as log:
   result=subprocess.run([exe,'--path',str(p),*args],stdout=log,stderr=subprocess.STDOUT,timeout=290)
  text=(d/'run.log').read_text('utf8')
  row={'exit':result.returncode,'errors':'ERROR:' in text or 'SCRIPT ERROR' in text,'seconds':time.time()-start}
 except subprocess.TimeoutExpired:row={'exit':'timeout','errors':True}
 (d/'process.json').write_text(json.dumps(row),encoding='utf8');print(name,row,flush=True)
 if row['exit']!=0 or row['errors']:break
