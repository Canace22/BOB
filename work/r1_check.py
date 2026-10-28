from pathlib import Path
import json,hashlib,re,xml.etree.ElementTree as ET
from html.parser import HTMLParser
from PIL import Image
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
d=json.loads((p/'data/r1-design.json').read_text('utf8'));a=json.loads((p/'data/elements.json').read_text('utf8'))
class Check(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  at=dict(attrs)
  if 'id'in at:self.ids.append(at['id'])
  for key in ['src','href']:
   if key in at:self.links.append(at[key])
c=Check();c.feed((p/'首关全景与拆解册.html').read_text('utf8'))
missing=[]
for ref in c.links:
 if ref.startswith('#'):
  if ref[1:]not in c.ids:missing.append(ref)
 elif not (p/ref).exists():missing.append(ref)
imgs=[]
for file in sorted((p/'images').glob('*.png')):
 im=Image.open(file);im.verify();im=Image.open(file)
 imgs.append({'path':file.relative_to(p).as_posix(),'width':im.width,'height':im.height,'mode':im.mode,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
for file in (p/'maps').glob('*.svg'):ET.parse(file)
checks={'seven_rooms':len(d['rooms'])==7,'two_revisit':len(d['scope']['revisit'])==2,'assets_33':len(a['assets'])==33,'unique_asset_ids':len({x['id']for x in a['assets']})==33,'unique_html_ids':len(set(c.ids))==len(c.ids),'images_valid':len(imgs)==4,'eight_svg_valid':len(list((p/'maps').glob('*.svg')))==8,'links_valid':len(missing)==0}
(p/'data/validation.json').write_text(json.dumps({'checks':checks,'missing_links':missing,'images':imgs,'browser_preview':'not_run: CUA security policy rejected file://; no workaround attempted','engine_integration':'not_applicable: design-only scope'},ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(checks))
assert all(v for k,v in checks.items() if k!='links_valid')
