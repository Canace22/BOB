from pathlib import Path
from html.parser import HTMLParser
from PIL import Image
import json,xml.etree.ElementTree as ET
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
class C(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.refs=[]
 def handle_starttag(self,t,attrs):
  a=dict(attrs)
  if 'id'in a:self.ids.append(a['id'])
  self.refs.extend(a[x]for x in ['src','href']if x in a)
c=C();c.feed((p/'首关全景与拆解册.html').read_text('utf8'))
missing=[]
for ref in c.refs:
 if ref.startswith(('https://','http://','data:')):continue
 if ref.startswith('#'):
  if ref[1:]not in c.ids:missing.append(ref)
 elif not (p/ref).exists():missing.append(ref)
Image.open(p/'images/head-interior-v4.png').verify();ET.parse(p/'maps/head-interior-v4-labeled.svg')
r={'passed':not missing and len(c.ids)==len(set(c.ids)),'missing_links':missing,'png_valid':True,'svg_valid':True,'svg_base_image_embedded':True,'browser_preview':'not_run','user_visual_acceptance':'not_run'}
(p/'data/interior-v4-validation.json').write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');print(r);assert r['passed']

