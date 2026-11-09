import {createServer} from 'node:http';
import {readFileSync, existsSync} from 'node:fs';
import path from 'node:path';
import {buildLore, output} from './build.mjs';
buildLore();
const types = {'.html':'text/html; charset=utf-8','.css':'text/css','.js':'text/javascript','.json':'application/json','.md':'text/plain; charset=utf-8'};
createServer((req, res) => {
  let url;
  try { url = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); } catch { res.writeHead(400).end(); return; }
  if (url === '/') { res.writeHead(302, {Location:'/BOB/lore/'}).end(); return; }
  const name = url.replace(/^\/BOB\/lore\//, '') || 'index.html';
  const file = path.resolve(output, name);
  if (path.dirname(file) !== output || !existsSync(file)) { res.writeHead(404).end('Not found'); return; }
  res.writeHead(200, {'Content-Type':types[path.extname(file)] || 'application/octet-stream','Cache-Control':'no-store'});
  res.end(readFileSync(file));
}).listen(4191, '127.0.0.1', () => console.log('World archive: http://127.0.0.1:4191/BOB/lore/'));
