"""Deterministic plain-background extraction, preserves a common canvas and native timing."""
from pathlib import Path
import argparse,json
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage as ndi
BASE=Path(__file__).resolve().parent
def matte(im):
    arr=np.asarray(im.convert('RGB')).astype(np.float32)
    bg=np.median(np.concatenate([arr[:16].reshape(-1,3),arr[-16:].reshape(-1,3),arr[:,:16].reshape(-1,3),arr[:,-16:].reshape(-1,3)]),axis=0)
    d=np.linalg.norm(arr-bg,axis=2)
    candidate=d<25
    labels,n=ndi.label(candidate)
    border=np.unique(np.concatenate([labels[0],labels[-1],labels[:,0],labels[:,-1]]));border=border[border!=0]
    background=np.isin(labels,border)
    # Also remove genuinely enclosed flat backdrop holes between the rope and fork.
    sizes=np.bincount(labels.ravel())
    for label in range(1,n+1):
        if label in border or sizes[label]<18:continue
        yy,xx=np.where(labels==label)
        if yy.mean()>280 and np.median(d[labels==label])<20:background|=labels==label
    support=~background
    components,num=ndi.label(support)
    counts=np.bincount(components.ravel());counts[0]=0
    support=components==np.argmax(counts)
    # Estimate foreground coverage from nearby interior colour to remove grey matte fringes.
    interior=ndi.binary_erosion(support,iterations=2)
    nearest=ndi.distance_transform_edt(~interior,return_distances=False,return_indices=True)
    foreground=arr[nearest[0],nearest[1]]
    edge=support & ~interior
    alpha=support.astype(np.float32)
    vec=foreground-bg
    coverage=np.sum((arr-bg)*vec,axis=2)/np.maximum(np.sum(vec*vec,axis=2),1)
    alpha[edge]=np.clip(coverage[edge],0,1)
    recovered=bg+(arr-bg)/np.maximum(alpha[:,:,None],0.08)
    arr[edge]=np.clip(recovered[edge],0,255)
    rgba=np.dstack([arr,np.round(alpha*255)]).astype(np.uint8)
    return Image.fromarray(rgba),bg.tolist()
def main(state,revision,samples):
    name=f'{state}_{revision}';files=sorted((BASE/'raw'/name).glob('*.png'))
    dest=BASE/'transparent'/name;dest.mkdir(parents=True,exist_ok=True)
    selected=[files[i] for i in np.linspace(0,len(files)-1,8,dtype=int)] if samples else files
    checks=[];sheet=Image.new('RGB',(4*352,2*380),'#19313b')
    for k,p in enumerate(selected):
        clean,bg=matte(Image.open(p));clean.save(dest/p.name)
        checks.append({'frame':p.name,'background_rgb':bg,'alpha_bbox':clean.getbbox()})
        if samples:
            small=clean.resize((352,352));x=k%4*352;y=k//4*380;sheet.paste(small,(x,y),small);ImageDraw.Draw(sheet).text((x+8,y+356),p.stem,fill='white')
    if samples:sheet.save(BASE/'review'/f'{name}_matte-samples.jpg',quality=93)
    (BASE/'review'/f'{name}_matte.json').write_text(json.dumps({'mode':'samples' if samples else 'all','algorithm':'border connected plain-backdrop removal; no per-frame resizing or root shift','frames':checks},indent=2),encoding='utf-8')
    print('MATTE',name,len(selected))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('state');p.add_argument('--revision',default='r1');p.add_argument('--samples',action='store_true');a=p.parse_args();main(a.state,a.revision,a.samples)
