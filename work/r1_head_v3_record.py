from pathlib import Path
import json,sys,os,subprocess
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def run(args):
 r=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8',env={**os.environ,'PYTHONIOENCODING':'utf-8'});assert r.returncode==0,r.stderr;return json.loads(r.stdout)
run(['status']);j=run(['next']);tid=j['task_id'];assert tid.startswith('D03')
(p/f'.production/tasks/{tid}.execution.md').write_text((p/'docs/鲸头v3执行.md').read_text('utf-8-sig'),encoding='utf8')
r={'task_id':tid,'status':'pass','summary':'新参考驱动鲸头结构重绘；近侧颊壁剖开，保留窄口裂/厚舌/颌骨/须列，脑区灯误植已返修，页面与落位图更新。','artifacts':['首关全景与拆解册.html','docs/验收记录.md','RESUME.md','images/head-structure-v3-final.png','maps/head-structure-v3-labeled.svg','docs/鲸头v3复核.md','data/head-v3-generation.json','data/head-v3-prompt.txt','data/head-v3-fix-prompt.txt'],'checks':[{'id':'delivery','status':'pass','reviewer':'agent','notes':'结构底图已目视，首次生成缺陷局部修复。完整玩法保留在七房坐标图，未声称医学精确/引擎接入/用户审美确认。HTML链接与PNG/SVG有效；浏览器preview not_run。','evidence':['images/head-structure-v3-final.png','docs/鲸头v3复核.md','data/head-v3-validation.json']}]}
f=p/f'.production/tasks/{tid}.actual.json';f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');print(run(['record','--result',str(f)]));print(run(['next']))
