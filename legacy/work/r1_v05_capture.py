from pathlib import Path
import subprocess,json,time
P=Path('G:/鲸落万物生/BOB/godot/first-level-artmatch')
EXE='C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
rows=[]
jobs=[(f'R1-{i:02}',i,[])for i in range(1,8)]+[(f'layer-{i}',1,[f'--solo={i}'])for i in range(4)]+[('terrain-02',2,['--outlines']),('near-04',4,['--zoom'])]
for name,room,args in jobs:
 out=P/'evidence'/f'{name}.png'
 with (P/'evidence'/f'{name}.log').open('w',encoding='utf8')as log:
  result=subprocess.run([EXE,'--audio-driver','Dummy','--path',str(P),'--',f'--capture={out}',f'--room={room}','--capture-quit',*args],stdout=log,stderr=subprocess.STDOUT,timeout=30)
 text=(P/'evidence'/f'{name}.log').read_text('utf8')
 row=dict(name=name,exit=result.returncode,errors='ERROR:'in text or 'SCRIPT ERROR'in text,image=out.exists(),audio_driver='Dummy',purpose='visual capture only; not hardware audio validation')
 rows.append(row);print(row,flush=True)
 (P/'evidence/capture-results.json').write_text(json.dumps(rows,indent=2),encoding='utf8')
 if row['errors']or row['exit']!=0:break
