import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { dirname, extname, isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const assetRoot = resolve(root, '../docs/鲸腹遗城原画集/V2');
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.woff2': 'font/woff2', '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.md': 'text/plain; charset=utf-8' };
const inside = (base, path) => { const rel = relative(base, path); return rel === '' || (!isAbsolute(rel) && rel !== '..' && !rel.startsWith(`..${sep}`)); };
const fail = (response, status, message) => { response.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8', 'X-Content-Type-Options': 'nosniff' }); response.end(message); };

const server = createServer(async (request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) { fail(response, 405, 'Method not allowed'); return; }
  let pathname;
  try { pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname); }
  catch { fail(response, 400, 'Invalid request'); return; }
  if (pathname.includes('\0') || pathname.includes('\\') || pathname.split('/').includes('..')) { fail(response, 403, 'Forbidden'); return; }
  let base, suffix;
  if (pathname === '/' || pathname === '/mvp-v2' || pathname === '/mvp-v2/') { base = root; suffix = 'index.html'; }
  else if (pathname.startsWith('/mvp-v2/')) { base = root; suffix = pathname.slice('/mvp-v2/'.length); }
  else if (pathname.startsWith('/docs/鲸腹遗城原画集/V2/')) { base = assetRoot; suffix = pathname.slice('/docs/鲸腹遗城原画集/V2/'.length); }
  else { fail(response, 404, 'Not found'); return; }
  if (suffix.split('/').some(segment => segment.startsWith('.'))) { fail(response, 403, 'Forbidden'); return; }
  const path = resolve(base, suffix);
  if (!inside(base, path)) { fail(response, 403, 'Forbidden'); return; }
  try {
    const canonical = await realpath(path);
    if (!inside(await realpath(base), canonical)) { fail(response, 403, 'Forbidden'); return; }
    const info = await stat(canonical);
    if (!info.isFile()) { fail(response, 404, 'Not found'); return; }
    const body = request.method === 'HEAD' ? undefined : await readFile(canonical);
    response.writeHead(200, { 'Content-Type': types[extname(canonical).toLowerCase()] || 'application/octet-stream', 'Content-Length': info.size, 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
    response.end(body);
  } catch (error) { fail(response, error.code === 'ENOENT' || error.code === 'ENOTDIR' ? 404 : 500, error.code === 'ENOENT' || error.code === 'ENOTDIR' ? 'Not found' : 'Unable to read file'); }
});

const port = Number(process.env.PORT || 4176);
server.listen(port, '127.0.0.1', () => console.log(`鲸落万物生 · 2D MVP  http://127.0.0.1:${port}/`));
server.on('error', error => { console.error(`启动失败：${error.message}`); process.exitCode = 1; });
