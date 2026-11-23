"""按固定网格裁片并注册根点；不生成新姿态、不逐帧缩放或变形。"""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
OUT=ROOT/'assets/runtime/sprites/player-basic-slash-v3'
GAME=ROOT/'game/art/player-basic-slash-v3'
BASE=json.loads((ROOT/'game/art/tide-picker-action36/animations.json').read_text(encoding='utf-8'))['actions']
SPECS={'parry':{'roots':[291,290,291,291],'height':250,'rotation':0.0,'scale':1.0},'strike1':{'roots':[280,279,279,281],'height':204,'rotation':0.0,'scale':0.9},'strike2':{'roots':[284,283,283,283],'height':207,'rotation':0.0,'scale':0.6}}
def sha(data):return hashlib.sha256(data).hexdigest()
def build():
 OUT.mkdir(parents=True,exist_ok=True);GAME.mkdir(parents=True,exist_ok=True)
 manifest={'version':3,'actions':{},'profiles':{}}
 report={'method':'rounded equal 4x4 source cells, common 384px output, fixed scale1, fixed root_x156, reviewed per-row ground; no interpolation or per-frame resizing','actions':{}}
 for key,spec in SPECS.items():
  path=HERE/'masters'/f'{key}.png';im=Image.open(path).convert('RGBA')
  atlas=Image.new('RGBA',(1536,1536));frames=[];hashes=[];audit=[];clips=[]
  for i in range(16):
   col,row=i%4,i//4
   box=[round(col*im.width/4),round(row*im.height/4),round((col+1)*im.width/4),round((row+1)*im.height/4)]
   cell=im.crop(box);alpha=cell.getchannel('A');solid=alpha.point(lambda a:255 if a>32 else 0).getbbox()
   if not solid or min(solid[:2])<=0 or solid[2]>=cell.width or solid[3]>=cell.height:raise ValueError((key,i,'empty or clipped'))
   dx=192-156;dy=340-spec['roots'][row]
   atlas.paste(cell,(col*384+dx,row*384+dy))
   frames.append([col*384,row*384,384,384])
   visible=bytearray(cell.tobytes())
   for n in range(0,len(visible),4):
    if visible[n+3]==0:visible[n:n+3]=b'\0\0\0'
   hashes.append(sha(bytes(visible)));audit.append({'frame':i,'source_rect':box,'alpha32':solid,'translation':[dx,dy],'root':[156,spec['roots'][row]]})
   f=atlas.crop((col*384,row*384,col*384+384,row*384+384));bg=Image.new('RGBA',f.size,'#142431');bg.alpha_composite(f);clips.append(bg.convert('RGB'))
  target=OUT/f'{key}-body.png';atlas.save(target,optimize=True);shutil.copyfile(target,GAME/target.name)
  # 已入库弧光只旋转/等比显示；命中范围仍由独立战斗规格决定。
  manifest['actions'][key]={'frame_count':16,'fps':24,'reference_height':spec['height'],'event_phase':6/16,'authored_pivot':True,'fx_frame_count':12,'body':{'texture':f'res://art/player-basic-slash-v3/{key}-body.png','pivot':[192,340],'frames':frames,'sha256':sha(target.read_bytes())},'fx':BASE['strike1']['fx'],'fx_blend':'additive','slash_fx':{'contact_frame':4,'fps':24,'rotation':spec['rotation'],'scale':spec['scale']}}
  manifest['profiles'][key]={'prepare':list(range(6)),'release':list(range(6,16)),'prepare_marks':[[0,0],[0.08,1],[0.2,2],[0.35,3],[0.5,4],[0.62,5]],'release_marks':[[0,6],[0.06,7],[0.34,8],[0.42,9],[0.50,10],[0.58,11],[0.66,12],[0.74,13],[0.82,14],[0.90,15]]}
  if key=='parry':
   manifest['actions'][key]['fx']=None
   manifest['actions'][key].pop('slash_fx')
   manifest['profiles'][key]={'mode':'guard','prepare':[0,1,2],'hold_loop':[3,4,5,6],'recover':[12,13,14,15],'loop_fps':6,'impact_marks':[[0,7],[0.18,8],[0.5,9],[0.68,10],[0.85,11]]}
  preview=ROOT/'game/build/qa'/f'{key}-slash-v3.gif';clips[0].save(preview,save_all=True,append_images=clips[1:],duration=[70,70,70,80,90,80,35,35,45,55,65,60,55,55,55,80],loop=0)
  report['actions'][key]={'source':path.relative_to(ROOT).as_posix(),'source_sha256':sha(path.read_bytes()),'runtime':target.relative_to(ROOT).as_posix(),'runtime_sha256':sha(target.read_bytes()),'size':atlas.size,'alpha_extrema':atlas.getextrema()[3],'drawn_frames':16,'unique_visible_pixels':len(set(hashes)),'reference_height':spec['height'],'frames':audit,'review':'source poses reviewed, runtime/GIF acceptance pending'}
 for p in [OUT/'animations.json',GAME/'animations.json']:p.write_bytes((json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
 (HERE/'production.json').write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
 print('Packed 3 actions, 48 authored frames; source pixels retained at scale1')
if __name__=='__main__':build()
