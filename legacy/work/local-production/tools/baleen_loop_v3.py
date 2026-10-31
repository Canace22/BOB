"""Registered painted poses, delayed-tip periodic guide, real Wan refinement.

Existing painted pixels are deformed, not newly hand-drawn. Wan material detail
is fitted in material coordinates to a periodic basis; authored alpha is retained.
"""
from pathlib import Path
import json, math, shutil, sys, zipfile, xml.etree.ElementTree as ET
import numpy as np
import cv2
from PIL import Image, ImageDraw
import baleen_keyart_v2 as wan

ROOT=wan.ROOT
OUT=ROOT/'assets/source/baleen-loop-v3'
SIZE=384
YY,XX=np.mgrid[:SIZE,:SIZE].astype(np.float32)

def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def save(path,a):
    Image.fromarray(np.uint8(np.clip(a,0,1)*255+.5)).save(path)

def setup():
    for d in ['original','keyposes','guide','guide-alpha','workflows','metadata','raw-repair','frames','review','krita','videos','dark','light']:
        (OUT/d).mkdir(parents=True,exist_ok=True)

def base():
    im=Image.open(ROOT/'assets/source/baleen-keyart-v2/keyposes/paint-00.png').convert('RGBA').resize((336,336),Image.Resampling.LANCZOS)
    a=np.zeros((384,384,4),np.float32);a[24:360,24:360]=np.asarray(im)/255
    a[a[:,:,3]<.012]=0
    return a

def root(x):return 24+(184.5-.345*(x-24)/.875)*.875+13

def lengths():
    # A smooth guide avoids folds where the painted silhouette has deep notches.
    # Do not normalize displacement independently to each alpha column's bottom.
    return (160+.12*(np.arange(SIZE)-50)).astype(np.float32)

LENGTHS=lengths()

def movement(x,y,theta):
    length=np.interp(x,np.arange(SIZE),LENGTHS)
    v=np.clip((y-root(x))/length,0,1.15)
    phase=theta+.30*np.sin((x-50)/63)
    # Tip is a delayed response to the lower-section bend, not a rigid rotation.
    dx=v*v*(6*np.sin(phase-.85*v)+14*v*np.sin(phase-1.8*v))
    dx+=1.5*v**3*np.sin(2*phase-2*v+x/140)
    dy=-1.8*v*v*(.5+.5*np.cos(2*phase-1.4*v))
    return dx.astype(np.float32),dy.astype(np.float32)

def inverse(theta):
    sx=XX.copy();sy=YY.copy()
    for _ in range(10):
        dx,dy=movement(sx,sy,theta);sx=XX-dx;sy=YY-dy
    return sx,sy

