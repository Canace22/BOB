from pathlib import Path
import json,hashlib,zipfile,shutil
root=Path(__file__).resolve().parents[1]
release=root.parents[1]/'builds'/'须门遗港-v0.1'
text='''鲸落万物生 · 须门遗港 v0.1
Windows键盘试玩。双击 Whalefall.exe，保持Whalefall.pck在同目录。

AD/方向键移动，Space跳跃；Q短击，恢复后半再Q接第二击；R重鸣（2蓄振）；F原地调息（耗2蓄振/1.1秒恢复1生命）；E营地/门/奖励；L灯罩。Boss胜后右侧E拿到能力，Shift贴流冲。
Tab地图，Esc暂停，暂停C回营地，F2两次确认新旅程；Alt+F4退出。

路线：外伤坡学走跳→须筛学蟹预告→舌台双敌与高处碎片→负壳蟹（跳扫、退砸、半血二扫）→右侧E授能→流膜育窝三段跳冲→右门E结关。结关Esc可回访。
营地在外伤坡和Boss左门庭；永久进度自动保存。退出后从最近记录营地继续。玩家档在%APPDATA%/WhalefallFirstLevel/save-v1.json，备份.bak。

本版为五房首通可玩版本，有限关键姿势/程序音效/重复地形仍需后续打磨。完整原画与玩法设计不是全部已实现。主观音效听感尚待人工试听。
使用Godot4.7.2同版本便携运行时，不依赖编辑器；相关许可随包提供。
'''
(release/'操作说明.txt').write_text(text,encoding='utf-8-sig')
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
files=[{'name':p.name,'bytes':p.stat().st_size,'sha256':digest(p)} for p in sorted(release.iterdir()) if p.is_file()]
zpath=release.parent/(release.name+'.zip')
with zipfile.ZipFile(zpath,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted(release.iterdir()):
        if p.is_file():z.write(p,release.name+'/'+p.name)
with zipfile.ZipFile(zpath) as z: assert z.testzip() is None
source=[{'path':str(p.relative_to(root)),'sha256':digest(p)} for folder in ['scripts','scenes'] for p in sorted((root/folder).glob('*')) if p.is_file()]
manifest={'version':'0.1','runtime':'Godot4.7.2.stable.official.ed1daf0bf / exact installed runtime plus PCK','package_directory':str(release),'zip':str(zpath),'zip_bytes':zpath.stat().st_size,'zip_sha256':digest(zpath),'files':files,'source':source,'verification':['evidence/standalone-run/prototype.json','evidence/standalone-run/performance.json','evidence/p07-run/persistence.json','evidence/p07-run/integration-v1.json'],'zip_crc':'passed','normal_save_included':False}
(root/'evidence/build-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({'zip':str(zpath),'bytes':zpath.stat().st_size,'crc':'passed'},ensure_ascii=False))
