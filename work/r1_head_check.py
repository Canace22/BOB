from pathlib import Path
import base64,json,xml.etree.ElementTree as ET
from html.parser import HTMLParser
from PIL import Image
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
f=p/'maps/head-cutaway-labeled-v2.svg';s=f.read_text('utf8');s=s.replace('../images/head-cutaway-v2.png','data:image/png;base64,'+base64.b64encode((p/'images/head-cutaway-v2.png').read_bytes()).decode());f.write_text(s,encoding='utf8');ET.parse(f)
class Check(HTMLParser):
 def __init__(self):super().__init__();self.refs=[];self.ids=[]
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if 'id'in a:self.ids.append(a['id'])
  self.refs.extend(a[k]for k in ['src','href']if k in a)
c=Check();c.feed((p/'首关全景与拆解册.html').read_text('utf8'))
missing=[r for r in c.refs if (r.startswith('#') and r[1:]not in c.ids)or(not r.startswith('#') and not (p/r).exists())]
Image.open(p/'images/head-cutaway-v2.png').verify()
result={'new_image_valid':True,'annotation_svg_valid':True,'svg_background_embedded':True,'head_image_referenced': 'images/head-cutaway-v2.png' in c.refs,'old_image_preserved':(p/'images/panorama.png').exists(),'missing':missing,'duplicate_ids':len(c.ids)!=len(set(c.ids)),'browser_preview':'not_run; prior local-file security rejection respected'}
(p/'data/head-validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(result))
