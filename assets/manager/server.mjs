import http from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createCatalogStore, RequestError } from './store.mjs';

const defaultRoot = fileURLToPath(new URL('../../', import.meta.url));
const uiFiles = new Set(['index.html', 'app.js', 'styles.css', 'requirements.html', 'requirements.js']);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.gif': 'image/gif', '.json': 'application/json; charset=utf-8', '.md': 'text/plain; charset=utf-8', '.txt': 'text/plain; charset=utf-8' };

function json(res, status, data, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', ...headers });
  res.end(JSON.stringify(data));
}

function localOrigin(req, port) {
  let host;
  try { host = new URL(`http://${req.headers.host}`); } catch { throw new RequestError(403, '仅支持本机访问。'); }
  if (!['127.0.0.1', 'localhost', '[::1]'].includes(host.hostname) || Number(host.port || 80) !== port || host.username || host.password) {
    throw new RequestError(403, '仅支持本机访问。');
  }
  return host.origin;
}

async function body(req) {
  if (req.headers['content-type']?.split(';')[0].trim() !== 'application/json') throw new RequestError(415, '请使用 JSON 提交修改。');
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 65536) throw new RequestError(413, '修改内容超过 64KB。');
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); } catch { throw new RequestError(400, '修改内容不是有效 JSON。'); }
}

async function serveFile(root, pathname, res) {
  const name = decodeURIComponent(pathname);
  const uiName = name === '/' ? 'index.html' : name.slice(1);
  const isUi = uiFiles.has(uiName);
  let directory;
  let file;
  if (isUi) {
    directory = path.join(root, 'assets/manager');
    file = path.join(directory, uiName);
  } else {
    const allowed = ['assets/runtime/', 'assets/source/'].find(prefix => name.startsWith(`/${prefix}`));
    if (!allowed) throw new RequestError(404, '文件不存在。');
    directory = path.join(root, allowed);
    file = path.resolve(root, `.${name}`);
  }
  const [realDirectory, realFile] = await Promise.all([realpath(directory), realpath(file)]);
  if (!realFile.startsWith(realDirectory + path.sep) || !(await stat(realFile)).isFile()) throw new RequestError(403, '不能访问此文件。');
  const extension = path.extname(realFile).toLowerCase();
  const contentType = !isUi && ['.html', '.js', '.css'].includes(extension) ? 'text/plain; charset=utf-8' : types[extension] || 'application/octet-stream';
  res.writeHead(200, { 'Content-Type': contentType, 'Cache-Control': 'no-cache', 'X-Content-Type-Options': 'nosniff' });
  res.end(await readFile(realFile));
}

export function createAssetManager({ root = defaultRoot } = {}) {
  const store = createCatalogStore(path.join(root, 'assets/catalog.json'));
  const server = http.createServer(async (req, res) => {
    try {
      const origin = localOrigin(req, server.address().port);
      const url = new URL(req.url, origin);
      if (url.origin !== origin) throw new RequestError(403, '不能访问其他站点。');
      if (req.method === 'GET' && ['/api/catalog', '/api/catalog/export'].includes(url.pathname)) {
        const headers = url.pathname.endsWith('/export') ? { 'Content-Disposition': 'attachment; filename="bob-art-catalog.json"' } : {};
        json(res, 200, await store.read(), headers);
        return;
      }
      const asset = /^\/api\/assets\/([a-z][a-z0-9-]{0,95})$/.exec(url.pathname);
      if (req.method === 'PATCH' && asset) {
        if (req.headers.origin !== origin) throw new RequestError(403, '请从本机资源管理页面保存修改。');
        json(res, 200, await store.update(asset[1], await body(req)));
        return;
      }
      if (req.method !== 'GET') throw new RequestError(405, '不支持此操作。');
      if (url.pathname === '/favicon.ico') { res.writeHead(204).end(); return; }
      await serveFile(root, url.pathname, res);
    } catch (error) {
      const missing = ['ENOENT', 'ENOTDIR'].includes(error.code);
      const status = error.status || (missing ? 404 : error instanceof URIError ? 400 : 500);
      const message = error.status ? error.message : missing ? '文件不存在。' : status === 400 ? '文件地址无效。' : '读取或保存失败，请检查台账文件及目录权限。';
      if (!res.headersSent) json(res, status, { error: message });
      else res.end();
    }
  });
  return server;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 4176);
  createAssetManager().listen(port, '127.0.0.1', () => console.log(`BOB 美术资源管理 http://127.0.0.1:${port}/`));
}
