"""Render manually entered atlas QA findings; never edits runtime metadata."""
from pathlib import Path
import json
BASE=Path(__file__).resolve().parent
review=json.loads((BASE/'isnet-batch-review.json').read_text(encoding='utf-8'))
findings=[]
lines=['# ISNet动作逐项资产复核','',
       '这是已完成图集的全帧本体/特效复核，不等于游戏操作或正式美术最终验收。帧号从0开始；来源hash锁定被检查版本。','',
       '| 动作 | 状态 | 本体 | 特效 | 处理建议 |','|---|---|---|---|---|']
for key,a in review['actions'].items():
    lines.append('| '+' | '.join(str(v).replace('|','/') for v in [key,a['status'],a.get('body_review','待本批完成'),a.get('fx_review','待复核'),a.get('next_action','')])+' |')
    for issue in a.get('findings',[]):
        findings.append({'key':key,**issue,'body_sha256':a.get('body_sha256'),'evidence':a.get('evidence')})
for key,a in review['actions'].items():
    if a.get('production_decision'):
        lines.extend(['',f"{key} production decision: {a['production_decision']}"])
(BASE/'isnet-batch-review.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(BASE/'review/action-review-findings.json').write_text(json.dumps({'version':1,'frame_index_base':0,'findings':findings},ensure_ascii=False,indent=2),encoding='utf-8')
repair_path=BASE/'isnet-repair-review.json'
if repair_path.exists():
    repaired=json.loads(repair_path.read_text(encoding='utf-8'))
    out=['# ISNet返修版本复核','', '图集人工复核；不替代实机验收。每条绑定本体/特效SHA256，保留原版缺陷证据。','', '| 动作 | 版本 | 状态 | 本体 | 特效 |','|---|---|---|---|---|']
    for key, versions in repaired['versions'].items():
        for a in versions:
            out.append('| '+' | '.join(str(v).replace('|','/') for v in [key,a['version'],a['status'],a['body_review'],a['fx_review']])+' |')
    (BASE/'isnet-repair-review.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
