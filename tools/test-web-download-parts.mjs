import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, cpSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { randomBytes, webcrypto } from 'node:crypto';
import { gunzipSync } from 'node:zlib';
import vm from 'node:vm';
import { buildDownloadEntry, publicationOmissions, includePublicationFile, sha256 } from './web-download-parts.mjs';

const source = randomBytes(180000);
const artifacts = new Map();
const info = buildDownloadEntry(source, 'pck', (file, bytes) => artifacts.set(file, Buffer.from(bytes)), 16384);
assert(info.parts.length > 1 && info.rawParts.length > 1);
for (const part of [...info.parts, ...info.rawParts]) {
  assert(part.bytes <= 16384);
  assert.equal(sha256(artifacts.get(part.file)), part.sha256);
}
assert.deepEqual(gunzipSync(Buffer.concat(info.parts.map(part => artifacts.get(part.file)))), source);
assert.deepEqual(Buffer.concat(info.rawParts.map(part => artifacts.get(part.file))), source);
assert(publicationOmissions({ 'index.pck': info }).has('index.pck'));
const smallSource=Buffer.from('tiny engine');
const small = buildDownloadEntry(smallSource, 'wasm', (file,bytes)=>artifacts.set(file,Buffer.from(bytes)), 16384);
artifacts.set('index.wasm',smallSource);
assert(small.file && !small.rawParts);
assert.equal(publicationOmissions({ 'index.wasm': small }).size, 0);
console.log('PASS chunk size, compressed/raw round trips, hashes, publication omission');

const copyRoot = mkdtempSync(path.join(tmpdir(), 'bob-web-publication-'));
assert.equal(path.dirname(copyRoot), path.resolve(tmpdir()));
try {
  const exported = path.join(copyRoot, 'exported'), published = path.join(copyRoot, 'published');
  mkdirSync(path.join(exported, 'nested'), {recursive:true});
  writeFileSync(path.join(exported, 'index.pck'), source);
  writeFileSync(path.join(exported, 'index.wasm'), smallSource);
  writeFileSync(path.join(exported, 'nested', 'index.pck'), 'keep nested content');
  writeFileSync(path.join(exported, 'index.pck.import'), 'editor metadata');
  for (const part of info.rawParts) writeFileSync(path.join(exported, part.file), artifacts.get(part.file));
  const omitted = publicationOmissions({'index.pck':info});
  cpSync(exported,published,{recursive:true,filter:file=>includePublicationFile(file,exported,omitted)});
  assert(!existsSync(path.join(published,'index.pck')));
  assert(!existsSync(path.join(published,'index.pck.import')));
  assert(existsSync(path.join(published,'index.wasm')));
  assert(existsSync(path.join(published,'nested','index.pck')));
  for (const part of info.rawParts) assert.equal(sha256(readFileSync(path.join(published,part.file))),part.sha256);
  console.log('PASS real filesystem copy omits root PCK on Windows namespaced paths');
} finally {
  assert.equal(path.dirname(copyRoot), path.resolve(tmpdir()));
  assert(path.basename(copyRoot).startsWith('bob-web-publication-'));
  rmSync(copyRoot,{recursive:true});
}

const loader = readFileSync(new URL('../game/web/preload.js', import.meta.url), 'utf8');
const base = 'http://localhost:4187/';
function browser({ decompression = true, cacheEnabled = true, failFile = '', corruptCache = false } = {}) {
  const stored = new Map();
  const calls = [];
  const label = { textContent: '' };
  const cache = {
    async match(url) { return stored.get(url)?.clone(); },
    async put(url, response) { stored.set(url, response.clone()); },
    async delete(url) { return stored.delete(typeof url === 'string' ? url : url.url); },
    async keys() { return [...stored.keys()].map(url => new Request(url)); },
  };
  if (corruptCache) stored.set(base + info.parts[0].file, new Response(Buffer.alloc(info.parts[0].bytes)));
  const window = {
    BOB_WEB_FILES: { 'index.pck': info, 'index.wasm': small }, crypto: webcrypto,
    caches: { async open() { if (!cacheEnabled) throw new Error('Storage disabled'); return cache; } },
    async fetch(input, init) {
      const url = typeof input === 'string' ? input : input.url;
      const file = new URL(url, base).pathname.slice(1);
      calls.push({ file, signal: init?.signal, method: init?.method || input.method || 'GET' });
      if (file === failFile) return new Response('missing', { status: 404 });
      if (!artifacts.has(file)) throw new Error('Unpublished or unexpected file requested: ' + file);
      return new Response(artifacts.get(file));
    },
  };
  vm.runInNewContext(loader, {
    window, document: { baseURI: base + 'index.html', getElementById() { return label; } },
    URL, Request, Response, ReadableStream, TransformStream,
    DecompressionStream: decompression ? DecompressionStream : undefined,
  });
  return { window, calls, stored, label };
}
for (const options of [{}, { decompression: false }, { cacheEnabled: false }, { corruptCache: true }, { failFile: info.parts[0].file }]) {
  const b = browser(options);
  const response = await b.window.fetch(base + 'index.pck');
  assert.equal(response.headers.get('content-length'), String(source.length));
  assert.deepEqual(Buffer.from(await response.arrayBuffer()), source);
  assert(!b.calls.some(call => call.file === 'index.pck'));
  console.log('PASS streamed startup ' + JSON.stringify(options));
}
const warm = browser();
for (const options of [{}, { decompression: false }, { decompression: false, cacheEnabled: false }]) {
  const b=browser(options);
  assert.deepEqual(Buffer.from(await (await b.window.fetch(base+'index.wasm')).arrayBuffer()),smallSource);
  assert(b.calls.some(call=>call.file===(options.decompression===false?'index.wasm':small.file)));
  console.log('PASS small WASM startup '+JSON.stringify(options));
}
await (await warm.window.fetch(base + 'index.pck')).arrayBuffer();
await new Promise(resolve => setTimeout(resolve, 0));
warm.calls.length = 0;
assert.deepEqual(Buffer.from(await (await warm.window.fetch(base + 'index.pck')).arrayBuffer()), source);
assert.equal(warm.calls.length, 0);
console.log('PASS warm cache makes no network requests');
const broken = browser({ failFile: info.parts[1].file });
await assert.rejects(async () => (await broken.window.fetch(base + 'index.pck')).arrayBuffer());
assert.match(broken.label.textContent, /失败/);
console.log('PASS missing later part fails visibly instead of starting corrupt data');
