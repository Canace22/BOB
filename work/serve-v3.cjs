const http=require('http'),fs=require('fs'),path=require('path');
const root=path.resolve('G:/鲸落万物生/outputs/鲸落万物生_V3');
const types={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.md':'text/plain; charset=utf-8','.png':'image/png'};
http.createServer((req,res)=>{
  if(!['GET','HEAD'].includes(req.method)){res.writeHead(405,{'Allow':'GET, HEAD'});return res.end();}
  let rel;try{rel=decodeURIComponent(new URL(req.url,'http://localhost').pathname);}catch{res.writeHead(400);return res.end();}
  if(rel==='/')rel='/原画册.html';
  const target=path.resolve(root,'.'+rel);
  if(!target.startsWith(root+path.sep)||rel.includes('\\')||rel.includes('\0')){res.writeHead(403);return res.end();}
  fs.stat(target,(err,stat)=>{
    if(err||!stat.isFile()){res.writeHead(404);return res.end('Not found');}
    res.writeHead(200,{'Content-Type':types[path.extname(target)]||'application/octet-stream','Content-Length':stat.size,'X-Content-Type-Options':'nosniff','Cache-Control':'no-cache'});
    if(req.method==='HEAD')return res.end();
    fs.createReadStream(target).on('error',()=>res.destroy()).pipe(res);
  });
}).listen(8086,'0.0.0.0',()=>console.log('Whalefall V3 listening on 0.0.0.0:8086; root='+root));
