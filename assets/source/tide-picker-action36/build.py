"""Deterministic video extraction; no generated or interpolated poses.

Run with Python + OpenCV/Numpy/Scipy/Pillow. --inspect exports candidate mattes.
Source videos are kept outside Git; source manifest preserves original hashes.
"""
from pathlib import Path
import argparse, json, hashlib, math, os
import cv2
import numpy as np
from scipy import ndimage as ndi
from PIL import Image, ImageDraw, ImageFont

BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
SOURCE=REPO.parent/'outputs/拾潮者_14集参考_左右动作全集'
RUNTIME=REPO/'assets/runtime/sprites/tide-picker-action36'
REVIEW=BASE/'review'
for p in [RUNTIME,REVIEW]:p.mkdir(parents=True,exist_ok=True)
SOURCES=json.loads((BASE/'inputs/selected_sources.json' if (BASE/'inputs/selected_sources.json').exists() else SOURCE/'selected_sources.json').read_text(encoding='utf-8'))
REVIEWS={a['key']:a for a in json.loads((BASE/'inputs/integration_source_review.json' if (BASE/'inputs/integration_source_review.json').exists() else SOURCE/'integration_source_review.json').read_text(encoding='utf-8'))['actions']}
VIDEO_CACHE={'path':None,'frames':[],'fps':24.0}
SEMANTIC=None
CANVAS=640
PIVOT=[320,448]

def register_rgba(picture,matrix):
    rgba=np.asarray(picture).astype(np.float32)/255.0
    rgba[:,:,:3]*=rgba[:,:,3:4]
    warped=cv2.warpAffine(rgba,matrix,(CANVAS,CANVAS),flags=cv2.INTER_LANCZOS4,borderMode=cv2.BORDER_CONSTANT)
    alpha=warped[:,:,3:4].clip(0,1)
    color=(warped[:,:,:3]/np.maximum(alpha,1/255)).clip(0,1)
    color[alpha[:,:,0]<1/255]=0
    return (np.concatenate([color,alpha],axis=2)*255).round().astype(np.uint8)

def semantic_layers(rgb,key,ground_y=None):
    global SEMANTIC
    from semantic_matte import SemanticMatte,body_rgba,background_color
    if SEMANTIC is None:
        config={'threads':int(os.environ.get('ACTION36_THREADS','4')),'provider':os.environ.get('ACTION36_PROVIDER','cpu')}
        if os.environ.get('ACTION36_MATTE_MODEL'):
            config.update(model_path=Path(os.environ['ACTION36_MATTE_MODEL']),model_family=os.environ.get('ACTION36_MATTE_FAMILY','birefnet'))
        SEMANTIC=SemanticMatte(**config)
        print('Semantic model provider:',SEMANTIC.provider,flush=True)
    probability=SEMANTIC.predict(rgb,REVIEW/'mask-cache')
    bg=background_color(rgb)
    if bg[0]>bg[1]+65 and bg[2]>bg[1]+50:
        # Semantic models can keep thin chroma-screen lines inside the silhouette.
        # The AND of red and blue excludes the costume's red-only tether.
        chroma=rgb.astype(np.float32)
        magenta=np.minimum(chroma[:,:,0],chroma[:,:,2])-chroma[:,:,1]
        probability=probability*np.clip((60-magenta)/40,0,1)
    preserve=[]
    if key=='cyclone':
        pose=REVIEWS[key]['initialReferencePose'];h,w=rgb.shape[:2]
        x=int(pose['centerXNormalized']*w);ground=int(pose['groundYNormalized']*h)
        preserve=[(x-110,ground-100,x+110,ground+4)]
    body=body_rgba(rgb,probability,preserve_regions=preserve)
    raw=np.asarray(body)[:,:,3]>2
    protected=ndi.binary_dilation(raw,iterations=2)
    v=rgb.astype(float);bg=background_color(rgb)
    # Only authored source light outside the protected silhouette enters this pass.
    # This avoids stealing ivory helmet/fork highlights into a separate FX layer.
    emission=np.maximum(v-bg,0)
    coverage=(emission.max(2)/255).clip(0,1)
    # Connected soft light support rejects isolated compression/background variation.
    support=ndi.binary_propagation(coverage>.14,mask=coverage>.035)
    alpha=coverage*~protected*support
    h,w=raw.shape;yy=np.indices((h,w))[0]
    if key=='cyclone':
        # Reviewed waist ring ends around y332; projected floor ring starts345.
        # Fade only the FX, retaining all actual legs in the independent body.
        alpha*=np.clip((344-yy)/10,0,1)
    reference_ground=REVIEWS[key]['initialReferencePose'].get('groundYNormalized')
    ground=float(ground_y) if ground_y is not None else (float(reference_ground)*h if reference_ground is not None else float(h))
    if key=='dash_slash':
        # Low, neutral source dust must not follow an airborne dash slash.
        # Bright ivory/cyan slash cores and all protected body pixels remain.
        neutral=np.clip((30-(v.max(2)-v.min(2)))/10,0,1)*np.clip((205-v.mean(2))/25,0,1)
        alpha*=1-neutral*(yy>ground-65)
    # Ground response has its own world-space event; floor reflections never ride the body.
    if key not in ['heavy','dive','dark_dive','scan','strike1','strike2','upper','great_slash','dash_slash','cyclone','up_spell','abyss_scream']:
        alpha[yy>=ground-4]=0
    if key in ['idle','walk','run','hurt','defeat','turn','interact','pogo','wall_jump','wall_slide','anchor','slit','swim','tram','dash','shadow_dash','crystal_dash','orb','shadow_orb','parry']:
        alpha[:]=0
    # Fired projectiles are independently extracted and simulated by TideOrb.
    if key in ['orb','shadow_orb']:
        center=torso(rgb)
        if center is not None:alpha[:,int(center[0]+160):]=0
    alpha[alpha<.025]=0
    clean=(emission/np.maximum(coverage[...,None],.025)).clip(0,255)
    clean[alpha==0]=0
    return body,Image.fromarray(np.dstack([clean,alpha*255]).astype(np.uint8))

