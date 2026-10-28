import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../build/web');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (!url.pathname.startsWith('/BOB/godot/')) { response.writeHead(404).end(); return; }
  const file = path.resolve(root, '.' + decodeURIComponent(url.pathname.slice('/BOB/godot'.length)), url.pathname.endsWith('/') ? 'index.html' : '');
  if (!file.startsWith(root + path.sep) || !existsSync(file) || !statSync(file).isFile()) { response.writeHead(404).end(); return; }
  response.setHeader('Content-Type', types[path.extname(file)] ?? 'application/octet-stream');
  response.setHeader('Cache-Control', 'no-store');
  response.end(readFileSync(file));
}).listen(Number(process.env.PORT ?? 4187), '127.0.0.1', () => console.log('Godot test server: http://127.0.0.1:4187/BOB/godot/'));
