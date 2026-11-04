"""Read-only hash/bounds audit and paired-facing sheet for authored replacements.

This checks asset structure. It is not a gameplay or user-art approval.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import numpy as np

BASE=Path(__file__).resolve().parents[1]
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-action36'
REVIEW=BASE/'review/sprite-sheets'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def audit(keys):
    metadata=json.loads((BASE/'sprite-sheet-actions.json').read_text(encoding='utf8'))['actions']
    result={'kind':'asset_structure_and_agent_source_visual_review; not gameplay approval','actions':{}}
    for key in keys:
        data=metadata[key];body=data['body'];path=RUNTIME/Path(body['texture']).name
        atlas=Image.open(path).convert('RGBA')
        items=[];sheet=Image.new('RGB',(8*240,4*240))
        assert digest(path)==body['sha256'],key
        assert digest(Path(data['source']))==data['source_sha256'],key
        assert len(body['frames'])==data['frame_count'],key
        assert max(atlas.size)<=2048,key
        for i,rect in enumerate(body['frames']):
            x,y,w,h=rect
            assert x>=0 and y>=0 and x+w<=atlas.width and y+h<=atlas.height,(key,i)
            frame=atlas.crop((x,y,x+w,y+h));a=np.asarray(frame)[:,:,3]
            border=max(int(a[0,:].max()),int(a[-1,:].max()),int(a[:,0].max()),int(a[:,-1].max()))
            assert border==0,(key,i,'atlas frame border')
            source=data['frame_review'][i]
            assert sum(source['source_border_pixels_alpha_gt12'].values())==0,(key,i,'source border')
            items.append({'frame':i,'atlas_border_max_alpha':border,'source_alpha_gt64_bbox':source['source_opaque_bbox'],
                          'source_border_pixels_alpha_gt12':source['source_border_pixels_alpha_gt12'],
                          'transparent_fraction':round(float((a==0).mean()),5)})
            for bg_index,color in enumerate(('#122c38','#eee8dd')):
                for direction in range(2):
                    tile=Image.new('RGBA',(240,240),color)
                    reduced=frame.resize((round(w*.6),round(h*.6)),Image.Resampling.LANCZOS)
                    root_x,root_y=body['pivot'];px=120-round(root_x*.6);py=185-round(root_y*.6)
                    tile.alpha_composite(reduced,(px,py))
                    if direction:tile=ImageOps.mirror(tile)
                    draw=ImageDraw.Draw(tile);draw.line((0,185,239,185),fill='#777777')
                    draw.text((8,8),f'{key} {i+1} '+('L' if direction else 'R'),fill='white' if bg_index==0 else 'black')
                    sheet.paste(tile.convert('RGB'),(i*240,(bg_index*2+direction)*240))
        sheet_path=REVIEW/f'{key}-both-facing.jpg';sheet.save(sheet_path,quality=95)
        result['actions'][key]={'source_sha256':data['source_sha256'],'body_sha256':body['sha256'],
                               'atlas_size':list(atlas.size),'atlas_bytes':path.stat().st_size,'frame_count':data['frame_count'],
                               'scale':data['scale'],'reference_height':data['reference_height'],'root_source':data['root_source'],
                               'checks_passed':True,'frames':items,'contact_sheet':str(sheet_path),
                               'runtime_validation':'pending; owner must verify main-scene physics and event mapping'}
    unchanged_path=REVIEW/'unchanged-run-parry-hashes.json'
    if unchanged_path.exists():
        previous=json.loads(unchanged_path.read_text())
        result['unchanged_metadata']={key:hashlib.sha256(json.dumps(metadata[key],sort_keys=True).encode()).hexdigest()==value for key,value in previous.items()}
        assert all(result['unchanged_metadata'].values()),'Unrelated run/parry metadata changed'
    output=REVIEW/'replacement-batch-audit.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps({'output':str(output),'actions':list(result['actions']),'checks_passed':True}))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--keys',nargs='+',default=['wall_jump','heavy','dive'])
    audit(parser.parse_args().keys)
