from pathlib import Path
import json,shutil,subprocess,time,sys,hashlib
p=Path('G:/鲸落万物生/BOB/godot/first-level');b=Path('G:/鲸落万物生/builds/须门遗港-v0.4-七房路线与分层');b.mkdir(parents=True,exist_ok=True)
old=b.parent/'须门遗港-v0.3-场景还原'
for name in ['Whalefall.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:shutil.copy2(old/name,b/name)
exe='C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
with (p/'docs/v04/export.log').open('w',encoding='utf8')as log:
 r=subprocess.run([exe,'--headless','--path',str(p),'--export-pack','Windows Portable',str(b/'Whalefall.pck')],stdout=log,stderr=subprocess.STDOUT,timeout=120)
assert r.returncode==0,(p/'docs/v04/export.log').read_text('utf8')
assert 'ERROR:'not in (p/'docs/v04/export.log').read_text('utf8')
for filename,arg in [('七房场景巡览.cmd','--scene-tour'),('七房回访路线验证.cmd','--route-tour')]:
 (b/filename).write_text('@echo off\r\nstart "" "%~dp0Whalefall.exe" -- '+arg+'\r\n',encoding='ascii')
(b/'操作说明.txt').write_text('''鲸落万物生 · 须门遗港 v0.4 七房路线与分层
引擎：Godot 4.7.2.stable.official.ed1daf0bf / Compatibility / Windows x64。
运行：双击Whalefall.exe；必须保留同目录Whalefall.pck。
看场景：七房场景巡览.cmd 或游戏内F6。1–7切房，WASD镜头，F5全房/近景，F10依次查看合成/远景/中景/可玩层/前景。
F7叠加路线、平台坐标、能力门与锚点范围；F8并列显示本房原图及坐标设计；Tab显示巨鲸头部与七房连接。
走路线：七房回访路线验证.cmd 或F9，临时取得A1/A2/A3并进入须筛；不写入正常存档。F9退出并恢复原房间、能力和资源。
A/D移动；Space跳跃/从环脱离；W浮升，落台补满压力；J抓最近前方合法环，再按J换环；E交互/门/奖励；Shift贴流冲。
正常旅程：A/D走，Space跳，Q短击，R重鸣，F调息，L灯罩，E记录/拾取/门，Esc暂停，暂停C回营地。F2二次确认重开。
正常首访：01外伤坡→02须筛→03舌台→04负壳蟹，胜利E领取A1→05三段冲刺沟→胃枢边界结束。
回访A2：02 x5U三段补压台到E33→06，沿高台到静菌；E34远侧闩此侧不能开，返回02同一高门。
回访A3：02 x25U起依次抓(26,13)、(29,10)、(32,7)三个环，落x33U高岸E35→07；四环两沟取右岸奖励，右壁封闭；原路回左门。
R2-05/R3-01属于后续区域，未扩建。A2/A3正式取得流程仍在后续章节；本包只实现R1回访段和独立验证模式。
原画构图与精确坐标有冲突时，以坐标表和最新解剖修订为准；不是原图的逐像素复制。UI与操作说明可查看交付册。
构建方式：缺少发行导出模板，采用官方同版本便携程序+导出的项目PCK，不是裁剪发行模板。
''',encoding='utf8')
visual_only='--visual-only' in sys.argv
results=json.loads((p/'docs/v04/package-qa.json').read_text('utf8')) if visual_only else []
if visual_only: results=[r for r in results if r['name'] not in ['art','normal']]
for name,args in [('art',['--','--qa-v04-art']),('routes',['--','--qa-routes']),('mechanisms',['--','--qa-mechanisms']),('play',['--','--qa-render']),('reload',['--headless','--','--qa-load']),('normal',['--quit-after','90'])]:
 if visual_only and name not in ['art','normal']:continue
 d=p/'evidence/v04'/('package-'+name);d.mkdir(parents=True,exist_ok=True)
 cmd=[str(b/'Whalefall.exe'),*args]
 if '--' in args:cmd+=['--evidence-dir='+str(d)]
 start=time.time()
 with (d/'run.log').open('w',encoding='utf8')as log:r=subprocess.run(cmd,cwd=b,stdout=log,stderr=subprocess.STDOUT,timeout=290)
 log=(d/'run.log').read_text('utf8');row={'name':name,'exit':r.returncode,'errors':'ERROR:' in log or 'SCRIPT ERROR' in log,'seconds':time.time()-start}
 (d/'process.json').write_text(json.dumps(row),encoding='utf8');results.append(row)
 (p/'docs/v04/package-qa.json').write_text(json.dumps(results,indent=2),encoding='utf8');print(row,flush=True)
 if row['exit']!=0 or row['errors']:sys.exit(2)
(p/'docs/v04/build-manifest.json').write_text(json.dumps({'folder':str(b),'type':'official 4.7.2 portable + exported PCK','files':[{'name':f.name,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in b.iterdir()if f.is_file()]},ensure_ascii=False,indent=2),encoding='utf8')
