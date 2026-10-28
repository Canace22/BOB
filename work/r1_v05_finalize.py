from pathlib import Path
import json, datetime, hashlib, subprocess, shutil
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit

root=Path('G:/鲸落万物生')
p=root/'BOB/godot/WhalebellyRuins'
out=root/'outputs/须门遗港_v0.5_参考图可玩关卡'
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]
    def handle_starttag(self,tag,attrs):
        for k,v in attrs:
            if k in ('src','href') and v: self.links.append(v)
page=out/'交付与验收.html'
parser=Links();parser.feed(page.read_text('utf8'))
missing=[]
for link in parser.links:
    u=urlsplit(link)
    if u.scheme or not u.path: continue
    target=page.parent/unquote(u.path)
    if not target.exists(): missing.append(str(target))
manifest=json.loads((p/'docs/element-manifest.json').read_text('utf8'))
counts={}
for e in manifest['elements']:
    for d in e['dimensions'].values():
        if isinstance(d,dict) and d.get('requirement')=='required':
            s=d['status'];counts[s]=counts.get(s,0)+1
normal=json.loads((p/'evidence/package-normal/normal-run.json').read_text('utf8'))
reload=json.loads((p/'evidence/package-reload/normal-reload.json').read_text('utf8'))
native=json.loads((p/'docs/native-export.json').read_text('utf8'))
assert normal['pass'] and all(t.get('pass') for t in normal['tests'])
assert reload['pass'] and len(native)==43
for item in native:
    artifact=p/item['path'].removeprefix('res://')
    assert artifact.is_file() and artifact.stat().st_size>100, str(artifact)
assert not missing,missing
timestamp=datetime.datetime.now().astimezone().isoformat()
check={'at':timestamp,'local_links_checked':len(parser.links),'missing':missing,'elements':len(manifest['elements']),'required_dimensions':counts,'native_exports':len(native),'normal_tests':len(normal['tests']),'normal_pass':normal['pass'],'independent_reload_pass':reload['pass'],'visual_review':'Seven composites and representative moving camera screenshots reviewed separately; HTML links checked statically, not browser-rendered.'}
(p/'evidence/delivery-integrity.json').write_text(json.dumps(check,ensure_ascii=False,indent=2),encoding='utf8')
state={'version':'0.5','updated_at':timestamp,'workflow':'reference-to-complete-playable-level','stage':'final_acceptance','status':'blocked','overall_accepted':False,'scope':'R1-01 至 R1-07 参考图可见七房；正常首关主路与后续能力回访练习','engine':'4.7.2.stable.official.ed1daf0bf','project':str(p/'project.godot'),'delivery':str(page),'build':str(root/'builds/须门遗港-v0.5-参考图可玩关卡/Whalefall.exe'),'coverage':check,'stages':[{'id':'R0','name':'输入与引擎固定','status':'pass'},{'id':'R1','name':'九宫格/边缘/层级扫描与元素合同','status':'pass'},{'id':'R2','name':'原件/遮罩/补绘母版/运行分层','status':'pass'},{'id':'R3','name':'固定机位七房画面对照','status':'pass'},{'id':'R4','name':'动态/碰撞/交互/声音事件/保存接入','status':'pass'},{'id':'R5','name':'逐元素和机制验证','status':'pass'},{'id':'R6','name':'正常首访/支路/恢复/独立重载','status':'pass'},{'id':'R7','name':'独立包与本机性能','status':'pass'},{'id':'R8','name':'整体验收','status':'blocked'}],'blockers':[{'id':'WINDOWS_AUDIO_OUTPUT','reason':'Godot WASAPI ERR_CANT_OPEN，回落Dummy；音频服务运行，设备可见不足以证明输出成功。','evidence':'evidence/audio-devices.log','resolution':'确认可用Windows默认播放设备，再运行真实音频设备/混音和独立包声音测试；不得用Dummy关闭此项。'}],'limitations':['远景独显有少量原遮挡细节叠层；连续补绘母版另存，不声称恢复不存在的原始隐藏分层。','原图静态鱼群/光点与新增动态生成器分别登记；并非每个原画像素独立运动。','A2/A3为后续章节回访能力，本范围以F9明示临时练习验证。','历史强制quit-after绕开正常关闭清理警告保留；正常关闭证据单列。'],'next_instruction':'读取RESUME.md和docs/coverage-readiness.md；等待设备侧信息，恢复实际Windows音频输出后仅复验受影响项目。保留已通过七房与旧v0.4，不重做已验收素材。','evidence_root':str(p/'evidence')}
state['stages'][2]['status']='rework'
state['global_acceptance']=manifest.get('global_acceptance',[])
state['limitations'].insert(0,'独立可玩层拆件仍残留平台/锚环周边原图背景；精细分层资产验收未通过，不能仅凭合成画面通过视为完成。')
state['rework']=[{'id':'LAYER_EDGE_CLEANUP','status':'open','evidence':'assets/runtime/layers/R1-02/World.png','instruction':'针对平台/锚环周边蓝色背景逐物件制作精细透明边缘；避免再次全局色键破坏组织。复验独显、原图合成与最大视差机位，再导出受影响资产与PCK。','prior_attempts':'全局色键曾破坏暗组织，已回退；广泛替换远景产生接缝，已回退。'}]
state['blockers'].append({'id':'WINDOW_CLOSE_DESKTOP','reason':'最终便携包真实窗口关闭复验时交互桌面拒绝访问；自动测试正常退出已验，实际窗口关闭未验。','resolution':'交互桌面可访问后重跑正常窗口关闭验证。'})
state['next_instruction']='先读取RESUME.md及coverage-readiness.md。独立分层边缘定向返修与设备音频复验分别接续；保留已通过玩法和旧v0.4，不批量重做原图。音频需设备侧信息，不得用Dummy关闭阻塞。'
for rel in ['scripts/main.gd','scripts/player.gd','scripts/environment.gd','scripts/mechanisms.gd','scripts/layer.gdshader','assets/rooms.json']:
    state.setdefault('frozen_sha256',{})[rel]=hashlib.sha256((p/rel).read_bytes()).hexdigest()
(p/'.production/state.json').write_text(json.dumps(state,ensure_ascii=False,indent=2),encoding='utf8')
build=root/'builds/须门遗港-v0.5-参考图可玩关卡'
instructions=build/'操作说明.txt'
note='\n最终复查未完成项：平台/锚环独立分层边缘仍夹带原图背景，须继续精修；本次真实窗口关闭复验受交互桌面拒绝访问阻挡，自动测试正常退出不代表窗口关闭已验。\n'
content=instructions.read_text('utf8')
if '最终复查未完成项' not in content: instructions.write_text(content+note,encoding='utf8')
bm=json.loads((p/'docs/build-manifest.json').read_text('utf8'))
bm['files']=[{'name':f.name,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in build.iterdir() if f.is_file()]
for target in [p/'docs/build-manifest.json',out/'docs/build-manifest.json']:target.write_text(json.dumps(bm,ensure_ascii=False,indent=2),encoding='utf8')
shutil.make_archive(str(build),'zip',build)
print(json.dumps(check,ensure_ascii=False,indent=2))
