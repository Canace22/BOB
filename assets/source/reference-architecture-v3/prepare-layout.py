from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
recipes=ROOT/'game/content/whalebelly/world/recipes'
catalog={a['id']:a for a in json.loads((ROOT/'assets/catalog.json').read_text(encoding='utf-8'))['assets']}
for file in recipes.glob('R*.json'):
    data=json.loads(file.read_text(encoding='utf-8'));id=data['id'];width=data['size'][0]
    framing=[f for f in data.get('framing',[]) if not f['art'].endswith('-v3') and f['art']!='r3-intestinal-loop']
    art='r2-membrane-cavern-frame-v3' if id.startswith('R2') else 'r3-gastric-cavern-frame-v3' if id.startswith('R3') else 'r5-tail-window-frame-v3' if id=='R5-08' else 'r5-cranial-cavern-frame-alpha-v3'
    cover=max(width,data['size'][1]*1280/720)*1.08
    framing.insert(0,{'art':art,'at':[width/2,-.4],'units':round(cover,3),'max':0,'z':-13,'opacity':.8 if id.startswith('R2') else .72})
    if id=='R3-01':
        for prop in data['props']:
            if prop['art']=='shell-camp': prop.update(art='r3-low-shell-camp-v3',units=3.8,max=0)
    if id=='R5-01':
        data['props']=[p for p in data['props'] if p['art']!='progress-three-slots']
        data['retained_art']=[{'art':'progress-three-slots','max':640}]
        framing.append({'art':'r5-three-socket-wall-v3','at':[21,15.5],'units':10,'max':0,'z':-12,'opacity':.78})
        wall=catalog['r5-three-socket-wall-v3'];scale=800/(wall['bbox'][2]-wall['bbox'][0])
        x0=21*80-wall['pivot'][0]*scale;y0=15.5*80-wall['pivot'][1]*scale
        for slot,(x,y) in zip(data['progress_slots'],[(437.5,396.5),(768,398.5),(1090.5,395.5)]):
            slot.update(at=[round((x0+x*scale)/80,5),round((y0+y*scale)/80,5)],pixels=84)
    data['framing']=framing
    file.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
