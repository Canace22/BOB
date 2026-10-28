"""Bake video-measured motion onto complete character art; no generated pixel replacement."""
from pathlib import Path
import hashlib
import json
import shutil
import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[2]
ASSET = 'tide-picker-idle-v03'
RUNTIME = REPO / 'assets/runtime/sprites' / ASSET
GODOT = REPO / 'godot/WhalebellyRuins'
DEST = GODOT / 'assets/runtime' / ASSET


def extract_reference(rgb):
    # The neutral source backdrop differs strongly from teal cloth, ivory shell and red rope.
    a = rgb.astype(np.float32)
    neutral = ((a.max(2) - a.min(2)) < 37) & (a.mean(2) > 72) & (a[:,:,0] >= a[:,:,1]) & (a[:,:,1] >= a[:,:,2])
    labels, _ = ndi.label(neutral)
    border = np.unique(np.r_[labels[0], labels[-1], labels[:, 0], labels[:, -1]])
    background = np.isin(labels, border[border > 0])
    # Enclosed backdrop in the fork and the loop of red cord.
    for label in range(1, labels.max() + 1):
        region = labels == label
        yy, xx = np.where(region)
        if region.sum() > 20 and xx.mean() > 180 and yy.mean() > 90:
            background |= region
    foreground = ~background
    foreground[327:] = False
    parts, _ = ndi.label(foreground)
    counts = np.bincount(parts.ravel())
    counts[0] = 0
    foreground = parts == counts.argmax()
    # Keep painted dark boundary; fractional edge coverage only on the outermost pixel.
    interior = ndi.binary_erosion(foreground)
    nearest = ndi.distance_transform_edt(~interior, return_distances=False, return_indices=True)
    fg = a[nearest[0], nearest[1]]
    bg = np.median(a[background & (np.indices(background.shape)[0] < 290)], axis=0)
    edge = foreground & ~interior
    vector = fg - bg
    coverage = ((a-bg)*vector).sum(2) / np.maximum((vector*vector).sum(2), 1)
    alpha = foreground.astype(np.float32)
    alpha[edge] = np.clip(coverage[edge], 0, 1)
    cleaned = bg + (a-bg)/np.maximum(alpha[...,None], 0.1)
    a[edge] = cleaned[edge].clip(0,255)
    a[alpha == 0] = 0
    return np.dstack([a, alpha*255]).clip(0,255).astype(np.uint8)


def smoothstep(a, b, x):
    v = np.clip((x-a)/(b-a), 0, 1)
    return v*v*(3-2*v)


def rigid_field(flow, mask, xx, yy):
    ys, xs = np.where(mask)
    points = np.c_[xs[::5], ys[::5]].astype(np.float32)
    targets = points + flow[ys[::5], xs[::5]]
    matrix, _ = cv2.estimateAffinePartial2D(points, targets, method=cv2.LMEDS)
    if matrix is None:
        return np.broadcast_to(np.median(flow[mask],axis=0), flow.shape).copy()
    # Rigid rotation/translation: never breathe by stretching the shell or fork.
    scale = np.hypot(matrix[0,0], matrix[1,0])
    matrix[:,:2] /= max(scale, 1e-6)
    return np.stack([matrix[0,0]*xx+matrix[0,1]*yy+matrix[0,2]-xx,
                     matrix[1,0]*xx+matrix[1,1]*yy+matrix[1,2]-yy],axis=2)


