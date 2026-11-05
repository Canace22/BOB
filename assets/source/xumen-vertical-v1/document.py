from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[3];S=Path(__file__).resolve().parent
def write(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
items=[]
for file in (S/'masters').glob('*-placement.json'):
    edge=file.name.split('-')[0];data=json.loads(file.read_text(encoding='utf8'))
    for item in data['instances']:
        items.append({**item,'edge':edge,'judgement':'static','basis':'authored bone is rigid; no deformation required','material':'painted bitmap','motion':'none','collision':item.get('collision','none: background only or original access body'),'interaction':'none: preserves original passage','sound':'existing chapter water bed; no new source','restore':'deterministic placement on reload','node':'AuthoredShafts/'+item['id'],'acceptance':'GPU bottom/middle/top plus no-front and original physical route','verified':'see game/progress.md; user aesthetic separate'})
    for i in range(2):
        for kind,count in [('FISH',6),('BUBBLE',6)]:
            items.append({'id':edge+'_'+kind+'_'+str(i),'edge':edge,'judgement':'motion','basis':'underwater ecology already present in approved concept','count':count,'layer':'middle water','method':'8-frame body plus path' if kind=='FISH' else 'prewarmed bounded pool with fade and recycle','alternative':'skeletal body' if kind=='FISH' else 'GPU particles','reason':'reuse measured stable technique; no new service cost','clock':'host.clock','collision':'none, decorative','interaction':'none','sound':'no new source, underwater distant decoration','restore':'seeded phase from chapter clock; pause freezes','node':'AuthoredShafts/'+edge+'_'+kind+'_'+str(i),'acceptance':'continuous browser playback, pause/resume and bounded instance QA'})
write(S/'elements.json',{'elements':items,'policy':'original collision/abilities/7 rooms/V6 retained; no new gameplay','sourceHashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (S/'originals').glob('*.png')},'sourceTool':'built-in imagegen; model not exposed; generated task identity in PNG file provenance and prompts.json'})
