from pathlib import Path
import subprocess,shutil,json,hashlib,sys
ROOT=Path('G:/鲸落万物生');P=ROOT/'godot/first-level-artmatch'
B=ROOT/'builds/须门遗港-v0.5-参考图可玩关卡';B.mkdir(parents=True,exist_ok=True)
EXE='C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
OLD=ROOT/'builds/须门遗港-v0.4-七房路线与分层'
for name in ['Whalefall.exe','GODOT-LICENSE.txt','GODOT-THIRD-PARTY.json']:shutil.copy2(OLD/name,B/name)
def run(name,cmd,timeout=300):
 folder=P/'evidence'/name;folder.mkdir(exist_ok=True)
 with (folder/'run.log').open('w',encoding='utf8')as out:r=subprocess.run(cmd,cwd=B,stdout=out,stderr=subprocess.STDOUT,timeout=timeout)
 log=(folder/'run.log').read_text('utf8')
 row={'exit':r.returncode,'script_errors':'SCRIPT ERROR'in log,'errors':'ERROR:'in log,'audio':'Dummy where explicitly selected; no physical sound claim','cmd':cmd}
 (folder/'process.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf8')
 print(name,row['exit'],row['errors'],flush=True)
 if r.returncode or row['errors']:raise RuntimeError(name+' failed: '+log[-2000:])
 return folder
run('package-import',[EXE,'--headless','--path',str(P),'--editor','--import'])
run('package-export',[EXE,'--headless','--path',str(P),'--export-pack','Windows Portable',str(B/'Whalefall.pck')])
run('package-normal',[str(B/'Whalefall.exe'),'--audio-driver','Dummy','--','--qa-normal','--evidence='+str(P/'evidence/package-normal')],400)
normal=json.loads((P/'evidence/package-normal/normal-run.json').read_text('utf8'))
assert normal.get('pass') and all(t.get('pass',False) for t in normal['tests']), 'Normal route report failed'
run('package-reload',[str(B/'Whalefall.exe'),'--audio-driver','Dummy','--','--qa-normal-reload','--evidence='+str(P/'evidence/package-reload')])
reload_report=json.loads((P/'evidence/package-reload/normal-reload.json').read_text('utf8'))
assert reload_report.get('pass'), 'Independent normal-save reload failed'
# Normal user window-close evidence is recorded separately in package-startup-clean.
# --quit-after forcibly bypasses the application's graceful close handler.
(B/'静音兼容启动.cmd').write_text('@echo off\r\nstart "" "%~dp0Whalefall.exe" --audio-driver Dummy\r\n',encoding='ascii')
(B/'engine-version.txt').write_text('Godot 4.7.2.stable.official.ed1daf0bf\nWindows x64 / GL Compatibility\nOfficial portable executable + exported PCK (release export templates were not installed).\n',encoding='utf8')
(B/'操作说明.txt').write_text('''须门遗港 v0.5 · 参考图可玩关卡
运行：双击 Whalefall.exe，保留同目录 Whalefall.pck。
音频复验已恢复WASAPI，用户确认能发声；本版采用柔和水流/摩擦/低频碰撞音色，每类3变体及重复限流。听感验收最新状态见交付册。静音兼容启动.cmd仅用于静音排查。
引擎固定 Godot 4.7.2.stable.official.ed1daf0bf / Compatibility / Windows x64。
本包采用官方便携程序+PCK；没有伪称发行模板构建。

A/D 或左右箭头移动；空格跳跃；Q攻击；击败负壳蟹后Shift冲刺。
E使用营地/拾取；同位置有营地与门时，A或D+E明确过门。
W浮游、J锚环是后续回访能力，本关正常首访未获得。F9临时练习可测试上层与记忆袋；练习退出恢复正式进度。
舌台中央薄膜受压后，S+空格下潜到返坡；返回中央下层按空格回弹。其它房间S不穿地形。
Esc暂停，M静音，F5保存当前安全位置，F6重载，R返回检查点。
Tab切换近景/全房；F2源图对照；F3碰撞/门/锚点；F4四层独显；数字1–7场景检查。

正常主路：01外伤坡→02须筛→03舌台→04负壳蟹→05流膜育窝出口。
回访：02左上→06喷气孔外侧旧伤，高岸远侧闩此侧不开；02右上→07记忆袋，四环与奖励后原路返回，右壁封闭。
图片中的悬空英雄位置只用于构图对照；正常出生在稳定岸上。
未扩建R2/R3后续章节。原图之外的隐藏补绘、动效、音效和软膜下潜是有记录的设计补足。

旧v0.4工程/构建均保留。新工程：G:/鲸落万物生/BOB/godot/first-level-artmatch/project.godot
原件：assets/reference/r1；遮罩/Shader/场景是可编辑母版；assets/clean是补绘母版；assets/runtime/layers是Godot原生导出的分层/角色复用图。
主图纹理由互补遮罩进入四层，独立角色/敌人/门/拾取物、曲面碰撞、状态与事件在引擎运行，不是把整图当可玩关卡。
远景独显可见少量源图遮挡细节叠层；干净远景母版在assets/clean/*-far.png。源图未包含的隐藏面为合理补绘，不声称恢复了不存在的原始分层工程。
数字混音/事件/保存/路线已有实测；真实输出已恢复，音色根据用户反馈修订，详见交付册和验收记录。
''',encoding='utf8')
manifest={'kind':'official portable executable + exported PCK','version':'4.7.2.stable.official.ed1daf0bf','folder':str(B),'files':[{'name':f.name,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}for f in B.iterdir()if f.is_file()]}
(P/'docs/build-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
shutil.make_archive(str(B),'zip',B)
print('BUILD',str(B),flush=True)
