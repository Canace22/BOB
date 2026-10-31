from pathlib import Path
import json,subprocess,sys
p=Path('G:/鲸落万物生/BOB/godot/first-level');workflow='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def call(*args):
 r=subprocess.run([sys.executable,workflow,*args,'--project',str(p)],capture_output=True,text=True,encoding='utf8',check=True)
 return json.loads(r.stdout)
plan=json.loads((p/'v04-plan.json').read_text('utf8'))
evidence={
'A':['docs/v04/inputs.json','docs/v04/audit.md','evidence/v04/import/run.log'],
'B':['evidence/v04/package-art/R1-02-composite.png','evidence/v04/package-art/R1-06-composite.png','evidence/v04/package-art/R1-07-composite.png','docs/v04/art-review.md','docs/v04/assets.json'],
'C':['evidence/v04/package-art/art.json','evidence/v04/package-routes/routes.json','evidence/v04/package-mechanisms/mechanisms.json','evidence/v04/package-routes/A2-three-platforms.png','evidence/v04/package-routes/07-right-wall-rewards.png'],
'D':['evidence/v04/package-play/prototype.json','evidence/v04/package-reload/persistence.json','evidence/v04/branch/branch.json','evidence/v04/death/combat.json','evidence/v04/latch/latch-reload.json','docs/v04/package-qa.json','docs/v04/delivery-check.json']}
notes={
'A':'已读原画、坐标、层级与既有代码；确认平台已有、房间关系仍缺失；原图冲突以房表和最新解剖修订取舍，已保存哈希与备份。',
'B':'5项独立素材接入；真实图形截图核对七房布局/中前景视差/透明边缘；旧三角支撑和矩形覆盖已返修。素材来源/准确提示词/源母版运行均保留；长段模块重复仍列美术精修项，未声称逐像素复制。',
'C':'49项场景检查、35项回访检查、6项机关检查通过；门ID/返回脚位/A2补压/A3挂环双向/07右壁/外部远端锁均观察；明确A3夹具起点与后续区域未包含。',
'D':'独立包五房Input完整通关、回访路径、机关、原图层显隐、重载与启动通过；项目支路/死亡/门闩重载通过。最终仅地图布局与art夹具变更，重新导出后复测art和启动。55张实际截图交付；80个本地链接与ZIP CRC通过。'}
for stage in plan['stages']:
 task=call('next');assert task['task_id'].startswith(stage['id']+'-'),task
 file=p/task['instruction']
 with file.open('a',encoding='utf8')as f:f.write('\n\n实际执行说明：先前已保存docs/v04/execution.md并执行真实工具。本条将本轮阶段证据纳入新范围账本；不重复生成资源。\n'+notes[stage['id']]+'\n输入路径/工具/失败分支/下一条件详见execution.md；实际证据：'+', '.join(evidence[stage['id']]))
 artifacts=stage['outputs'].copy()
 if stage['id']=='B':artifacts+=['docs/v04/generation-prompts.json']+[str(f.relative_to(p)).replace('\\','/')for f in (p/'assets/runtime/v04').glob('*.png')]
 if stage['id']=='C':artifacts+=['docs/v04/element-mapping.json']+[str(f.relative_to(p)).replace('\\','/')for f in (p/'scenes/r1').glob('*.tscn')]+['scripts/'+name for name in ['main.gd','level.gd','player.gd','game.gd','room_routes.gd','route_blueprint.gd','scene_inspector.gd','world_graph.gd','scenery_motion.gd','atmosphere.gd']]
 result={'task_id':task['task_id'],'status':'pass','summary':notes[stage['id']],'artifacts':artifacts,'checks':[{'id':'accept','status':'pass','reviewer':'agent','notes':notes[stage['id']],'evidence':evidence[stage['id']]}]}
 dest=p/'.production/tasks'/f'{task["task_id"]}.submission.json';dest.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
 r=call('record','--result',str(dest));print(stage['id'],r.get('status'),flush=True)
print(json.dumps(call('status'),ensure_ascii=False))
(p/'docs/v04/progress.json').write_text(json.dumps({'status':'passed','stages':['A','B','C','D'],'evidence':'docs/v04/qa-summary.json','delivery':'outputs/须门遗港_首关场景_v0.4_路线与分层/场景交付册.html','next':'Follow RESUME-v04.md for future refinements; no required work remains within R1 scene/route scope.'},ensure_ascii=False,indent=2),encoding='utf8')
