"""Reviewed source-coordinate separation of cyan ground responses.

Only these explicitly reviewed bands are processed. Dark boots, red rope and
warm ivory fork pixels are excluded from the cyan criterion. This cannot
reconstruct costume pixels that the source effect fully occludes.
"""
import numpy as np
from PIL import Image

BANDS={'heavy':330,'dive':350}

def separate(rgb, body, key):
    if key not in BANDS:
        raise ValueError('Unreviewed ground-effect source: '+key)
    pixels=rgb.astype(np.float32)
    y=np.indices(rgb.shape[:2])[0]
    # Source coordinates at working width 768; do not silently rescale ROIs.
    if rgb.shape[1]!=768:
        raise ValueError('Ground bands require the reviewed 768-pixel source')
    cyan=np.minimum(pixels[:,:,1]-pixels[:,:,0]-10,pixels[:,:,2]-pixels[:,:,0]-5)
    strength=np.clip(cyan/38,0,1)*np.clip((pixels[:,:,1]-85)/50,0,1)
    strength[y<BANDS[key]]=0
    selected=strength>.025
    result=np.asarray(body).copy()
    result[:,:,3][selected]=0
    result[result[:,:,3]==0,:3]=0
    # Retain original authored ring color, using chroma coverage as alpha.
    # Normal blend is required: a teal ring over beige is not additive light.
    color=pixels.copy(); color[~selected]=0
    effect=Image.fromarray(np.dstack([color,strength*255]).clip(0,255).astype('uint8'))
    return Image.fromarray(result),effect
