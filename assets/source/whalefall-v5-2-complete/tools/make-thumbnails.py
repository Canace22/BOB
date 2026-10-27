"""Non-destructive gallery previews. Requires Pillow; the manager has no runtime dependency."""
from pathlib import Path
from PIL import Image
import json,os,datetime
root=Path(__file__).resolve().parents[4];file=root/'assets/catalog.json';catalog=json.loads(file.read_text());out=root/'assets/source/whalefall-v5-2-complete/thumbnails';out.mkdir(parents=True,exist_ok=True)
for asset in catalog['assets']:
 dest=out/f"{asset['id']}-{asset['sha256'][:12]}.png"
 if not dest.exists():
  im=Image.open(root/asset['file']).convert('RGBA').crop(tuple(asset['bbox']));im.thumbnail((448,308),Image.Resampling.LANCZOS)
  preview=Image.new('RGBA',(480,340));preview.alpha_composite(im,((480-im.width)//2,(340-im.height)//2));preview.save(dest)
 asset['thumbnail']=str(dest.relative_to(root))
catalog['revision']+=1;catalog['updatedAt']=datetime.datetime.now(datetime.timezone.utc).isoformat();tmp=file.with_suffix('.json.thumbnails');tmp.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n');os.replace(tmp,file)
print(json.dumps({'thumbnails':len(catalog['assets']),'revision':catalog['revision']}))
