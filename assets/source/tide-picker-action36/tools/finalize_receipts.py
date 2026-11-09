"""Read existing Chaos jobs through its supported CLI; never submit generation.

Sanitized receipts preserve job IDs, timestamps and URL paths, but strip URL queries.
Original generation JSON is audited without editing it. No direct API calls.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timezone
from urllib.parse import urlsplit, urlunsplit

ROOT=Path(__file__).resolve().parents[1]
JOBS=ROOT/'jobs'
NAMES=('wall_slide','wall_jump','anchor','slit','swim','tram','slit-r2')
URL=re.compile(r'https?://[^\s<>"\]]+')
SECRET=re.compile(r'(?:tsk_[A-Za-z0-9_-]{12,}|Bearer\s+[A-Za-z0-9_.-]{16,}|\bsk-[A-Za-z0-9_-]{20,})')

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(path,data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')

def sanitize(value):
    if isinstance(value,dict):
        return {k: ('[REDACTED]' if re.fullmatch(r'(?i)(authorization|api[_-]?key|access[_-]?token|refresh[_-]?token|password)',k) else sanitize(v)) for k,v in value.items()}
    if isinstance(value,list): return [sanitize(v) for v in value]
    if isinstance(value,str):
        value=SECRET.sub('[REDACTED]',value)
        return URL.sub(lambda m: urlunsplit((*urlsplit(m.group())[:3],'','')),value)
    return value

def audit(value,path='$',findings=None):
    findings=[] if findings is None else findings
    if isinstance(value,dict):
        for k,v in value.items(): audit(v,f'{path}.{k}',findings)
    elif isinstance(value,list):
        for i,v in enumerate(value): audit(v,f'{path}[{i}]',findings)
    elif isinstance(value,str):
        if SECRET.search(value): findings.append({'path':path,'kind':'credential_like_value'})
        for match in URL.finditer(value):
            query=urlsplit(match.group()).query
            if query:
                names=sorted({s.split('=',1)[0] for s in query.split('&')})
                findings.append({'path':path,'kind':'query_bearing_url','query_parameter_names':names})
    return findings

def cli(script,args):
    env=os.environ.copy()
    env['PYTHONIOENCODING']='utf-8'
    result=subprocess.run([sys.executable,str(script),*args],capture_output=True,text=True,encoding='utf-8',env=env)
    if result.returncode:
        # Do not echo raw transport output which may contain temporary media links.
        raise RuntimeError(f'Chaos CLI {args[0]} failed (exit {result.returncode}); raw output withheld')
    return json.loads(result.stdout.lstrip('\ufeff'))

def snapshot(data,ids):
    canvas=data['data']
    return {'workflowId':data.get('workflowId',canvas.get('id')),'canvasName':data.get('canvasName',canvas.get('name')),
            'canvasUrl':data.get('canvasUrl'),'observed_at':datetime.now(timezone.utc).isoformat(),
            'nodeCount':len(canvas['nodes']),'nodes':[n for n in canvas['nodes'] if n['id'] in ids]}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--cli',type=Path,required=True)
    args=parser.parse_args()
    records={name:read(JOBS/f'{name}-status.json') for name in NAMES}
    workflow=next(iter(records.values()))['workflowId']
    ids={r['data']['node_id'] for r in records.values()}
    before=cli(args.cli,['read','--workflow-id',workflow])
    before_nodes={n['id']:n for n in before['data']['nodes']}
    # Only a stale active job may be written back; an older job must never replace r2.
    rows=[]
    for name,record in records.items():
        task=record['data']['task_id']
        node=record['data']['node_id']
        current=before_nodes[node]['data']
        superseded=current.get('taskId',current.get('task_id'))!=task
        needs_writeback=not superseded and current.get('status') not in ('success','completed','succeeded')
        command=['poll','--task-id',task,'--workflow-id',workflow,'--node-id',node,'--timeout','60']
        if needs_writeback: command+=['--writeback','--apply']
        result=cli(args.cli,command)
        receipt=f'{name}-final-receipt.json'
        save(JOBS/receipt,{'sanitization':'URL query/fragment removed; credential-like values redacted. Job status is original CLI response.','response':sanitize(result)})
        source=JOBS/f'{name}-body.mp4'
        row={'name':name,'task_id':task,'node_id':node,'workflow_id':workflow,'status':result['data']['status'],
             'canvas_writeback_performed':bool(result.get('writeback',False)),'superseded_on_canvas':superseded,
             'receipt':f'jobs/{receipt}','local_source':f'jobs/{source.name}',
             'local_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest() if source.exists() else None}
        rows.append(row)
        print(f'{name}: {row["status"]}; writeback={row["canvas_writeback_performed"]}; superseded={superseded}',flush=True)
    after=cli(args.cli,['read','--workflow-id',workflow])
    save(JOBS/'canvas-final-before.json',sanitize(snapshot(before,ids)))
    save(JOBS/'canvas-final-read.json',sanitize(snapshot(after,ids)))
    after_nodes={n['id']:n for n in after['data']['nodes']}
    for row in rows:
        node=after_nodes[row['node_id']]['data']
        row['canvas_status']=node.get('status')
        row['canvas_task_id']=node.get('taskId',node.get('task_id'))
        row['pending_task_ids']=node.get('pending_task_ids',[])
    save(ROOT/'generation-final-map.json',{'checked_at':datetime.now(timezone.utc).isoformat(),'workflow_id':workflow,
        'canvas_url':after.get('canvasUrl'),'canvas_name':after.get('canvasName'),
        'node_count_before':len(before['data']['nodes']),'node_count_after':len(after['data']['nodes']),
        'generation_submitted':False,'new_nodes_created':False,'jobs':rows})
    files=[]
    for path in sorted(JOBS.glob('*.json')):
        findings=audit(read(path))
        if findings: files.append({'file':f'jobs/{path.name}','findings':findings})
    save(ROOT/'receipt-security-audit.json',{'checked_at':datetime.now(timezone.utc).isoformat(),
        'original_jobs_modified':False,'value_output':'No credentials or URL query values included in audit.',
        'credential_like_count':sum(x['kind']=='credential_like_value' for f in files for x in f['findings']),
        'query_url_count':sum(x['kind']=='query_bearing_url' for f in files for x in f['findings']),
        'recommendation':'Commit sanitized *-final-receipt.json, generation-final-map.json and filtered canvas-final snapshots. Keep raw submit/dryrun/status/canvas/model JSON local or sanitize copies before staging. Preserve original local sources.',
        'files':files})
    print('Saved sanitized final receipts, mapping, selected-node snapshots and security audit.',flush=True)

if __name__=='__main__': main()
