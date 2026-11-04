"""Merge independently built world FX, reviewed reuse decisions and hand sockets.

Run after build.py and merge_sprite_sheets.py finish. Candidates remain pending
main-scene verification; this script never creates acceptance evidence.
"""
from pathlib import Path
import copy, json
BASE=Path(__file__).resolve().parent
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-action36'
path=RUNTIME/'animations.json'
data=json.loads(path.read_text(encoding='utf-8'));actions=data['actions']
ground=json.loads((BASE/'ground-effects.json').read_text(encoding='utf-8'))
for key,entry in ground['actions'].items():
    actions[key].update(entry)
    if key in ['heavy','dive']:actions[key]['event_phase']=4/8

pure_path=BASE/'pure-effects.json'
if pure_path.exists():
    pure=json.loads(pure_path.read_text(encoding='utf-8'))
    pure=pure['effects']['ground_ring']
    if pure.get('status','').startswith('rejected'):raise ValueError('Pure effect source rejected')
    for key,scale in [('heavy',1.0),('dive',1.6)]:
        effect=copy.deepcopy(pure)
        effect['event_frame']=4
        actions[key].update(fx=effect,fx_blend='normal',fx_scale=scale,
            fx_source={k:pure[k] for k in ['source_kind','source','source_sha256','method','known_limits']},superseded_fx=ground['actions'][key]['fx_source'])

for key,base,reason in [
    ('shadow_dash','dash','Rejected original video: baked second grey character, clipped dark tail. Reuse clean dash poses; world historical ghosts and a runtime cold tint supply the upgrade effect.'),
    ('dark_dive','dive','Rejected original video: source-ring torso registration jumps and opaque dark ring in body. Upgrade reuses clean dive body and the independent world ring, with deep-teal tint and range-scaled size.')]:
    old=actions[key]
    original=old.get('superseded_video',{'source':old.get('source'),'sha256':old.get('source_sha256')})
    title=old['title']
    actions[key]=copy.deepcopy(actions[base])
    actions[key].update(id=key,title=title,derived_from_action=base,reuse_reason=reason,superseded_video=original,status='candidate_pending_main_scene_review')
    if key=='dark_dive':
        actions[key]['fx_tint']=[0.42,0.74,0.82,1.0]
        actions[key]['fx_scale']=2.1 if pure_path.exists() else 1.2

sockets=json.loads((BASE/'socket-overrides.json').read_text(encoding='utf-8'))
for key,entry in sockets['actions'].items():
    action=actions[key]
    if entry['source_sha256']!=action['source_sha256'] or entry['frame_count']!=action['frame_count']:
        raise ValueError('Socket/source mismatch: '+key)
    action['sockets_per_frame']=entry['sockets_per_frame']
    action['socket_provenance']={k:entry[k] for k in ['source_sha256','working_width','registration','estimated_manual_error_source_pixels','status']}

for key,action in actions.items():
    action['direction_rule']='one right-facing source; facing mirrors body, local socket and local effect once; emitted world objects retain locked direction'
    if key in ['heavy','dive','dark_dive','scan']:
        action['layer_policy']='clean body plus independently timed world-space ground response; world layer behind actor; no second baked ground response'
    elif key in ['shadow_dash','dash','crystal_dash']:
        action['layer_policy']='body plus historical-position runtime bitmap ghosts; no baked duplicate body/tail'
    elif key in ['orb','shadow_orb']:
        action['layer_policy']='local charge light may remain in body; released projectile is a separate world-space source bitmap'
    else:
        action['layer_policy']='local silhouette may retain authored light or membrane at contact; residual FX excludes protected body pixels, so the same authored light is not composited twice'
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Merged world FX, two explicit upgrade reuses and frame-specific tether sockets')
