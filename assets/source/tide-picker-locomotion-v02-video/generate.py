"""Resumable local ComfyUI video generation; one submission per named revision."""
import argparse,json,shutil,time,urllib.request,urllib.error
from pathlib import Path
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
COMFY=REPO/'work/wan22-production/ComfyUI'
API='http://127.0.0.1:8188'
PROMPTS={
 'walk': 'A beautifully animated hand-painted amphibian explorer walks continuously in place toward the right. A clear relaxed two-step walking cycle: the left leg swings forward and plants its webbed foot, then pushes back while the right leg swings past and plants forward. The two legs alternate naturally, with bent knees during passing and straight legs during contact. At least one foot is always on the ground. The pelvis gently rises and falls, the chest counter-rotates and the free arm swings. His short teal cape sways with a soft delayed wave, and the attached hip lantern swings gently. The character stays centered and the camera stays completely fixed. Preserve the illustrated design, the rigid round ivory helmet with one black round lens, the held bone tuning fork and the red rope. Full body visible with padding. Plain flat warm gray background. Smooth lively traditional 2D animation, not a still image.',
 'idle': 'A small hand-painted amphibian explorer stands alert and breathes in a continuous idle cycle. His two webbed feet stay planted. He softly shifts his weight from one foot to the other without stepping, bends his knees slightly and straightens, his chest expands with a deep breath then relaxes. His head gently follows the breathing with a small attentive nod. The teal cape ripples softly from shoulder to hem with a delayed swaying motion. The amber hip lantern swings like a tiny pendulum and settles. He keeps the U-shaped bone tuning fork firmly in the same hand. Preserve the rigid ivory helmet and its single black glass lens, which never blinks. Keep the same character proportions and equipment. Smooth expressive hand-painted 2D animation. Fixed camera, full body in frame, flat warm gray background.',
 'run': 'The hand-painted amphibian explorer runs energetically in place toward the right, alternating both legs in a continuous full running cycle. Strong forward lean, knees drive forward high, the other foot pushes backward and kicks up behind. Left leg and right leg take turns leading. Clear short airborne flight phases between footfalls. The body compresses on landing and springs upward on push-off; the rigid round helmet follows a smooth bouncing arc. The short teal cape streams behind and snaps in overlapping waves. The attached amber hip lantern swings with a delayed rhythm, red rope follows the hand. He keeps gripping the bone U-shaped tuning fork in the same hand throughout. Same original illustrated character, fixed camera, centered full body, generous margins, flat warm gray background. Lively continuous traditional 2D animation.'
}
NEGATIVE='still image, frozen legs, sliding feet, hopping on one leg, backwards walking, turning around, camera movement, zoom, pan, perspective change, cropped head, cropped feet, extra arms, extra legs, detached limbs, growing limbs, melting helmet, blinking eye, mouth, face, new weapon, disappearing equipment, changing costume, shadows on background, scenery, text, watermark'
def req(route,data=None):
    body=None if data is None else json.dumps(data).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(API+route,body,{'Content-Type':'application/json'}),timeout=60) as f:return json.load(f)
    except urllib.error.HTTPError as e:raise RuntimeError(e.read().decode())
