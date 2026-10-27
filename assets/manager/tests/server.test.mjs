import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { once } from 'node:events';
import http from 'node:http';
import { createAssetManager } from '../server.mjs';

async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), 'bob-art-manager-'));
  for (const dir of ['assets/manager', 'assets/runtime/sprites/hero', 'assets/source/hero']) await mkdir(path.join(root, dir), { recursive: true });
  const catalog = { schemaVersion: 1, revision: 1, assets: [{ id: 'hero', name: '拾潮者', status: 'accepted', tags: [], notes: '', file: 'assets/runtime/sprites/hero/idle.png', qa: { passed: true } }] };
  await writeFile(path.join(root, 'assets/catalog.json'), JSON.stringify(catalog));
  await writeFile(path.join(root, 'assets/manager/index.html'), '<h1>美术资源</h1>');
  await writeFile(path.join(root, 'assets/runtime/sprites/hero/idle.png'), 'image fixture');
  await writeFile(path.join(root, 'secret.txt'), 'private');
  const server = createAssetManager({ root });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  t.after(async () => { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); await rm(root, { recursive: true, force: true }); });
  const patch = (data, headers = {}) => fetch(`${base}/api/assets/hero`, { method: 'PATCH', headers: { Origin: base, 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(data) });
  return { root, base, server, patch };
}

test('保存允许字段并持久化，保留资源路径与验收证据', async t => {
  const { root, base, patch } = await fixture(t);
  const response = await patch({ revision: 1, name: ' 拾潮者 · 站立 ', tags: ['角色', '角色', ' 主角 '], notes: '待补左向姿态', status: 'needs-work' });
  assert.equal(response.status, 200);
  const result = await response.json();
  assert.equal(result.revision, 2); assert.deepEqual(result.assets[0].tags, ['角色', '主角']);
  assert.equal(result.assets[0].name, '拾潮者 · 站立'); assert.equal(result.assets[0].file, 'assets/runtime/sprites/hero/idle.png');
  assert.deepEqual(result.assets[0].qa, { passed: true });
  assert.deepEqual(JSON.parse(await readFile(path.join(root, 'assets/catalog.json'), 'utf8')), result);
  const restarted = createAssetManager({ root }); restarted.listen(0, '127.0.0.1'); await once(restarted, 'listening');
  const read = await fetch(`http://127.0.0.1:${restarted.address().port}/api/catalog`); assert.deepEqual(await read.json(), result);
  restarted.closeAllConnections(); await new Promise(resolve => restarted.close(resolve));
  const exported = await fetch(`${base}/api/catalog/export`); assert.match(exported.headers.get('content-disposition'), /attachment/); assert.deepEqual(await exported.json(), result);
});

test('非法字段或参数不会破坏台账', async t => {
  const { base, patch } = await fixture(t);
  for (const fields of [{ file: '../../secret.txt' }, { status: 'integrated' }, { name: ' ' }, { tags: [12] }, { notes: 'a'.repeat(4001) }, {}]) {
    assert.equal((await patch({ revision: 1, ...fields })).status, 400);
  }
  assert.equal((await patch({ name: 'No revision' })).status, 400);
  assert.equal((await (await fetch(`${base}/api/catalog`)).json()).revision, 1);
});

test('并发同版本写入只成功一次，旧版本返回409', async t => {
  const { base, patch } = await fixture(t);
  const responses = await Promise.all([patch({ revision: 1, notes: 'one' }), patch({ revision: 1, notes: 'two' })]);
  assert.deepEqual(responses.map(r => r.status).sort(), [200, 409]);
  const catalog = await (await fetch(`${base}/api/catalog`)).json(); assert.equal(catalog.revision, 2);
  assert.equal((await patch({ revision: 1, status: 'archived' })).status, 409);
  assert.equal((await patch({ revision: 2, status: 'archived' })).status, 200);
});

test('只提供管理页和资源目录文件，拒绝目录穿越与符号链接越界', async t => {
  const { root, base } = await fixture(t);
  assert.equal((await fetch(base)).status, 200);
  const image = await fetch(`${base}/assets/runtime/sprites/hero/idle.png`); assert.equal(image.status, 200); assert.equal(image.headers.get('content-type'), 'image/png');
  assert.equal((await fetch(`${base}/assets/catalog.json`)).status, 404);
  assert.equal((await fetch(`${base}/secret.txt`)).status, 404);
  assert.equal((await fetch(`${base}/assets/runtime/%2e%2e%2f%2e%2e%2fsecret.txt`)).status, 403);
  await symlink(path.join(root, 'secret.txt'), path.join(root, 'assets/source/hero/secret.txt'));
  assert.equal((await fetch(`${base}/assets/source/hero/secret.txt`)).status, 403);
});

test('跨源、伪造Host、无Origin及过大请求被拒绝', async t => {
  const { base, patch } = await fixture(t);
  assert.equal((await patch({ revision: 1, notes: 'bad' }, { Origin: 'https://example.com' })).status, 403);
  const forgedHostStatus = await new Promise((resolve, reject) => {
    const request = http.request(`${base}/api/catalog`, { headers: { Host: 'example.com' } }, response => { response.resume(); resolve(response.statusCode); });
    request.on('error', reject); request.end();
  });
  assert.equal(forgedHostStatus, 403);
  assert.equal((await fetch(`${base}/api/assets/hero`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: '{}' })).status, 403);
  assert.equal((await patch({ revision: 1, notes: 'bad' }, { 'Content-Type': 'text/plain' })).status, 415);
  assert.equal((await patch({ revision: 1, notes: 'x'.repeat(70000) })).status, 413);
  const response = await fetch(`${base}/api/catalog`); assert.equal(response.headers.get('access-control-allow-origin'), null);
  assert.equal((await response.json()).revision, 1);
});
