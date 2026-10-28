from pathlib import Path
import json,shutil,hashlib,zipfile,subprocess,sys,os
p=Path('G:/鲸落万物生/BOB/godot/first-level'); src=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
doc=p/'docs/v03';doc.mkdir(parents=True,exist_ok=True)
backup=Path('G:/鲸落万物生/BOB/work/r1-before-scene-v03.zip')
if not backup.exists():
 with zipfile.ZipFile(backup,'w',zipfile.ZIP_DEFLATED)as z:
  for base in ['scripts','scenes','.production']:
   for f in (p/base).rglob('*'):
    if f.is_file():z.write(f,str(f.relative_to(p)))
  for name in ['project.godot','assets/rooms.json','export_presets.cfg','RESUME.md','project-config.json']:z.write(p/name,name)
snapshot=[]
for f in [src/'首关全景与拆解册.html',src/'images/head-mouth-v5.png',src/'data/r1-design.json',src/'data/elements.json',p/'project.godot']:
 snapshot.append({'path':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
(doc/'input-snapshot.json').write_text(json.dumps(snapshot,ensure_ascii=False,indent=2),encoding='utf8')
rooms=json.loads((src/'data/r1-design.json').read_text('utf8'))['rooms']
rooms[5]['anatomy']['part']='喷气孔旁颅侧旧伤／鼻道外侧；脑区不进入'
(p/'assets/rooms.json').write_text(json.dumps(rooms,ensure_ascii=False,indent=2),encoding='utf8')
(doc/'specification.md').write_text('''# R1 场景还原 v0.3

输入：最新张口版全景 + 七房坐标设计，Godot 4.7.2 Compatibility / 1280×720。1U=64像素；碰撞顶边按platform.y，原画比例用于气氛及解剖结构，不能把全景整图铺在前景代替场景。

交付：七个可编辑.tscn房间、独立远/中/可玩/前景、实际动态、第一至第五房现有可玩流程和全部七房场景巡览、全景位置索引、Windows独立包。保留用户正常存档和v0.2运行包。

逐房验收：01上下颌独立且开口有水体；02多层须幕和高岸能力门；03起伏舌台/壳闩支路；04宽战场/两侧避险台/隔离营地；05食管纵膜与3沟、无须；06鼻道外侧颅骨旧伤、三段竖向平台、闭锁肺侧门；07须根口袋/四环两沟/封闭右壁。

五房剧情保持能力解锁逻辑。06/07为后续能力回访设计，本轮还原完整场景和物件，巡览模式可检查全部空间，不冒充A2/A3后续章节已开发。巡览冻结战斗，用独立镜头检视；退出恢复正常关卡。

制作：先以须筛作为分层样板并实际截图，确认可读性后扩展七房。现有独立角色/敌人/壳灯素材复用；新增厚舌地形、上颚须幕、独立下颌、远海与颅侧远景。全部AI位图使用内置image_gen，免费工具选用本机Godot原生节点/粒子/Shader，不安装额外工具或调用第三方付费。

验证：每房真实渲染和相机边界、全部地形碰撞与坐标匹配、输入驱动五房通关/支路/死亡复活/跨进程存档恢复；音效沿用旧版，本轮不声称重新试听。原画还原按构图/解剖/分层/材质和可玩轮廓审查，非逐像素复刻。
''',encoding='utf8')
config=json.loads((p/'project-config.json').read_text('utf8'));config['project_id']='whalefall-r1-scene-v03';config['scope']={'deliverable':'七房场景还原与五房运行回归','included':['七房可编辑场景','多层美术','动态','场景巡览','五房原流程','独立运行包'],'excluded':['其它区域','A2/A3完整章节','外部发布','第三方付费生成'],'current_turn_limit':'完成首关场景还原'}
config['art']['style_version']='R1-head-mouth-v5';config['authorization']['source']='当前用户要求读取首关图册并完整还原场景';config['art']['reference_paths']=[str(src/'首关全景与拆解册.html'),str(src/'images/head-mouth-v5.png')]
(p/'v03-config.json').write_text(json.dumps(config,ensure_ascii=False,indent=2),encoding='utf8')
stages=[]
for sid,name,dep,outs,kind in [('S0','环境与场景规格',[],['docs/v03/specification.md','docs/v03/input-snapshot.json'],'technical'),('S1','素材与分层样板',['S0'],['docs/v03/assets.json','docs/v03/sample-review.md'],'visual'),('S2','七房还原',['S1'],['docs/v03/scene-manifest.json','docs/v03/scene-review.md'],'visual'),('S3','运行回归与交付',['S2'],['docs/v03/delivery.md','RESUME-v03.md'],'runtime')]:
 stages.append({'id':sid,'name':name,'depends_on':dep,'inputs':['最新首关图册及既有工程'],'input_files':['docs/v03/input-snapshot.json'],'outputs':outs,'checks':[{'id':'accept','kind':kind,'text':'真实工具执行并保留观察证据'}],'prompt':'按specification实际制作，核对截图与日志，失败定向返修。','on_pass':[],'on_fail':'保存错误与重试证据'})
(p/'v03-plan.json').write_text(json.dumps({'schema_version':1,'name':'R1-scene-restoration','scope_note':'七房场景，首通五房玩法复用，未来能力房提供实景巡览','stages':stages},ensure_ascii=False,indent=2),encoding='utf8')
old=p/'production-history/v02-ledger'
if not old.exists():shutil.copytree(p/'.production',old)
# Resolved target is exactly the archived ledger inside this project.
ledger=(p/'.production').resolve();assert ledger.parent==p.resolve() and ledger.name=='.production'
shutil.rmtree(ledger)
wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
r=subprocess.run([sys.executable,wf,'init','--project',str(p),'--config',str(p/'v03-config.json'),'--plan',str(p/'v03-plan.json')],env={**os.environ,'PYTHONIOENCODING':'utf-8'},capture_output=True,encoding='utf8');print(r.stdout);assert r.returncode==0,r.stderr
print('v0.3 initialized, backup preserved:',backup)
