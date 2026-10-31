import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { dirname, extname, isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

// Plain static hosting, with no development asset mounts or URL rewriting.
export async function startPagesServer({ root = resolve(dirname(fileURLToPath(import.meta.url)), '../../../../.pages-dist'), prefix = '/BOB/' } = {}) {
  if (!/^\/[a-zA-Z0-9_-]+\/$/.test(prefix)) throw new Error('Expected a single project prefix such as /BOB/.');
  const canonicalRoot = await realpath(root);
  const inside = path => {
    const suffix = relative(canonicalRoot, path);
    return suffix !== '' && !isAbsolute(suffix) && suffix !== '..' && !suffix.startsWith(`..${sep}`);
  };
  const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.png': 'image/png', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.ico': 'image/x-icon' };
  const server = createServer(async (request, response) => {
    if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405); response.end('Method not allowed'); return; }
    try {
      const pathname = decodeURIComponent(request.url.split('?')[0]);
      if (!pathname.startsWith(prefix) || pathname.includes('\\') || pathname.includes('\0') || pathname.includes(':') || pathname.split('/').includes('..')) throw new Error('Invalid path');
      const suffix = pathname.slice(prefix.length);
      const candidate = resolve(canonicalRoot, suffix.endsWith('/') || !suffix ? `${suffix}index.html` : suffix);
      if (!inside(candidate)) throw new Error('Path escaped the build');
      const path = await realpath(candidate);
      if (!inside(path)) throw new Error('Linked file escaped the build');
      const info = await stat(path);
      if (!info.isFile()) throw new Error('Not a file');
      const body = request.method === 'HEAD' ? undefined : await readFile(path);
      response.writeHead(200, { 'Content-Type': types[extname(path)] || 'application/octet-stream', 'Content-Length': info.size, 'Cache-Control': 'no-store' });
      response.end(body);
    } catch { response.writeHead(404); response.end('Not found'); }
  });
  await new Promise((accept, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', accept); });
  const origin = `http://127.0.0.1:${server.address().port}`;
  return {
    server, origin, prefix, url: `${origin}${prefix}mvp-v2/`,
    async close() { server.closeAllConnections(); await new Promise((accept, reject) => server.close(error => error ? reject(error) : accept())); },
  };
}