def warp(a,theta):
    prem=a.copy();prem[:,:,:3]*=prem[:,:,3:4]
    sx,sy=inverse(theta)
    p=cv2.remap(prem,sx,sy,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
    p[:,:,:3]=np.divide(p[:,:,:3],p[:,:,3:4],out=np.zeros_like(p[:,:,:3]),where=p[:,:,3:4]>.001)
    return p

def ora(files,path):
    doc=ET.Element('image',{'w':'384','h':'384','name':'BaleenLoopKeys','version':'0.0.3'});stack=ET.SubElement(doc,'stack')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,f in enumerate(files):
            dest=f'data/pose{i:02d}.png';z.write(f,dest)
            ET.SubElement(stack,'layer',{'name':f'Pose {i:02d} - phase {i*45} degrees','src':dest,'opacity':'1.0','visibility':'visible' if i==0 else 'hidden','composite-op':'svg:src-over','x':'0','y':'0'})
        z.writestr('stack.xml',ET.tostring(doc,encoding='utf-8'));z.write(files[0],'mergedimage.png')

def prepare():
    setup();a=base();save(OUT/'original/registered-paint.png',a)
    shutil.copy2(ROOT/'assets/source/baleen-keyart-v2/keyposes/paint-00.png',OUT/'original/paint-source.png')
    write(OUT/'metadata/instructions.json',{
        'scope':'Standalone 2D baleen loop; no game or gameplay changes',
        'steps':[
          'Register existing ivory painted baleen on 384 square with 24 pixel padding; design eight delayed-tip poses.',
          'Bake 73 guide frames at 24 FPS. Pin root, increase bend amplitude downstream and delay tips.',
          'Run ComfyUI Wan2.2 TI2V 5B low-denoise video refinement; preserve job ID and raw frames.',
          'Inverse-warp model color into material coordinates; fit 2 temporal harmonics; retain painted alpha and 78 percent original color.',
          'Bake 48 unique frames at 12 FPS, four-second periodic loop; create Krita native master and export all frames for comparison.',
          'Check root, tip displacement, closure velocity, transparent padding, light/dark previews, real Krita roundtrip.'
        ],
        'retry':'Retain failed results; repair only defective stage. Never resubmit existing running job.',
        'reference_video':'../baleen-chaos/seedance2-source.mp4',
        'art_lineage':'../baleen-keyart-v2/keyposes/paint-00.png; derived pose drawings, not fresh hand-painted cells',
        'output_frames':48,'output_fps':12,'guide_frames':73,'guide_fps':24})
    for i in range(8):save(OUT/'keyposes'/f'pose-{i:02d}.png',warp(a,2*np.pi*i/8))
    ora(sorted((OUT/'keyposes').glob('*.png')),OUT/'keyposes-layered.ora')
    sheet=Image.new('RGB',(1536,816),(13,30,40));draw=ImageDraw.Draw(sheet)
    for i,f in enumerate(sorted((OUT/'keyposes').glob('*.png'))):
        im=Image.open(f);x=i%4*384;y=i//4*408;sheet.paste(im,(x,y),im);draw.text((x+15,y+384),f'{i+1:02d}   phase {i*45:03d}   t={i*.5:.1f}s',fill='white')
    sheet.save(OUT/'review/eight-keyposes.jpg',quality=94)
    green=np.array([0,.60,.18],np.float32)
    for i in range(73):
        p=warp(a,2*np.pi*i/72);save(OUT/'guide-alpha'/f'{i:04d}.png',p)
        save(OUT/'guide'/f'{i:04d}.png',p[:,:,:3]*p[:,:,3:4]+green*(1-p[:,:,3:4]))
    wan.movie(OUT/'guide',OUT/'videos/keyart-guide.mp4',24)
    shutil.copy2(OUT/'videos/keyart-guide.mp4',wan.COMFY/'input/baleen_loop_v3_guide.mp4')
    write(OUT/'metadata/environment.json',wan.request('/system_stats'))
    write(OUT/'progress.json',{'stage':'eight_pose_guide_ready','next':'inspect keyposes and submit real Wan refinement'})
    print('PREPARED',flush=True)

def run():
    record=OUT/'metadata/wan-repair-job.json'
    if not record.exists():
        graph=json.loads((ROOT/'assets/source/baleen-keyart-v2/workflows/wan22-guided-repair-api.json').read_text(encoding='utf-8'))
        graph['7']['inputs']['file']='baleen_loop_v3_guide.mp4'
        graph['10']['inputs'].update(denoise=.10,cfg=2.0,seed=291029812)
        graph['12']['inputs']['filename_prefix']='baleen_loop_v3/delayed_tip'
        graph['5']['inputs']['text']='Single hand-painted ivory whale baleen fringe underwater. Preserve provided animation exactly. Dark diagonal root perfectly fixed. Flexible slender fibers: middle bends first, lower section follows, delicate tips lag and sweep wider, smooth S-shaped waves downstream. Gentle buoyant underwater drag, not rubber sheet, no rigid rotation. Keep original silhouette, fiber lengths, colors and uniform flat green background. Fixed camera. Only subtle painted shading refinement.'
        write(OUT/'workflows/wan22-guided-repair-api.json',graph)
        result=wan.request('/prompt',{'prompt':graph,'client_id':'baleen-loop-v3'})
        import time
        write(record,{'status':'running','prompt_id':result['prompt_id'],'started':time.time(),'model':'Wan2.2 TI2V 5B','mode':'periodic key-pose guide low-denoise refinement','denoise':.10,'source_fps':24})
    wan.OUT=OUT;wan.run(True)

def finish():
    a=base();files=sorted((OUT/'raw-repair').glob('*.png'))
    if len(files)!=73:raise RuntimeError(f'Expected 73 real model frames, got {len(files)}')
    green=np.array([0,.60,.18],np.float32)
    phases=np.arange(73)*2*np.pi/72
    basis=np.array([np.ones(73),np.sin(phases),np.cos(phases),np.sin(2*phases),np.cos(2*phases)]).T
    residual=[]
    for i,f in enumerate(files):
        raw=np.asarray(Image.open(f).convert('RGB'),np.float32)/255
        dx,dy=movement(XX,YY,phases[i])
        material=cv2.remap(raw,XX+dx,YY+dy,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
        clean=(material-green*(1-a[:,:,3:4]))/np.maximum(a[:,:,3:4],.10)
        clean=np.clip(clean,0,1);clean[:,:,1]=np.minimum(clean[:,:,1],np.maximum(clean[:,:,0],clean[:,:,2])+.025)
        delta=np.clip(clean-a[:,:,:3],-.2,.2)*np.clip((a[:,:,3:4]-.25)/.5,0,1)
        residual.append(cv2.GaussianBlur(delta,(5,5),.8))
    weights=np.ones(73);weights[[0,-1]]=.5
    coeff=(np.linalg.pinv(basis*weights[:,None])@(np.stack(residual).reshape(73,-1)*weights[:,None])).reshape(5,384,384,3).astype(np.float32)
    np.savez_compressed(OUT/'metadata/periodic-material.npz',coefficients=coeff)
    v=np.clip((YY-root(XX))/LENGTHS[None,:],0,1.15)
    paint_weight=np.clip((v-.10)/.25,0,1)[...,None]*.22
    frames=[];dark=[];light=[]
    for i in range(48):
        t=2*np.pi*i/48;b=np.array([1,np.sin(t),np.cos(t),np.sin(2*t),np.cos(2*t)],np.float32)
        painted=a.copy();painted[:,:,:3]=np.clip(a[:,:,:3]+paint_weight*np.tensordot(b,coeff,axes=1),0,1)
        p=warp(painted,t);save(OUT/'frames'/f'{i:04d}.png',p);frames.append(Image.open(OUT/'frames'/f'{i:04d}.png').convert('RGBA'))
        for target,color,arr in [('dark',(12,29,40),dark),('light',(220,225,221),light)]:
            bg=Image.new('RGBA',(384,384),color+(255,));bg.alpha_composite(frames[-1]);bg=bg.convert('RGB');bg.save(OUT/target/f'{i:04d}.png');arr.append(bg)
    atlas=Image.new('RGBA',(3072,2304))
    for i,im in enumerate(frames):atlas.paste(im,(i%8*384,i//8*384))
    atlas.save(OUT/'baleen-sway-atlas.png')
    for d in ['dark','light']:wan.movie(OUT/d,OUT/'videos'/f'baleen-loop-{d}-12fps.mp4',12)
    # GIF timing is quantized to 10ms; MP4/PNG timeline is the exact 12FPS master.
    dark[0].save(OUT/'review/baleen-loop.gif',save_all=True,append_images=dark[1:],duration=[80,80,90]*16,loop=0,disposal=2)
    import subprocess,imageio_ffmpeg
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-loglevel','error','-stream_loop','2','-i',str(OUT/'videos/baleen-loop-dark-12fps.mp4'),'-c','copy',str(OUT/'videos/three-cycles.mp4')],check=True)
    source=OUT/'videos/wan22-refined-repair-source.mp4';cap=cv2.VideoCapture(str(source));n=int(cap.get(cv2.CAP_PROP_FRAME_COUNT));fps=cap.get(cv2.CAP_PROP_FPS);cap.release()
    assert math.ceil(n/fps)*12==len(frames)
    write(OUT/'manifest.json',{'asset_id':'BALEEN-LOOP-V3','frame_size':[384,384],'frame_count':48,'fps':12,'seconds':4,'loop':True,'anchor':[192,127],'atlas':'baleen-sway-atlas.png','columns':8,'rows':6,'source_video':str(source.relative_to(OUT)).replace('\\','/'),'source_frames':n,'source_fps':fps,'source_seconds':n/fps,'rounding':'ceil(actual source frames / fps) * 12 = 48; one designed cycle retimed to four seconds','keyposes':8,'method':'Existing painted base deformed into eight registered designs and 73 guidance frames. Actual Wan low-denoise refinement. Two-harmonic material-coordinate residual fit at 22 percent blend. Painted alpha and periodic deformation retained. Not direct video extraction or hand-drawn inbetweens.','loop_sampling':'phase=2*pi*frame/48; no repeated endpoint','limits':['One independent cluster asset, not four scene placements','Not integrated in Godot this turn','Naturalness is a visual judgment; numerical tests do not replace user review']})
    write(OUT/'progress.json',{'stage':'loop_rendered','next':'measure loop and actual Krita export roundtrip','model_prompt_id':json.loads((OUT/'metadata/wan-repair-job.json').read_text())['prompt_id']})
    print('FINAL_FRAMES_READY',flush=True)

def validate():
    frames=[np.asarray(Image.open(p).convert('RGBA'),np.int16) for p in sorted((OUT/'frames').glob('*.png'))]
    a=base();rootmask=(YY<root(XX)-4)&(a[:,:,3]>.3)
    root_error=max(int(np.abs(f-frames[0])[rootmask].max()) for f in frames)
    bounds=[];edge=0
    for f in frames:
        y,x=np.where(f[:,:,3]>3);bounds.append([int(x.min()),int(y.min()),int(x.max()),int(y.max())])
        edge=max(edge,int(max(f[0,:,3].max(),f[-1,:,3].max(),f[:,0,3].max(),f[:,-1,3].max())))
    differences=[float(np.abs(frames[(i+1)%48]-frames[i]).mean()) for i in range(48)]
    ts=np.linspace(0,2*np.pi,480,endpoint=False);tracks=[]
    for x in [80,130,180,230,280,330]:
        result={'x':x}
        for label,v in [('middle',.5),('lower',.75),('tip',1.0)]:
            y=root(x)+LENGTHS[x]*v
            dx=np.array([movement(np.float32(x),np.float32(y),t)[0] for t in ts])
            phase=np.angle(np.sum(dx*np.exp(-1j*ts)))
            result[label]={'swing_peak_to_peak_px':float(np.ptp(dx)),'fundamental_phase':float(phase)}
        lag=(result['lower']['fundamental_phase']-result['tip']['fundamental_phase'])%(2*np.pi)
        result['tip_lag_after_lower_seconds']=float(lag/(2*np.pi)*4)
        tracks.append(result)
    closure=max(float(np.abs(movement(XX,YY,0)[i]-movement(XX,YY,2*np.pi)[i]).max()) for i in [0,1])
    eps=.001
    def velocity(t):return tuple((b-a)/(2*eps) for a,b in zip(movement(XX,YY,t-eps),movement(XX,YY,t+eps)))
    velocity_error=max(float(np.abs(a-b).max()) for a,b in zip(velocity(0),velocity(2*np.pi)))
    min_det=10.;inverse_error=0.
    for t in np.arange(48)*2*np.pi/48:
        dx,dy=movement(XX,YY,t);dxy,dxx=np.gradient(dx);dyy,dyx=np.gradient(dy)
        min_det=min(min_det,float(((1+dxx)*(1+dyy)-dxy*dyx)[a[:,:,3]>.1].min()))
        sx,sy=inverse(t);ddx,ddy=movement(sx,sy,t)
        inverse_error=max(inverse_error,float(np.hypot(sx+ddx-XX,sy+ddy-YY).max()))
    # Compare the step across wrap with ordinary steps, not equality of frame47 and frame0.
    report={'frame_count':len(frames),'root_max_channel_error':root_error,'edge_alpha_max':edge,'frame_bounds':bounds,'tracked_guide_points':tracks,'periodic_closure_px':closure,'periodic_velocity_closure_px_per_radian':velocity_error,'minimum_deformation_jacobian':min_det,'inverse_map_max_error_px':inverse_error,'adjacent_rgba_mean_absolute':differences,'wrap_to_median_step_ratio':differences[-1]/float(np.median(differences[:-1])),'duplicate_adjacent_frames':sum(d==0 for d in differences),'meaning':'Geometry checks measure authored deformation; pixel checks measure final baked frames. Perceived naturalness and game placement remain separate.'}
    write(OUT/'review/loop-validation.json',report)
    assert root_error==0 and edge==0 and closure<.001 and velocity_error<.05 and min_det>.2 and inverse_error<.05
    assert len(frames)==48 and all(d>0 for d in differences) and report['wrap_to_median_step_ratio']<1.5
    write(OUT/'review/technical-pass.json',{'passed':True,'tests':['root unchanged','48 distinct RGBA frames','transparent safety border','periodic pose and velocity','no folded deformation','normal wrap pixel step']})
    print(json.dumps({k:v for k,v in report.items() if k not in ['frame_bounds','adjacent_rgba_mean_absolute','tracked_guide_points']},indent=2),flush=True)

def krita():
    import baleen_kra_native as k
    k.OUT=OUT;k.prepare();k.assemble();k.verify()
    files=sorted((OUT/'review/krita-roundtrip').glob('*.png'));errors=[]
    for i,file in enumerate(files):
        a=np.asarray(Image.open(file).convert('RGBA'),np.int16);b=np.asarray(Image.open(OUT/'frames'/f'{i:04d}.png').convert('RGBA'),np.int16)
        errors.append(int(np.abs(a-b).max()))
    write(OUT/'review/krita-validation.json',{'actual_krita_export':True,'exported_frames':len(files),'max_channel_errors':errors,'all_pixel_identical':len(files)==48 and max(errors)==0})
    write(OUT/'metadata/krita-results.json',{'status':'actual_krita_export_verified','key_art_layers':8,'animation_keyframes':48,'fps':12,'all_pixel_identical':max(errors)==0})
    assert len(files)==48 and max(errors)==0
    print('KRITA_PIXEL_IDENTICAL_48',flush=True)

if __name__=='__main__':globals()[sys.argv[1]]()
