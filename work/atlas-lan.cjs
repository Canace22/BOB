const http=require('http'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../../outputs');
const simple='鲸落万物生_V5.2_简明设计文档',full='鲸落万物生_V5.2_完整游戏设计';
const actions='拾潮者_3C技能动作_V2';
const allowed=new Set([simple,full,'鲸落万物生_V5_完整游戏设计','鲸落万物生_V5.2_地图原画设计规范',actions,'拾潮者_Wan22动作技能']);
const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'application/javascript; charset=utf-8','.png':'image/png','.jpg':'image/jpeg','.webp':'image/webp','.mp4':'video/mp4','.zip':'application/zip','.svg':'image/svg+xml','.json':'application/json; charset=utf-8','.md':'text/plain; charset=utf-8','.txt':'text/plain; charset=utf-8'};
const server=http.createServer((req,res)=>{
 if(!['GET','HEAD'].includes(req.method)){res.writeHead(405);return res.end();}
 let url;try{url=decodeURIComponent(new URL(req.url,'http://localhost').pathname);}catch{res.writeHead(400);return res.end();}
 if(url==='/'){res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});return res.end('<!doctype html><meta charset="utf-8"><title>鲸落万物生</title><style>body{font:22px/2 sans-serif;background:#10232b;color:#e8dec8;padding:8vw}a{color:#a8dad1;display:block}</style><h1>鲸落万物生 · V5.2</h1><a href="/simple/">简明设计文档</a><a href="/full/">完整地图原画册</a>');}
 if(url==='/simple'||url==='/full'||url==='/actions'){res.writeHead(302,{Location:url+'/'});return res.end();}
 url=url.replace(/^\/simple\//,'/'+simple+'/').replace(/^\/full\//,'/'+full+'/').replace(/^\/actions\//,'/'+actions+'/');
 if(url.endsWith('/'))url+=url.startsWith('/'+simple+'/')?'设计文档.html':url.startsWith('/'+actions+'/')?'动作技能册.html':'原画册.html';
 const parts=url.split('/').filter(Boolean);if(!allowed.has(parts[0])||parts.some(s=>s==='..'||s.includes('\\')||s.includes(':')||s.includes('\0'))){res.writeHead(403);return res.end('Forbidden');}
 const dest=path.resolve(root,...parts),rel=path.relative(root,dest);
 if(rel.startsWith('..')||path.isAbsolute(rel)){res.writeHead(403);return res.end();}
 try{const real=fs.realpathSync(dest),safe=path.relative(root,real);if(safe.startsWith('..')||path.isAbsolute(safe)||!allowed.has(safe.split(path.sep)[0]))throw Error('outside root');const st=fs.statSync(real);if(!st.isFile())throw Error('not file');res.writeHead(200,{'Content-Type':mime[path.extname(real).toLowerCase()]||'application/octet-stream','Content-Length':st.size,'Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});if(req.method==='HEAD')return res.end();fs.createReadStream(real).on('error',()=>res.destroy()).pipe(res);}catch{res.writeHead(404);res.end('Not found');}
});
server.listen(8765,'0.0.0.0',()=>console.log('Whalefall atlas LAN service on port 8765; outputs whitelist only.'));
