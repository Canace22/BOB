from pathlib import Path
import json,html,hashlib,shutil,zipfile
p=Path('G:/鲸落万物生/BOB/godot/first-level');b=Path('G:/鲸落万物生/builds/须门遗港-v0.3-场景还原');out=Path('G:/鲸落万物生/outputs/须门遗港_首关场景_v0.3');out.mkdir(parents=True,exist_ok=True)
def read(name):return json.loads((p/name).read_text('utf-8-sig'))
processes=read('docs/v03/final-qa-processes.json');assert len(processes)==3 and all(x['exit_code']==0 and not x['error_in_log']for x in processes),processes
paths={'seven_room_scenery':'evidence/v03/scenery-pack/scenery.json','five_room_completion':'evidence/v03/play-final/prototype.json','save_reload':'evidence/v03/reload-final/persistence.json','branch':'evidence/v03/branch/branch.json','latch_reload':'evidence/v03/latch-reload/latch-reload.json','death_recovery':'evidence/v03/recover/combat.json'}
qa={k:{'passed':read(v)['passed'],'evidence':v}for k,v in paths.items()};assert all(v['passed']for v in qa.values())
qa['processes']=processes;qa['performance']=read('evidence/v03/play-final/performance.json');qa['human_review']='not_run';qa['audio_listening']='not_run; reused previous audio';qa['build_type']='official Godot4.7.2 portable executable plus project PCK; export templates absent'
(p/'docs/v03/qa-summary.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2),encoding='utf8')
controls='''须门遗港 v0.3 · 首关场景还原

运行：双击 Whalefall.exe，Whalefall.pck 必须留在旁边。无需另装Godot。
场景巡览：双击“场景巡览.cmd”，或游戏内按 F6。
巡览中：数字1～7切换房间；W A S D移动镜头；Tab打开鲸头全景位置图，可点房间；F6返回游戏（正在进行的战斗会重新入场）。巡览不写正常存档。
普通游戏：A/D或左右移动，Space跳跃，Q短击，R重鸣，F调息，E交互，L灯罩，Shift冲刺（Boss后解锁），Tab地图，Esc暂停。
暂停：C回营地；F2两次确认重开会清除当前正常进度。

范围：七房美术场景均已制作，01～05保留实际可玩首通流程。06/07是后续能力回访房，本包可完整巡览，不代表后续A2/A3章节已实现。
正常存档沿用 %APPDATA%/WhalefallFirstLevel/save-v1.json。自动验收用独立save-qa.json。
可编辑工程：G:/鲸落万物生/BOB/godot/first-level/project.godot
房间场景：scenes/r1/R1-01.tscn～R1-07.tscn，四个分层节点可编辑。

本包使用已安装官方Godot4.7.2便携引擎及PCK，不是精简导出模板；该机未安装模板。许可证随包。
已验证：七房实际渲染、切房/返回、五房输入驱动通关、支路/开闩/死亡恢复和跨进程重载。非真人试玩结论。
仍可完善：现有角色/Boss连续动作、手工地形变体、精细材质接缝、低配机测试与主观音效试听。
'''
(b/'操作说明.txt').write_text(controls,encoding='utf-8-sig')
(b/'场景巡览.cmd').write_text('@echo off\ncd /d "%~dp0"\nstart "" "Whalefall.exe" -- --scene-tour\n',encoding='ascii')
resume='''# v0.3 接续：七房场景还原

正式工程：G:/鲸落万物生/BOB/godot/first-level/project.godot；固定Godot4.7.2 Compatibility。独立包：G:/鲸落万物生/builds/须门遗港-v0.3-场景还原/Whalefall.exe。交付册：G:/鲸落万物生/outputs/须门遗港_首关场景_v0.3/场景交付册.html。

先运行 tools/ledger.cjs status/next 检查最新账本，读 docs/v03/specification.md、scene-manifest.json、qa-summary.json。旧v0.2账本已归档production-history/v02-ledger；旧脚本/场景完整备份 G:/鲸落万物生/BOB/work/r1-before-scene-v03.zip，旧运行包未改。

新增五类位图：assets/source/v03保存原件，master/v03为未破坏副本，runtime/v03为运行资源；提示在docs/v03/generation-prompts.json，来源/alpha/hash在assets.json。完整场景可直接编辑scenes/r1，脚本绑定碰撞/主体角色；work/r1_scene_build.py可重建，但会覆盖场景人工改动，改前比对。

F6进入只读巡览，数字1～7切房，WASD镜头，Tab全景，F6返回。01～05正常玩法；06/07场景完整但未来能力逻辑未接入。不要把巡览截图标记为七房全流程通关。

最终独立包证据：evidence/v03/play-final、reload-final、normal-final；七房及巡览控制：scenery-pack；支路branch、门闩重载latch-reload、死亡recover。QA存档与正常存档隔离。场景截图都是Godot实际渲染；音效复用旧版，未新增主观试听。

首次导出release缺少模板，已使用官方便携引擎+PCK；重复ShellHinge节点导致资源泄漏已修，QA退出时奖励音频未结束的问题也已修，旧失败日志保留。后续如果需要小体积发行包，再补同版本模板后导出并复验。
'''
(p/'RESUME-v03.md').write_text(resume,encoding='utf8')
(p/'RESUME.md').write_text('# 当前迭代\n\nv0.3七房场景还原，读[接续记录](RESUME-v03.md)。旧v0.2仍保留[记录](RESUME-v02.md)。先用tools/ledger.cjs status/next检查实际状态。\n',encoding='utf8')
delivery=f'''# 须门遗港 v0.3 场景交付

七房场景已按首关图册装配到现有Godot工程：张开的上颚/下颌、须幕、舌台、两间能力回访房、Boss场地与咽后食管。每房独立.tscn、四层节点、真实平台碰撞。原五房可玩流程保留，新增F6巡览与全景索引。

- 工程：{p}/project.godot
- 运行：{b}/Whalefall.exe
- 图文入口：{out}/场景交付册.html
- 验收：qa-summary.json，scene-review.md，sample-review.md

最终包已实际运行：七房检查{len(read(paths['seven_room_scenery'])['checks'])}项；五房输入驱动通关（含Boss与冲刺），跨进程存档重载；支路8项、死亡恢复及门闩重载通过。最终play/reload/normal三进程退出码0且日志无ERROR。首轮退出泄漏与缺少模板问题均留存日志并已采用已验证方案处理。

1280×720 / NVIDIA RTX5060 / Compatibility，最终通关帧时间P95={qa['performance']['p95_ms']:.2f}ms，最长={qa['performance']['max_ms']:.2f}ms；包含截图/切房长帧，不宣称恒定60FPS或低配表现。

06与07完整还原的是场景与空间构成，可巡览，未实现依赖下一章节的A2/A3能力获取及主线。美术采用独立模块还原，不是逐像素复制全景，模块衔接与连续角色动作仍可深化。人工审美/新音效试听/低配机未验证。

内置image_gen新增5件原始图，提示/来源/实际引用已记录；没有调用第三方收费服务，内置实际费用unknown。工程、原画、旧版本均保留，未对外发布。
'''
(p/'docs/v03/delivery.md').write_text(delivery,encoding='utf8')
# Build a self-contained screenshot gallery without modifying the actual screenshots.
(out/'screenshots').mkdir(exist_ok=True)
rooms=read('assets/rooms.json');cards=[]
for i,r in enumerate(rooms):
 name=r['id']+'-'+('left'if i==0 else 'middle')+'.png'
 shutil.copy2(p/'evidence/v03/scenery-pack'/name,out/'screenshots'/name)
 cards.append(f'<section id="room{i+1}"><p class="eyebrow">{r["id"]} · {"首通场景"if i<5 else "能力回访场景 / 巡览"}</p><h2>{html.escape(r["name"])}</h2><p>{html.escape(r["anatomy"]["part"])}</p><a href="screenshots/{name}" target="_blank"><img src="screenshots/{name}" alt="{r["name"]}Godot实机截图"></a></section>')
shutil.copy2(p/'evidence/v03/scenery-pack/head-atlas.png',out/'screenshots/head-atlas.png')
gameframe=sorted((p/'evidence/v03/play-final').glob('*room-1.png'))[0];shutil.copy2(gameframe,out/'screenshots/gameplay.png')
page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>须门遗港 · 场景交付 v0.3</title><style>*{box-sizing:border-box}body{margin:0;background:#071722;color:#dbe6e8;font:17px/1.8 "Microsoft YaHei",sans-serif}header,main{max-width:1400px;margin:auto;padding:35px 5vw}header{padding-top:65px}h1{font-size:46px;line-height:1.2;color:#f0d3a5}h2{font-size:29px;color:#e9c998}.eyebrow{letter-spacing:3px;color:#88beb9}a{color:#a4e4d3}nav{position:sticky;top:0;padding:14px;background:#102b36ee;display:flex;flex-wrap:wrap;gap:18px;z-index:2}section{padding:38px 0;scroll-margin-top:60px;border-top:1px solid #2b424b}img{width:100%;border-radius:12px}aside{background:#18313b;border-left:3px solid #c7a475;padding:18px 25px}.links{display:flex;gap:20px;flex-wrap:wrap}.links a{border:1px solid #52726f;padding:12px 18px;border-radius:7px}small{color:#8faab3}</style><header><p class="eyebrow">WHALEFALL / GODOT 4.7.2 / R1</p><h1>须门遗港<br>七房场景还原 · v0.3</h1><p>本页图片来自实际 Godot 运行。鲸头全景用于定位，各房间由独立分层素材、碰撞和动态节点组成。</p><div class="links"><a href="../../builds/须门遗港-v0.3-场景还原/Whalefall.exe">Windows 运行文件</a><a href="../../builds/须门遗港-v0.3-场景还原/场景巡览.cmd">直接场景巡览</a><a href="../../godot/first-level/project.godot">可编辑 Godot 工程</a><a href="../../builds/须门遗港-v0.3-场景还原/操作说明.txt">操作说明</a></div><p>F6 巡览／返回游戏 · 数字 1–7 切房 · WASD 平移巡览镜头 · Tab 全景位置图</p><aside>01–05 已运行通关；06、07 的完整场景可以巡览，后续 A2/A3 章节能力未接入。AI 目视审查不代表人工审美确认。</aside></header><nav>'''+''.join(f'<a href="#room{i+1}">{i+1} {html.escape(r["name"])}</a>'for i,r in enumerate(rooms))+'''</nav><main><section><h2>实际游戏画面</h2><img src="screenshots/gameplay.png"><h2>头部位置索引</h2><img src="screenshots/head-atlas.png"></section>'''+''.join(cards)+'''<section><h2>验证与后续</h2><p>已检查七房分层、碰撞、切房、巡览返回，以及五房首通、支路往返、死亡恢复、存档与壳闩重载。</p><p>便携包采用官方引擎＋PCK；不能分开 exe 与 pck。连续角色动画、更多地形变体、低配机和人工音效试听仍可继续完善。</p><a href="../../godot/first-level/docs/v03/delivery.md">完整交付与验证记录</a> · <a href="../../godot/first-level/RESUME-v03.md">制作流程接续</a></section></main></html>'''
(out/'场景交付册.html').write_text(page,encoding='utf8')
archive=b.parent/'须门遗港-v0.3-场景还原.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=5)as z:
 for file in b.iterdir():
  if file.is_file():z.write(file,file.name)
manifest={'files':[{'path':str(f),'size':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}for f in b.iterdir()if f.is_file()],'zip':str(archive),'zip_size':archive.stat().st_size}
(p/'docs/v03/build-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print('Delivery gallery and portable package ready:',out,archive)
