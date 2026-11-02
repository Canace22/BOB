from pathlib import Path
from PIL import Image,ImageDraw
import json,zipfile,hashlib
P=Path(__file__).resolve().parent
m=json.loads((P/'delivery/manifest.json').read_text());checks=[];projects={};all_preview=[];all_times=[]
(P/'previews').mkdir(exist_ok=True)
for clip,c in m['clips'].items():
 d=P/clip/'platform';run=json.loads((d/'review/platform-run.json').read_text());projects[clip]=run['projectId']
 assert run['fps']<=50
 z=zipfile.ZipFile(d/'exports'/f'player-left-v2-{clip}.zip');zm=json.loads(z.read('manifest.json'))
 assert len(zm['frames'])==run['frameCount']
 for f in zm['frames']:
  assert z.read(f['filename'])==(d/'processed'/f['sourceName']).read_bytes()
 frames=[];rows=[]
 for f in c['frames']:
  file=P/'delivery'/Path(f['file']).name;a=Image.open(file).convert('RGBA');b=a.getchannel('A').getbbox();assert a.size==(384,384) and b
  edge=b[0]==0 or b[1]==0 or b[2]==384 or b[3]==384
  assert not edge,(clip,file.name,b)
  rows.append({'file':f['file'],'durationMs':f['durationMs'],'alphaBbox':b,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
  frames.append(a)
  small=a.resize((106,106),Image.Resampling.LANCZOS);card=Image.new('RGBA',(180,150),(38,43,48,255));card.alpha_composite(small,(37,8));draw=ImageDraw.Draw(card);draw.text((6,128),clip,fill='white');all_preview.append(card);all_times.append(f['durationMs'])
 duration=sum(f['durationMs'] for f in c['frames']);assert abs(duration-run['durationMs'])<1e-6,(clip,duration,run['durationMs'])
 if 'activeWindowMs' in c:
  start,end=c['activeWindowMs'];assert 0<start<end<duration
 frames[0].save(P/'previews'/f'{clip}.webp',save_all=True,append_images=frames[1:],duration=[f['durationMs'] for f in c['frames']],loop=0 if c['loop'] else 1,lossless=True)
 checks.append({'clip':clip,'durationMs':duration,'posesInManifest':len(frames),'uniqueDecodedFrames':len({im.tobytes() for im in frames}),'platformTicks':run['frameCount'],'platformFps':run['fps'],'projectId':run['projectId'],'zipBytesMatch':True,'canvas':[384,384],'noCanvasEdgeContact':True,'loop':c['loop'],'platformManifestLoop':zm['loop'],'frames':rows})
all_preview[0].save(P/'previews'/'all-actions-game-scale.webp',save_all=True,append_images=all_preview[1:],duration=all_times,loop=0,lossless=True)
(P/'review/delivery-checks.json').write_text(json.dumps({'canvas':[384,384],'pivot':[192,342],'gameScale':.275,'standingHeightWorld':66,'checks':checks,'notCertified':['User artistic acceptance','Gameplay foot-slip and input/state transitions; parent task handles actual game verification']},indent=2)+'\n')
(P/'review/current-projects.json').write_text(json.dumps(projects,indent=2)+'\n')
print(json.dumps({'clips':list(m['clips']),'pngCount':len(list((P/'delivery').glob('*.png'))),'allZipBytesMatch':True,'noEdgeContact':True,'maxPlatformFps':max(c['platformFps'] for c in checks),'projects':projects},indent=2))
