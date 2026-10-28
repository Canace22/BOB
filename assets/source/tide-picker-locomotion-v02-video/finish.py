"""Select chronological native frames and make a documented short optical-flow loop bridge.
No reversed locomotion, per-frame bbox alignment, or duplicated still-frame padding.
"""
from pathlib import Path
import json, math, hashlib, shutil, subprocess
import numpy as np
import cv2
from scipy import ndimage as ndi
from PIL import Image, ImageDraw
from matte import matte
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
RUNTIME=REPO/'assets/runtime/sprites/tide-picker-locomotion-v02-video'

def clean(im,state):
    cut,_=matte(im)
    a=np.array(cut)
    if state=='run':
        rgb=a[:,:,:3].astype(float)
        sat=(rgb.max(2)-rgb.min(2))/np.maximum(rgb.max(2),1)
        # Remove neutral baked floor shadow. Preserve enclosed foot interiors.
        yy=np.indices(sat.shape)[0]
        candidate=(yy>465)&(sat<.29)&(rgb.max(2)>65)
        support=(a[:,:,3]>0)&~candidate
        support=ndi.binary_fill_holes(support)
        a[:,:,3]*=support.astype(np.uint8)
    a[a[:,:,3]==0,:3]=0
    cut=Image.fromarray(a)
    # A single transform per sequence; native bob and flight are preserved.
    scale=1.30 if state=='run' else 1.0
    source_ground=550 if state=='run' else 630
    target=Image.new('RGBA',(704,704))
    resized=cut.resize((round(704*scale),round(704*scale)),Image.Resampling.LANCZOS)
    target.paste(resized,(round(352-352*scale),round(630-source_ground*scale)))
    return target.resize((512,512),Image.Resampling.LANCZOS)

