from pathlib import Path
import json,sys,os,subprocess
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def run(args):
 r=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8',env={**os.environ,'PYTHONIOENCODING':'utf-8'});assert r.returncode==0,r.stderr;return json.loads(r.stdout)
run(['status']);j=run(['next']);tid=j['task_id'];assert tid.startswith('D03'),j
(p/f'.production/tasks/{tid}.execution.md').write_text('按用户新参考将吻端上下颌分开。实际编辑指令 data/mouth-v5-prompt.txt，源图 images/head-interior-v4.png。内置 image_gen 单次局部修改，通过目视后同步HTML与标注SVG；保留旧图。限于本轮设计图修订。',encoding='utf8')
r={'task_id':tid,'status':'pass','summary':'吻端上下颌明显分离，更新全景与七房投影，静态检查通过。','artifacts':['首关全景与拆解册.html','docs/验收记录.md','RESUME.md','images/head-mouth-v5.png','maps/head-mouth-v5-labeled.svg','docs/吻端开口v5复核.md','data/mouth-v5-generation.json','data/mouth-v5-prompt.txt'],'checks':[{'id':'delivery','status':'pass','reviewer':'agent','notes':'主代理查看最终图确认前端上下颌不接触；子代理复核需更新的旧文案。PNG/SVG/链接有效；浏览器预览和人类审美未运行。','evidence':['images/head-mouth-v5.png','docs/吻端开口v5复核.md','data/mouth-v5-validation.json']}]}
f=p/f'.production/tasks/{tid}.actual.json';f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');print(run(['record','--result',str(f)]));print(run(['next']))
