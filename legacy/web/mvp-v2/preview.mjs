import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { dirname, extname, isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { networkInterfaces } from 'node:os';

const sourceRoot = dirname(fileURLToPath(import.meta.url));
const RELEASE_ID = /^[a-z0-9][a-z0-9-]{0,79}$/;
const types = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.woff2': 'font/woff2',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.md': 'text/plain; charset=utf-8',
};
const inside = (base, path) => {
  const rel = relative(base, path);
  return rel === '' || (!isAbsolute(rel) && rel !== '..' && !rel.startsWith(`..${sep}`));
};
const fail = (response, status, message) => {
  response.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
  response.end(message);
};

export function createPreviewServer({ previewRoot = resolve(sourceRoot, '.preview') } = {}) {
  const releases = resolve(previewRoot, 'releases');
  const active = async () => {
    const marker = JSON.parse(await readFile(resolve(previewRoot, 'active.json'), 'utf8'));
    if (!RELEASE_ID.test(marker.id)) throw new Error('Invalid active release');
    await stat(resolve(releases, marker.id, 'mvp-v2/index.html'));
    return marker;
  };
  return createServer(async (request, response) => {
    if (!['GET', 'HEAD'].includes(request.method)) { fail(response, 405, 'Method not allowed'); return; }
    let pathname;
    // Validate before URL normalization can hide a dot-dot traversal segment.
    try { pathname = decodeURIComponent(request.url.split('?')[0]); }
    catch { fail(response, 400, 'Invalid request'); return; }
    if (!pathname.startsWith('/') || pathname.includes('\0') || pathname.includes('\\') || pathname.includes(':') || pathname.split('/').some(segment => segment.startsWith('.'))) {
      fail(response, 403, 'Forbidden'); return;
    }
    try {
      if (pathname === '/health' || pathname === '/__preview/status') {
        const marker = await active();
        const body = JSON.stringify({ service: 'whalefall-preview', release: marker.id, id: marker.id, entry: `/build/${marker.id}/mvp-v2/` });
        response.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Length': Buffer.byteLength(body) });
        response.end(request.method === 'HEAD' ? undefined : body); return;
      }
      if (pathname === '/' || pathname === '/mvp-v2' || pathname.startsWith('/mvp-v2/')) {
        const marker = await active();
        const suffix = pathname.startsWith('/mvp-v2/') ? pathname.slice('/mvp-v2/'.length) : '';
        response.writeHead(302, { Location: `/build/${marker.id}/mvp-v2/${suffix}`, 'Cache-Control': 'no-store' });
        response.end(); return;
      }
      const match = /^\/build\/([^/]+)\/(.*)$/.exec(pathname);
      if (!match || !RELEASE_ID.test(match[1])) { fail(response, 404, 'Not found'); return; }
      const [, id, suffix] = match;
      const base = resolve(releases, id);
      const path = resolve(base, suffix.endsWith('/') ? `${suffix}index.html` : suffix);
      if (!inside(base, path)) { fail(response, 403, 'Forbidden'); return; }
      const [canonicalReleases, canonicalBase, canonical] = await Promise.all([realpath(releases), realpath(base), realpath(path)]);
      if (!inside(canonicalReleases, canonicalBase) || !inside(canonicalBase, canonical)) { fail(response, 403, 'Forbidden'); return; }
      const info = await stat(canonical);
      if (!info.isFile()) { fail(response, 404, 'Not found'); return; }
      const body = request.method === 'HEAD' ? undefined : await readFile(canonical);
      response.writeHead(200, {
        'Content-Type': types[extname(canonical).toLowerCase()] || 'application/octet-stream',
        'Content-Length': info.size, 'Cache-Control': 'public, max-age=31536000, immutable',
        'X-Content-Type-Options': 'nosniff',
      });
      response.end(body);
    } catch (error) {
      const unavailable = ['ENOENT', 'ENOTDIR'].includes(error.code);
      if (pathname === '/' || pathname === '/health' || pathname === '/__preview/status' || pathname.startsWith('/mvp-v2')) {
        fail(response, 503, 'No complete preview release. Run node publish-preview.mjs first.');
      } else fail(response, unavailable ? 404 : 500, unavailable ? 'Not found' : 'Unable to read preview');
    }
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 4175);
  const host = process.env.HOST || '0.0.0.0';
  const server = createPreviewServer();
  server.listen(port, host, () => {
    console.log(`鲸落万物生 · 稳定试玩 http://127.0.0.1:${port}/`);
    if (host === '0.0.0.0') for (const addresses of Object.values(networkInterfaces())) {
      for (const address of addresses || []) if (address.family === 'IPv4' && !address.internal) console.log(`局域网试玩 http://${address.address}:${port}/`);
    }
  });
  server.on('error', error => { console.error(`稳定试玩启动失败：${error.message}`); process.exitCode = 1; });
}
