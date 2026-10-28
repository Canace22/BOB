from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
BASE=Path(__file__).resolve().parent
runtime=BASE.parents[2]/'assets/runtime/sprites/tide-picker-locomotion-v02-video'
m=json.loads((runtime/'manifest.json').read_text());report={'visual_status':'needs_refinement','checks':{}}
for state,a in m['animations'].items():
    frames=[np.array(Image.open(runtime/f['file']).convert('RGBA')) for f in a['frames']]
    assert all(im.shape==(512,512,4) for im in frames)
    assert all(not (im[0,:,3].any() or im[-1,:,3].any() or im[:,0,3].any() or im[:,-1,3].any()) for im in frames)
    unique=len(set(hashlib.sha256(im.tobytes()).hexdigest() for im in frames));assert unique==len(frames)
    def premul(im):
        im=im.astype(float)/255;im[:,:,:3]*=im[:,:,3:4];return im
    p=[premul(im) for im in frames]
    delta=[float(np.abs(p[(i+1)%len(p)]-p[i]).mean()) for i in range(len(p))]
    source=Image.open(BASE/'native-sources'/f'{a["source"]}.webp');assert source.n_frames==81
    report['checks'][state]={'frame_count':len(frames),'unique_pixel_hashes':unique,'transparent_borders':True,'size':[512,512],'source_frames':source.n_frames,'seam_mean_absolute_delta':delta[-1],'median_adjacent_delta':float(np.median(delta)),'max_adjacent_delta':max(delta),'native_selected':a['native_frames'],'derived_bridge':a['bridge_frames']}
(BASE/'review/asset-checks.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
