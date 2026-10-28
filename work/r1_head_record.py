from pathlib import Path
import subprocess,json,sys,os
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def run(args):
 q=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8',env={**os.environ,'PYTHONIOENCODING':'utf-8'});print(q.stdout);assert q.returncode==0,q.stderr;return json.loads(q.stdout)
run(['status']);job=run(['next']);tid=job['task_id'];assert tid.startswith('D03')
(p/f'.production/tasks/{tid}.execution.md').write_text((p/'docs/鲸头返修执行.md').read_text('utf-8-sig'),encoding='utf8')
r={'task_id':tid,'status':'pass','summary':'用户反馈鲸头识别失败后重绘完整鲸头侧剖；新图及中文落位标注已替换主图，旧图保留，文件链接检查通过。','artifacts':['首关全景与拆解册.html','docs/验收记录.md','RESUME.md','images/head-cutaway-v2.png','maps/head-cutaway-labeled-v2.svg','docs/鲸头重绘复核.md','data/head-generation-record.json','data/head-redraw-prompt.txt'],'checks':[{'id':'delivery','status':'pass','reviewer':'agent','notes':'目视可辨长吻/上下颌/眼位/双孔/连续厚舌/上颚鲸须及右后口咽；06后上、07前上。七房坐标仍为几何依据；browser preview not_run已披露。','evidence':['images/head-cutaway-v2.png','docs/鲸头重绘复核.md','data/head-validation.json']}]}
f=p/f'.production/tasks/{tid}.actual.json';f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');run(['record','--result',str(f)]);run(['next'])

