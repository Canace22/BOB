"""Register authored pose sheets, retaining original source pixels.

These are AI-authored replacement key poses, NOT video-extracted animation.
Does not edit animations.json. The owner integrates reviewed action metadata.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import os

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

BASE=Path(__file__).resolve().parent
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-action36'
REVIEW=BASE/'review/sprite-sheets'
PIVOT=(192,256)
CANVAS=384
CONFIG={
    'run': {'file':'run-v3.png','grid':[4,2],'scale':.4,'baseline':416,'root_x':242,'fps':12,'loop':True,'order':list(range(8)), 'visual_status':'v3_alternating_support_leg_and_all_registered_phases_reviewed; exaggerated_eight_pose_cycle_for_in_game_trial'},
    'parry': {'grid':[3,2],'scale':160/435,'baseline':460,'root_x':250,'fps':16,'loop':False,'order':list(range(6)), 'visual_status':'six_source_poses_and_registered_dark_light_sheet_reviewed; gameplay_pending'},
    'wall_jump': {'grid':[4,2],'scale':.4,'baseline':416,'root_x':242,'fps':20,'loop':False,'order':list(range(8)), 'visual_status':'source_two_hands_two_feet_and_registered_dark_light_sheet_reviewed; gameplay_pending',
                  'registration_points':[[249,142],[233.5,99],[244.5,75],[247.5,55.5],[245.5,58.5],[240.5,58],[242.5,63],[237.5,67]],
                  'reference_registration':[242,68]},
    'heavy': {'grid':[4,2],'scale':160/370,'baseline':414,'root_x':220,'fps':16,'loop':False,'order':list(range(8)),
              'visual_status':'source_eight_grounded_poses_and_registered_dark_light_sheet_reviewed; gameplay_pending'},
    'dive': {'grid':[4,2],'scale':160/365,'baseline':409,'root_x':220,'fps':16,'loop':False,'order':list(range(8)),
             'visual_status':'source_eight_poses_and_registered_dark_light_sheet_reviewed; gameplay_pending',
             'registration_points':[[230,409],[232,409],[230,409],[250,439],[220,409],[220,409],[220,409],[220,409]],
             'reference_registration':[220,409]},
}

def keep_main_alpha(rgba):
    """Remove disconnected speckles without colour-keying costume reds."""
    a=np.asarray(rgba).copy()
    labels,n=ndi.label(a[:,:,3]>12)
    sizes=np.bincount(labels.ravel());sizes[0]=0
    main=labels==sizes.argmax()
    near=ndi.binary_dilation(main,iterations=1)
    a[:,:,3]*=near
    a[a[:,:,3]==0,:3]=0
    return Image.fromarray(a)

def local_background_unmix(rgb,body):
    """Use nearby rejected source pixels for gradient-backdrop soft edges."""
    alpha=np.asarray(body)[:,:,3].astype(float)/255
    nearest=ndi.distance_transform_edt(alpha>=.01,return_distances=False,return_indices=True)
    background=rgb[nearest[0],nearest[1]].astype(float)
    color=rgb.astype(float)
    soft=(alpha>.01)&(alpha<.99)
    unmixed=(color-background*(1-alpha[...,None]))/np.maximum(alpha[...,None],.05)
    color[soft]=unmixed[soft].clip(0,255)
    color[alpha==0]=0
    return Image.fromarray(np.dstack([color,alpha*255]).astype('uint8'))

def make_atlas(frames,key):
    boxes=[f.getbbox() for f in frames]
    box=(min(b[0] for b in boxes)-3,min(b[1] for b in boxes)-3,max(b[2] for b in boxes)+3,max(b[3] for b in boxes)+3)
    w,h=box[2]-box[0],box[3]-box[1]
    cols=min(len(frames),2048//w)
    image=Image.new('RGBA',(cols*w,math.ceil(len(frames)/cols)*h))
    rects=[]
    for i,frame in enumerate(frames):
        x,y=i%cols*w,i//cols*h
        image.alpha_composite(frame.crop(box),(x,y));rects.append([x,y,w,h])
    path=RUNTIME/f'{key}-body.png';image.save(path)
    return {'texture':f'res://art/tide-picker-action36/{key}-body.png','frames':rects,'pivot':[PIVOT[0]-box[0],PIVOT[1]-box[1]],'size':list(image.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def build(key,write_runtime=False):
    cfg=CONFIG[key];path=BASE/'sprite-sheets'/cfg.get('file',f'{key}-v1.png')
    src=Image.open(path).convert('RGBA');cols,rows=cfg['grid'];w,h=src.size
    frames=[];source_boxes=[];stats=[]
    engine=None
    if key=='parry':
        from semantic_matte import SemanticMatte,body_rgba
        engine=SemanticMatte(threads=int(os.environ.get('ACTION36_THREADS','4')),provider='cpu')
    for i in cfg['order']:
        x,y=i%cols,i//cols
        box=(round(x*w/cols),round(y*h/rows),round((x+1)*w/cols),round((y+1)*h/rows))
        tile=src.crop(box);source_boxes.append(box)
        if engine:
            rgb=np.asarray(tile)[:,:,:3].copy()
            probability=engine.predict(rgb,BASE/'review/mask-cache')
            tile=body_rgba(rgb,probability)
            tile=local_background_unmix(rgb,tile)
        raw_alpha=np.asarray(tile)[:,:,3]
        raw_alpha_mass=int(raw_alpha.sum())
        tile=keep_main_alpha(tile)
        tile.save(REVIEW/f'{key}-source-{i:02}.png')
        s=cfg['scale']
        shift=np.array(cfg['registration_points'][i])-np.array(cfg['reference_registration']) if 'registration_points' in cfg else np.zeros(2)
        matrix=np.array([[s,0,PIVOT[0]-(cfg['root_x']+shift[0])*s],[0,s,PIVOT[1]-(cfg['baseline']+shift[1])*s]],np.float32)
        pixels=np.asarray(tile).astype(np.float32)/255
        pixels[:,:,:3]*=pixels[:,:,3,None]
        registered=cv2.warpAffine(pixels,matrix,(CANVAS,CANVAS),flags=cv2.INTER_LANCZOS4).clip(0,1)
        registered[:,:,:3]/=np.maximum(registered[:,:,3,None],1e-6)
        registered[registered[:,:,3]<1/255]=0
        frame=Image.fromarray((registered.clip(0,1)*255).astype('uint8'))
        frames.append(frame)
        alpha=np.asarray(tile)[:,:,3]
        yy,xx=np.where(alpha>64)
        stats.append({'frame':i,'source_box':box,'source_alpha_bbox':tile.getbbox(),
                      'source_opaque_bbox':[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],
                      'source_border_pixels_alpha_gt12':{'top':int((alpha[0,:]>12).sum()),'bottom':int((alpha[-1,:]>12).sum()),'left':int((alpha[:,0]>12).sum()),'right':int((alpha[:,-1]>12).sum())},
                      'detached_alpha_mass_removed':raw_alpha_mass-int(alpha.sum()),
                      'registered_alpha_bbox':frame.getbbox(),'registration_shift':shift.tolist()})
        print(key,i,'registered',flush=True)
    sheet=Image.new('RGB',(384*cols,384*rows*2))
    for bg_index,color in enumerate(['#122c38','#eee8dd']):
        for i,frame in enumerate(frames):
            tile=Image.new('RGBA',(384,384),color);tile.alpha_composite(frame)
            draw=ImageDraw.Draw(tile);draw.line((0,256,383,256),fill='#777777');draw.text((8,8),f'{key} phase {i+1}',fill='white' if bg_index==0 else 'black')
            sheet.paste(tile.convert('RGB'),(i%cols*384,(i//cols+bg_index*rows)*384))
    sheet.save(REVIEW/f'{key}-registered.jpg',quality=95)
    previews=[]
    for frame in frames:
        tile=Image.new('RGBA',(384,384),'#122c38');tile.alpha_composite(frame)
        ImageDraw.Draw(tile).line((0,256,383,256),fill='#777777')
        previews.append(tile.convert('RGB'))
    previews[0].save(REVIEW/f'{key}-preview.gif',save_all=True,append_images=previews[1:],duration=round(1000/cfg['fps']),loop=0)
    movie=cv2.VideoWriter(str(REVIEW/f'{key}-preview.mp4'),cv2.VideoWriter_fourcc(*'mp4v'),cfg['fps'],(384,384))
    for repeat in range(8):
        for frame in previews:movie.write(cv2.cvtColor(np.asarray(frame),cv2.COLOR_RGB2BGR))
    movie.release()
    data={'id':key,'title':'跑步' if key=='run' else '迎珠·偏转','source':str(path),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source_kind':'AI-authored replacement key-pose sheet; not extracted from video','reference_height':160,'loop':cfg['loop'],'frame_count':len(frames),'fps':cfg['fps'],'fx':None,'scale':cfg['scale'],'root_source':[cfg['root_x'],cfg['baseline']],'source_facing':'right','direction_rule':'single right-facing source; one runtime facing mirror','source_grid':cfg['grid'],'source_cells':source_boxes,'status':'candidate_pending_visual_and_gameplay_review','method':'fixed per-action scale and baseline; original source pixel colors; no per-frame height normalization; semantic alpha for parry / source alpha for run; detached speckle cleanup','frame_review':stats,'events':{'authority':'existing skill timeline; sprite poses do not grant or define parry immunity','candidate_contact_frame':2 if key=='parry' else None}}
    data['visual_review']=cfg['visual_status']
    data['title']={'run':'跑步','parry':'迎珠·偏转','wall_jump':'蹬壁反跳','heavy':'重鸣·涨潮环','dive':'坠潮·沉钟'}[key]
    data['method']='fixed per-action source scale; original source colors; source alpha with detached-speckle cleanup; premultiplied-alpha registration; no per-frame height normalization'
    data['events']['authority']='existing skill timeline and physics; sprite poses do not create damage or immunity'
    if 'registration_points' in cfg:
        data['registration_points']=cfg['registration_points']
        data['reference_registration']=cfg['reference_registration']
        data['registration_method']='reviewed helmet-center translation only; fixed source scale; limb/cape pose offsets retained, world trajectory owned by physics' if key=='wall_jump' else 'manual root-axis translation; airborne extended-foot reference and pelvis-axis estimate; tucked frame stays elevated; shared landing baseline for frames 5-8; world trajectory owned by physics'
    data['status']='rejected_source_motion' if cfg['visual_status'].startswith('rejected') else 'source_pose_and_alpha_reviewed_pending_gameplay'
    if key=='parry':
        data['matte_method']='BiRefNet General Lite; detached component cleanup; local rejected-background soft-edge unmix; premultiplied-alpha registration'
    elif key=='run':
        data['known_limits']=['Eight authored poses, not smooth mocap; large leg displacement into flight phases 4/8 is retained.','Phase 1 uses light near-leg front contact; phase 5 dark far-leg front contact. Source knee/hip overlap is stylized, not anatomically exact.','Contact foot bottom varies by 0-2 asset pixels; airborne phase feet are intentionally raised.','Real-time main-scene loop, physical speed matching and left-facing playback remain to be checked by game owner.']
    elif key=='wall_jump':
        data['known_limits']=['Authored wall-jump key poses with no wall baked in; push direction/collision are physics-owned.','Head-center registration removes sheet translation; intentional knee tuck and cape motion remain.','In-game left/right wall contact and wall-jump transition remain untested by this source processor.']
    elif key=='heavy':
        data['known_limits']=['Eight authored key poses with shared grounded baseline; no optical-flow interpolation.','Foot-contact envelope differs by up to 3 source pixels (1.3 output pixels); recovery must use skill time mapping.','Body has no baked ring or hitbox; FX is integrated separately by game owner.','Main-scene playback, strike event alignment and left-facing attack remain untested by source processor.']
    elif key=='dive':
        data['known_limits']=['Eight authored poses: air preparation 1-2, descent 3-4, impact/compression 5-6, recovery 7-8.','Frame 4 cape has 5 source pixels of top padding at alpha>64; reviewed silhouette is complete, with no opaque boundary contact.','Airborne root estimates remove whole-cell translation; knee tuck and landing compression are preserved rather than grounding each alpha-bottom.','Body contains no ground ring; physics landing must gate impact poses and separately anchored world FX.','Main-scene land timing and left-facing playback remain untested by source processor.']
    if write_runtime:
        if cfg['visual_status'].startswith('rejected'):
            raise RuntimeError(f'{key} source rejected: refusing runtime export')
        data['body']=make_atlas(frames,key)
    return data

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--keys',nargs='+',default=['run','parry']);parser.add_argument('--write-runtime',action='store_true');args=parser.parse_args()
    REVIEW.mkdir(parents=True,exist_ok=True);RUNTIME.mkdir(parents=True,exist_ok=True)
    manifest_path=BASE/'sprite-sheet-actions.json'
    manifest=json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {'version':1,'actions':{}}
    for key in args.keys:manifest['actions'][key]=build(key,args.write_runtime)
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8',newline='\n')
