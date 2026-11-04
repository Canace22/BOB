import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const story = process.argv.includes('--story');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), story ? '../build/story-web' : '../build/web');
const prefix = story ? '/BOB/godot-story/' : '/BOB/godot/';
const port = Number(process.env.PORT ?? (story ? 4193 : 4187));
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (!url.pathname.startsWith(prefix)) { response.writeHead(404).end(); return; }
  const file = path.resolve(root, '.' + decodeURIComponent(url.pathname.slice(prefix.length - 1)), url.pathname.endsWith('/') ? 'index.html' : '');
  if (!file.startsWith(root + path.sep) || !existsSync(file) || !statSync(file).isFile()) { response.writeHead(404).end(); return; }
  response.setHeader('Content-Type', types[path.extname(file)] ?? 'application/octet-stream');
  response.setHeader('Cache-Control', 'no-store');
  response.end(readFileSync(file));
}).listen(port, '127.0.0.1', () => console.log(`Godot test server: http://127.0.0.1:${port}${prefix}`));
