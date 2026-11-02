"""Crop generated heavy poses and call existing Framecraft BiRefNet lite API unchanged."""
from pathlib import Path
from PIL import Image
import json,urllib.request,uuid,time,hashlib
P=Path(__file__).resolve().parent
src=P/'raw/heavy-v01-background-source.png';im=Image.open(src)
boxes=[(0,0,820,566),(820,0,1536,566),(0,566,850,1024),(850,566,1536,1024)]
O=P/'heavy/matting';O.mkdir(parents=True,exist_ok=True)
options={'mode':'birefnet','device':'cpu','resolution':'1024','birefnet_variant':'lite','key_color':'#426d6f','spill':'0'}
for i,box in enumerate(boxes):
 original=O/f'source-{i:02}.png';target=O/f'pose-{i:02}.png';im.crop(box).save(original)
 boundary=uuid.uuid4().hex;parts=[]
 for key,value in options.items():parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode())
 parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{original.name}"\r\nContent-Type: image/png\r\n\r\n'.encode()+original.read_bytes()+b'\r\n')
 parts.append(f'--{boundary}--\r\n'.encode())
 req=urllib.request.Request('http://127.0.0.1:8766/api/matte',data=b''.join(parts),headers={'Content-Type':f'multipart/form-data; boundary={boundary}'})
 t=time.monotonic()
 with urllib.request.urlopen(req,timeout=600) as response:target.write_bytes(response.read());headers=dict(response.headers)
 out=Image.open(target);assert out.size==im.crop(box).size
 record={'source':str(src.relative_to(P)),'crop':box,'request':options,'endpoint':'http://127.0.0.1:8766/api/matte','elapsedSeconds':round(time.monotonic()-t,3),'sourceSHA256':hashlib.sha256(original.read_bytes()).hexdigest(),'resultSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),'alphaRange':out.getchannel('A').getextrema(),'headers':headers}
 (O/f'pose-{i:02}.json').write_text(json.dumps(record,indent=2)+'\n');print(i,record['elapsedSeconds'],out.size,flush=True)
