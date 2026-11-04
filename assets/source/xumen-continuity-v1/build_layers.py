"""Deterministic editable source masks. Artwork is generated, never procedurally painted."""
from pathlib import Path
import json, math, zipfile
import numpy as np
from PIL import Image, ImageFilter
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[3]
BASE=Path(__file__).resolve().parent
OUT=BASE/'runtime'; MASTER=BASE/'master'
OUT.mkdir(exist_ok=True); MASTER.mkdir(exist_ok=True)
sheet=Image.open(BASE/'originals/seams-clean.png').convert('RGBA')
W,H=sheet.size
STRIPS=[(0,288),(298,583),(596,887)]
profile=[[(0,276),(.12,276),(.23,276),(.35,255),(.45,224),(.51,192),(.58,184),(.66,219),(.72,248),(.82,220),(.9,211),(1,238)],
[(0,220),(.1,209),(.2,245),(.32,231),(.44,220),(.52,239),(.62,264),(.72,267),(.85,259),(1,248)],
[(0,236),(.12,247),(.24,262),(.38,262),(.5,266),(.58,256),(.67,248),(.77,240),(.84,235),(1,238)]]
manifest=[]

def polygon_mask(points):
    # Editable SVG polygon is the master; rasterization uses Pillow's deterministic mask.
    from PIL import ImageDraw
    mask=Image.new('L',(W,h)); ImageDraw.Draw(mask).polygon(points,fill=255)
    return mask

def export(img,mask,name):
    arr=np.array(img);arr[:,:,3]=np.minimum(arr[:,:,3],np.array(mask));arr[arr[:,:,3]==0,:3]=0
    result=Image.fromarray(arr)
    result.save(OUT/(name+'.png'))
    return result

