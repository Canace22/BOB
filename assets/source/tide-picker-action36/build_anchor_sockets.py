"""Manual reviewed raised-fork grip coordinates; same registration as build.py."""
from pathlib import Path
import hashlib,json,sys
import numpy as np
from PIL import Image,ImageDraw
BASE=Path(__file__).resolve().parent
sys.path.insert(0,str(BASE))
import build
cfg=json.loads((BASE/'overrides.json').read_text(encoding='utf-8'))['anchor']
times=np.linspace(cfg['start'],cfg['end'],20)
# Coordinates are measured on 768-wide source frames, not invented empty hands.
grips=[[400,161],[413,161],[442,176],[471,184],[493,180],
       [538,155],[560,149],[573,138],[579,133],[582,133],
       [580,132],[576,132],[552,151],[534,155],[507,155],
       [486,159],[482,159],[477,159],[478,159],[479,159]]
initial=build.read_frame(cfg['source'],0)
h,w=initial.shape[:2]
root=np.array([w*cfg['center_x_normalized'],h*cfg['ground_y_normalized']])
scale=160/(h*cfg['body_height_normalized'])
base_torso=build.torso(initial)
records=[]
sheet=Image.new('RGB',(4*384,5*240),'#122c38')
registered=Image.new('RGB',(4*320,5*340),'#122c38')
for i,t in enumerate(times):
    rgb=build.read_frame(cfg['source'],float(t))
    shift=build.torso(rgb)-base_torso
    source=np.array(grips[i],float)
    offset=(source-root-shift)*scale
    record={'frame':i,'seconds':float(t),'source_frame':round(t*24),'source_xy':source.tolist(),'torso_shift_xy':shift.tolist(),'offset_from_player_root_160':offset.tolist(),'method':'manual grip-center measurement on this selected source frame; no image interpolation'}
    records.append(record)
    image=Image.fromarray(rgb);draw=ImageDraw.Draw(image);x,y=source
    draw.ellipse((x-7,y-7,x+7,y+7),outline='#00ffff',width=2);draw.line((x,y-42,x,y-7),fill='#00ffff',width=2)
    image.save(BASE/'review'/f'anchor-socket-marked-{i:02}.png')
    sheet.paste(image.resize((384,216)),(i%4*384,i//4*240));ImageDraw.Draw(sheet).text((i%4*384+6,i//4*240+218),f'{i}: grip {int(x)},{int(y)}',fill='white')
    # Source RGB preview transformed with the identical root/torso matrix.
    import cv2
    matrix=np.array([[scale,0,160-(root[0]+shift[0])*scale],[0,scale,260-(root[1]+shift[1])*scale]])
    tile=Image.fromarray(cv2.warpAffine(np.asarray(image),matrix,(320,320)))
    ImageDraw.Draw(tile).line((0,260,319,260),fill='#aaaaaa')
    registered.paste(tile,(i%4*320,i//4*340));ImageDraw.Draw(registered).text((i%4*320+6,i//4*340+322),f'{i} offset {offset[0]:.1f},{offset[1]:.1f}',fill='white')
sheet.save(BASE/'review/anchor-socket-marked20.jpg',quality=95)
registered.save(BASE/'review/anchor-socket-registered20.jpg',quality=95)
data={'version':1,'actions':{'anchor':{'source':cfg['source'],'source_sha256':hashlib.sha256(Path(cfg['source']).read_bytes()).hexdigest(),'working_width':768,'working_height':h,'reference_height':160,'frame_count':20,'range_seconds':[cfg['start'],cfg['end']],'scale':float(scale),'root_source':root.tolist(),'registration':'offset=(source_grip - root_source - (torso(frame)-torso(source0))) * scale; both x/y shift, identical airborne anchor build path','socket_name':'tether_grip','socket_semantics':'center of actual raised hand gripping fork/handle; NOT empty hand or chest','direction_rule':'offset x multiplied once by facing; source and offsets are right-facing','estimated_manual_error_source_pixels':4,'status':'marked_source_and_registration_review_pending','frames':records}}}
data['actions']['anchor']['socket_name']='tether'
data['actions']['anchor']['sockets_per_frame']={'tether':[r['offset_from_player_root_160'] for r in records]}
data['actions']['anchor']['evidence']=['review/anchor-socket-marked20.jpg','review/anchor-socket-registered20.jpg']
(BASE/'socket-overrides.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
