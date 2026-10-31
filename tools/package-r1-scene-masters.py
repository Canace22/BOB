"""Package native exported layers into editable OpenRaster documents (Krita compatible).
No new pixels are painted here. The Godot exporter owns extraction and hidden-pixel margins.
"""
import json, pathlib, zipfile, xml.etree.ElementTree as ET
root = pathlib.Path(__file__).resolve().parents[1]
spec = json.loads((root/'assets/source/r1-chapter-scenes/chapter.json').read_text(encoding='utf-8'))
for room in spec['rooms']:
    directory = root/room['runtime']
    if not (directory/'World.png').exists():
        continue
    index = json.loads((root/room['master']/'export-map.json').read_text(encoding='utf-8'))
    positions = {e['id']:e['origin'] for e in index['elements']}
    image = ET.Element('image', {'w':str(int(room['size'][0])),'h':str(int(room['size'][1])),'name':room['id']+' editable original-pixel layers','version':'0.0.3'})
    stack = ET.SubElement(image,'stack')
    selections=[]
    for layer in ['Foreground','World','Middle','Far']:
        for e in reversed(room['elements']):
            if e['layer'] == layer and e['kind'] in ['flex','lamp']:
                selections.append((e['id'],directory/(e['id']+'.png'),positions[e['id']]))
        selections.append((layer,directory/(layer+'.png'),[-16,-16]))
    selections.append(('hidden-surface-underpaint',directory/'underpaint.png',[-16,-16]))
    destination = root/room['master']/(room['id']+'-layers.ora')
    with zipfile.ZipFile(destination,'w') as archive:
        archive.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(name,path,position) in enumerate(selections):
            source = f'data/layer{i:03}.png'
            archive.write(path,source)
            ET.SubElement(stack,'layer',{'name':name,'src':source,'x':str(position[0]),'y':str(position[1]),'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
        archive.writestr('stack.xml',ET.tostring(image,encoding='utf-8',xml_declaration=True))
        archive.writestr('production.json',json.dumps({'element_spec':room,'export_map':index},ensure_ascii=False,indent=2))
    print(destination.relative_to(root))
