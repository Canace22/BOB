import json, hashlib, shutil
from pathlib import Path
root=Path('G:/鲸落万物生/outputs/须门遗港_R1_全景与分层拆解')
sources=[Path('G:/鲸落万物生/outputs')/x for x in ['鲸落万物生_V5_完整游戏设计','鲸落万物生_V5.2_地图原画设计规范','鲸落万物生_V5.1_地图深化','鲸落万物生_V5.2_完整游戏设计']]
files=[]
for d in sources:
 for p in d.glob('*.md'):
  files.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
for i,name in enumerate(['7ca9a830-3288-4169-94f0-b7d47a410a82','76da3109-abb1-47ab-af96-f5aa5597a0d5','7235663a-72d5-45d3-946e-9fb019a1f0f3','d4a4ce07-71ee-440d-936c-dae3fe4e5bf6'],1):
 p=Path('C:/Users/Kingsoft/AppData/Local/Temp')/('codex-clipboard-'+name+'.png')
 shutil.copy2(p,root/'references'/f'user-{i}.png')
 files.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'copy':f'references/user-{i}.png'})
(root/'data/input-snapshot.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf8')
config={'schema_version':1,'project_id':'r1-panorama-breakdown','project_root':str(root),'scope':{'deliverable':'首关七房全景、分层拆解、物件动态说明与路线册','included':['四版资料核对','新全景原画','分层与元素设计图','精确路线示意','可接续证据'],'excluded':['修改既有Godot工程','生成可直接导入的分层PSD','引擎动态接入','后续区域制作'],'current_turn_limit':'本地设计图册'},'engine':{'name':'Godot','version':'4.7.2 (reference only)'},'art':{'review_policy':'agent_against_references'},'authorization':{'source':'current_user_request','paid_services':[],'publish_requested':False},'retry_policy':{'local_attempts_per_failure':3},'tools':[{'name':'image_gen','status':'callable'},{'name':'Python + HTML/SVG','status':'writable'}]}
(root/'project-config.json').write_text(json.dumps(config,ensure_ascii=False,indent=2),encoding='utf8')
plan={'schema_version':1,'name':'R1-design-only','scope_note':'本轮是全景与拆解设计，非引擎资产集成；不改已验收工程账本。','stages':[]}
for id,name,deps,outputs,checks in [('D01','资料与路线核对',[],['data/r1-design.json','docs/设计依据.md'],['sources']),('D02','全景与拆解原画',['D01'],['images/panorama.png','images/layers.png','images/elements.png','data/prompts.json'],['visual']),('D03','图册与交付',['D02'],['首关全景与拆解册.html','docs/验收记录.md','RESUME.md'],['delivery'])]:
 plan['stages'].append({'id':id,'name':name,'depends_on':deps,'inputs':['四版资料与用户四张原图'],'input_files':['data/input-snapshot.json'],'outputs':outputs,'checks':[{'id':c,'kind':'visual' if c=='visual' else 'technical','text':'实际检查并记录证据'} for c in checks],'prompt':'读取输入，保存实际执行指令并执行，核对源数据与生成图。','on_pass':[],'on_fail':'保留失败结果，定向返修'})
(root/'production-plan.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf8')
(root/'docs/执行说明.md').write_text('范围：首关R1七房，5主线+2回访。采用V5.2解剖为材料权威，地图JSON为几何依据，冲突显式记录。生成全景压缩概念图、四层分析板、物件与动态分件板；精确路线用SVG另绘。原画不是碰撞地图，板图不是独立透明运行资产。本轮不修改Godot、不调用第三方收费服务。内置image_gen实际费用未知。\n原图背景肋形重复不作为口腔解剖依据；鼻口隔断、咽后无鲸须优先。生成图若有偏差用注记与结构图明确，严重拓扑错误返修。',encoding='utf8')
print(root)
