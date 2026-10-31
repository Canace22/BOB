"""Measure Wan video motion and bake original RGBA paint with pinned roots.
The user specifically requested video-to-2D frames; derived motion is recorded.
"""
from pathlib import Path
import json, math, subprocess, hashlib
import cv2
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];BASE=ROOT/'assets/source/baleen-wan22'
FFMPEG=Path('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/Lib/site-packages/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe')
def write(p,data):p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def smooth(a,b,x):
    t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)
def video(folder,target,fps):
    subprocess.run([str(FFMPEG),'-y','-loglevel','error','-framerate',str(fps),'-i',str(folder/'%04d.png'),'-c:v','libx264','-crf','16','-pix_fmt','yuv420p','-movflags','+faststart',str(target)],check=True)
def main():
    raw=BASE/'raw/CONTEXT-MOTION';files=sorted(raw.glob('*.png'))
    if not files:raise RuntimeError('Wan context job has not completed')
    for name in ['BALEEN-CENTER','CONTEXT-MOTION']:
        video(BASE/'raw'/name,BASE/'videos'/(name+'-source.mp4'),24)
    cap=cv2.VideoCapture(str(BASE/'videos/CONTEXT-MOTION-source.mp4'));fps=cap.get(cv2.CAP_PROP_FPS);decoded=[]
    while True:
        ok,bgr=cap.read()
        if not ok:break
        decoded.append(cv2.cvtColor(bgr,cv2.COLOR_BGR2GRAY))
    cap.release();seconds=len(decoded)/fps;n=math.ceil(seconds)*12
    write(BASE/'metadata/video-probe.json',dict(decoded_frames=len(decoded),fps=fps,duration=seconds,rounded_seconds=math.ceil(seconds),output_frames=n,output_fps=12,method='full source retimed to integer seconds; smooth motion-envelope seam repair, not duplicate padding'))
    dis=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    fields=[]
    for gray in decoded:
        field=dis.calc(gray,decoded[0],None)
        fields.append(cv2.GaussianBlur(field,(0,0),2.0))
    fields=np.array(fields)
    # Resample continuous source rather than assigning a repeated held tail.
    temporal=np.linspace(0,len(fields)-1,n+1)[:-1]
    sampled=[]
    for t in temporal:
        a=int(t);b=min(a+1,len(fields)-1);sampled.append(fields[a]*(1-(t-a))+fields[b]*(t-a))
    sampled=np.array(sampled)
    rootpts=np.array([(0,180),(180,155),(275,104),(440,55),(595,40),(742,18),(900,0),(1040,5),(1160,65),(1280,240)],np.float32)
    jobs=[j for j in json.loads((BASE/'jobs.json').read_text(encoding='utf-8')) if j['id']!='CONTEXT-MOTION']
    manifest=[]
    for index,j in enumerate(jobs):
        name=j['id'];ox,oy,w,h=j['rect'];dest=BASE/'frames'/name;dest.mkdir(parents=True,exist_ok=True)
        source=np.array(Image.open(ROOT/'assets/source/baleen-blender/paint'/f'{name}.png').convert('RGBA')).astype(np.float32)/255
        yy,xx=np.mgrid[:h,:w].astype(np.float32);gx=xx+ox;gy=yy+oy
        if index<3:
            start=np.interp(gx,rootpts[:,0],rootpts[:,1])+24
            weight=smooth(start,np.maximum(start+25,[300,170,290][index]),gy)**1.3
            a,b=j['partition'];weight*=np.maximum(0,np.sin(np.pi*np.clip((gx-a)/(b-a),0,1)))**.45
        else:
            weight=smooth(168,358,gy)**1.5*np.clip(np.minimum.reduce([(gx-880)/28,(1050-gx)/28,(385-gy)/30]),0,1)
        # Exact Comfy input center crop: original x40..1240 ->640, y0..720 ->384.
        mapx=((gx-40)*640/1200).astype(np.float32);mapy=(gy*384/720).astype(np.float32)
        local=[]
        for f in sampled:
            flow=cv2.remap(f,mapx,mapy,cv2.INTER_LINEAR,borderMode=cv2.BORDER_REPLICATE)
            flow[:,:,0]*=1200/640;flow[:,:,1]*=720/384
            local.append(flow)
        local=np.array(local)
        # Remove common camera/attachment drift, independently per group/frame.
        support=(source[:,:,3]>.25)&(weight<.03)
        if support.sum()<20:support=weight<.03
        for flow in local:flow-=np.median(flow[support],axis=0)
        active=(source[:,:,3]>.15)&(weight>.2)
        magnitude=float(np.percentile(np.abs(local[:,:,:,0][:,active]),90)) if active.any() else 0
        gain=min(4.0,[10,7,9,3][index]/max(magnitude,1e-3))
        limit=[11,8,10,3][index]
        local[:,:,:,0]=np.clip(local[:,:,:,0]*gain,-limit,limit)
        local[:,:,:,1]=np.clip(local[:,:,:,1]*gain*.20,-1.4,1.4)
        # One source motion segment -> smooth return-to-rest for environmental loop.
        envelope=np.sin(np.pi*np.arange(n)/n)**2
        local*=weight[None,:,:,None]*envelope[:,None,None,None]
        local=local.astype(np.float32)
        premul=source.copy();premul[:,:,:3]*=source[:,:,3:4]
        rgba=[];hashes=[]
        for i,flow in enumerate(local):
            warped=cv2.remap(premul,xx+flow[:,:,0],yy+flow[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT)
            warped=np.clip(warped,0,1);warped[:,:,:3]/=np.maximum(warped[:,:,3:4],1e-5)
            pixels=np.round(warped.clip(0,1)*255).astype(np.uint8)
            # Preserve truly pinned pixels bit-for-bit, including their alpha.
            pixels[weight==0]=np.round(source[weight==0]*255).astype(np.uint8)
            Image.fromarray(pixels).save(dest/f'{i:04d}.png');rgba.append(pixels);hashes.append(hashlib.sha256(pixels.tobytes()).hexdigest())
        differences=[float(np.abs(rgba[(i+1)%n].astype(np.int16)-rgba[i].astype(np.int16)).mean()) for i in range(n)]
        root_changes=max(int(np.any(p!=rgba[0],axis=2)[weight==0].sum()) for p in rgba)
        np.savez_compressed(BASE/'metadata'/f'{name}-motion.npz',inverse_flow_q256=np.round(local*256).astype(np.int16),weight_q255=np.round(weight*255).astype(np.uint8),source_positions=temporal)
        atlas=Image.new('RGBA',(w*6,h*math.ceil(n/6)))
        for i,p in enumerate(rgba):atlas.paste(Image.fromarray(p),(i%6*w,i//6*h))
        for path in [ROOT/'assets/runtime/baleen-wan22',ROOT/'godot/WhalebellyRuins/assets/baleen_wan22']:
            path.mkdir(parents=True,exist_ok=True);atlas.save(path/f'{name}.png')
        video(dest,BASE/'videos'/f'{name}-12fps.mp4',12)
        # Preview on neutral gray, inspect transparent edge and motion at actual scale.
        sheet=Image.new('RGB',(w*3,h*2),(45,52,62))
        for k,i in enumerate([0,6,12,18,24,30]):
            im=Image.fromarray(rgba[i]);sheet.paste(im,(k%3*w,k//3*h),im)
        sheet.save(BASE/'review'/f'{name}-contact.png')
        manifest.append(dict(id=name,rect=j['rect'],z=j['z'],width=w,height=h,frames=n,fps=12,duration=n/12,columns=6,rows=math.ceil(n/6),unique_frames=len(set(hashes)),root_changed_pixels=root_changes,max_displacement=float(np.linalg.norm(local,axis=3).max()),source_flow_p90=magnitude,gain=gain,seam_difference=differences[-1],max_adjacent_difference=max(differences[:-1]),frame_hashes=hashes,source_video='videos/CONTEXT-MOTION-source.mp4',method='Wan video optical-flow reprojected onto approved original RGBA; root pinning and smooth return envelope'))
    write(BASE/'manifest.json',manifest)
    write(BASE/'metadata/krita-request.json',manifest)
    print(json.dumps([{k:j[k] for k in ['id','frames','unique_frames','root_changed_pixels','max_displacement','source_flow_p90']} for j in manifest],indent=2))
if __name__=='__main__':main()
