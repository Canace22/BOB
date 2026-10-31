"""Read-only verification: validate current runtime pixels against source crops."""
import hashlib,json,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
out=root/'.production/tide-main-integration'
m=json.loads((root/'assets/animations/player/manifest.json').read_text(encoding='utf-8'))
source=Path(m['source']);issues=[];count=0
for action,entry in m['actions'].items():
    if len(entry['frames'])!=36:issues.append([action,'frame_count'])
    for f in entry['frames']:
        name=f"{f['frame']:03}.png"
        if hashlib.sha256((source/'frames'/action/name).read_bytes()).hexdigest()!=f['source_sha256']:issues.append([action,name,'source_changed'])
        pairs=[('frames',action),('character','body/'+action)]
        if action in ['heavy','A1_dash','A2_float','A3_anchor','A4_parry']:pairs.append(('fx','effects/'+action))
        for a,b in pairs:
            with Image.open(source/a/action/name) as im, Image.open(root/'assets/animations/player'/b/name) as current:
                expected=im.convert('RGBA').crop(f['crop'])
                if current.size!=tuple(m['size']) or current.convert('RGBA').tobytes()!=expected.tobytes():issues.append([b,name,'pixel_mismatch'])
            count+=1
report={'images_checked':count,'actions':len(m['actions']),'issues':issues,'pass':not issues,'method':'exact RGBA bytes versus unchanged source crop; no image writes'}
(out/'assets-current.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False));sys.exit(bool(issues))