def main():
    for directory in [RUNTIME, DEST, BASE/'review', BASE/'frames']:
        directory.mkdir(parents=True, exist_ok=True)
    rgb = np.asarray(Image.open(BASE/'reference.png').convert('RGB'))
    reference = extract_reference(rgb)
    Image.fromarray(reference).save(BASE/'master-rgba.png')
    cap = cv2.VideoCapture(str(BASE/'source.mp4'))
    decoded = []
    while True:
        ok, frame = cap.read()
        if not ok: break
        decoded.append(cv2.cvtColor(cv2.resize(frame,(255,340)),cv2.COLOR_BGR2GRAY))
    cap.release()
    # Video is a centered 3:4 crop of the original 284x340 reference.
    dis = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    yy, xx = np.mgrid[:340,:284].astype(np.float32)
    head = ((xx-139)/55)**2 + ((yy-53)/48)**2 < 1
    fork = (xx>215)&(yy>48)&(yy<146)&(reference[:,:,3]>150)&(rgb[:,:,0]>110)
    head_weight = (1-smoothstep(85,109,yy)) * smoothstep(70,93,xx) * (1-smoothstep(191,210,xx))
    fork_weight = smoothstep(211,221,xx) * (1-smoothstep(143,165,yy))
    lamp_distance = ((xx-111)/33)**2 + ((yy-190)/40)**2
    lamp_mask = (lamp_distance < 0.55) & (reference[:,:,3]>150)
    lamp_weight = 1-smoothstep(0.65,1.4,lamp_distance)
    grounded_weight = 1-smoothstep(255,292,yy)
    frames, fields, bboxes, source_indices = [], [], [], []
    premul = reference.astype(np.float32)/255
    premul[:,:,:3] *= premul[:,:,3:4]
    for i in range(72):
        phase = i/72
        index = round(phase*(len(decoded)-1))
        inverse = dis.calc(decoded[index], decoded[0], None)
        flow = np.pad(inverse, ((0,0),(14,15),(0,0)), mode='edge')
        flow = cv2.GaussianBlur(flow,(0,0),1.1)
        head_flow = rigid_field(flow,head,xx,yy)
        fork_flow = rigid_field(flow,fork,xx,yy)
        lamp_flow = rigid_field(flow,lamp_mask,xx,yy)
        flow = flow*(1-head_weight[...,None])+head_flow*head_weight[...,None]
        flow = flow*(1-fork_weight[...,None])+fork_flow*fork_weight[...,None]
        flow = flow*(1-lamp_weight[...,None])+lamp_flow*lamp_weight[...,None]
        # Zero position AND velocity at the loop boundary. Feet never slide.
        flow *= grounded_weight[...,None] * np.sin(np.pi*phase)**2 * 0.45
        flow = np.clip(flow,-8,8).astype(np.float32)
        fields.append(flow)
        warped = cv2.remap(premul,xx+flow[:,:,0],yy+flow[:,:,1],cv2.INTER_CUBIC,borderMode=cv2.BORDER_CONSTANT)
        warped = np.clip(warped,0,1)
        warped[:,:,:3] /= np.maximum(warped[:,:,3:4],1e-5)
        rgba = Image.fromarray(np.round(warped.clip(0,1)*255).astype(np.uint8))
        rgba = rgba.resize((233,279),Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA',(256,320))
        canvas.paste(rgba,(13,32))
        canvas.save(BASE/'frames'/f'idle_{i:03d}.png')
        frames.append(canvas)
        bboxes.append(canvas.getbbox())
        source_indices.append(index)
    np.savez_compressed(BASE/'motion-fields.npz',inverse_flow_q256=np.round(np.array(fields)*256).astype(np.int16),source_indices=source_indices,quantization_scale=256)
    samples = frames
    frames, durations = [], []
    for frame in samples:
        if frames and frame.tobytes() == frames[-1].tobytes():
            durations[-1] += 1
        else:
            frames.append(frame)
            durations.append(1)
    if frames[-1].tobytes() == frames[0].tobytes():
        durations[0] += durations.pop()
        frames.pop()
    count = len(frames)
    milliseconds = [round(sum(durations[:i+1])*1000/12)-round(sum(durations[:i])*1000/12) for i in range(count)]
    atlas = Image.new('RGBA',(2048,2880))
    for i,frame in enumerate(frames): atlas.paste(frame,((i%8)*256,(i//8)*320))
    atlas.save(RUNTIME/'idle-atlas.png')
    # Lossless animated master retains frame order and alpha for inspection/re-export.
    frames[0].save(BASE/'master.webp',save_all=True,append_images=frames[1:],duration=milliseconds,loop=0,lossless=True)
    lines=[f'[gd_resource type="SpriteFrames" load_steps={count+2} format=3]', '',
           f'[ext_resource type="Texture2D" path="res://assets/runtime/{ASSET}/idle-atlas.png" id="1"]','']
    for i in range(count):
        lines += [f'[sub_resource type="AtlasTexture" id="Frame_{i}"]','atlas = ExtResource("1")',
                  f'region = Rect2({(i%8)*256}, {(i//8)*320}, 256, 320)','filter_clip = true','']
    lines += ['[resource]','animations = [{','"frames": [']
    lines += [f'{{"duration": {durations[i]}.0, "texture": SubResource("Frame_{i}")}}'+(',' if i<count-1 else '') for i in range(count)]
    lines += ['],','"loop": true,','"name": &"idle",','"speed": 12.0','}]']
    (RUNTIME/'idle.tres').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    for filename in ['idle-atlas.png','idle.tres']: shutil.copy2(RUNTIME/filename,DEST/filename)
    arrays = [np.asarray(f).astype(np.float32) for f in frames]
    deltas = [float(np.abs(arrays[(i+1)%count]-arrays[i]).mean()) for i in range(count)]
    foot_change = max(float(np.abs(a[278:]-arrays[0][278:]).max()) for a in arrays)
    report={'asset':ASSET,'source_task':'vj_f85f7ee4-8f48-4eb8-aa99-8107706fc8dc',
            'source_url':'https://xsj-ai-orange.seasungame.com/prod/video/20261029/7dcf67c1-6876-4510-85e7-c1369c5b5ff3.mp4',
            'source_sha256':hashlib.sha256((BASE/'source.mp4').read_bytes()).hexdigest(),
            'source_decoded_frames':len(decoded),'baked_samples':72,'frames':count,'frame_durations':durations,'fps':12,'duration':6,
            'canvas':[256,320],'pivot':[128,300],'visible_reference_height':261,
            'source_frame_indices':source_indices,'alpha_bboxes':bboxes,
            'unique_pixel_frames':len({hashlib.sha256(np.asarray(f).tobytes()).hexdigest() for f in frames}),
            'frame_delta_mean':float(np.mean(deltas)),'loop_seam_delta':deltas[-1],
            'fixed_foot_max_channel_change':foot_change,'method':'video-motion reprojected onto complete reference; rigid shell/fork; fixed feet; periodic envelope',
            'reviewer':'agent','visual_review':'pending','runtime_review':'pending'}
    (RUNTIME/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    shutil.copy2(RUNTIME/'manifest.json',DEST/'manifest.json')
    sheet=Image.new('RGB',(4*256,2*348),'#18313a')
    for k,index in enumerate([0,12,24,36,48,60,71,0]):
        x,y=k%4*256,k//4*348
        sheet.paste(samples[index],(x,y),samples[index])
        ImageDraw.Draw(sheet).text((x+8,y+323),f'{index/12:.2f}s / frame {index}',fill='white')
    sheet.save(BASE/'review/contact.png')
    for bg,name in [('#18313a','dark'),('#e2e1da','light')]:
        pictures=[]
        for frame in frames:
            view=Image.new('RGB',(512,400),bg)
            view.paste(frame,(28,45),frame)
            small=frame.resize((92,115),Image.Resampling.LANCZOS)
            view.paste(small,(358,245),small)
            pictures.append(view)
        pictures[0].save(BASE/'review'/f'{name}-loop.webp',save_all=True,append_images=pictures[1:],duration=milliseconds,loop=0,quality=90)
    print(json.dumps({k:v for k,v in report.items() if k not in ['source_frame_indices','alpha_bboxes']},ensure_ascii=False))


if __name__=='__main__': main()
