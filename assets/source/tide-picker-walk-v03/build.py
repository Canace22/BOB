"""Video extraction with reference restoration; keep original source and explicit provenance."""
from pathlib import Path
import importlib.util
import json
import hashlib
import math
import shutil
import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[2]
ASSET = 'tide-picker-walk-v03'
RUNTIME = REPO / 'assets/runtime/sprites' / ASSET
DEST = REPO / 'godot/WhalebellyRuins/assets/runtime' / ASSET
OLD = BASE.parent / 'tide-picker-idle-v03'
spec = importlib.util.spec_from_file_location('idle_builder', OLD / 'build.py')
old = importlib.util.module_from_spec(spec)
spec.loader.exec_module(old)

def matte(rgb):
    a = rgb.astype(np.float32)
    neutral = (a.max(2)-a.min(2)<42) & (a.mean(2)>62) & (a[:,:,0]>=a[:,:,1]) & (a[:,:,1]>=a[:,:,2])
    labels, n = ndi.label(neutral)
    border = np.unique(np.r_[labels[0],labels[-1],labels[:,0],labels[:,-1]])
    bg = np.isin(labels,border[border>0])
    # Enclosed neutral backdrop around rope and between hand/legs, below the ivory shell.
    for lab in range(1,n+1):
        yy,xx=np.where(labels==lab)
        if len(xx)>12 and yy.mean()>110: bg |= labels==lab
    mask=~bg
    labels,n=ndi.label(mask);counts=np.bincount(labels.ravel());counts[0]=0
    mask=labels==counts.argmax()
    inner=ndi.binary_erosion(mask)
    nearest=ndi.distance_transform_edt(~inner,return_distances=False,return_indices=True)
    fg=a[nearest[0],nearest[1]]
    background=np.median(a[bg & (np.indices(bg.shape)[0]<280)],axis=0)
    v=fg-background
    alpha=mask.astype(np.float32)
    edge=mask & ~inner
    coverage=((a-background)*v).sum(2)/np.maximum((v*v).sum(2),1)
    alpha[edge]=coverage[edge].clip(0,1)
    a[edge]=(background+(a-background)/np.maximum(alpha[...,None],.1))[edge].clip(0,255)
    a[alpha==0]=0
    return np.dstack([a,alpha*255]).astype(np.uint8)

def premul(im):
    a=np.asarray(im).astype(np.float32)/255
    a[:,:,:3]*=a[:,:,3:4]
    return a

def unpremul(a):
    a=a.copy().clip(0,1)
    a[:,:,:3]/=np.maximum(a[:,:,3:4],1e-6)
    return Image.fromarray(np.round(a.clip(0,1)*255).astype(np.uint8))