def graph(state,revision,seed):
    def n(cls,**kw):return {'class_type':cls,'inputs':kw}
    filename=f'locomotion_v02_{state}_{revision}.png'
    source=BASE/'inputs'/f'{state}_{revision}.png'
    if not source.exists():source=BASE/'inputs'/f'{state}.png'
    shutil.copy2(source,COMFY/'input'/filename)
    prompt=PROMPTS[state]
    if revision=='r2' and state=='run':prompt='The character runs quickly on the spot towards the right. His legs alternate with long strides, his knees lift high and his feet kick back. A lively continuous running cycle, his short cape flaps behind him. He keeps holding his fork. His round helmet and attached amber hip lamp remain intact. Locked camera, whole body visible, traditional 2D animation on a plain background.'
    if revision=='r2' and state=='idle':prompt='The small diver takes a deep breath: his chest rises, shoulders lift, knees straighten and his head tilts up, then he exhales, shoulders relax and knees bend slightly. Repeat this expressive breathing motion twice. His cape sways and hip lantern swings gently. Both feet remain planted. He holds his fork firmly. Rigid round helmet stays unchanged. Traditional 2D animation, full body, fixed camera, plain background.'
    if revision=='r3' and state=='idle':prompt='The character stands quietly and breathes rhythmically. His torso rises and falls gently. His cape flutters softly in the breeze and his hanging lamp sways. His feet stay still and his hands stay down. Looping idle animation, locked camera, whole body visible, plain background.'
    if revision=='r2' and state=='walk':prompt='The character walks steadily on the spot towards the right. Left foot then right foot, repeatedly alternating relaxed steps. His knees bend as each foot swings past the other. His body bobs gently and his cape sways behind him. He keeps holding his fork. His round helmet and amber hip lamp remain intact. Continuous walking cycle, locked camera, whole body visible, traditional 2D animation on a plain background.'
    negative=NEGATIVE
    if revision=='r3' or (state=='walk' and revision=='r2'):negative='static, still image, slow motion, frozen legs, extra limbs, deformed limbs, elongated feet, weapon morphing, camera movement, zoom, cropped body, text, subtitles, watermark, waving hands'
    return {
     '1':n('UNETLoader',unet_name='wan2.2_ti2v_5B_fp16.safetensors',weight_dtype='default'),
     '2':n('CLIPLoader',clip_name='umt5_xxl_fp8_e4m3fn_scaled.safetensors',type='wan',device='cpu'),
     '3':n('VAELoader',vae_name='wan2.2_vae.safetensors'),
     '4':n('ModelSamplingSD3',model=['1',0],shift=8.0),
     '5':n('CLIPTextEncode',clip=['2',0],text=prompt),
     '6':n('CLIPTextEncode',clip=['2',0],text=negative),
     '7':n('LoadImage',image=filename),
     '8':n('Wan22ImageToVideoLatent',vae=['3',0],width=704,height=704,length=81,batch_size=1,start_image=['7',0]),
     '9':n('KSampler',model=['4',0],positive=['5',0],negative=['6',0],latent_image=['8',0],seed=seed,steps=24,cfg=5.0,sampler_name='uni_pc',scheduler='simple',denoise=1.0),
     '10':n('VAEDecode',samples=['9',0],vae=['3',0]),
     '11':n('SaveImage',images=['10',0],filename_prefix=f'locomotion_v02/{state}_{revision}')}
def main():
    p=argparse.ArgumentParser();p.add_argument('command',choices=['submit','status','fetch']);p.add_argument('state',choices=PROMPTS);p.add_argument('--revision',default='r1');p.add_argument('--seed',type=int,default=28102026);args=p.parse_args()
    record=BASE/'jobs'/f'{args.state}_{args.revision}.json'
    if args.command=='submit':
        if record.exists():print(record.read_text());return
        workflow=graph(args.state,args.revision,args.seed)
        (BASE/'jobs'/f'{args.state}_{args.revision}_workflow.json').write_text(json.dumps(workflow,indent=2),encoding='utf-8')
        result=req('/prompt',{'prompt':workflow,'client_id':'tide-picker-video-v02'})
        data={'state':args.state,'revision':args.revision,'prompt_id':result['prompt_id'],'status':'queued','started':time.time(),'frames':81,'size':[704,704],'fps':24,'seed':args.seed,'model':'Wan2.2 TI2V 5B fp16; CPU UMT5 fp8 encoder','steps':24,'cfg':5.0}
        record.write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps(data));return
    data=json.loads(record.read_text());pid=data['prompt_id'];hist=req('/history/'+pid)
    if pid not in hist:
        queue=req('/queue')
        print(json.dumps({'status':'pending','elapsed_seconds':round(time.time()-data['started']),'running':[x[1] for x in queue.get('queue_running',[])],'pending':[x[1] for x in queue.get('queue_pending',[])]}));return
    h=hist[pid];status=h.get('status',{}).get('status_str')
    if args.command=='status':print(json.dumps({'status':status,'output_count':len(h.get('outputs',{}).get('11',{}).get('images',[]))}));return
    (BASE/'jobs'/f'{args.state}_{args.revision}_history.json').write_text(json.dumps(h,indent=2),encoding='utf-8')
    if status!='success':raise RuntimeError(str(h.get('status')))
    dest=BASE/'raw'/f'{args.state}_{args.revision}';dest.mkdir(parents=True,exist_ok=True)
    images=h['outputs']['11']['images']
    for i,item in enumerate(images):shutil.copy2(COMFY/'output'/item['subfolder']/item['filename'],dest/f'{i:04d}.png')
    data.update(status='generated_needs_review',frame_count=len(images),elapsed_seconds=round(time.time()-data['started']))
    record.write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps(data))
if __name__=='__main__':main()
