from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote,quote
from urllib.request import Request,urlopen
from concurrent.futures import ThreadPoolExecutor
import shutil,json,hashlib

SOURCE=Path('C:/Users/Kingsoft/Documents/Codex/2026-10-16/new-chat-2/outputs/鲸腹遗城原画集')
TARGET=Path(__file__).resolve().parent/'public'/'whale-city-art'
TARGET.mkdir(exist_ok=True)
class References(HTMLParser):
    def __init__(self):super().__init__();self.paths=set();self.images=set()
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        for key in ('src','href'):
            value=a.get(key,'');u=urlsplit(value)
            if value and not u.scheme and not u.netloc and u.path:
                p=unquote(u.path);self.paths.add(p)
                if tag=='img':self.images.add(p)
parser=References()
source_html=SOURCE/'原画册.html'
parser.feed(source_html.read_text(encoding='utf-8'))
for name in sorted(parser.paths):
    src=(SOURCE/name).resolve()
    if not src.is_relative_to(SOURCE.resolve()):raise RuntimeError('Out-of-directory dependency: '+name)
    if not src.is_file():raise RuntimeError('Missing dependency: '+name)
    dest=TARGET/name;dest.parent.mkdir(exist_ok=True,parents=True)
    shutil.copy2(src,dest)
    assert hashlib.sha256(src.read_bytes()).digest()==hashlib.sha256(dest.read_bytes()).digest()
shutil.copy2(source_html,TARGET/'index.html')
base='http://10.11.140.20:8876/whale-city-art/'
def check(name):
    with urlopen(Request(base+quote(name),method='HEAD'),timeout=20) as response:
        return {'file':name,'status':response.status,'size':response.headers.get('Content-Length')}
with ThreadPoolExecutor(max_workers=4) as pool:
    result=list(pool.map(check,['index.html']+sorted(parser.paths)))
report={'url':base+'index.html','images':len(parser.images),'checks':result,'source':str(source_html)}
(Path(__file__).resolve().parent/'artbook-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'url':report['url'],'image_count':len(parser.images),'all_http_200':all(x['status']==200 for x in result),'file_count':len(result)},ensure_ascii=False))