for i,(top,bottom) in enumerate(STRIPS):
    # Source is the preserved 1774x887 approved layout. If a later edit changes dimensions, fail.
    assert (W,H)==(1774,887),(W,H)
    plate=sheet.crop((0,top,W,bottom));h=plate.height
    n=i+1
    road=[(round(x*W),max(0,min(h-1,y-top if i else y))) for x,y in profile[i]]
    # For strips 2/3 their profiles are already strip-local coordinates.
    if i: road=[(round(x*W),y) for x,y in profile[i]]
    terrain=polygon_mask(road+[(W,h),(0,h)])
    terrain=terrain.filter(ImageFilter.GaussianBlur(.65))
    a=np.array(plate); yy,xx=np.mgrid[0:h,0:W]
    warm=(a[:,:,0].astype(float)>a[:,:,2]*1.04)&(a[:,:,0]>40)
    upper=yy < np.interp(xx,[p[0] for p in road],[p[1]-22 for p in road])
    # Mid contains actual ceiling/side material. Far owns cool water; no copied creatures.
    mid_arr=np.where(warm&upper,255,0).astype('uint8')
    mid=Image.fromarray(mid_arr).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(1.4))
    front=np.clip((yy-(h-48))/25,0,1)*255
    front=Image.fromarray(front.astype('uint8')).filter(ImageFilter.GaussianBlur(2))
    # Ground comes from the original rooms. This plate is only distant continuity, not fake ground.
    above=np.array(terrain)<10
    water=Image.fromarray(np.where((~warm)&above,220,0).astype('uint8')).filter(ImageFilter.GaussianBlur(9))
    masks={'Far':Image.new('L',(W,h),255),'Middle':mid,'World':terrain,'Foreground':front,'WaterMask':water}
    layers={}
    for layer,mask in masks.items():
        name=f'seam-{n}-{layer}'
        if layer=='WaterMask':
            # White RGB + source-derived soft alpha: mask, not generated scenery.
            blank=Image.new('RGBA',(W,h),(255,255,255,255));layers[layer]=export(blank,mask,name)
        else: layers[layer]=export(plate,mask,name)
        mask.save(MASTER/(name+'-mask.png'))
    outline=' '.join(f'{x},{y}' for x,y in road+[(W,h),(0,h)])
    (MASTER/f'seam-{n}-ground.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {h}"><polygon points="{outline}" fill="white"/></svg>',encoding='utf8')
    # Editable OpenRaster includes original plate + independent named layers and alpha masks.
    ora=MASTER/f'seam-{n}.ora'
    root=ET.Element('image',w=str(W),h=str(h),name=f'Xumen seam {n}')
    stack=ET.SubElement(root,'stack')
    import io
    def png(im):
        b=io.BytesIO();im.save(b,format='PNG');return b.getvalue()
    with zipfile.ZipFile(ora,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for layer in ['Foreground','World','Middle','Far']:
            ET.SubElement(stack,'layer',name=layer,src=f'data/{layer}.png',opacity='1.0',visibility='visible',x='0',y='0',**{'composite-op':'svg:src-over'})
            z.writestr(f'data/{layer}.png',png(layers[layer]),compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('data/Original.png',png(plate));ET.SubElement(stack,'layer',name='Original clean source (hidden)',src='data/Original.png',visibility='hidden',opacity='1.0',x='0',y='0')
        z.writestr('stack.xml',ET.tostring(root));z.writestr('mergedimage.png',png(plate))
    manifest.append({'id':f'seam-{n}','sourceCrop':[0,top,W,bottom],'size':[W,h], 'road_profile':road,'layers':list(masks),'purpose':'reference art plate decomposed; runtime masks exclude all painted road/collision pixels'})

    # Remove the source road from the distant glimpse completely. Only low-contrast
    # underwater pixels may sit behind a real collision edge.
    cool=(a[:,:,2].astype(float)>a[:,:,0]*1.12)&(a[:,:,2]>36)&above
    glimpse=Image.fromarray(np.where(cool,230,0).astype('uint8')).filter(ImageFilter.MinFilter(9)).filter(ImageFilter.GaussianBlur(12))
    export(plate,glimpse,f'seam-{n}-Glimpse')

# Share current anatomy art in the in-game map, not as a full-screen play background.
Image.open(ROOT/'assets/source/world-continuity-v1/images/02-r1-continuous.png').convert('RGBA').save(OUT/'r1-anatomy-overview.png')

# Protect legacy extraction islands: their water pixels belong to the old far
# plate too. Feather the NEW depth back into the existing painting near every
# static-layer contour, rather than exposing hard polygon/crop boundaries.
rooms=json.loads((ROOT/'game/art/whalebelly/rooms.json').read_text(encoding='utf8'))
for room in rooms:
    w,h=map(lambda v:round(v),room['size'])
    occupied=np.zeros((h,w),dtype=np.uint8)
    for layer in ['World','Middle','Foreground']:
        path=ROOT/f'game/art/r1-chapter-scenes/{room["id"]}/{layer}.png'
        if not path.exists():continue
        image=Image.open(path).convert('RGBA').crop((16,16,w+16,h+16))
        occupied=np.maximum(occupied,np.array(image)[:,:,3])
    if room['id']=='R1-01':
        # Starting room remains the accepted reference assembly; shared region
        # art is shown in the map and its door vista only.
        occupied[:]=255
    blurred=np.array(Image.fromarray(occupied).filter(ImageFilter.GaussianBlur(40))).astype(float)/255
    # Zero influence at the legacy crop edge; blend starts only in open water.
    guard=np.uint8(np.clip((.98-blurred*2.0)/.5,0,1)**5*255)
    rgba=np.full((h,w,4),255,dtype=np.uint8);rgba[:,:,3]=guard
    Image.fromarray(rgba).save(OUT/f'depth-guard-{room["id"]}.png')
(BASE/'layers.json').write_bytes((json.dumps({'source':'originals/seams-clean.png','strips':manifest},ensure_ascii=False,indent=2)+'\n').encode('utf8'))
print(json.dumps({'strips':len(manifest),'rgba_exports':len(list(OUT.glob('*.png'))),'ora':3}))
