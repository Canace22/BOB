import test from 'node:test';
import assert from 'node:assert/strict';
import { request } from 'node:http';
import { mkdir, mkdtemp, realpath, rm, writeFile } from 'node:fs/promises';
import { dirname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createPreviewServer } from '../preview.mjs';
import { createDevelopmentServer } from '../server.mjs';

const testRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../output/tests');

async function fixture(t) {
  await mkdir(testRoot, { recursive: true });
  const previewRoot = await mkdtemp(resolve(testRoot, 'preview-'));
  for (const id of ['version-a', 'version-b']) {
    const build = resolve(previewRoot, 'releases', id);
    await mkdir(resolve(build, 'mvp-v2/assets'), { recursive: true });
    await mkdir(resolve(build, 'assets/runtime/sprites/tide-picker'), { recursive: true });
    await mkdir(resolve(build, 'docs/鲸腹遗城原画集/V2/images'), { recursive: true });
    await writeFile(resolve(build, 'mvp-v2/index.html'), `<html><head><base href="/build/${id}/mvp-v2/"></head><body>${id}</body></html>`);
    await writeFile(resolve(build, 'mvp-v2/game.js'), `export const version = '${id}';`);
    await writeFile(resolve(build, 'mvp-v2/assets/bone.png'), `bone-${id}`);
    await writeFile(resolve(build, 'assets/runtime/sprites/tide-picker/idle-right.png'), `picker-${id}`);
    await writeFile(resolve(build, 'docs/鲸腹遗城原画集/V2/images/title.png'), `title-${id}`);
  }
  const activate = id => writeFile(resolve(previewRoot, 'active.json'), JSON.stringify({ id }));
  await activate('version-a');
  const server = createPreviewServer({ previewRoot });
  await new Promise((accept, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', accept);
  });
  t.after(async () => {
    server.closeAllConnections();
    await new Promise(accept => server.close(accept));
    // Delete only the unique fixture created above, never the real .preview tree.
    const canonicalRoot = await realpath(testRoot), canonicalFixture = await realpath(previewRoot);
    assert(canonicalFixture.startsWith(`${canonicalRoot}${sep}preview-`));
    assert.equal(dirname(canonicalFixture), canonicalRoot);
    await rm(canonicalFixture, { recursive: true });
  });
  return { activate, origin: `http://127.0.0.1:${server.address().port}` };
}

function raw(origin, path, method = 'GET') {
  return new Promise((accept, reject) => {
    // node:http preserves dot segments; fetch/URL would normalize them first.
    const req = request(origin, { path, method }, response => {
      const chunks = [];
      response.on('data', chunk => chunks.push(chunk));
      response.on('end', () => accept({ status: response.statusCode, headers: response.headers, body: Buffer.concat(chunks).toString('utf8') }));
    });
    req.on('error', reject);
    req.end();
  });
}

test('publishing changes new visits while an already opened build keeps its original files', async t => {
  const { origin, activate } = await fixture(t);
  const first = await raw(origin, '/');
  assert.equal(first.status, 302);
  assert.equal(first.headers.location, '/build/version-a/mvp-v2/');
  assert.equal(first.headers['cache-control'], 'no-store');
  const originalPage = await raw(origin, first.headers.location);
  const originalModule = await raw(origin, `${first.headers.location}game.js`);
  const sharedAssetPath = '/build/version-a/assets/runtime/sprites/tide-picker/idle-right.png';
  const originalSprite = await raw(origin, sharedAssetPath);
  assert.equal(originalSprite.status, 200);
  assert.equal(originalPage.status, 200);
  assert.match(originalPage.headers['cache-control'], /immutable/);

  await activate('version-b');
  const next = await raw(origin, '/');
  assert.equal(next.headers.location, '/build/version-b/mvp-v2/');
  assert.match((await raw(origin, next.headers.location)).body, /version-b/);
  assert.equal((await raw(origin, first.headers.location)).body, originalPage.body);
  assert.equal((await raw(origin, `${first.headers.location}game.js`)).body, originalModule.body);
  assert.equal((await raw(origin, sharedAssetPath)).body, originalSprite.body);
  assert.equal((await raw(origin, '/build/version-b/assets/runtime/sprites/tide-picker/idle-right.png')).body, 'picker-version-b');
  const status = await raw(origin, '/__preview/status');
  assert.equal(status.status, 200);
  assert.deepEqual(JSON.parse(status.body), {
    service: 'whalefall-preview', release: 'version-b', id: 'version-b', entry: '/build/version-b/mvp-v2/',
  });
  assert.equal(status.headers['cache-control'], 'no-store');
});

