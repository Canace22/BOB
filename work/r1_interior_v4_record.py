from pathlib import Path
import json,sys,os,subprocess
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def run(args):
 r=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8',env={**os.environ,'PYTHONIOENCODING':'utf-8'});assert r.returncode==0,r.stderr;return json.loads(r.stdout)
run(['status']);j=run(['next']);tid=j['task_id'];assert tid.startswith('D03'),j
(p/f'.production/tasks/{tid}.execution.md').write_text('固定用户图1的外形，只重绘内部。输入 references/interior-v4-shape-lock.png 与用户局部原画；工具为内置 image_gen。已保存实际首次与修复提示。产出 images/head-interior-v4.png、地图投影和同一本HTML。验收为图像目视及静态检查；失败时保留初稿定向修复；本轮不进入引擎。',encoding='utf8')
r={'task_id':tid,'status':'pass','summary':'外形保持，内部重绘；脑区与咽后误植已局部返修，双代理目视与静态链接检查通过。','artifacts':['首关全景与拆解册.html','docs/验收记录.md','RESUME.md','images/head-interior-v4.png','images/head-interior-v4-draft.png','maps/head-interior-v4-labeled.svg','docs/内部重绘v4复核.md','data/interior-v4-generation.json','data/interior-v4-prompt.txt','data/interior-v4-fix-prompt.txt'],'checks':[{'id':'delivery','status':'pass','reviewer':'agent','notes':'固定头形与内部丰富度均经目视；HTML链接/PNG/SVG检查通过。浏览器与人类审美not_run；未接入引擎。','evidence':['images/head-interior-v4.png','docs/内部重绘v4复核.md','data/interior-v4-validation.json']}]}
f=p/f'.production/tasks/{tid}.actual.json';f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8');print(run(['record','--result',str(f)]));print(run(['next']))
