"""Local Wan2.2 jobs. Persist IDs before polling, never duplicate an in-flight job."""
from pathlib import Path
import argparse, json, shutil, time, urllib.request, urllib.error
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/source/baleen-wan22'
COMFY=ROOT/'work/wan22-production/ComfyUI'
API='http://127.0.0.1:8188'
def write(p,v):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def request(p,data=None):
    r=urllib.request.Request(API+p,None if data is None else json.dumps(data).encode(),{'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r,timeout=40) as f:return json.load(f)
    except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode())
def prepare():
    from PIL import Image
    for d in ['reference','inputs','raw','videos','workflows','metadata','frames','krita','review']:(OUT/d).mkdir(parents=True,exist_ok=True)
    shutil.copy2('C:/Users/Kingsoft/AppData/Local/Temp/codex-clipboard-892b5787-e680-497e-b6ed-a70b11d1e34a.png',OUT/'reference/marked-regions.png')
    jobs=json.loads((ROOT/'assets/source/baleen-blender/jobs.json').read_text(encoding='utf-8'))
    for i,j in enumerate(jobs):
        im=Image.open(ROOT/'assets/source/baleen-blender/paint'/f'{j["id"]}.png').convert('RGBA')
        # Letterboxed source preserves silhouette and a generous motion margin.
        scale=min(320/im.width,272/im.height)
        size=(round(im.width*scale),round(im.height*scale)); offset=((384-size[0])//2,(320-size[1])//2)
        plate=Image.new('RGB',(384,320),(8,12,18));small=im.resize(size,Image.Resampling.LANCZOS)
        plate.paste(small,offset,small);plate.save(OUT/'inputs'/f'{j["id"]}.png')
        j.update(width=384,height=320,length=49,source_fps=24,target_fps=12,steps=20,cfg=5.0,seed=291029101+i,fit={'scale':scale,'size':size,'offset':offset})
        if 'DISTANT' in j['id']:
            j['prompt']='Locked off camera. An underwater blue curtain of fine hanging filaments, matching this painted reference. A very gentle slow underwater current moves the thin hanging strands slightly sideways, soft wave traveling from the stationary top to the tips. The large blue silhouette, rock, framing, exposure and colors remain still and unchanged. Delicate subtle movement, hand painted 2D environment animation, calm mysterious deep sea.'
        else:
            j['prompt']='Locked off camera. This isolated ivory whale baleen fringe hangs down from a fixed upper root. Fine individual hanging strands sway gently sideways in a slow underwater current, their tips trailing and settling. Soft flowing ripple travels downward. Root and dark attachment remain completely stationary. Tiny natural phase differences between strands. Keep the exact ivory blue painted texture, silhouette and number of strands. Black background stays empty and still, no new objects. Hand painted 2D game environmental animation, graceful restrained subtle motion.'
        j['negative']='camera motion, pan, zoom, rotation, fast motion, storm, violent flapping, melting, morphing, changing shape, growing, disappearing strands, new objects, fish, bubbles, text, logo, flashes, flicker, moving roots, moving rocks, floating entire object'
    write(OUT/'jobs.json',jobs)
    write(OUT/'metadata/environment.json',request('/system_stats'))
    write(OUT/'progress.json',{'stage':'pilot_generation','scope':'four marked baleen groups','pipeline':['ComfyUI 0.42.0','Wan2.2 TI2V 5B fp16 weights, fp8_e4m3fn loading','Krita 5.3.4.1','Godot 4.7.2'],'frame_rule':'ceil(decoded_video_duration)*12; full source retimed across integer duration, no freeze-padding','pending':['generate and review','RGBA frames','Krita native master','engine QA']})
def workflow(j):
    def n(c,**kw):return dict(class_type=c,inputs=kw)
    filename='baleen_'+j['id']+'.png'
    shutil.copy2(OUT/'inputs'/f'{j["id"]}.png',COMFY/'input'/filename)
    return {'1':n('UNETLoader',unet_name='wan2.2_ti2v_5B_fp16.safetensors',weight_dtype='fp8_e4m3fn'),
      '2':n('CLIPLoader',clip_name='umt5_xxl_fp8_e4m3fn_scaled.safetensors',type='wan',device='cpu'),
      '3':n('VAELoader',vae_name='wan2.2_vae.safetensors'),
      '4':n('ModelSamplingSD3',model=['1',0],shift=8.0),
      '5':n('CLIPTextEncode',clip=['2',0],text=j['prompt']),
      '6':n('CLIPTextEncode',clip=['2',0],text=j['negative']),
      '7':n('LoadImage',image=filename),
      '8':n('Wan22ImageToVideoLatent',vae=['3',0],width=j['width'],height=j['height'],length=j['length'],batch_size=1,start_image=['7',0]),
      '9':n('KSampler',model=['4',0],positive=['5',0],negative=['6',0],latent_image=['8',0],seed=j['seed'],steps=j['steps'],cfg=j['cfg'],sampler_name='uni_pc',scheduler='simple',denoise=1.0),
      '10':n('VAEDecode',samples=['9',0],vae=['3',0]),
      '11':n('SaveImage',images=['10',0],filename_prefix='baleen/'+j['id'])}
def run(name):
    j=next(x for x in json.loads((OUT/'jobs.json').read_text(encoding='utf-8')) if x['id']==name)
    record=OUT/'metadata'/f'{name}-job.json'
    if record.exists():
        state=json.loads(record.read_text(encoding='utf-8'))
        if state['status']=='generated_needs_review':print('Already rendered',name);return
        if state['status']=='failed':raise RuntimeError('Inspect retained failed job; no automatic retry')
    else:
        graph=workflow(j);write(OUT/'workflows'/f'{name}-api.json',graph)
        result=request('/prompt',{'prompt':graph,'client_id':'baleen-wan22-local'})
        state=dict(id=name,prompt_id=result['prompt_id'],status='running',started=time.time(),model='wan2.2_ti2v_5B_fp16.safetensors',loading='fp8_e4m3fn',settings=j)
        write(record,state)
    pid=state['prompt_id'];print('JOB',name,pid,flush=True)
    while True:
        h=request('/history/'+pid)
        if pid in h:
            h=h[pid];write(OUT/'metadata'/f'{name}-history.json',h)
            if h.get('status',{}).get('status_str')=='error':
                state['status']='failed';write(record,state);raise RuntimeError(str(h['status']))
            files=h.get('outputs',{}).get('11',{}).get('images',[])
            if not files:raise RuntimeError('No decoded frames in history')
            dest=OUT/'raw'/name;dest.mkdir(parents=True,exist_ok=True)
            for i,f in enumerate(files):shutil.copy2(COMFY/'output'/f.get('subfolder','')/f['filename'],dest/f'{i:04d}.png')
            state.update(status='generated_needs_review',elapsed_seconds=round(time.time()-state['started'],2),frames=len(files))
            write(record,state);print('DONE',name,len(files),state['elapsed_seconds'],flush=True);return
        print('RUNNING',name,round(time.time()-state['started']),flush=True);time.sleep(20)
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('action',choices=['prepare','run']);a.add_argument('--ids',nargs='+',default=['BALEEN-CENTER']);args=a.parse_args()
    if args.action=='prepare':prepare()
    else:
        for name in args.ids:run(name)