test('snapshot-local assets, Unicode document paths, legacy entry links and HEAD requests work', async t => {
  const { origin } = await fixture(t);
  const asset = await raw(origin, '/build/version-a/mvp-v2/assets/bone.png');
  assert.equal(asset.status, 200);
  assert.equal(asset.body, 'bone-version-a');
  assert.equal(asset.headers['content-type'], 'image/png');
  const shared = await raw(origin, '/build/version-a/assets/runtime/sprites/tide-picker/idle-right.png');
  assert.equal(shared.status, 200);
  assert.equal(shared.headers['content-type'], 'image/png');
  assert.equal(shared.body, 'picker-version-a');
  const document = await raw(origin, `/build/version-a/docs/${encodeURIComponent('鲸腹遗城原画集')}/V2/images/title.png`);
  assert.equal(document.status, 200);
  assert.equal(document.body, 'title-version-a');
  const head = await raw(origin, '/build/version-a/mvp-v2/assets/bone.png', 'HEAD');
  assert.equal(head.status, 200);
  assert.equal(head.body, '');
  assert.equal(Number(head.headers['content-length']), Buffer.byteLength(asset.body));
  const legacy = await raw(origin, '/mvp-v2/scene-lab.html');
  assert.equal(legacy.status, 302);
  assert.equal(legacy.headers.location, '/build/version-a/mvp-v2/scene-lab.html');
});

test('development serves runtime sprites without exposing source art or traversal paths', async t => {
  const server = createDevelopmentServer();
  await new Promise((accept, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', accept);
  });
  t.after(async () => {
    server.closeAllConnections();
    await new Promise(accept => server.close(accept));
  });
  const origin = `http://127.0.0.1:${server.address().port}`;
  const sprite = await raw(origin, '/assets/runtime/sprites/tide-picker/idle-right.png', 'HEAD');
  assert.equal(sprite.status, 200);
  assert.equal(sprite.headers['content-type'], 'image/png');
  assert(Number(sprite.headers['content-length']) > 0);
  assert.equal(sprite.body, '');
  assert.equal((await raw(origin, '/assets/source/tide-picker/idle-right.png')).status, 404);
  assert.equal((await raw(origin, '/assets/catalog.json')).status, 404);
  for (const path of [
    '/assets/runtime/sprites/../../../catalog.json',
    '/assets/runtime/sprites/%2e%2e/%2e%2e/catalog.json',
    '/assets/runtime/sprites/%5csecret',
    '/assets/runtime/sprites/.private.png',
  ]) assert.equal((await raw(origin, path)).status, 403, path);
});

test('preview blocks raw and encoded traversal, hidden files and mutation methods', async t => {
  const { origin } = await fixture(t);
  for (const path of [
    '/build/version-a/../active.json',
    '/build/version-a/%2e%2e/active.json',
    '/build/version-a/%2e%2e%2factive.json',
    '/build/version-a/%5csecret',
    '/build/version-a/mvp-v2/index.html%00',
    '/build/version-a/C:/secret',
    '/.preview/active.json',
  ]) assert.equal((await raw(origin, path)).status, 403, path);
  assert.equal((await raw(origin, '/build/version-a/mvp-v2/%invalid')).status, 400);
  assert.equal((await raw(origin, '/build/missing/mvp-v2/')).status, 404);
  assert.equal((await raw(origin, '/__preview/status', 'POST')).status, 405);
  assert.equal((await raw(origin, '/build/version-a/mvp-v2/game.js', 'PUT')).status, 405);
});
