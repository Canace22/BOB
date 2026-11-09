"""Extract the user's Run v2 video at fixed scale; no generated inbetween poses."""
from pathlib import Path
import json, math, hashlib, shutil
import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[2]
ASSET = 'tide-picker-run-v03'
RUNTIME = REPO/'assets/runtime/sprites'/ASSET
DEST = REPO/'godot/WhalebellyRuins/assets/runtime'/ASSET

def matte(rgb):
    a=rgb.astype(np.float32)
    # Neutral beige backdrop and shadow, excluding the brighter ivory equipment.
    neutral=(a.max(2)-a.min(2)<42)&(a.mean(2)>62)&(a.mean(2)<185)&(a[:,:,0]>=a[:,:,1])&(a[:,:,1]>=a[:,:,2])
    labels,n=ndi.label(neutral)
    border=np.unique(np.r_[labels[0],labels[-1],labels[:,0],labels[:,-1]])
    bg=np.isin(labels,border[border>0])
    for lab in range(1,n+1):
        yy,xx=np.where(labels==lab)
        if len(xx)>12 and yy.mean()>110:bg|=labels==lab
    labels,n=ndi.label(~bg);counts=np.bincount(labels.ravel());counts[0]=0
    mask=labels==counts.argmax()
    inner=ndi.binary_erosion(mask)
    nearest=ndi.distance_transform_edt(~inner,return_distances=False,return_indices=True)
    fg=a[nearest[0],nearest[1]]
    background=np.median(a[bg & (np.indices(bg.shape)[0]<280)],axis=0)
    v=fg-background;alpha=mask.astype(np.float32);edge=mask&~inner
    coverage=((a-background)*v).sum(2)/np.maximum((v*v).sum(2),1)
    alpha[edge]=coverage[edge].clip(0,1)
    a[edge]=(background+(a-background)/np.maximum(alpha[...,None],.1))[edge].clip(0,255)
    a[alpha==0]=0
    return Image.fromarray(np.dstack([a,alpha*255]).astype(np.uint8))

def main():
    for p in [RUNTIME,DEST,BASE/'frames',BASE/'review']:p.mkdir(parents=True,exist_ok=True)
    cap=cv2.VideoCapture(str(BASE/'source.mp4'));fps=cap.get(cv2.CAP_PROP_FPS);decoded=[]
    while True:
        ok,bgr=cap.read()
        if not ok:break
        decoded.append(cv2.cvtColor(cv2.resize(bgr,(255,340)),cv2.COLOR_BGR2RGB))
    cap.release();count=math.ceil(len(decoded)/fps)*12
    indices=[min(len(decoded)-1,round(i*(len(decoded)-1)/(count-1))) for i in range(count)]
    frames=[]
    for k,idx in enumerate(indices):
        picture=matte(decoded[idx]).resize((242,323),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(256,336));canvas.paste(picture,(7,6));frames.append(canvas)
        canvas.save(BASE/'frames'/f'run_{k:03d}.png')
    atlas=Image.new('RGBA',(2048,math.ceil(count/8)*336))
    for i,im in enumerate(frames):atlas.paste(im,(i%8*256,i//8*336))
    atlas.save(RUNTIME/'run-atlas.png')
    lines=[f'[gd_resource type="SpriteFrames" load_steps={count+2} format=3]','',f'[ext_resource type="Texture2D" path="res://assets/runtime/{ASSET}/run-atlas.png" id="1"]','']
    for i in range(count):lines += [f'[sub_resource type="AtlasTexture" id="Frame_{i}"]','atlas = ExtResource("1")',f'region = Rect2({i%8*256}, {i//8*336}, 256, 336)','filter_clip = true','']
    lines+=['[resource]','animations = [{','"frames": [']+[f'{{"duration": 1.0, "texture": SubResource("Frame_{i}")}}'+(',' if i<count-1 else '') for i in range(count)]+['],','"loop": true,','"name": &"run",','"speed": 12.0','}]']
    (RUNTIME/'run.tres').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    report={'asset':ASSET,'source_task':'vj_42f4e2c7-74f6-4c66-b240-bbafcfa89564','source_url':'https://xsj-ai-orange.seasungame.com/prod/video/20261029/663347e4-4907-463a-ad6b-5d9a3601cfe4.mp4','source_sha256':hashlib.sha256((BASE/'source.mp4').read_bytes()).hexdigest(),'source_frames':len(decoded),'source_fps':fps,'source_duration':len(decoded)/fps,'duration':count/12,'fps':12,'frames':count,'source_indices':indices,'canvas':[256,336],'pivot':[128,300],'visible_reference_height':266,'source_ground_y':309,'unique_pixel_frames':len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames}),'method':'Entire source interval 0..144 uniformly retimed to 7 seconds; deterministic matte and global scale; no pose interpolation, hold tail, reversal or reference repaint','limitations':['Source cape/feet/fork clipping retained; transparent padding cannot restore missing pixels','Fork grip, limb anatomy and loop seam retain source drift','Fixed 12 FPS may cause sliding at 265 px/s; original source motion slowed by about 14 percent']}
    (RUNTIME/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    for name in ['run-atlas.png','run.tres','manifest.json']:shutil.copy2(RUNTIME/name,DEST/name)
    sheet=Image.new('RGB',(6*256,2*360),'#19313b')
    for k,idx in enumerate([0,7,14,21,28,35,42,49,56,63,70,83]):
        x,y=k%6*256,k//6*360;sheet.paste(frames[idx],(x,y),frames[idx]);ImageDraw.Draw(sheet).text((x+5,y+338),str(idx),fill='white')
    sheet.save(BASE/'review/contact.png');print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
