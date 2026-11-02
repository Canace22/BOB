"""Calls the existing Framecraft workflow; 50 FPS ticks preserve clip timing exactly."""
from pathlib import Path
import json,shutil,subprocess,sys
P=Path(__file__).resolve().parent
ROOT=P.parents[3]
PLATFORM='/Users/canace/Documents/Codex/2026-11-02/https-github-com-eanojiang-sprite-workbench/work/sprite-workbench'
clips=json.loads((P/'clips-source.json').read_text())
D=P/'delivery';D.mkdir(exist_ok=True)
manifest={'direction':'right','canvas':[384,384],'pivot':[192,342],'scale':.275,'standingHeight':240,'clips':{}}
if (D/'manifest.json').exists():manifest=json.loads((D/'manifest.json').read_text())
for name,c in clips.items():
 if len(sys.argv)>1 and name not in sys.argv[1:]:continue
 src=P/name/'timeline-input';fr=src/'frames';fr.mkdir(parents=True,exist_ok=True)
 for old in fr.glob('*.png'):old.unlink()
 tick=20;fps=50;rows=[];n=0
 for pose,dur in zip(c['poses'],c['durations']):
  assert dur%tick==0,(name,dur)
  for _ in range(dur//tick):
   n+=1;file=f'frame-{n:03}.png';shutil.copyfile(P/'registered'/f'{pose}.png',fr/file);rows.append({'file':file,'pose':pose,'durationMs':tick})
 (src/'timeline.json').write_text(json.dumps({'clip':name,'fps':fps,'loop':c['loop'],'canvas':[384,384],'pivot':[192,342],'frames':rows},indent=2)+'\n')
 opts={'name':f'拾潮者_RIGHT_v2_{name}_50FPS根脚注册','output':str(P/name/'platform'),'framesDirectory':'frames','fps':fps,'loop':c['loop'],'pivot':[192,342],'direction':'right','exportName':f'player-right-v2-{name}','settings':{'scale':1,'alphaThreshold':8,'sharpen':0},'limitations':['Hand-painted poses; repeated timing ticks do not claim new inbetweens.','Gameplay placement and artistic acceptance reviewed separately.'],'copySourceFrames':False}
 op=P/name/'platform-options.json';op.write_text(json.dumps(opts,ensure_ascii=False,indent=2)+'\n')
 subprocess.run(['node',str(ROOT/'assets/source/crab-animation-platform-v1/process.mjs'),PLATFORM,str(src),str(op)],check=True)
 entry={'loop':c['loop'],'frames':[]};n=0
 for i,(pose,dur) in enumerate(zip(c['poses'],c['durations'])):
  filename=f'{name}-{i:02}.png';shutil.copyfile(P/name/'platform'/'processed'/f'frame-{n+1:03}.png',D/filename)
  entry['frames'].append({'file':f'right/{filename}','durationMs':dur});n+=dur//tick
 for key in ['stridePixels','activeWindowMs']:
  if key in c:entry[key]=c[key]
 manifest['clips'][name]=entry
 (D/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 print('DELIVERED',name,flush=True)
