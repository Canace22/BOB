"""Deterministic crop/registration of authored poses; never generates anatomy."""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[2]
DEST = ROOT / 'assets/runtime/sprites/corpse-crab-actions-v1'
QA = ROOT / 'game/build/qa/corpse-crab/assets'
SCALE = .48
ANCHOR = (144, 224)
SPECS = {
    'attack': {'edges': [0, 440, 890, 1320, 1774], 'feet': [376]*4+[819]*4},
    'walk': {'edges': [0, 444, 890, 1333, 1774], 'feet': [356]*4+[799]*4},
    'life': {'edges': [0, 444, 890, 1333, 1774], 'feet': [356]*4+[799]*4},
}
CLIPS = {
    'idle': {'sheet': 'life', 'frames': [0,1,2,3,2,1], 'fps': 5, 'loop': True},
    'walk': {'sheet': 'walk', 'frames': list(range(8)), 'stride_pixels': 40, 'loop': True},
    'tell': {'sheet': 'attack', 'frames': [0,1,2], 'duration': .7},
    'active': {'sheet': 'attack', 'frames': [3,4,5], 'duration': .2, 'events': [{'id':'sweep','time':.06}]},
    'recover': {'sheet': 'attack', 'frames': [6,7], 'duration': 1.1},
    'hurt': {'sheet': 'life', 'frames': [4,5], 'duration': .22},
    'dead': {'sheet': 'life', 'frames': [5,6,7], 'duration': .5},
}

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    (QA.parents[2] / '.gdignore').touch()
    meta = {'id':'corpse-crab-actions-v1','canvas':[256,256],'anchor':list(ANCHOR),
            'source_scale':SCALE,'world_scale':.82,'facing':'left','direction':'whole-body-mirror',
            'model':'image_gen; model identifier not exposed','clips':CLIPS,'sheets':{}}
    all_frames={}
    for name, spec in SPECS.items():
        src=SOURCE/f'{name}-source.png'
        im=Image.open(src).convert('RGBA')
        assert im.size==(1774,887), 'Source changed; re-review crops/registration'
        sheet=Image.new('RGBA',(1024,512))
        frames=[]; records=[]
        for i in range(8):
            row,col=divmod(i,4)
            rect=(spec['edges'][col],443*row,spec['edges'][col+1],443 if row==0 else 887)
            tile=im.crop(rect)
            # Fixed global scale; premultiply during interpolation to avoid dark matte.
            tile=tile.convert('RGBa').resize((round(tile.width*SCALE),round(tile.height*SCALE)),Image.Resampling.LANCZOS).convert('RGBA')
            root=(270+443*col,spec['feet'][i])
            offset=(round(ANCHOR[0]-(root[0]-rect[0])*SCALE),round(ANCHOR[1]-(root[1]-rect[1])*SCALE))
            frame=Image.new('RGBA',(256,256)); frame.alpha_composite(tile,offset)
            bbox=frame.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
            assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<256 and bbox[3]<256,(name,i,bbox)
            frame.save(DEST/f'{name}-{i:02}.png',optimize=True)
            sheet.alpha_composite(frame,(col*256,row*256));frames.append(frame)
            records.append({'source_rect':rect,'source_root':root,'offset':offset,'visible_bbox_alpha32':bbox})
        output=DEST/f'{name}.png';sheet.save(output,optimize=True)
        meta['sheets'][name]={'file':output.name,'columns':4,'rows':2,'frame_count':8,
                             'source':str(src.relative_to(ROOT)).replace('\\','/'),'source_sha256':digest(src),
                             'sha256':digest(output),'frames':records}
        # Review composites only, not game assets.
        review=Image.new('RGB',(1024,1024),(225,229,226))
        review.paste(sheet,(0,0),sheet);review.paste((12,28,36),(0,512,1024,1024));review.paste(sheet,(0,512),sheet)
        review.save(QA/f'{name}-contact.png')
        all_frames[name]=frames
    (DEST/'animations.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    timeline=[]
    for action in ['idle','walk','tell','active','recover','hurt','dead']:
        clip=CLIPS[action]
        frame_ids=clip['frames']
        durations=round(1000*clip.get('duration',1.2)/len(frame_ids))
        for index in frame_ids:
            frame=Image.new('RGB',(600,300),(15,30,39))
            art=all_frames[clip['sheet']][index]
            frame.paste(art,(24,20),art)
            reverse=art.transpose(Image.Transpose.FLIP_LEFT_RIGHT);frame.paste(reverse,(320,20),reverse)
            ImageDraw.Draw(frame).text((20,280),action,fill='white')
            timeline.append((frame,durations))
    timeline[0][0].save(QA/'actions.gif',save_all=True,append_images=[x[0] for x in timeline[1:]],duration=[x[1] for x in timeline],loop=0)
    print(json.dumps({'sheets':3,'unique_source_poses':24,'actions':list(CLIPS),'atlas_bytes':sum((DEST/f'{k}.png').stat().st_size for k in SPECS),'qa':str(QA)},ensure_ascii=False))

if __name__=='__main__': main()
