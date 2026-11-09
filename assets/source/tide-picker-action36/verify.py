"""Verify real atlas bytes/rectangles/alpha. This does not judge animation quality."""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image

BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
RUNTIME=REPO/'assets/runtime/sprites/tide-picker-action36'

def main():
    source=json.loads((BASE/'inputs/actions.json').read_text(encoding='utf-8'))
    data=json.loads((RUNTIME/'animations.json').read_text(encoding='utf-8'))['actions']
    errors=[];warnings=[];rows=[];unique_files={}
    expected={a['key'] for a in source}
    if set(data)!=expected:errors.append({'keys_missing':sorted(expected-set(data)),'keys_extra':sorted(set(data)-expected)})
    for key,a in data.items():
        row={'key':key,'status':a['status'],'frames':a['frame_count'],'layers':{}}
        source_frames=a.get('source_seconds',a.get('source_cells',[]))
        if len(source_frames)!=a['frame_count']:errors.append(key+': source/frame count mismatch')
        for layer in ['body','fx']:
            spec=a.get(layer)
            if spec is None:
                if layer=='body':errors.append(key+': missing body')
                continue
            path=RUNTIME/Path(spec['texture']).name
            if not path.exists():errors.append(str(path));continue
            digest=hashlib.sha256(path.read_bytes()).hexdigest()
            unique_files[path.name]=path.stat().st_size
            if digest!=spec['sha256']:errors.append(key+': '+layer+' SHA256 mismatch')
            im=Image.open(path).convert('RGBA');alpha=np.asarray(im)[:,:,3]
            if list(im.size)!=spec['size']:errors.append(key+': '+layer+' size mismatch')
            if len(spec['frames'])!=spec.get('frame_count',a['frame_count']):errors.append(key+': '+layer+' rectangle count mismatch')
            if 'event_frame' in spec and not 0<=spec['event_frame']<len(spec['frames']):errors.append(key+': '+layer+' invalid event frame')
            clipped=[];empty=[]
            for i,(x,y,w,h) in enumerate(spec['frames']):
                if min(x,y,w,h)<0 or w==0 or h==0 or x+w>im.width or y+h>im.height:
                    errors.append(key+': invalid rectangle '+str(i));continue
                tile=alpha[y:y+h,x:x+w]
                if tile.max()==0:empty.append(i)
                edge=np.concatenate([tile[0],tile[-1],tile[:,0],tile[:,-1]])
                if edge.max()>8:clipped.append(i)
            if layer=='body' and empty:errors.append(key+': empty body frames '+str(empty))
            if clipped:warnings.append(key+': '+layer+' visible pixels touch frame border '+str(clipped))
            row['layers'][layer]={'bytes':path.stat().st_size,'size':list(im.size),'sha256':digest,'border_frames':clipped,'empty_frames':empty}
        rows.append(row)
    output=REPO/'game/build/qa/action36/atlas-integrity.json'
    output.parent.mkdir(parents=True,exist_ok=True)
    report={'scope':'Atlas byte/rectangle/alpha integrity only; not gameplay or art acceptance','actions':rows,'errors':errors,'warnings':warnings,'bytes':sum(unique_files.values()),'unique_atlases':len(unique_files),'referenced_layer_bytes':sum(v['bytes'] for row in rows for v in row['layers'].values())}
    output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps({'actions':len(rows),'errors':errors,'warnings':warnings,'MiB':report['bytes']/1048576},ensure_ascii=False))
    if errors:raise SystemExit(1)

if __name__=='__main__':main()
