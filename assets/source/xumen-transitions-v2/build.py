"""Export authored plates at fixed world anchors; never modify collision data."""
from pathlib import Path
import io, json, zipfile, hashlib
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

R = Path(__file__).resolve().parents[3]
S = Path(__file__).resolve().parent
O = R / 'assets/runtime/scenes/xumen-transitions-v2'
O.mkdir(parents=True, exist_ok=True)
ROOMS = json.loads((R / 'game/art/whalebelly/rooms.json').read_text(encoding='utf8'))
ORIGINS = [(0,0),(2183,-86.153),(4367,61.847),(6551,17.847),(8654,171.847),(2283,-1476.153),(4033,-1476.153)]

def write(path, value):
    path.write_bytes((json.dumps(value, ensure_ascii=False, indent=2)+'\n').encode('utf8'))

def fade(image, left, right):
    a = np.array(image.convert('RGBA')).copy()
    x = np.arange(image.width)
    f = np.clip(x/max(1,left),0,1)*np.clip((image.width-1-x)/max(1,right),0,1)
    a[:,:,3] = (a[:,:,3]*f[None,:]).astype('uint8')
    return Image.fromarray(a)

def sample(points, x):
    for a,b in zip(points,points[1:]):
        if a[0] <= x <= b[0]:
            return a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0])
    return points[0][1] if x < points[0][0] else points[-1][1]

def save(image, name):
    image.save(O/(name+'.png'), compress_level=9)

def master(edge, canvas, layers):
    x0,y0,w,h=canvas
    root=ET.Element('image',w=str(w),h=str(h),name=edge+' joint master',version='0.0.3')
    stack=ET.SubElement(root,'stack'); merged=Image.new('RGBA',(w,h))
    with zipfile.ZipFile(S/'masters'/(edge+'-joint.ora'),'w') as z:
        z.writestr('mimetype','image/openraster')
        for name,at in layers:
            im=Image.open(O/(name+'.png')).convert('RGBA'); x,y=round(at[0]-x0),round(at[1]-y0)
            merged.alpha_composite(im,(x,y)); b=io.BytesIO(); im.save(b,format='PNG')
            z.writestr('data/'+name+'.png',b.getvalue())
        for name,at in reversed(layers):
            ET.SubElement(stack,'layer',name=name,src='data/'+name+'.png',x=str(round(at[0]-x0)),y=str(round(at[1]-y0)),opacity='1.0',visibility='visible',**{'composite-op':'svg:src-over'})
        z.writestr('stack.xml',ET.tostring(root)); b=io.BytesIO(); merged.save(b,format='PNG'); z.writestr('mergedimage.png',b.getvalue())
    merged.thumbnail((1082,768)); merged.save(S/'review'/(edge+'-joint.png'))

def main_edge(edge, index, floor_y, gx, canvas_x):
    depth=Image.open(S/'originals'/(edge+'-depth.png')).convert('RGBA')
    # Equal scale to width; slight differing image ratio is cropped by the canvas.
    depth=depth.resize((2164,round(depth.height*2164/depth.width)),Image.Resampling.LANCZOS)
    depth=fade(depth,330,330); save(depth,edge+'-depth')
    raw=Image.open(S/'originals'/(edge+'-ground.png')).convert('RGBA')
    arr=np.array(raw); occupied=(arr[:,:,3]>200).sum(axis=1)
    start=int(np.where(occupied>raw.width*.9)[0][0])
    bottom=int(np.where(occupied>0)[0][-1])+1
    ground=raw.crop((0,start,raw.width,bottom))
    ground=ground.resize((1600,round(ground.height*1600/raw.width)),Image.Resampling.LANCZOS)
    source=np.array(ground); out=np.zeros((500,1600,4),dtype=np.uint8); tops=[]
    a,b=ORIGINS[index],ORIGINS[index+1]
    left=a[0]+ROOMS[index]['size'][0]; right=b[0]
    gy=floor_y-80
    for x in range(1600):
        wx=gx+x
        y=sample(ROOMS[index]['surfaces'][0],wx-a[0])+a[1] if wx<left else sample(ROOMS[index+1]['surfaces'][0],wx-b[0])+b[1] if wx>right else floor_y
        off=round(y-gy); tops.append(off)
        out[off:off+source.shape[0],x]=source[:,x]
    save(fade(Image.fromarray(out),190,230),edge+'-ground')
    arch=Image.open(S/'originals'/(edge+'-arch.png')).convert('RGBA')
    arch=arch.resize((1300,round(arch.height*1300/arch.width)),Image.Resampling.LANCZOS)
    save(fade(arch,160,180),edge+'-arch')
    anchors={'depth':[canvas_x,floor_y-896],'arch':[gx+150,floor_y-880],'ground':[gx,gy]}
    master(edge,[canvas_x,floor_y-896,2164,1536],[(edge+'-'+n,anchors[n]) for n in ['depth','arch','ground']])
    write(S/'masters'/(edge+'-placement.json'),{'edge':edge,'canvas':[canvas_x,floor_y-896,2164,1536],'anchors':anchors,'ground_top_per_column':tops,'original_collision_changed':False,'source_ground_crop_top':start,'scale':'uniform resize then column translation to original surface'})
    # Spatial pixel ownership, preserving existing upper branch structures.
    for ri in [index,index+1]:
        w,h=map(int,ROOMS[ri]['size']); ox,oy=ORIGINS[ri]
        yy,xx=np.mgrid[:h,:w]; wx=xx+ox; wy=yy+oy
        f=np.clip((wx-gx)/190,0,1)*np.clip((gx+1600-wx)/230,0,1)
        save(Image.fromarray((255*(1-f)).astype('uint8')).convert('RGBA'),edge+'-other-owner-'+str(ri))
        if ri==1:
            protect=np.clip((450-wy)/80,0,1)*np.clip((wx-3490)/80,0,1)
            f*=1-protect
        keep=(255*(1-f)).astype('uint8'); save(Image.fromarray(keep).convert('RGBA'),edge+'-owner-'+str(ri))
        # Far plates contain water only; clear a wider entire vertical strip.
        f=np.clip((wx-(gx-120))/330,0,1)*np.clip((gx+1720-wx)/330,0,1)
        save(Image.fromarray((255*(1-f)).astype('uint8')).convert('RGBA'),edge+'-far-owner-'+str(ri))
    return anchors