def main():
    for p in [RUNTIME,DEST,BASE/'frames',BASE/'review']:p.mkdir(parents=True,exist_ok=True)
    shutil.copy2(OLD/'reference.png',BASE/'reference.png')
    ref=np.asarray(Image.open(OLD/'master-rgba.png').convert('RGBA'))
    cap=cv2.VideoCapture(str(BASE/'source.mp4'))
    source_fps=cap.get(cv2.CAP_PROP_FPS);decoded=[]
    while True:
        ok,bgr=cap.read()
        if not ok:break
        rgb=cv2.cvtColor(cv2.resize(bgr,(255,340)),cv2.COLOR_BGR2RGB)
        decoded.append(rgb)
    cap.release()
    count=math.ceil(len(decoded)/source_fps)*12
    # Matched phases at native frames 22 and 142; two continuous forward gait cycles.
    source_ids=[22+round(i*120/(count-1)) for i in range(count)]
    dis=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    first=cv2.cvtColor(decoded[0],cv2.COLOR_RGB2GRAY)
    yy,xx=np.mgrid[:340,:284].astype(np.float32)
    ref_pm=premul(ref)
    fork=(xx>215)&(yy>48)&(yy<146)&(ref[:,:,3]>150)&(ref[:,:,0]>110)
    frames=[]
    for index in source_ids:
        rgb=decoded[index]
        grey=cv2.cvtColor(rgb,cv2.COLOR_RGB2GRAY)
        inverse=dis.calc(grey,first,None)
        flow=np.pad(inverse,((0,0),(14,15),(0,0)),mode='edge')
        rigid=old.rigid_field(flow,fork,xx,yy).astype(np.float32)
        # Restore the whole bone fork with its measured rigid transform, including outside crop.
        fork_ref=ref_pm.copy()
        fork_ref[(xx<214)|(yy<43)|(yy>148)]=0
        restored=cv2.remap(fork_ref,xx+rigid[:,:,0],yy+rigid[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT).clip(0,1)
        rgba=matte(rgb)
        full=np.zeros((340,284,4),np.uint8);full[:,14:269]=rgba
        current=premul(full)
        # Remove generated fork pixels at its tracked reference footprint before replacing it.
        region=((xx+rigid[:,:,0]>214)&(yy+rigid[:,:,1]>43)&(yy+rigid[:,:,1]<148))
        current[region]=0
        current=restored+current*(1-restored[:,:,3:4])
        # Reproject original cloak pixels only outside the video crop, feather inside its boundary.
        warped=cv2.remap(ref_pm,xx+flow[:,:,0],yy+flow[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT).clip(0,1)
        weight=(1-old.smoothstep(13,20,xx))*(yy>105)*(yy<250)
        current=current*(1-weight[...,None])+warped*weight[...,None]
        picture=unpremul(current).resize((227,272),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(256,320));canvas.paste(picture,(14,35))
        frames.append(canvas)
    native_count=len(frames)
    extra=0
    atlas=Image.new('RGBA',(2048,math.ceil(count/8)*320))
    for i,im in enumerate(frames):
        im.save(BASE/'frames'/f'walk_{i:03d}.png')
        atlas.paste(im,((i%8)*256,(i//8)*320))
    atlas.save(RUNTIME/'walk-atlas.png')
    lines=[f'[gd_resource type="SpriteFrames" load_steps={count+2} format=3]','',f'[ext_resource type="Texture2D" path="res://assets/runtime/{ASSET}/walk-atlas.png" id="1"]','']
    for i in range(count):lines += [f'[sub_resource type="AtlasTexture" id="Frame_{i}"]','atlas = ExtResource("1")',f'region = Rect2({i%8*256}, {i//8*320}, 256, 320)','filter_clip = true','']
    lines+=['[resource]','animations = [{','"frames": [']+[f'{{"duration": 1.0, "texture": SubResource("Frame_{i}")}}'+(',' if i<count-1 else '') for i in range(count)]+['],','"loop": true,','"name": &"walk",','"speed": 12.0','}]']
    (RUNTIME/'walk.tres').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    report={'asset':ASSET,'source_task':'vj_0f535bce-6ef0-45b1-a033-9c1925e52589','source_url':'https://xsj-ai-orange.seasungame.com/prod/video/20261029/391ec3c9-a5be-4628-bb40-7b5846e61ad7.mp4','source_sha256':hashlib.sha256((BASE/'source.mp4').read_bytes()).hexdigest(),'source_frames':len(decoded),'source_fps':source_fps,'source_duration':len(decoded)/source_fps,'duration':count/12,'fps':12,'frames':count,'video_sample_frames':native_count,'derived_closure_frames':extra,'source_indices':source_ids,'selected_source_interval_inclusive':[22,142],'selected_source_seconds':5.0,'retimed_to_seconds':7.0,'canvas':[256,320],'pivot':[128,300],'visible_reference_height':261,'unique_pixel_frames':len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames}),'method':'Two phase-matched forward gait cycles (source frames 22..142), uniformly retimed to 7 seconds at 12 FPS; rigid reference fork and cloak edge restoration; no optical-flow seam synthesis','limitations':['Source feet and cape may retain clipping or shape drift','Phase-matched loop retains some drawing discontinuity at seam','At fixed 12 FPS foot speed is not guaranteed to match 265 px/s movement']}
    (RUNTIME/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    for name in ['walk-atlas.png','walk.tres','manifest.json']:shutil.copy2(RUNTIME/name,DEST/name)
    sheet=Image.new('RGB',(6*256,2*345),'#19313b')
    for k,index in enumerate([0,6,12,18,24,30,36,48,60,72,78,83]):
        x,y=k%6*256,k//6*345;sheet.paste(frames[index],(x,y),frames[index]);ImageDraw.Draw(sheet).text((x+5,y+322),str(index),fill='white')
    sheet.save(BASE/'review/contact.png')
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
