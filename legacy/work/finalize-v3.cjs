const fs=require('fs'),path=require('path'),crypto=require('crypto'),cp=require('child_process');
const work='G:/鲸落万物生/BOB/work',out='G:/鲸落万物生/outputs/鲸落万物生_V3';
const asm=work+'/assemble-v3.cjs';let s=fs.readFileSync(asm,'utf8');s=s.replace("'05_生物物件与细节设定.md'];","'05_生物物件与细节设定.md','06_AI实施契约.md'];").replaceAll('五份完整文档','六份完整文档').replaceAll('5 份嵌入文档','6 份嵌入文档').replace("r[2]+'线'+(r[2]==='选'?'支路':'')","(r[2]==='选'?'可选支路':'主线')");fs.writeFileSync(asm,s);
const ver=work+'/verify-v3.cjs';let v=fs.readFileSync(ver,'utf8').replace('images:22,docs:5','images:22,docs:6');fs.writeFileSync(ver,v);
cp.execFileSync(process.execPath,[asm],{stdio:'inherit'});cp.execFileSync(process.execPath,[ver],{stdio:'inherit'});
fs.mkdirSync(out+'/tools',{recursive:true});fs.writeFileSync(out+'/tools/verify.cjs',v.replace("const out='G:/鲸落万物生/outputs/鲸落万物生_V3';","const out=path.resolve(__dirname,'..');"));
const delivery='C:/Users/Kingsoft/Documents/Codex/2026-10-16/new-chat-2/outputs/鲸落万物生_V3';fs.mkdirSync(path.dirname(delivery),{recursive:true});fs.cpSync(out,delivery,{recursive:true});
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?files(dir+'/'+e.name):[dir+'/'+e.name]);}
let checked=0;for(const src of files(out)){const rel=path.relative(out,src),dst=path.join(delivery,rel);const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');if(hash(src)!==hash(dst))throw Error('Copy mismatch '+rel);checked++;}
console.log(JSON.stringify({out,delivery,filesCompared:checked,totalBytes:files(out).reduce((n,f)=>n+fs.statSync(f).size,0)}));
