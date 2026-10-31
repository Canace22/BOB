const fs=require('fs'),cp=require('child_process'),path=require('path');
const root=path.resolve(__dirname,'..');
const python='C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe';
const workflow='C:/Users/Kingsoft/.codex/skills/game-production-pipeline/scripts/workflow.py';
const cmd=process.argv[2];
if(cmd==='next'||cmd==='status'){console.log(cp.execFileSync(python,[workflow,cmd,'--project',root],{encoding:'utf8',env:{...process.env,PYTHONIOENCODING:'utf-8'}}));}
else if(cmd==='record'){const f=path.resolve(root,process.argv[3]);console.log(cp.execFileSync(python,[workflow,'record','--project',root,'--result',f],{encoding:'utf8',env:{...process.env,PYTHONIOENCODING:'utf-8'}}));}