def clean_e02_room_layers():
    # Ownership is spatial and editable, never a global blue colour key.
    im=Image.open(R/'assets/runtime/scenes/xumen-e01-seam-v1/hub-world-clean.png').convert('RGBA')
    a=np.array(im);a[:,1050:,3]=0;im=Image.fromarray(a)
    mask=Image.new('L',im.size,255);d=ImageDraw.Draw(mask)
    d.polygon([(770,0),(1050,0),(1050,645),(1015,641),(1010,630),(985,634),(975,622),(965,600),(955,600),(945,610),(930,617),(915,623),(900,627),(880,623),(860,628),(840,635),(820,645),(790,670),(770,678)],fill=0)
    # Remove the last water cap at the original hill lip. Small attached flora
    # inside this repaint volume are replaced by the clean support's flora.
    for x in range(770,1050):
        top=sample(ROOMS[1]['surfaces'][0],x-16)+12
        d.line((x,0,x,round(top)),fill=0)
    aa=np.array(im);aa[:,:,3]=(aa[:,:,3].astype(float)*np.array(mask.filter(ImageFilter.GaussianBlur(.7)))/255).astype('uint8');im=Image.fromarray(aa)
    support=Image.open(S/'originals/E02-hub-support.png').convert('RGBA')
    support=support.resize((654,800),Image.Resampling.LANCZOS)
    # The generated extraction is a candidate painting, not an exact crop.
    # Register its only upper walking lip to the original sloping hub ledge.
    old=np.array(support);new=np.zeros_like(old)
    for x in range(654):
        wx=x+1050-16
        source_top=285 if x<310 else 286
        target=sample(ROOMS[1]['surfaces'][4],wx)+16
        lookup=np.interp(np.arange(800),[0,target,550,799],[0,source_top,550,799])
        for c in range(4):new[:,x,c]=np.interp(lookup,np.arange(800),old[:,x,c]).astype('uint8')
    support=Image.fromarray(new)
    im.alpha_composite(support,(1050,0));save(im,'hub-world-clean')
    im=Image.open(R/'game/art/r1-chapter-scenes/R1-03/World.png').convert('RGBA')
    mask=Image.new('L',im.size,255);d=ImageDraw.Draw(mask)
    # Cut only the baked water band above the hill; the door on the left remains.
    profile=[(0,0),(550,0),(550,570),(520,569),(490,571),(450,579),(420,591),(390,601),(350,607),(310,609),(270,609),(230,603),(200,600),(170,599),(140,597),(110,594),(90,590),(75,578),(65,567),(0,567)]
    d.polygon(profile,fill=0);mask=mask.filter(ImageFilter.GaussianBlur(.7))
    # Legacy door is replaced by E02 structure; no unreferenced transition prop.
    aa=np.array(im);aa[:,:,3]=(aa[:,:,3].astype(float)*np.array(mask)/255).astype('uint8')
    # A bounded auxiliary water selection above the authored road, not global
    # chroma key: ivory flora and all pixels below the walking surface survive.
    yy,xx=np.mgrid[:im.height,:im.width]
    lip=np.array([sample(ROOMS[2]['surfaces'][0],x-16)+16 for x in range(im.width)])
    water_zone=(xx<1120)&(yy<lip[None,:]-3)&(yy>450)
    rgb=aa[:,:,:3].astype(float)
    blue=np.clip((rgb[:,:,2]-rgb[:,:,0]*1.2)/12,0,1)*np.clip((rgb[:,:,1]-rgb[:,:,0]*1.12)/12,0,1)
    # Operator-authored zone and selection both retained as editable masks.
    selection=(blue*water_zone)
    Image.fromarray((selection*255).astype('uint8')).save(S/'masters/tongue-local-water-selection.png')
    aa[:,:,3]=(aa[:,:,3]*(1-selection)).astype('uint8')
    save(Image.fromarray(aa),'tongue-world-clean');mask.save(S/'masters/tongue-world-mask.png')
    im=Image.open(R/'game/art/r1-chapter-scenes/R1-03/Middle.png').convert('RGBA')
    mask=Image.new('L',im.size,255);d=ImageDraw.Draw(mask)
    d.polygon([(0,130),(28,150),(45,180),(55,220),(65,260),(80,285),(100,300),(125,315),(160,325),(185,340),(220,350),(260,363),(310,370),(360,375),(430,380),(500,380),(550,400),(550,im.height),(0,im.height)],fill=0)
    aa=np.array(im);aa[:,:,3]=(aa[:,:,3].astype(float)*np.array(mask.filter(ImageFilter.GaussianBlur(1)))/255).astype('uint8')
    save(Image.fromarray(aa),'tongue-middle-clean');mask.save(S/'masters/tongue-middle-mask.png')

if __name__=='__main__':
    config={}
    config['E02']=main_edge('E02',1,626.847,3310,3029)
    clean_e02_room_layers()
    write(S/'masters/placements.json',config)
    write(S/'masters/export-hashes.json',{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in O.glob('*.png')})
