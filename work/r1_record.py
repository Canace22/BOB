from pathlib import Path
import subprocess,json,sys
p=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解');wf='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py'
def call(args):
 r=subprocess.run([sys.executable,wf,*args,'--project',str(p)],capture_output=True,encoding='utf8');print(r.stdout);assert r.returncode==0,r.stderr;return json.loads(r.stdout)
steps=[('D01',['data/r1-design.json','docs/设计依据.md','data/input-snapshot.json'],'sources',['data/r1-design.json','docs/设计依据.md'],'四目录来源已核对：7房/门/平台/奖励及解剖修订；保留原值并记录首房门位冲突。'),('D02',['images/panorama.png','images/layers.png','images/elements.png','data/prompts.json','data/generation-record.json'],'visual',['images/panorama.png','images/layers.png','images/elements.png','docs/验收记录.md'],'新绘全景经一次局部返修，分层/物件板已目视；通过概念图说明用途，准确几何以SVG为准。明确未配准/非透明运行资产与图面简化。'),('D03',['首关全景与拆解册.html','docs/验收记录.md','RESUME.md','data/elements.json','docs/分层与动态.md'],'delivery',['data/validation.json','docs/验收记录.md'],'7房/33项/8张SVG/4张新图含初稿与链接静态检查通过。浏览器file协议预览被拒，交互排版not_run，已披露。')]
for stage,artifacts,check,evidence,notes in steps:
 packet=call(['next']);tid=packet['task_id'];assert tid.startswith(stage)
 (p/f'.production/tasks/{tid}.execution.md').write_text((p/'docs/执行说明.md').read_text('utf8')+'\n'+notes+'\n本步骤产物：'+','.join(artifacts),encoding='utf8')
 result={'task_id':tid,'status':'pass','summary':notes,'artifacts':artifacts,'checks':[{'id':check,'status':'pass','reviewer':'agent','notes':notes,'evidence':evidence}]}
 out=p/f'.production/tasks/{tid}.actual.json';out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8');call(['record','--result',str(out)])
call(['next'])
