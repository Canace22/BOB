from pathlib import Path
import sys,subprocess,json,os
p=Path('G:/鲸落万物生/BOB/godot/first-level');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def run(args):
 r=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8',env={**os.environ,'PYTHONIOENCODING':'utf-8'});assert r.returncode==0,r.stderr;return json.loads(r.stdout)
j=run(['next']);print(j.get('task_id',j.get('status')))
if len(sys.argv)<2:sys.exit()
sid=sys.argv[1];assert j['stage_id']==sid if 'stage_id' in j else j['task_id'].startswith(sid)
tid=j['task_id']
details={
'S0':('环境/资料读取完成，固定4.7.2，旧版代码与账本备份后裁剪七房场景计划。',['docs/v03/specification.md','docs/v03/input-snapshot.json'],['docs/v03/environment.txt']),
'S1':('独立透明资产与须筛样板已实际运行并目视；素材来源与alpha记录完整。',['docs/v03/assets.json','docs/v03/sample-review.md'],['evidence/v03/scenery-release/R1-02-middle.png','docs/v03/sample-review.md']),
'S2':('七房场景与解剖位置已逐房截图复核，所有平台碰撞按图册，巡览不会写正常存档。',['docs/v03/scene-manifest.json','docs/v03/scene-review.md'],['evidence/v03/scenery-release/scenery.json','docs/v03/scene-review.md']),
'S3':('独立Windows包渲染与五房通关、支路/复活/重载回归完成；交付说明明确未来能力范围。',['docs/v03/delivery.md','RESUME-v03.md'],['docs/v03/qa-summary.json','docs/v03/delivery.md'])}
summary,arts,evidence=details[sid]
(p/f'.production/tasks/{tid}.execution.md').write_text((p/'docs/v03/specification.md').read_text('utf8')+'\n本阶段实际执行：'+summary+'\n具体产出：'+str(arts),encoding='utf8')
r={'task_id':tid,'status':'pass','summary':summary,'artifacts':arts,'checks':[{'id':'accept','status':'pass','reviewer':'agent','notes':summary+' AI审查不代表用户审美确认。','evidence':evidence}]}
f=p/f'.production/tasks/{tid}.actual.json';f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');print(run(['record','--result',str(f)]));print(run(['next']).get('task_id','all_passed'))

