from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[3];S=Path(__file__).resolve().parent
rooms=json.loads((R/'game/art/whalebelly/rooms.json').read_text(encoding='utf8'))
layout=json.loads((R/'assets/source/xumen-connected-v2/layout-snapshot.json').read_text(encoding='utf8'))
contract=json.loads((R/'assets/source/xumen-transition-style-v1/integration-contract.json').read_text(encoding='utf8'))
origin=[v['origin'] for v in layout['rooms']]
surfaces=[]
for i,room in enumerate(rooms):
 for j,points in enumerate(room['surfaces']):
  if i==0 and j>0:continue
  at=[[round(x+origin[i][0],3),round(y+origin[i][1],3)] for x,y in points]
  # The curved lowest bed in R1-06 remains a distinct physical surface.
  surfaces.append({'id':room['id']+'-surface-'+str(j),'room':i,'surface':j,'points':at,'depth':190 if j==0 and i<5 else 48,'kind':'main' if j==0 and i<5 else 'ledge'})
for edge in contract['edges']:
 if edge['id'].startswith('E0'):
  a,b=edge['anchors']['from'],edge['anchors']['to']
  surfaces.append({'id':edge['id'],'room':-1,'points':[[a[0]-18,a[1]],[b[0]+18,b[1]]],'depth':190,'kind':'main'})
 else:
  for p in edge['platforms']:surfaces.append({'id':p['id'],'room':-1,'points':[[p['x'][0],p['y']],[p['x'][1],p['y']]],'depth':34,'kind':'step'})
  for access,p in edge['existingAccess'].items():
   p=sorted(p,key=lambda a:a[0]);surfaces.append({'id':edge['id']+'-'+access,'room':-1,'points':p,'depth':34,'kind':'step'})
data={'canvas':[-640,-1880,11584,3520],'rooms':layout['rooms'],'surfaces':surfaces,'source_room_hash':hashlib.sha256((R/'game/art/whalebelly/rooms.json').read_bytes()).hexdigest(),'collision_changes':False}
(S/'layout.json').write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
im=Image.new('RGB',(1738,528),'#10242e');d=ImageDraw.Draw(im);x0,y0,w,h=data['canvas'];q=im.width/w
for i,r in enumerate(layout['rooms']):
 x,y=r['origin'];rw,rh=r['size'];d.rectangle(((x-x0)*q,(y-y0)*q,(x+rw-x0)*q,(y+rh-y0)*q),outline='#355365',width=1);d.text(((x-x0)*q+6,(y-y0)*q+8),r['id'],fill='#d8e0d7')
for item in surfaces:d.line([((x-x0)*q,(y-y0)*q) for x,y in item['points']],fill='#e7d6b0',width=2)
im.save(S/'masters/layout-guide.png')
(S/'production.json').write_bytes((json.dumps({'stage':'unified_art','scope':'7 rooms,6 existing links; unified master then textured terrain','old_visual_review':'user rejected; technical history retained','completed':['layout snapshot and original collision hash'],'pending':['new painted kit','editable world master','scene integration','visual and physical tests','publish and online']},ensure_ascii=False,indent=2)+'\n').encode('utf8'))
