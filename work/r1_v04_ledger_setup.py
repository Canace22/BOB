from pathlib import Path
import json,subprocess,hashlib
p=Path('G:/鲸落万物生/BOB/godot/first-level');doc=p/'docs/v04'
skill=Path('C:/Users/Kingsoft/.codex/skills/game-production-pipeline')
cfg=json.loads((p/'v03-config.json').read_text('utf8'))
cfg['project_id']='whalefall-r1-routes-layers-v04'
cfg['scope']['deliverable']='七房原图依据的路线、门关系、分层场景、实际回访路线验证'
cfg['scope']['included']=['七房四层编辑场景','房间ID/门ID驱动连接','R1 A2/A3回访段操作','原图坐标对照与层显隐','独立运行包']
cfg['scope']['current_turn_limit']='完成R1场景与七房路线关系的实际交付'
cfg['tools']=['Godot 4.7.2 CLI','PowerShell','Python file/JSON and read-only Pillow inspection','view_image','builtin image_gen']
cfg['gameplay']['abilities']=['basic','A1','A2/A3 for R1 revisit; temporary sandbox without later chapter acquisition']
(p/'v04-config.json').write_text(json.dumps(cfg,ensure_ascii=False,indent=2),encoding='utf8')
stages=[]
for id,name,deps,outputs,kind in [
 ('A','设计与既有场景差异复核',[],['docs/v04/inputs.json','docs/v04/audit.md'],'technical'),
 ('B','按原画修正素材与四层样板',['A'],['docs/v04/assets.json','docs/v04/art-review.md'],'visual'),
 ('C','七房坐标、连接与回访路线',['B'],['docs/v04/scene-manifest.json','docs/v04/route-review.md'],'runtime'),
 ('D','独立包回归与交付',['C'],['docs/v04/delivery.md','docs/v04/qa-summary.json','RESUME-v04.md'],'runtime')]:
 stages.append({'id':id,'name':name,'depends_on':deps,'inputs':['首关设计册及当前v0.3场景；具体路径与哈希见inputs.json'],'input_files':['docs/v04/inputs.json'],'outputs':outputs,'checks':[{'id':'accept','kind':kind,'text':'实际观察、输出证据和需求覆盖'}],'prompt':'执行docs/v04/execution.md中对应阶段。保留原始失败证据，运行截图与坐标/门合同逐项检查。通过后执行下一步。','on_pass':[],'on_fail':'保存具体缺陷，修正并复验受影响用例'})
(p/'v04-plan.json').write_text(json.dumps({'schema_version':1,'name':'R1-seven-room-route-layer-restoration','scope_note':'延续v0.3；保留已验证首访；七房路线回访能力在不写档的测试模式提供；不扩建R2/R3，不外发','stages':stages},ensure_ascii=False,indent=2),encoding='utf8')
(doc/'audit.md').write_text('''# 依据复核 / AI审查
已读并查看七张原图、七张坐标SVG、最新全景、分层元素规范与Godot脚本。
v0.3平台坐标七房已一致，首房E01已修订至右门，但运行交互按room_index±1推断出口，无法形成02⇄06、02⇄07；门图像与运行门位不一致。缺少须筛三锚互动；未接A2/A3；中/前景未按0.5/1.2实际视差；新前景层覆盖不足。修正范围因此成立。
优先级：精确平台/锚/门数据控制碰撞与路线；最新解剖说明控制材料；原画控制氛围构图。07原图右门作废，采用唯一左门；06采用鼻道外侧旧创伤，不进入脑；05/06无鲸须；01保留最新上下颌分离外形。
正常首访仍01→02→03→04→05。06/07需要后续A2/A3回访，不能把能力直接塞给正常新存档。F9只提供临时验证并恢复原进度。R2-05远端闩不可从06开启；R3-01为本关结束边界。
真实环境：Godot --version=4.7.2.stable.official.ed1daf0bf；导入与图形启动有日志；未调用外部收费服务。原图与坐标不可逐像素等同比例拼接，映射U=64px，1U代表主角站立高度。
''',encoding='utf8')
# Explicitly resolve paths before moving the old ledger within the project.
old=(p/'.production').resolve();dest=(p/'production-history/v03-ledger-before-v04').resolve();root=p.resolve()
assert old.is_relative_to(root) and dest.is_relative_to(root)
if old.exists() and not dest.exists():old.rename(dest)
subprocess.run([__import__('sys').executable,str(skill/'scripts/workflow.py'),'init','--project',str(p),'--config',str(p/'v04-config.json'),'--plan',str(p/'v04-plan.json')],check=True)
print('v0.4 production plan initialized; archived v0.3 ledger preserved')
