from pathlib import Path
import urllib.request, json, shutil, hashlib

ROOT=Path(__file__).resolve().parent
SOURCE=Path('G:/鲸落万物生/outputs/whalefall-12-concepts')
PUBLIC=ROOT/'public'
PUBLIC.mkdir(exist_ok=True)
for name in ['index.html','concepts.json','references.json','image-prompts.json','鲸落_12种游戏策划.md']:
    shutil.copy2(SOURCE/name,PUBLIC/name)
shutil.copytree(SOURCE/'assets',PUBLIC/'assets',dirs_exist_ok=True)
req=urllib.request.Request('https://api.github.com/repos/cloudflare/cloudflared/releases/latest',headers={'User-Agent':'whalefall-share'})
release=json.load(urllib.request.urlopen(req,timeout=30))
asset=next(a for a in release['assets'] if a['name']=='cloudflared-windows-amd64.exe')
target=ROOT/'cloudflared.exe'
if not target.exists():
    urllib.request.urlretrieve(asset['browser_download_url'],target)
digest='sha256:'+hashlib.sha256(target.read_bytes()).hexdigest()
expected=asset.get('digest')
if expected and digest!=expected: raise RuntimeError('Binary digest mismatch')
print(json.dumps({'version':release['tag_name'],'digest':digest,'verified':bool(expected),'public':str(PUBLIC)},ensure_ascii=False))
