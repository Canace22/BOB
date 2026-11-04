"""Extract authored projectile/rope pixels. No procedural painted replacement."""
import json, hashlib
import numpy as np
from PIL import Image, ImageDraw
from build import BASE, REPO, RUNTIME, REVIEW, SOURCES, read_frame


def projectile(key, seconds, box, center, radii, name):
    source = next(s for s in SOURCES if s['action'] == key)
    rgb = read_frame(source['source'], seconds)
    x0,y0,x1,y1=box
    a=rgb[y0:y1,x0:x1].astype(float)
    bg=np.median(rgb[:70,:150].reshape(-1,3),axis=0)
    # Analytic over against the measured source backdrop, keeping the painted core.
    alpha=np.max(np.maximum(a-bg,0)/np.maximum(255-bg,1),axis=2).clip(0,1)
    yy,xx=np.indices(alpha.shape)
    distance=((xx+x0-center[0])/radii[0])**2+((yy+y0-center[1])/radii[1])**2
    if key=='shadow_orb': alpha=np.maximum(alpha,np.clip((1.04-distance)*18,0,1))
    # Soft region mask rejects the source muzzle beam without drawing new imagery.
    envelope=np.clip((2.6-distance)/.8,0,1)
    alpha*=envelope
    clean=(bg+(a-bg)/np.maximum(alpha[...,None],.025)).clip(0,255)
    alpha[alpha<.012]=0;clean[alpha==0]=0
    image=Image.fromarray(np.dstack([clean,alpha*255]).astype(np.uint8))
    image.save(RUNTIME/name,optimize=True)
    return {'file':name,'source':source['source'],'source_sha256':hashlib.sha256(__import__('pathlib').Path(source['source']).read_bytes()).hexdigest(),'seconds':seconds,'working_width':768,'crop':box,'center':center,'core_radii':radii,'method':'source pixels, analytic backdrop alpha and manually reviewed elliptical region exclusion','sha256':hashlib.sha256((RUNTIME/name).read_bytes()).hexdigest()}


def build():
    records=[]
    records.append(projectile('orb',83/24,(595,177,692,272),(640,222),(27,25),'projectile.png'))
    records.append(projectile('shadow_orb',59/24,(633,148,768,254),(698,201),(50,36),'shadow_projectile.png'))
    path=REPO/'assets/runtime/sprites/red-tether-segment/base.png'
    rope=Image.open(path).convert('RGBA')
    # Take a central, continuous segment of the existing painted braided rope.
    crop=(400,274,1700,448)
    rope=rope.crop(crop)
    a=np.array(rope);a[:,:,3][a[:,:,3]<12]=0;a[a[:,:,3]==0,:3]=0
    rope=Image.fromarray(a);rope=rope.crop(rope.getbbox())
    rope.save(RUNTIME/'tether.png',optimize=True)
    records.append({'file':'tether.png','source':str(path.relative_to(REPO)),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'crop':crop,'method':'central painted braid segment; transparent speckle cutoff12/255','sha256':hashlib.sha256((RUNTIME/'tether.png').read_bytes()).hexdigest()})
    (BASE/'effects-sources.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    preview=Image.new('RGB',(800,320),'#122c38')
    for i,name in enumerate(['projectile.png','shadow_projectile.png']):
        im=Image.open(RUNTIME/name);im=im.resize((im.width*2,im.height*2))
        preview.paste(im,(i*320+20,20),im)
    rope.thumbnail((740,50));preview.paste(rope,(20,260),rope)
    preview.save(REVIEW/'separate-effects.jpg',quality=95)
    print('Extracted',len(records),'authored bitmap effects')


if __name__=='__main__':build()
