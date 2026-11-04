"""Render source/body/ground-layer comparisons without writing runtime assets."""
import sys, json
import numpy as np
from PIL import Image,ImageDraw
from build import RUNTIME, REVIEW, read_frame, semantic_layers
from ground_effect_layers import separate

actions=json.loads((RUNTIME/'animations.json').read_text(encoding='utf-8'))['actions']
for key in sys.argv[1:]:
    action=actions[key]
    indices=[round(i*(action['frame_count']-1)/5) for i in range(6)]
    out=Image.new('RGB',(768*3,456*6),'#132b36')
    for row,index in enumerate(indices):
        rgb=read_frame(action['source'],action['source_seconds'][index])
        body,_=semantic_layers(rgb,key)
        clean,fx=separate(rgb,body,key)
        out.paste(Image.fromarray(rgb),(0,row*456))
        for col,layer in [(1,clean),(2,fx)]:
            tile=Image.new('RGBA',layer.size,'#132b36');tile.alpha_composite(layer)
            out.paste(tile.convert('RGB'),(col*768,row*456))
        ImageDraw.Draw(out).text((8,row*456+434),f'{key} source frame {index}: source / body / ground FX',fill='white')
    out.save(REVIEW/f'{key}-ground-split-review.jpg',quality=95)
    print('Rendered',key,flush=True)
