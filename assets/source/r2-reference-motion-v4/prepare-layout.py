from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
recipes=ROOT/'game/content/whalebelly/world/recipes'
for id,depth in [('R2-03','r2-observation-depth-v4'),('R2-04','r2-bloodnest-depth-v4')]:
 p=recipes/f'{id}.json';d=json.loads(p.read_text(encoding='utf-8'))
 d['reference_background']={'art':depth,'source':f'assets/source/whalefall-v5-2-complete/references/{"17" if id=="R2-03" else "18"}_{id}.png'}
 d['retained_art']=[{'art':'r2-heart-rupture','max':1280},{'art':'r2-membrane-patch','max':1280}]
 d['landmarks']=[a for a in d.get('landmarks',[]) if a['art'] not in ['r2-heart-rupture','r2-membrane-patch']]
 for a in d['framing']:
  if a['art']=='r2-foreground-membrane':a.update(motion='membrane',amplitude=7)
  if a['art'] in ['habitat-fungus-bed','r2-pearl-stalks-v4']:a.update(art='r2-pearl-stalks-v4',max=0,motion='glow')
 for a in d.get('props',[]):
  if a['art']=='habitat-fungus-bed':a.update(art='r2-pearl-stalks-v4',max=0)
 if id=='R2-03':
  d['background_schools']=[{'art':'r2-pelagic-amphipod-v4','rect':[2,6.8,26,1.8],'count':24,'width':48,'opacity':.50,'speed':32},{'art':'r2-pelagic-amphipod-v4','rect':[2,10,26,2.0],'count':30,'width':58,'opacity':.58,'speed':38}]
 else:
  d['background_schools']=[{'art':'r2-pelagic-amphipod-v4','rect':[3,11,30,2.5],'count':20,'width':44,'opacity':.38,'speed':26,'hide_flag':'pressure'}]
 p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
