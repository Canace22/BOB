"""Six painted keys -> motion guide -> real local Wan2.2 refinement.

The key art, flow-guided timing scaffold and model output remain distinct.
"""
from pathlib import Path
import argparse, json, time, shutil, urllib.request, urllib.error, subprocess
import cv2
import numpy as np
from PIL import Image, ImageDraw
import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'assets/source/baleen-keyart-v2'
COMFY = ROOT/'work/wan22-production/ComfyUI'
API = 'http://127.0.0.1:8188'

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def request(path, data=None):
    req=urllib.request.Request(API+path, None if data is None else json.dumps(data).encode(), {'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=45) as f: return json.load(f)
    except urllib.error.HTTPError as e: raise RuntimeError(e.read().decode())

def movie(folder, path, fps):
    subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-loglevel','error','-framerate',str(fps),'-i',str(folder/'%04d.png'),'-c:v','libx264','-crf','15','-pix_fmt','yuv420p','-movflags','+faststart',str(path)],check=True)

def prepare():
    for name in ['keyposes','guide','guide-alpha','workflows','metadata','raw','frames','review','krita','videos']:
        (OUT/name).mkdir(exist_ok=True)
    sheet=Image.open(OUT/'keyposes-generated.png').convert('RGBA')
    keys=[]
    yy,xx=np.mgrid[:384,:384].astype(np.float32)
    # Shared original root is pinned across the independent key paintings.
    line=184.5-0.345*xx
    root_weight=np.clip((line+24-yy)/15,0,1)[...,None]
    for i in range(6):
        im=sheet.crop((i%3*512,i//3*512,(i%3+1)*512,(i//3+1)*512))
        im.save(OUT/'keyposes'/f'paint-{i:02d}.png')
        a=np.asarray(im.resize((384,384),Image.Resampling.LANCZOS)).astype(np.float32)/255
        a[a[:,:,3]<0.012]=0
        a[:,:,:3]*=a[:,:,3:4]
        if keys:a=keys[0]*root_weight+a*(1-root_weight)
        keys.append(a)
    bg=np.array([0,0.60,0.18],np.float32)
    rgb=[np.uint8(np.clip((a[:,:,:3]+bg*(1-a[:,:,3:4]))*255,0,255)) for a in keys]
    flow=cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    phases=[]
    for k in range(6):
        other=(k+1)%6
        ga=cv2.cvtColor(rgb[k],cv2.COLOR_RGB2GRAY);gb=cv2.cvtColor(rgb[other],cv2.COLOR_RGB2GRAY)
        ab=flow.calc(ga,gb,None);ba=flow.calc(gb,ga,None)
        # Restrict only root motion, not the whole animation with a sine envelope.
        ab*=1-root_weight;ba*=1-root_weight
        np.savez_compressed(OUT/'metadata'/f'key-transition-{k}.npz',forward=ab,backward=ba)
        for j in range(12):
            t=j/12
            a=cv2.remap(keys[k],xx-ab[:,:,0]*t,yy-ab[:,:,1]*t,cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
            b=cv2.remap(keys[other],xx-ba[:,:,0]*(1-t),yy-ba[:,:,1]*(1-t),cv2.INTER_LINEAR,borderMode=cv2.BORDER_CONSTANT)
            p=a*(1-t)+b*t
            p=p*(1-root_weight)+keys[0]*root_weight
            phases.append(p)
    phases.append(keys[0])
    for i,p in enumerate(phases):
        rgba=np.dstack([np.divide(p[:,:,:3],p[:,:,3:4],out=np.zeros_like(p[:,:,:3]),where=p[:,:,3:4]>0.001),p[:,:,3]])
        Image.fromarray(np.uint8(np.clip(rgba*255,0,255))).save(OUT/'guide-alpha'/f'{i:04d}.png')
        Image.fromarray(np.uint8(np.clip((p[:,:,:3]+bg*(1-p[:,:,3:4]))*255,0,255))).save(OUT/'guide'/f'{i:04d}.png')
    movie(OUT/'guide',OUT/'videos/keyart-guide.mp4',24)
    shutil.copy2(OUT/'videos/keyart-guide.mp4',COMFY/'input/baleen_keyart_v2_guide.mp4')
    write(OUT/'metadata/environment.json',request('/system_stats'))
    write(OUT/'progress.json',{'stage':'keyart_guide_ready','key_art_count':6,'guide_frames':73,'guide_fps':24,'output_fps':12,'scope':'independent baleen asset, no main game replacement','pending':['Wan refinement','alpha and root verification','Krita master','motion review']})

def run(repair=False):
    suffix='-repair' if repair else ''
    record=OUT/'metadata'/f'wan{suffix}-job.json'
    dest=OUT/('raw'+suffix);dest.mkdir(exist_ok=True)
    if record.exists():
        state=json.loads(record.read_text())
        if state['status']=='generated': print('Already generated');return
        if state['status']=='failed': raise RuntimeError('Review retained failure before retry')
    else:
        def n(c,**kw):return {'class_type':c,'inputs':kw}
        prompt='A single delicate ivory whale baleen fringe, hand painted 2D game animation, submerged in a gentle underwater current. Preserve the supplied keyframe motion: fixed dark root strip, continuous soft S bends traveling down individual strands, lagging slender tips. Calm slow flowing, organically asynchronous fibers, consistent strand lengths and material. Static camera, static framing. Preserve the flat uniform green chroma key background exactly. No new objects. Smoothly refine the existing animated key poses, maintaining silhouette and root position.'
        graph={
            '1':n('UNETLoader',unet_name='wan2.2_ti2v_5B_fp16.safetensors',weight_dtype='fp8_e4m3fn'),
            '2':n('CLIPLoader',clip_name='umt5_xxl_fp8_e4m3fn_scaled.safetensors',type='wan',device='cpu'),
            '3':n('VAELoader',vae_name='wan2.2_vae.safetensors'),
            '4':n('ModelSamplingSD3',model=['1',0],shift=8.0),
            '5':n('CLIPTextEncode',clip=['2',0],text=prompt),
            '6':n('CLIPTextEncode',clip=['2',0],text='moving camera, moving root, violent waving, rigid swinging, changing colors, green strands, background texture, rock, fish, bubbles, text, glowing background, growing fibers, distorted anatomy, melting, flicker, double image'),
            '7':n('LoadVideo',file='baleen_keyart_v2_guide.mp4'),
            '8':n('GetVideoComponents',video=['7',0]),
            '9':n('VAEEncode',pixels=['8',0],vae=['3',0]),
            '10':n('KSampler',model=['4',0],positive=['5',0],negative=['6',0],latent_image=['9',0],seed=291029711,steps=20,cfg=4.5,sampler_name='uni_pc',scheduler='simple',denoise=0.30),
            '11':n('VAEDecode',samples=['10',0],vae=['3',0]),
            '12':n('SaveImage',images=['11',0],filename_prefix='baleen_keyart_v2/refined')}
        if repair:
            graph['10']['inputs'].update(denoise=0.10,cfg=2.0)
            graph['12']['inputs']['filename_prefix']='baleen_keyart_v2/refined_lowdenoise'
        write(OUT/'workflows'/f'wan22-guided{suffix}-api.json',graph)
        result=request('/prompt',{'prompt':graph,'client_id':'baleen-keyart-v2'})
        state={'status':'running','prompt_id':result['prompt_id'],'started':time.time(),'model':'Wan2.2 TI2V 5B','mode':'video-to-video key-art guide refinement','denoise':graph['10']['inputs']['denoise'],'source_fps':24}
        write(record,state)
    print('JOB',state['prompt_id'],flush=True)
    while True:
        h=request('/history/'+state['prompt_id'])
        if state['prompt_id'] in h:
            h=h[state['prompt_id']];write(OUT/'metadata'/f'wan{suffix}-history.json',h)
            if h.get('status',{}).get('status_str')=='error':
                state['status']='failed';write(record,state);raise RuntimeError(str(h['status']))
            files=h.get('outputs',{}).get('12',{}).get('images',[])
            if not files:raise RuntimeError('No decoded frames')
            for i,f in enumerate(files):shutil.copy2(COMFY/'output'/f.get('subfolder','')/f['filename'],dest/f'{i:04d}.png')
            movie(dest,OUT/'videos'/f'wan22-refined{suffix}-source.mp4',24)
            state.update(status='generated',frames=len(files),elapsed_seconds=round(time.time()-state['started'],2));write(record,state)
            print('DONE',len(files),flush=True);return
        print('RUNNING',round(time.time()-state['started']),flush=True);time.sleep(20)

def repair():run(True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('action',choices=['prepare','run','repair']);a=parser.parse_args()
    globals()[a.action]()