def bridge(a,b,count):
    aa=np.array(a).astype(np.float32)/255;bb=np.array(b).astype(np.float32)/255
    aa[:,:,:3]*=aa[:,:,3:4];bb[:,:,:3]*=bb[:,:,3:4]
    ga=cv2.cvtColor((aa[:,:,:3]*255).astype(np.uint8),cv2.COLOR_RGB2GRAY)
    gb=cv2.cvtColor((bb[:,:,:3]*255).astype(np.uint8),cv2.COLOR_RGB2GRAY)
    dis=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    f=dis.calc(ga,gb,None);back=dis.calc(gb,ga,None)
    y,x=np.indices(ga.shape,dtype=np.float32)
    result=[]
    for i in range(count):
        t=(i+1)/(count+1)
        wa=cv2.remap(aa,x-t*f[:,:,0],y-t*f[:,:,1],cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
        wb=cv2.remap(bb,x-(1-t)*back[:,:,0],y-(1-t)*back[:,:,1],cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
        c=wa*(1-t)+wb*t
        c[:,:,:3]/=np.maximum(c[:,:,3:4],.001)
        result.append(Image.fromarray((np.clip(c,0,1)*255).astype(np.uint8)))
    return result

def breathing(im,phase):
    # Controlled post-process on the stable video: rigid helmet translation,
    # chest expansion, feet fixed. This is recorded as deformation, not new AI frames.
    a=np.array(im);y,x=np.indices(a.shape[:2],dtype=np.float32)
    lift=(1-math.cos(phase*2*math.pi))*.5
    weight=np.clip((458-y)/190,0,1)
    chest=np.exp(-((y-287)/65)**2)*np.exp(-((x-260)/100)**2)
    mx=x-(x-260)*.025*lift*chest
    my=y+7*lift*weight
    return Image.fromarray(cv2.remap(a,mx,my,cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT))

def main():
    spec=json.loads((BASE/'selection.json').read_text())
    RUNTIME.mkdir(parents=True,exist_ok=True)
    manifest={'asset_id':RUNTIME.name,'status':'review_candidate','canvas':[512,512],'pivot':[256,458],
      'main_game_replaced':False,'animations':{}}
    for state,s in spec.items():
        src=BASE/'raw'/s['source'];native=[]
        for i in range(s['start'],s['end_exclusive']):
            im=clean(Image.open(src/f'{i:04d}.png'),state)
            if state=='idle':im=breathing(im,(i-s['start'])/(s['end_exclusive']-s['start']))
            native.append(im)
        frames=native+bridge(native[-1],native[0],s['bridge_frames'])
        out=RUNTIME/state;out.mkdir(exist_ok=True)
        records=[]
        for i,im in enumerate(frames):
            name=f'{state}/{i:04d}.png';im.save(RUNTIME/name)
            records.append({'file':name,'kind':'native_video' if i<len(native) else 'optical_flow_loop_bridge',
                'source_index':s['start']+i if i<len(native) else None,
                'postprocess':'localized breathing warp; 7px rigid helmet lift, fixed feet' if state=='idle' and i<len(native) else 'matte + fixed sequence transform'})
        cols=8;rows=math.ceil(len(frames)/cols)
        atlas=Image.new('RGBA',(cols*512,rows*512))
        for i,im in enumerate(frames):atlas.paste(im,(i%cols*512,i//cols*512))
        atlas.save(RUNTIME/f'{state}-atlas.png')
        durations=[round((i+1)*1000/s['fps'])-round(i*1000/s['fps']) for i in range(len(frames))]
        frames[0].save(BASE/'review'/f'{state}-loop.webp',save_all=True,append_images=frames[1:],duration=durations,loop=0,lossless=True)
        sheet=Image.new('RGB',(4*256,3*280),'#10222c');draw=ImageDraw.Draw(sheet)
        for k,i in enumerate(np.linspace(0,len(frames)-1,12,dtype=int)):
            thumb=frames[i].resize((256,256));x=k%4*256;y=k//4*280;sheet.paste(thumb,(x,y),thumb);draw.text((x+6,y+258),f'{state.upper()} {i:03d} / '+records[i]['kind'],fill='white')
        sheet.save(BASE/'review'/f'{state}-loop-contact.jpg',quality=93)
        hashes=[hashlib.sha256(im.tobytes()).hexdigest() for im in frames]
        assert len(set(hashes))==len(frames),'Duplicate frame'
        assert all(im.getpixel((0,0))[3]==0 for im in frames)
        manifest['animations'][state]={**s,'frame_count':len(frames),'native_frames':len(native),'loop':True,'duration_seconds':len(frames)/s['fps'],'atlas':f'{state}-atlas.png','columns':cols,'frames':records,'unique_pixel_hashes':len(set(hashes)),
          'sequence_transform':{'scale':1.30 if state=='run' else 1,'source_ground':550 if state=='run' else 630,'target_ground':630,'canvas_before_export':704}}
        print(state,len(native),'native +',s['bridge_frames'],'bridge',flush=True)
    (RUNTIME/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    # Use one atlas per state in the isolated Godot preview.
    dest=REPO/'godot/WhalebellyRuins/assets/runtime'/RUNTIME.name;dest.mkdir(parents=True,exist_ok=True)
    for state in spec:shutil.copy2(RUNTIME/f'{state}-atlas.png',dest/f'{state}-atlas.png')
    lines=['[gd_resource type="SpriteFrames" load_steps=%d format=3]'%(4+sum(v['frame_count'] for v in manifest['animations'].values())),'']
    for state in spec:lines.append(f'[ext_resource type="Texture2D" path="res://assets/runtime/{RUNTIME.name}/{state}-atlas.png" id="{state}"]')
    animations=[]
    for state,s in manifest['animations'].items():
        refs=[]
        for i in range(s['frame_count']):
            ident=f'{state}_{i:04d}';lines+=['',f'[sub_resource type="AtlasTexture" id="{ident}"]',f'atlas = ExtResource("{state}")',f'region = Rect2({i%8*512}, {i//8*512}, 512, 512)']
            refs.append('{"duration": 1.0, "texture": SubResource("'+ident+'")}')
        animations.append('{"frames": ['+',\n'.join(refs)+f'], "loop": true, "name": &"{state}", "speed": {s["fps"]}.0'+'}')
    lines+=['','[resource]','animations = ['+',\n'.join(animations)+']']
    (dest/'locomotion.tres').write_text('\n'.join(lines)+'\n',encoding='utf8')
    print('PACKED',sum(v['frame_count'] for v in manifest['animations'].values()))
if __name__=='__main__':main()
