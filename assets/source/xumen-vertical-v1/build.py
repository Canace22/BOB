"""Deterministic spatial registration of portrait paintings, never collision edits."""
from pathlib import Path
import io, json, zipfile, hashlib, sys
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[3]; S=Path(__file__).resolve().parent
O=R/'assets/runtime/scenes/xumen-vertical-v1'; O.mkdir(parents=True,exist_ok=True)
CONTRACT=json.loads((R/'assets/source/xumen-transition-style-v1/integration-contract.json').read_text(encoding='utf8'))
def write(p,v):p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
def fade(im,margin=100):
    a=np.array(im.convert('RGBA')).copy();h,w=a.shape[:2];yy,xx=np.mgrid[:h,:w]
    f=np.minimum.reduce([xx/margin,(w-1-xx)/margin,yy/margin,(h-1-yy)/margin,np.ones_like(xx)])
    a[:,:,3]=(a[:,:,3]*np.clip(f,0,1)).astype('uint8');return Image.fromarray(a)
def master(edge,layers):
    x0,y0,w,h=layers['canvas'];merged=Image.new('RGBA',(w,h))
    root=ET.Element('image',w=str(w),h=str(h),name=edge,version='0.0.3');stack=ET.SubElement(root,'stack')
    with zipfile.ZipFile(S/'masters'/(edge+'.ora'),'w') as z:
        def put(name,data):
            zi=zipfile.ZipInfo(name,date_time=(2026,11,5,0,0,0));z.writestr(zi,data)
        put('mimetype','image/openraster')
        for item in layers['instances']:
            im=Image.open(O/item['file']).convert('RGBA');x=round(item['at'][0]-x0);y=round(item['at'][1]-y0)
            merged.alpha_composite(im,(x,y));b=io.BytesIO();im.save(b,format='PNG');put('data/'+item['id']+'.png',b.getvalue())
        for item in reversed(layers['instances']):
            ET.SubElement(stack,'layer',name=item['id'],src='data/'+item['id']+'.png',x=str(round(item['at'][0]-x0)),y=str(round(item['at'][1]-y0)),opacity='1.0',visibility='visible',**{'composite-op':'svg:src-over'})
        put('stack.xml',ET.tostring(root));b=io.BytesIO();merged.save(b,format='PNG');put('mergedimage.png',b.getvalue())
    merged.thumbnail((900,1100));merged.save(S/'review'/(edge+'.png'))
