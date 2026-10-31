"""Deterministic V2.4 import. No rescale, alpha edits or generative redraw."""
from pathlib import Path
from PIL import Image
import json,hashlib,re
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT.parents[2]/'outputs/拾潮者_V2.4_透明边缘去紫'
OUT=ROOT/'assets/animations/player'
def main():
    html=(SOURCE/'透明边缘修订册.html').read_text(encoding='utf8')
    assert '透明度' in html and 'V2.4' in html
    actions=json.loads((SOURCE/'metadata/actions.json').read_text(encoding='utf8'))
    bounds=[0,0,0,0]
    for a in actions:
        meta=json.loads((SOURCE/'metadata'/f'{a["id"]}.json').read_text(encoding='utf8'))
        for i,e in enumerate(meta['frames']):
            box=Image.open(SOURCE/'frames'/a['id']/f'{i:03}.png').getbbox()
            rx,ry=round(e['x']+100),round(520-e['y'])
            bounds=[min(bounds[0],box[0]-rx),min(bounds[1],box[1]-ry),max(bounds[2],box[2]-rx),max(bounds[3],box[3]-ry)]
    bounds=[bounds[0]-4,bounds[1]-4,bounds[2]+4,bounds[3]+4]
    pivot=[-bounds[0],-bounds[1]];size=[bounds[2]-bounds[0],bounds[3]-bounds[1]]
    manifest={'source':str(SOURCE),'fps':12,'source_html_sha256':hashlib.sha256(html.encode()).hexdigest(),'edge_policy':'V2.4 already cleaned. Preserve RGBA exactly; do not erode alpha or apply contrast twice. Nearest filtering; no mipmaps.','pivot':pivot,'size':size,'scale':.22,'actions':{}}
    OUT.mkdir(parents=True,exist_ok=True)
    for a in actions:
        id=a['id'];meta=json.loads((SOURCE/'metadata'/f'{id}.json').read_text(encoding='utf8'));entries=[]
        assert len(meta['frames'])==36
        for folder in [id,'body/'+id]: (OUT/folder).mkdir(parents=True,exist_ok=True)
        for i,e in enumerate(meta['frames']):
            # Original producer used normalized (320,440) + (x-220,80-y).
            rootx=round(e['x']+100);rooty=round(520-e['y']);box=(rootx+bounds[0],rooty+bounds[1],rootx+bounds[2],rooty+bounds[3])
            for source_folder,target in [('frames',id),('character','body/'+id)]:
                src=SOURCE/source_folder/id/f'{i:03}.png';im=Image.open(src).convert('RGBA');cropped=im.crop(box)
                assert sum(im.getchannel('A').getdata())==sum(cropped.getchannel('A').getdata()),(id,i,'clipped')
                cropped.save(OUT/target/f'{i:03}.png')
            entries.append({'frame':i,'source_root':[rootx,rooty],'crop':box,'phase':e['phase'],'source_sha256':hashlib.sha256((SOURCE/'frames'/id/f'{i:03}.png').read_bytes()).hexdigest(),'alpha_preserved':True})
        manifest['actions'][id]={'label':a['name'],'loop':id in ['idle','run','A2_float'],'duration':3.0,'frames':entries}
        if id in ['heavy','A1_dash','A2_float','A3_anchor','A4_parry']:
            (OUT/'effects'/id).mkdir(parents=True,exist_ok=True)
            for e in entries:Image.open(SOURCE/'fx'/id/f'{e["frame"]:03}.png').crop(e['crop']).save(OUT/'effects'/id/f'{e["frame"]:03}.png')
        print(id,'36 frames imported',flush=True)
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
if __name__=='__main__':main()
