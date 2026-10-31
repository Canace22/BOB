"""Build editable timeline from Krita-encoded paint layers; verify by Krita export.

Krita CLI converts layered ORA into native tiles. This script only assembles the
animation XML and relocates native layer payloads; it does not invent tile data.
"""
from pathlib import Path
import zipfile, xml.etree.ElementTree as ET, json, re, subprocess
from baleen_keyart_v2 import OUT, ROOT, write

KRITA=ROOT/'work/wan22-production/krita/krita-x64-5.3.4.1/bin/krita.exe'
RES=ROOT/'work/wan22-production/krita-keyart-resources'
NS='http://www.calligra.org/DTD/krita'
KNS='http://www.calligra.org/DTD/krita-keyframes'

def native_convert(source,target):
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
    p=subprocess.run([str(KRITA),'--nosplash','--resource-location',str(RES),'--export','--export-filename',str(target),str(source)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,startupinfo=si,timeout=150)
    (OUT/'metadata'/(target.stem+'-native.log')).write_bytes(p.stdout+p.stderr)
    if p.returncode or not target.exists():raise RuntimeError(f'Krita conversion failed: {p.returncode} {target}')

def prepare():
    files=sorted((OUT/'frames').glob('*.png'))
    doc=ET.Element('image',{'w':'384','h':'384','name':'BaleenFrames','version':'0.0.3'});stack=ET.SubElement(doc,'stack')
    with zipfile.ZipFile(OUT/'frames-layered.ora','w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,file in enumerate(files):
            path=f'data/frame{i:04d}.png';z.write(file,path)
            ET.SubElement(stack,'layer',{'name':f'Frame {i:04d}','src':path,'opacity':'1.0','visibility':'visible' if i==0 else 'hidden','composite-op':'svg:src-over','x':'0','y':'0'})
        z.writestr('stack.xml',ET.tostring(doc,encoding='utf-8'));z.write(files[0],'mergedimage.png')
    native_convert(OUT/'keyposes-layered.ora',OUT/'krita/baleen-keyposes.kra')
    native_convert(OUT/'frames-layered.ora',OUT/'krita/baleen-frames-native-layers.kra')
    print('NATIVE_LAYERS_SAVED',flush=True)

def assemble():
    ET.register_namespace('',NS)
    with zipfile.ZipFile(OUT/'krita/baleen-frames-native-layers.kra') as z:
        tree=ET.fromstring(z.read('maindoc.xml'))
        image=tree.find(f'{{{NS}}}IMAGE')
        source_prefix=next(n.split('/layers/')[0] for n in z.namelist() if '/layers/' in n)
        name='BaleenSway';image.set('name',name)
        layers=image.find(f'{{{NS}}}layers')
        old=sorted(list(layers),key=lambda e:int(e.attrib['name'].split()[-1]))
        source_root=source_prefix+'/layers/'
        root_name=name+'/layers/'
        first=old[0]
        native_name=first.attrib['filename']
        first.set('name','Painted keys + Wan refinement - RGBA sway 12 FPS')
        first.set('keyframes',native_name+'.keyframes.xml');first.set('visible','1');first.set('selected','true');first.set('intimeline','1')
        for e in list(layers):layers.remove(e)
        layers.append(first)
        for item in list(image):
            if item.tag==f'{{{NS}}}animation':image.remove(item)
        anim=ET.SubElement(image,f'{{{NS}}}animation')
        ET.SubElement(anim,f'{{{NS}}}framerate',{'value':'12','type':'value'})
        ET.SubElement(anim,f'{{{NS}}}range',{'from':'0','to':str(len(old)-1),'type':'timerange'})
        ET.SubElement(anim,f'{{{NS}}}currentTime',{'value':'0','type':'value'})
        keys=ET.Element('keyframes',{'xmlns':KNS});channel=ET.SubElement(keys,'channel',{'name':'content'})
        with zipfile.ZipFile(OUT/'krita/baleen-sway-12fps.kra','w',zipfile.ZIP_DEFLATED) as dest:
            for file in z.namelist():
                if file=='maindoc.xml' or file.startswith(source_root) or '/animation/' in file:continue
                renamed=file.replace(source_prefix+'/',name+'/',1) if file.startswith(source_prefix+'/') else file
                dest.writestr(renamed,z.read(file))
            for i,layer in enumerate(old):
                source=layer.attrib['filename'];target=native_name if i==0 else f'{native_name}.f{i}'
                key=ET.SubElement(channel,'keyframe',{'color-label':'0','time':str(i),'frame':target})
                ET.SubElement(key,'offset',{'x':'0','y':'0','type':'point'})
                for file in z.namelist():
                    if file==source_root+source or file.startswith(source_root+source+'.'):
                        suffix=file[len(source_root+source):]
                        # Each frame retains its native pixel/default data; one profile on the layer.
                        if suffix=='.icc' and i!=0:continue
                        dest.writestr(root_name+target+suffix,z.read(file))
            dest.writestr('maindoc.xml',b'<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE DOC PUBLIC "-//KDE//DTD krita 2.0//EN" "http://www.calligra.org/DTD/krita-2.0.dtd">\n'+ET.tostring(tree,encoding='utf-8'))
            dest.writestr(root_name+native_name+'.keyframes.xml',ET.tostring(keys,encoding='utf-8'))
            metadata=ET.Element('animation-metadata',{'xmlns':NS})
            ET.SubElement(metadata,'framerate',{'value':'12','type':'value'})
            ET.SubElement(metadata,'range',{'from':'0','to':str(len(old)-1),'type':'timerange'})
            ET.SubElement(metadata,'currentTime',{'value':'0','type':'value'})
            dest.writestr(name+'/animation/index.xml',ET.tostring(metadata,encoding='utf-8'))
    write(OUT/'metadata/krita-results.json',{'status':'native_layer_conversion_and_timeline_assembled','key_art_layers':6,'animation_keyframes':48,'fps':12,'method':'Actual Krita CLI ORA-to-KRA native tiles, timeline XML assembly; pending Krita full sequence roundtrip'})
    print('ANIMATION_ASSEMBLED',flush=True)

def verify():
    dest=OUT/'review/krita-roundtrip';dest.mkdir(exist_ok=True)
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
    p=subprocess.run([str(KRITA),'--nosplash','--resource-location',str(RES),'--export-sequence','--export-filename',str(dest/'frame.png'),str(OUT/'krita/baleen-sway-12fps.kra')],stdout=subprocess.PIPE,stderr=subprocess.PIPE,startupinfo=si,timeout=150)
    (OUT/'metadata/krita-roundtrip.log').write_bytes(p.stdout+p.stderr)
    count=len(list(dest.glob('*.png')))
    if p.returncode!=0 or count!=48:raise RuntimeError(f'Krita roundtrip failed: exit={p.returncode}, frames={count}')
    print('ROUNDTRIP',p.returncode,count,flush=True)

if __name__=='__main__':
    import sys
    globals()[sys.argv[1]]()
