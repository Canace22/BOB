"""Transparent standalone animation from the reviewed Wan refinement.

Keeps source frames, key paintings and processing provenance separately.
"""
from pathlib import Path
import json, math, hashlib, zipfile, io
import cv2
import numpy as np
from PIL import Image, ImageDraw
from baleen_keyart_v2 import OUT, write, movie

def main():
    raw=sorted((OUT/'raw-repair').glob('*.png'))
    if len(raw)!=73:raise RuntimeError('Expected actual completed 73-frame Wan result')
    frames=[]
    guide0=np.asarray(Image.open(OUT/'guide-alpha/0000.png').convert('RGBA'),np.float32)/255
    yy,xx=np.mgrid[:384,:384].astype(np.float32)
    weight=np.clip((184.5-0.345*xx+24-yy)/15,0,1)[...,None]
    base=guide0.copy();base[:,:,:3]*=base[:,:,3:4]
    for i,p in enumerate(raw):
        rgb=np.asarray(Image.open(p).convert('RGB'),np.float32)/255
        excess=rgb[:,:,1]-np.maximum(rgb[:,:,0],rgb[:,:,2])
        alpha=np.clip(1-(excess-0.055)/0.39,0,1)
        guide=np.asarray(Image.open(OUT/'guide-alpha'/f'{i:04d}.png').getchannel('A'))
        # The refined clip contains a faint fringe outside the actual fibers.
        # Keep the separately authored guide silhouette as an upper alpha bound.
        alpha=np.minimum(alpha,guide.astype(np.float32)/255)
        # Despill only green-edge contamination, preserve ivory and blue shadows.
        rgb[:,:,1]=np.minimum(rgb[:,:,1],np.maximum(rgb[:,:,0],rgb[:,:,2])+0.025)
        premul=np.dstack((rgb*alpha[:,:,None],alpha))
        premul=premul*(1-weight)+base*weight
        frames.append(premul)
    # Enforce a short painted closure, not a full-cycle amplitude envelope.
    # Wan temporal decoding changes texture at its last frame. Blend its residual
    # to the same approved painted guide near the two endpoints only.
    for i in list(range(5))+list(range(68,73)):
        edge=min(i,72-i)/5
        guide=np.asarray(Image.open(OUT/'guide-alpha'/f'{i:04d}.png'),np.float32)/255
        guide[:,:,:3]*=guide[:,:,3:4]
        frames[i]=frames[i]*edge+guide*(1-edge)
    seconds=math.ceil(len(raw)/24);count=seconds*12
    chosen=np.linspace(0,72,count,endpoint=False)
    dark=OUT/'review/dark';light=OUT/'review/light'
    dark.mkdir(exist_ok=True);light.mkdir(exist_ok=True)
    atlas=Image.new('RGBA',(384*8,384*math.ceil(count/8)))
    processed=[]
    mapping=[]
    for n,t in enumerate(chosen):
        a=int(t);b=min(a+1,72);f=t-a
        p=frames[a]*(1-f)+frames[b]*f
        rgb=np.divide(p[:,:,:3],p[:,:,3:4],out=np.zeros_like(p[:,:,:3]),where=p[:,:,3:4]>0.004)
        rgba=np.uint8(np.clip(np.dstack((rgb,p[:,:,3]))*255,0,255))
        rgba[rgba[:,:,3]<3]=0
        im=Image.fromarray(rgba);im.save(OUT/'frames'/f'{n:04d}.png')
        atlas.paste(im,(n%8*384,n//8*384));processed.append(rgba)
        for folder,bg in [(dark,(8,24,34)),(light,(222,222,216))]:
            plate=Image.new('RGBA',(384,384),bg+(255,));plate.alpha_composite(im);plate.convert('RGB').save(folder/f'{n:04d}.png')
        mapping.append({'frame':n,'source_position':float(t),'source_indices':[a,b],'weight':float(f)})
    atlas.save(OUT/'baleen-sway-atlas.png')
    movie(dark,OUT/'videos/baleen-sway-dark-12fps.mp4',12)
    movie(light,OUT/'videos/baleen-sway-light-12fps.mp4',12)
    gifframes=[Image.open(dark/f'{i:04d}.png').convert('RGB') for i in range(count)]
    gifframes[0].save(OUT/'review/baleen-sway.gif',save_all=True,append_images=gifframes[1:],duration=[83,83,84]*(count//3),loop=0)
    contact=Image.new('RGB',(1536,800),(12,24,32));d=ImageDraw.Draw(contact)
    for n,index in enumerate([0,6,12,18,24,30,36,42]):
        im=Image.open(dark/f'{index:04d}.png');x=n%4*384;y=n//4*400
        contact.paste(im,(x,y));d.text((x+8,y+384),f'{index/12:.2f}s',fill='white')
    contact.save(OUT/'review/final-contact.jpg',quality=94)
    # Layered editable OpenRaster key art: separate paint layers, not flattened.
    import xml.etree.ElementTree as ET
    doc=ET.Element('image',{'w':'512','h':'512','name':'Baleen six painted key poses','version':'0.0.3'})
    stack=ET.SubElement(doc,'stack')
    with zipfile.ZipFile(OUT/'keyposes-layered.ora','w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,file in reversed(list(enumerate(sorted((OUT/'keyposes').glob('*.png'))))):
            path=f'data/key-{i:02d}.png';z.write(file,path)
            ET.SubElement(stack,'layer',{'name':f'Key pose {i+1:02d}','src':path,'opacity':'1.0','visibility':'visible' if i==0 else 'hidden','composite-op':'svg:src-over','x':'0','y':'0'})
        z.writestr('stack.xml',ET.tostring(doc,encoding='utf-8'));z.write(OUT/'keyposes/paint-00.png','mergedimage.png')
    delta=[float(np.abs(processed[(i+1)%count].astype(float)-processed[i]).mean()) for i in range(count)]
    fixed=(weight[:,:,0]>=0.999)&(guide0[:,:,3]>0.1)
    rootmax=max(int(np.abs(p.astype(int)-processed[0].astype(int))[fixed].max()) for p in processed)
    stats={'frames':count,'fps':12,'seconds':seconds,'frame_size':[384,384],'unique_frames':len({hashlib.sha256(x.tobytes()).hexdigest() for x in processed}),'root_max_channel_delta':rootmax,'adjacent_rgba_delta_mean':float(np.mean(delta)),'seam_rgba_delta':delta[-1],'max_adjacent_delta':max(delta),'naturalness':'agent review pending; user not yet approved','engine_integrated':False}
    write(OUT/'review/validation.json',stats)
    write(OUT/'manifest.json',{'asset_id':'BALEEN-KEYART-V2','source_video':'videos/wan22-refined-repair-source.mp4','source_frames':73,'source_fps':24,'source_seconds':73/24,'target_frames':count,'target_fps':12,'target_seconds':seconds,'atlas':'baleen-sway-atlas.png','columns':8,'frame_size':[384,384],'anchor':[192,118],'method':'Six separately painted keys, DIS-flow timing guide, actual Wan2.2 video-to-video refinement; chroma matte; common painted root; 5-source-frame edge closure; premultiplied retiming. Not hand-painted inbetweens, not direct raw video extraction.','mapping':mapping,'limits':['single standalone cluster sample','not all four original scene cluster shapes','not yet Godot integrated','fine strand identity and perceived smoothness require review']})
    write(OUT/'metadata/krita-import-spec.json',[
        {'title':'Baleen - six painted key poses','size':512,'folder':'keyposes','layer':'Six separately painted key poses - storyboard','file':'baleen-keyposes.kra'},
        {'title':'Baleen - transparent sway 12 FPS','size':384,'folder':'frames','layer':'Wan refined and root-corrected RGBA animation','file':'baleen-sway-12fps.kra'}])
    print(json.dumps(stats,indent=2))

if __name__=='__main__':main()