def read_frame(path,seconds,width=768):
    if VIDEO_CACHE['path']!=str(path):
        c=cv2.VideoCapture(str(path));frames=[];fps=c.get(cv2.CAP_PROP_FPS)
        while True:
            ok,bgr=c.read()
            if not ok:break
            frames.append(cv2.cvtColor(cv2.resize(bgr,(width,round(bgr.shape[0]*width/bgr.shape[1]))),cv2.COLOR_BGR2RGB))
        c.release()
        if not frames:raise RuntimeError(f'Cannot decode {path}')
        VIDEO_CACHE.update(path=str(path),frames=frames,fps=fps)
    return VIDEO_CACHE['frames'][min(len(VIDEO_CACHE['frames'])-1,round(seconds*VIDEO_CACHE['fps']))]

def matte(rgb,key):
    a=rgb.astype(np.float32);h,w=a.shape[:2]
    # Backdrop estimate uses outer corners; sample sides separately from floor.
    bg=np.median(np.concatenate([a[:h//6,:w//6].reshape(-1,3),a[:h//6,-w//6:].reshape(-1,3)]),axis=0)
    if bg[0]>bg[1]+65 and bg[2]>bg[1]+50:
        # Chroma-key matte. Preserve costume red, despill only magenta edges.
        mag=np.minimum(a[:,:,0],a[:,:,2])-a[:,:,1]
        alpha=np.clip((90-mag)/60,0,1)
        alpha[(a[:,:,0]>a[:,:,1]*1.6)&(a[:,:,2]>a[:,:,1]*1.6)&(mag>60)]=0
        mask=alpha>.05;lab,n=ndi.label(mask);sizes=np.bincount(lab.ravel());sizes[0]=0
        keep=lab==sizes.argmax();keep=ndi.binary_fill_holes(keep)
        alpha*=keep
        edge=(alpha>0)&(alpha<1)
        a[:,:,0][edge]=np.minimum(a[:,:,0][edge],a[:,:,1][edge]+40)
        a[:,:,2][edge]=np.minimum(a[:,:,2][edge],a[:,:,1][edge]+35)
        a[alpha==0]=0
        return Image.fromarray(np.dstack([a,alpha*255]).astype(np.uint8)),bg
    # Neutral shadow colours follow the beige background; ivory highlights remain.
    chroma=a.max(2)-a.min(2)
    neutral=(chroma<48)&(a[:,:,0]>=a[:,:,1]-3)&(a[:,:,1]>=a[:,:,2]-3)
    diff=np.linalg.norm(a-bg,axis=2)
    ratio=np.sum(a*bg,axis=2)/np.sum(bg*bg)
    residual=np.linalg.norm(a-bg*ratio[:,:,None],axis=2)
    ground=float(REVIEWS[key]['initialReferencePose']['groundYNormalized'])*h
    floor_shadow=(residual<14)&(ratio<1.0)&(ratio>.50)&(np.indices((h,w))[0]>ground-10)
    background=(diff<14)|floor_shadow
    mask=~background
    holes=ndi.binary_fill_holes(mask)&~mask
    hl,hn=ndi.label(holes);hs=np.bincount(hl.ravel());hs[0]=0
    mask|=holes&(hs[hl]<200)
    # Keep fine disconnected fork tips, but remove compression speckle.
    labels,n=ndi.label(mask);sizes=np.bincount(labels.ravel());sizes[0]=0
    mask=(sizes[labels]>12)&mask
    inner=ndi.binary_erosion(mask)
    if not inner.any():return Image.new('RGBA',(w,h)),bg
    nearest=ndi.distance_transform_edt(~inner,return_distances=False,return_indices=True)
    fg=a[nearest[0],nearest[1]];v=fg-bg
    alpha=mask.astype(np.float32);edge=mask&~inner
    coverage=((a-bg)*v).sum(2)/np.maximum((v*v).sum(2),1)
    alpha[edge]=np.clip(coverage[edge],0,1)
    a[edge]=(bg+(a-bg)/np.maximum(alpha[...,None],.12))[edge].clip(0,255)
    a[alpha==0]=0
    return Image.fromarray(np.dstack([a,alpha*255]).astype(np.uint8)),bg

def torso(rgb):
    a=rgb.astype(float)
    sel=(a[:,:,1]>a[:,:,0]*1.18)&(a[:,:,2]>a[:,:,0]*1.08)&(a.mean(2)<140)&(a.mean(2)>22)
    lab,n=ndi.label(sel);sizes=np.bincount(lab.ravel());sizes[0]=0
    if n==0 or sizes.max()<15:return None
    # The cape is the largest dark teal region; effects are brighter.
    yy,xx=np.where(lab==sizes.argmax())
    return np.array([np.median(xx),np.median(yy)])

def split_layers(image,rgb,bg,key):
    a=np.array(image).copy();h,w=a.shape[:2]
    yy,xx=np.indices((h,w));c=torso(rgb)
    if c is None:c=np.array([w/2,h*.6])
    # Remove detached source particles/shadows from body. Keep disconnected props near it.
    raw=a[:,:,3]>4;lab,n=ndi.label(raw);sizes=np.bincount(lab.ravel());sizes[0]=0
    main=(lab==sizes.argmax()) if n else raw
    body_near=ndi.binary_dilation(main,iterations=3)
    outlying=raw&~body_near
    v=rgb.astype(float)
    cyan=(v[:,:,1]>v[:,:,0]+18)&(v[:,:,2]>v[:,:,0]+12)&(v[:,:,1]>165)
    # Golden slash trails are separate from the amber lamp, whose brightness is lower.
    gold=(v[:,:,0]>214)&(v[:,:,1]>170)&(v[:,:,2]<v[:,:,1]-12)&((xx-c[0])**2+(yy-c[1])**2>75**2)
    effect=(cyan|gold|outlying)&raw
    effect=ndi.binary_dilation(effect,iterations=1)&raw
    if key in ['idle','walk','run','jump','double_jump','hurt','defeat','turn','interact']:
        a[:,:,3][outlying]=0
        effect=np.zeros_like(raw)
    fx=a.copy();fx[:,:,3]=np.where(effect,a[:,:,3],0)
    # Analytic alpha over known flat source backdrop for luminous energy, avoiding matte discs.
    luminous=effect&(v.mean(2)>bg.mean())
    cov=np.max(np.maximum(v-bg,0)/np.maximum(255-bg,1),axis=2).clip(0,1)
    fx[:,:,3][luminous]=(cov[luminous]*255).astype(np.uint8)
    for ch in range(3):
        clean=(bg[ch]+(v[:,:,ch]-bg[ch])/np.maximum(cov,.04)).clip(0,255)
        fx[:,:,ch][luminous]=clean[luminous].astype(np.uint8)
    a[:,:,3][effect]=0
    # Detached coloured floor reflections are never part of either layer.
    bottom=(yy>h*.88)&outlying
    fx[:,:,3][bottom]=0
    return Image.fromarray(a),Image.fromarray(fx)

def atlas(frames,key,suffix,pivot):
    bounds=[f.getbbox() for f in frames if f.getbbox()]
    if not bounds:return None
    box=[max(0,min(b[0] for b in bounds)-3),max(0,min(b[1] for b in bounds)-3),min(CANVAS,max(b[2] for b in bounds)+3),min(CANVAS,max(b[3] for b in bounds)+3)]
    cw,ch=box[2]-box[0],box[3]-box[1]
    cols=max(1,min(len(frames),2048//cw));rows=math.ceil(len(frames)/cols)
    page=Image.new('RGBA',(cols*cw,rows*ch));rects=[]
    for i,im in enumerate(frames):
        x,y=(i%cols)*cw,(i//cols)*ch
        page.paste(im.crop(box),(x,y));rects.append([x,y,cw,ch])
    filename=key+'-'+suffix+'.png';page.save(RUNTIME/filename,optimize=True)
    return {'texture':'res://art/tide-picker-action36/'+filename,'frames':rects,'pivot':[pivot[0]-box[0],pivot[1]-box[1]],'size':list(page.size),'sha256':hashlib.sha256((RUNTIME/filename).read_bytes()).hexdigest()}

def build(keys,semantic=False):
    manifest_path=RUNTIME/'animations.json'
    data=json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {'version':1,'actions':{}}
    loops={'idle','walk','run','wall_slide','float','swim'}
    translate={'walk','run','dash','shadow_dash','crystal_dash','wall_jump','wall_slide','anchor','hurt','jump','double_jump','float','dive','dark_dive','swim'}
    airborne={'jump','double_jump','wall_jump','wall_slide','anchor','float','dive','dark_dive','swim'}
    # Per-action pose budgets follow game readability, not the five-second source length.
    pose_counts={'idle':36,'walk':24,'run':24,'jump':18,'double_jump':16,'wall_slide':20,'wall_jump':10,
        'dash':12,'float':24,'anchor':20,'strike1':12,'strike2':12,'upper':12,'pogo':12,'orb':16,
        'heavy':16,'dive':20,'parry':12,'slit':18,'heal':24,'scan':16,'interact':12,'hurt':10,
        'defeat':36,'shadow_dash':12,'great_slash':16,'dash_slash':12,'cyclone':24,'crystal_dash':24,
        'up_spell':16,'abyss_scream':20,'shadow_orb':16,'dark_dive':24,'swim':24,'tram':16,'turn':8}
    for s in SOURCES:
        s=s.copy()
        key=s['action']
        if keys and key not in keys:continue
        review=REVIEWS[key];start,end=review['recommendedSourceRangeSeconds']
        if key in loops and review.get('loopCandidateSeconds'):start,end=review['loopCandidateSeconds']
        count=pose_counts[key]
        if key=='dash':start,end,count=.75,2.55,12
        if key=='pogo':start,end,count=1.3,1.85,12
        cfg=review['initialReferencePose'];initial=read_frame(s['source'],0)
        overrides=json.loads((BASE/'overrides.json').read_text(encoding='utf-8')) if (BASE/'overrides.json').exists() else {}
        override=overrides.get(key,{})
        if override and not override.get('reject',False):
            s['source']=override['source']
            s['sourceSHA256']=hashlib.sha256(Path(s['source']).read_bytes()).hexdigest()
            start,end=override['start'],override['end']
            cfg={'centerXNormalized':override['center_x_normalized'],'groundYNormalized':override['ground_y_normalized'],'bodyHeightNormalized':override['body_height_normalized']}
            initial=read_frame(s['source'],0)
        h,w=initial.shape[:2];root=np.array([w*cfg['centerXNormalized'],h*cfg['groundYNormalized']])
        scale=160/(h*cfg['bodyHeightNormalized']);base_torso=torso(initial)
        bodies=[];effects=[];times=np.linspace(start,end,count,endpoint=key not in loops)
        source_edit=None
        if key=='parry':
            times=np.array([30,34,38,60,61,62,76,78,80,84,88,90])/24
            count=len(times)
            source_edit='Reviewed discrete guard/lift/recover poses; skips deformed contact frames and independent source pearl. Not an intact source segment.'
        if key=='interact':
            times=np.array([57,58,59,60,61,62,63,62,61,60,59,58,57])/24
            count=len(times)
            source_edit='Reach before touching the source test handle; reverse selected reach poses for authored withdrawal, no interpolation.'
        if key=='strike2':
            times=times[[0,3,4,6,8,9,10,11]]
            count=len(times)
            source_edit='Reviewed discrete diagonal backhand poses; skips melted hand/fork poses 1/2 and compresses held overhead poses. Fast step from anticipation to diagonal extension, not an uninterrupted source swing or interpolated motion.'
        registration_path=BASE/'registration-overrides.json'
        registration=json.loads(registration_path.read_text(encoding='utf-8')).get(key,{}) if registration_path.exists() else {}
        if registration and (registration.get('source_sha256')!=s['sourceSHA256'] or registration.get('source_frame_count')!=count):
            raise ValueError(f'{key}: registration corrections do not match source hash/frame count')
        for i,t in enumerate(times):
            rgb=read_frame(s['source'],float(t))
            if semantic:body,fx=semantic_layers(rgb,key,float(cfg['groundYNormalized'])*h)
            else:
                im,bg=matte(rgb,key)
                body,fx=split_layers(im,rgb,bg,key)
            if key=='scan':
                # End the growing source ring before it reaches the video crop.
                rgba=np.asarray(fx).copy()
                rgba[:,:,3]=(rgba[:,:,3]*np.clip((14-i)/3,0,1)).astype(np.uint8)
                fx=Image.fromarray(rgba)
            if key=='dash_slash' and i in [1,5,6]:
                # Reviewed warm/neutral source dust behind the actor, not blade light.
                rgba=np.asarray(fx).copy();yy,xx=np.indices(rgb.shape[:2]);v=rgb.astype(float)
                dust=(xx<225)&(yy>275)&(v[:,:,1]<=v[:,:,0]+12)&(v[:,:,2]<=v[:,:,0]+12)
                rgba[:,:,3][dust]=0;fx=Image.fromarray(rgba)
            current=torso(rgb);shift=np.zeros(2)
            if str(i) in registration.get('torso_per_frame',{}):
                current=np.array(registration['torso_per_frame'][str(i)],dtype=float)
            if key in translate and current is not None and base_torso is not None:
                shift[0]=current[0]-base_torso[0]
                if key in airborne:shift[1]=current[1]-base_torso[1]
                if key in ['dive','dark_dive']:
                    impact=next(e['timeSeconds'] for e in review['eventCandidates'] if e['event']=='impact')
                    settle=np.clip((float(t)-impact+.3)/.3,0,1)
                    shift[1]*=1-settle*settle*(3-2*settle)
            matrix=np.array([[scale,0,PIVOT[0]-(root[0]+shift[0])*scale],[0,scale,PIVOT[1]-(root[1]+shift[1])*scale]])
            for picture,dest in [(body,bodies),(fx,effects)]:
                layer_matrix=matrix.copy()
                if dest is effects and key in ['dive','dark_dive']:
                    layer_matrix[1,2]=PIVOT[1]-root[1]*scale
                arr=register_rgba(picture,layer_matrix)
                if 'left during' in override.get('facing',''):arr=np.ascontiguousarray(arr[:,::-1])
                dest.append(Image.fromarray(arr))
        body_meta=atlas(bodies,key,'body',PIVOT);fx_meta=atlas(effects,key,'fx',PIVOT)
        meta={'id':key,'title':s['title'],'body':body_meta,'fx':fx_meta,'reference_height':160,'loop':key in loops,'frame_count':count,'fps':12 if key in loops else 24,'source':s['source'],'source_sha256':s['sourceSHA256'],'source_seconds':times.tolist(),'scale':scale,'root_source':root.tolist(),'source_facing':review['sourceFacing'],'status':'candidate','method':'selected chronological source frames; border-connected matte; analytic glow alpha; fixed per-action scale; body/effect passes; root translation registration'}
        events=[e for e in review['eventCandidates'] if e['event'] in ['hit','release','impact']]
        if events:meta['event_phase']=max(.02,min(.98,(events[0]['timeSeconds']-start)/(end-start)))
        if key=='orb':meta['event_phase']=(83/24-start)/(end-start)
        if key=='shadow_orb':meta['event_phase']=(59/24-start)/(end-start)
        if override:meta['repair']=override
        if semantic:meta['method']=SEMANTIC.model_family+' semantic silhouette with source edge unmix; protected body and residual authored glow; fixed per-action scale and root registration; variable cropped atlas'
        if semantic:meta['fx_blend']='additive'
        if semantic:meta['semantic_model']={'family':SEMANTIC.model_family,'file':Path(SEMANTIC.model_path).name,'sha256':SEMANTIC.model_tag.split(':')[0],'provider':SEMANTIC.provider,'resolution':SEMANTIC.input_size,'cache':'review/mask-cache; model+preprocess+RGB SHA256'}
        if key=='pogo':meta['event_phase']=.88
        if key=='jump':meta['phases']={'rise':[3/18,6/18],'apex':[6/18,8/18],'fall':[8/18,11/18],'land':[11/18,15/18]}
        if key=='anchor':meta['phases']={'hang':[.17,.80],'detach':[.80,1.0]}
        if key=='crystal_dash':meta['phases']={'charge':[0,14/24],'flight':[14/24,23/24],'exit':[23/24,1.0]}
        if key in ['orb','shadow_orb']:
            muzzle=np.array([574,222 if key=='orb' else 201])
            meta['sockets']={'muzzle':((muzzle-root)*scale).tolist()}
            meta['sockets_source']={'muzzle':muzzle.tolist(),'working_width':768,'seconds':83/24 if key=='orb' else 59/24}
        if key in ['parry','scan','tram']:
            event_time={'parry':2.05,'scan':2.6,'tram':2.15}[key]
            meta['event_phase']=max(.02,min(.98,(event_time-start)/(end-start)))
        if key=='parry':meta['event_phase']=3/12
        if key=='interact':meta['event_phase']=6/13
        if key=='strike2':meta['event_phase']=1/8
        if source_edit:meta['source_edit']=source_edit
        if key=='scan':meta['fx_edit']='Full ground ring retained; alpha fades over frames 11–14 before the source ring clips at video edges.'
        if registration:meta['registration_correction']=registration
        data['actions'][key]=meta
        manifest_path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8',newline='\n')
        sample=Image.new('RGB',(6*224,4*256),'#122c38')
        for i in range(12):
            idx=round(i*(count-1)/11);x=(i%6)*224;y=(i//6)*512
            for j,bgcol in enumerate(['#122c38','#eee8dd']):
                p=Image.new('RGBA',(CANVAS,CANVAS),bgcol);p.alpha_composite(bodies[idx]);p.alpha_composite(effects[idx]);p=p.crop((PIVOT[0]-192,PIVOT[1]-288,PIVOT[0]+192,PIVOT[1]+96)).resize((224,224))
                sample.paste(p.convert('RGB'),(x,y+j*256));ImageDraw.Draw(sample).text((x+4,y+j*256+228),f'{key} {idx} / {times[idx]:.2f}s',fill='white')
        sample.save(REVIEW/(key+'-registered.jpg'),quality=94)
        frames=[]
        for b,e in zip(bodies,effects):
            p=Image.new('RGBA',(CANVAS,CANVAS),'#122c38');p.alpha_composite(b);p.alpha_composite(e);frames.append(p.convert('RGB'))
        frames[0].save(REVIEW/(key+'.gif'),save_all=True,append_images=frames[1:],duration=83 if key in loops else 45,loop=0)
        print('Built',key,count,body_meta['size'],flush=True)

def inspect(keys):
    f=ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',20)
    for s in SOURCES:
        key=s['action']
        if keys and key not in keys:continue
        out=Image.new('RGB',(1152,900),'#122c38');d=ImageDraw.Draw(out)
        for i,t in enumerate([.25,1.25,2.25,3.25,4.25]):
            rgb=read_frame(s['source'],t)
            rgba,bg=matte(rgb,key);rgba.thumbnail((384,150))
            original=Image.fromarray(rgb);original.thumbnail((384,150))
            y=i*180+26
            out.paste(original,(0,y));out.paste(rgba,(384,y),rgba)
            light=Image.new('RGBA',(384,150),'#eee8dd');light.alpha_composite(rgba)
            out.paste(light.convert('RGB'),(768,y))
            d.text((8,i*180+3),f'{key} {t:.2f}s',font=f,fill='white')
        out.save(REVIEW/(key+'-matte.jpg'),quality=93)
        print('Inspected',key,flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--inspect',action='store_true');p.add_argument('--build',action='store_true');p.add_argument('--semantic',action='store_true');p.add_argument('--keys',default='')
    args=p.parse_args()
    if args.inspect:inspect(args.keys.split(',') if args.keys else [])
    if args.build:build(args.keys.split(',') if args.keys else [],args.semantic)
