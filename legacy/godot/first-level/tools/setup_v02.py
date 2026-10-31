from pathlib import Path
import json,hashlib,subprocess,os
root=Path(__file__).resolve().parents[1]
def write(p,data):
    (root/p).parent.mkdir(parents=True,exist_ok=True)
    (root/p).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
engine='C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
old=json.loads((root/'project-config.json').read_text('utf8'));old['project_id']='whalefall-r1-v02';old['scope']['deliverable']='在现有首关上完成分层环境动态样板并推广五房，保留核心玩法与存档，加入支路开闩';old['scope']['current_turn_limit']='完整首关v0.2迭代与实测，不开发后续区域';old['scope']['included']+=['独立环境部件','四层场景','事件同步效果','支路往返与壳闩持久状态'];write('v02-config.json',old)
stage_defs=[('P00','环境与原图复核',[],['docs/v02/environment.json'],[('environment','technical')]),('P01','规格与资产合同',['P00'],['docs/v02/specification.md','docs/v02/art-standard.md','docs/v02/asset-plan.json','docs/v02/level-map.svg'],[('spec','technical')]),('P03','既有灰盒与支路验证',['P01'],['docs/v02/graybox-review.md'],[('runtime','runtime')]),('P04','须筛完整样板',['P03'],['docs/v02/sample-review.md','docs/v02/asset-delivery.json'],[('visual','visual'),('events','runtime')]),('P10','五房扩展与回归',['P04'],['docs/v02/qa.md'],[('e2e','runtime'),('state','runtime'),('effects','visual')]),('P11','运行包与接续',['P10'],['docs/v02/delivery.md','RESUME-v02.md'],[('build','runtime')])]
plan={'schema_version':1,'name':'whalefall-v02-iteration','scope_note':'接续已通过v0.1，旧账本归档；保留原图/旧包。先复验灰盒再完成须筛动态样板，推广五房。','stages':[]}
for id,name,deps,outputs,checks in stage_defs:
    plan['stages'].append({'id':id,'name':name,'depends_on':deps,'inputs':['当前需求、已通过基线、V5.2设计原图'],'input_files':['docs/v02/input-snapshot.json'],'outputs':outputs,'checks':[{'id':c,'kind':k,'text':c+'实际验收并保留证据'} for c,k in checks],'prompt':'复核实际输入，具体化任务指令并执行；保留不可变快照和真实证据，失败修复后复验。','on_pass':[],'on_fail':'记录复现，局部返修；不通过删除功能凑通过。'})
write('v02-plan.json',plan)
paths=[root.parent.parent.parent/'outputs/鲸落万物生_V5.2_完整游戏设计/images/rooms/R1-01.png',root.parent.parent.parent/'outputs/鲸落万物生_V5.2_完整游戏设计/images/anatomy/rooms/R1-05.png',root/'production-history/v01-code.zip',root/'assets/rooms.json']
write('docs/v02/input-snapshot.json',[{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths])
version=subprocess.check_output([engine,'--version']).decode().strip()
write('docs/v02/environment.json',{'cwd':str(root.parent.parent),'project':str(root),'version':version,'engine':engine,'renderer':'gl_compatibility','python':'Pillow12.3.0 NumPy2.3.5 imageio_ffmpeg runtime verified','image_gen':'callable; current asset job pending; built-in mode','third_party_paid':'not used / no model or budget chosen','godot_mcp':'not required; CLI import/run/export works','templates':'only4.7.stable installed; use exact4.7.2 runtime+PCK','baseline':'v0.1 ledger all passed before archive','references_viewed':[str(paths[0]),str(paths[1])],'missing_required_tools':[]})
print(version)