def build(edge):
    c=next(x for x in CONTRACT['edges'] if x['id']==edge);x=c['shaftX'];ys=[p['y'] for p in c['platforms']]
    canvas=[x-905,ys[-1]-720,1965,round(ys[0]-ys[-1]+1440)]
    im=Image.open(S/'originals'/(edge+'-depth.png')).convert('RGBA');ratio=max(canvas[2]/im.width,canvas[3]/im.height)
    im=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS)
    im=im.crop((0,0,canvas[2],canvas[3]));fade(im,210).save(O/(edge+'-depth.png'))
    raw=Image.open(S/'originals'/(edge+'-spine.png')).convert('RGBA');raw=raw.crop(raw.getbbox())
    # Preserve aspect. Spine is behind traversable route, not a fake collider.
    h=round(ys[0]-ys[-1]+560);raw=raw.resize((round(raw.width*h/raw.height),h),Image.Resampling.LANCZOS)
    fade(raw,35).save(O/(edge+'-spine.png'))
    items=[{'id':edge+'-depth','file':edge+'-depth.png','at':canvas[:2],'z':-27},
           {'id':edge+'-spine','file':edge+'-spine.png','at':[x-round(raw.width*.55),ys[-1]-280],'z':-8}]
    sheet=Image.open(S/'originals'/(edge+'-ledges.png')).convert('RGBA')
    variants=[]
    for i in range(3):
        crop=sheet.crop((0,round(i*sheet.height/3),sheet.width,round((i+1)*sheet.height/3)));crop=crop.crop(crop.getbbox())
        a=np.array(crop);core=(a[:,:,3]>220).sum(axis=1);start=int(np.where(core>crop.width*.70)[0][0])
        # Store source selection; flat painted lip registered to physical y=0.
        crop=crop.crop((0,start,crop.width,crop.height));crop=crop.resize((210,round(crop.height*210/crop.width)),Image.Resampling.LANCZOS)
        crop.save(O/(edge+'-ledge-'+str(i)+'.png'));variants.append(crop)
    for i,y in enumerate(ys):items.append({'id':edge+'-step-'+str(i),'file':edge+'-ledge-'+str(i%3)+'.png','at':[x-105,y],'z':12,'collision':c['platforms'][i]['id']})
    for key,y in [('lower',ys[0]),('upper',ys[-1])]:
        a,b=sorted(c['existingAccess'][key],key=lambda p:p[0]);width=round(b[0]-a[0]);tile=variants[0 if key=='lower' else 2]
        # Composite repeated actual painted material, do not stretch vertically.
        image=Image.new('RGBA',(width+140,tile.height));
        for xx in range(0,image.width,180):image.alpha_composite(tile,(xx,0))
        arr=np.array(image);f=np.minimum(np.arange(image.width)/60,(image.width-1-np.arange(image.width))/60).clip(0,1);arr[:,:,3]=(arr[:,:,3]*f[None,:]).astype('uint8')
        Image.fromarray(arr).save(O/(edge+'-'+key+'.png'))
        items.append({'id':edge+'-'+key,'file':edge+'-'+key+'.png','at':[a[0]-70,y],'z':12})
    if edge=='E33':
        im=Image.open(S/'originals/E33-crown.png').convert('RGBA');im=im.crop(im.getbbox())
        im=im.resize((1300,round(im.height*1300/im.width)),Image.Resampling.LANCZOS);im.save(O/'E33-crown.png')
        items.append({'id':'E33-crown','file':'E33-crown.png','at':[1389,-270],'z':-2})
        im=Image.open(R/'assets/runtime/scenes/xumen-e01-seam-v1/arch.png').convert('RGBA');a=np.array(im);f=np.clip(np.arange(im.height)/60,0,1)
        a[:,:,3]=(a[:,:,3]*f[:,None]).astype('uint8');Image.fromarray(a).save(O/'E33-e01-arch-top.png')
    if edge=='E35':
        for layer,source in [('world','assets/runtime/scenes/xumen-transitions-v2/hub-world-clean.png'),('middle','assets/runtime/scenes/xumen-e01-seam-v1/hub-middle-clean.png')]:
            im=Image.open(R/source).convert('RGBA');a=np.array(im);yy,xx=np.mgrid[:im.height,:im.width];rgb=a[:,:,:3].astype(float)
            zone=np.clip((xx-1280)/100,0,1)*np.clip((560-yy)/100,0,1)
            sel=zone*np.clip((rgb[:,:,2]-rgb[:,:,0]*1.35)/18,0,1)*np.clip((rgb[:,:,1]-rgb[:,:,0]*1.15)/18,0,1)
            Image.fromarray((sel*255).astype('uint8')).save(S/'masters'/('E35-lower-'+layer+'-selection.png'))
            a[:,:,3]=(a[:,:,3]*(1-sel)).astype('uint8');Image.fromarray(a).save(O/('E35-lower-'+layer+'.png'))
        # The new right shaft can see the already accepted left branch room's
        # far right wall. Compose cleanup on E33 output, preserving its entry.
        for layer in ['world','middle']:
            im=Image.open(O/('E33-upper-'+layer+'.png')).convert('RGBA');a=np.array(im);yy,xx=np.mgrid[:im.height,:im.width];rgb=a[:,:,:3].astype(float)
            zone=np.clip((xx-1020)/120,0,1)*np.clip((yy-180)/70,0,1)
            sel=zone*np.clip((rgb[:,:,2]-rgb[:,:,0]*1.35)/9,0,1)*np.clip((rgb[:,:,1]-rgb[:,:,0]*1.15)/9,0,1)
            Image.fromarray((sel*255).astype('uint8')).save(S/'masters'/('E35-neighbor-'+layer+'-selection.png'))
            a[:,:,3]=(a[:,:,3]*(1-sel)).astype('uint8');Image.fromarray(a).save(O/('E35-neighbor-'+layer+'.png'))
    # Bounded operator selection only at the upper entry's old baked water.
    ri=5 if edge=='E33' else 6
    for layer in ['World','Middle']:
        im=Image.open(R/f'game/art/r1-chapter-scenes/R1-0{ri+1}/{layer}.png').convert('RGBA');a=np.array(im)
        yy,xx=np.mgrid[:im.height,:im.width];rgb=a[:,:,:3].astype(float)
        zone=np.clip((850-xx)/180,0,1)*np.clip((yy-(130 if edge=='E35' else 270))/80,0,1)
        divisor=9 if edge=='E35' else 18
        selection=zone*np.clip((rgb[:,:,2]-rgb[:,:,0]*1.35)/divisor,0,1)*np.clip((rgb[:,:,1]-rgb[:,:,0]*1.15)/divisor,0,1)
        Image.fromarray((selection*255).astype('uint8')).save(S/'masters'/(edge+'-'+layer+'-water-selection.png'))
        a[:,:,3]=(a[:,:,3]*(1-selection)).astype('uint8');Image.fromarray(a).save(O/(edge+'-upper-'+layer.lower()+'.png'))
    data={'canvas':canvas,'instances':items,'collisionChanged':False,'source':'built-in imagegen; portrait-native; deterministic alpha/contour registration','userAesthetic':'pending'}
    write(S/'masters'/(edge+'-placement.json'),data);write(O/(edge+'-placement.json'),data);master(edge,data)
    write(S/'masters'/(edge+'-hashes.json'),{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob(edge+'*.png')})
    mpath=R/'game/art/manifest.json';m=json.loads(mpath.read_text(encoding='utf8'))
    for p in O.glob(edge+'*'):
        dest='xumen-vertical/'+p.name;m['entries']=[e for e in m['entries'] if e['dest']!=dest];m['entries'].append({'src':p.relative_to(R).as_posix(),'dest':dest})
    write(mpath,m)
    cp=R/'assets/catalog.json';cat=json.loads(cp.read_text(encoding='utf8'))
    for p in O.glob(edge+'*.png'):
        aid='xumen-vertical-'+p.stem;cat['assets']=[a for a in cat['assets'] if a['id']!=aid];im=Image.open(p)
        cat['assets'].append({'id':aid,'name':p.stem+' 骨壁生台','kind':'environment','region':'R1','status':'candidate','target':'2d','file':p.relative_to(R).as_posix(),'width':im.width,'height':im.height,'integrationStatus':'awaiting-runtime-verification','source':{'method':'built-in imagegen; portrait and spatial registration','model':'not exposed','references':['assets/source/xumen-transition-style-v1/images/03-骨壁生台-上行过渡.png']},'metadata':'assets/source/xumen-vertical-v1/elements.json','notes':'Original collision unchanged; middle spine has no collider.'})
    cat['revision']+=1;write(cp,cat)
if __name__=='__main__':build(sys.argv[1])
