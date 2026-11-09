import assert from 'node:assert/strict';
import http from 'node:http';
import { once } from 'node:events';
import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { previewOutput } from '../build.mjs';

const modulePath = process.env.PLAYWRIGHT_MODULE;
const { chromium } = await import(modulePath ? pathToFileURL(path.resolve(modulePath)).href : 'playwright');
const prefix = '/BOB/art/';
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.webp': 'image/webp' };
let server, browser;
const cases = [], errors = [], failures = [], writes = [];

try {
  let url = process.env.ART_PREVIEW_URL;
  if (!url) {
    server = http.createServer(async (req, res) => {
      try {
        const pathname = new URL(req.url, 'http://localhost').pathname;
        if (!pathname.startsWith(prefix)) throw new Error('Wrong prefix');
        const file = path.resolve(previewOutput, decodeURIComponent(pathname.slice(prefix.length)) || 'index.html');
        if (!file.startsWith(previewOutput + path.sep)) throw new Error('Wrong path');
        const bytes = await fs.readFile(file);
        res.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream' }).end(bytes);
      } catch { res.writeHead(404).end(); }
    }).listen(0, '127.0.0.1');
    await once(server, 'listening');
    url = `http://127.0.0.1:${server.address().port}${prefix}`;
  }
  browser = await chromium.launch({ headless: true, channel: process.env.PLAYWRIGHT_CHANNEL || 'chrome' });
  const page = await browser.newPage({ viewport: { width: 1480, height: 1100 } });
  page.setDefaultTimeout(60000);
  page.on('pageerror', error => errors.push(error.message));
  page.on('response', response => { if (response.status() >= 400) failures.push(`${response.status()} ${response.url()}`); });
  page.on('request', request => { if (request.method() !== 'GET') writes.push(request.url()); });
  const catalogResponse = await page.request.get(new URL('catalog.json', url).href);
  assert.equal(catalogResponse.ok(), true);
  const catalog = await catalogResponse.json();
  await page.goto(url);
  await page.waitForSelector('body[data-ready=true]');
  const expected = catalog.assets.filter(asset => asset.status !== 'archived').length;
  await page.waitForFunction(count => {
    const canvases = [...document.querySelectorAll('.asset-card canvas')];
    return canvases.length === count && canvases.every(canvas => canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data.some((value, index) => index % 4 === 3 && value > 0));
  }, expected);
  assert.equal(await page.locator('#edit-name').isDisabled(), true);
  assert.equal(await page.locator('.save-actions').isVisible(), false);
  assert.equal(await page.locator('#save-state').textContent(), '只读预览');
  cases.push(`${expected} 项图片实际加载，管理信息只读，无保存入口`);

  await page.locator('#search').fill('life-fragment');
  assert.equal(await page.locator('.asset-card').count(), catalog.assets.filter(a => [a.id,a.name,...a.tags].join(' ').toLowerCase().includes('life-fragment')).length);
  await page.locator('#search').fill('');
  await page.locator('#kind').selectOption('character');
  assert.equal(await page.locator('.asset-card').count(), catalog.assets.filter(a => a.kind === 'character' && a.status !== 'archived').length);
  await page.locator('#kind').selectOption('');
  await page.getByRole('button', { name: '浅', exact: true }).click();
  assert.equal(await page.locator('#gallery').getAttribute('data-backdrop'), 'light');
  await page.locator('#zoom').fill('200');
  assert.equal(await page.locator('#zoom-value').textContent(), '200%');
  for (const id of ['download', 'atlas-image', 'atlas-json', 'catalog-export']) {
    const href = await page.locator(`#${id}`).getAttribute('href');
    assert.equal(new URL(href, url).pathname.startsWith(prefix), true);
    assert.equal((await page.request.get(new URL(href, url).href)).ok(), true);
  }
  cases.push('搜索、分类、底色、200% 放大及原图/图集/清单下载');

  await page.getByRole('link', { name: '完整需求与缺项', exact: true }).click();
  await page.waitForSelector('body[data-ready=true]');
  const coverage = await (await page.request.get(new URL('assets/source/whalefall-v5-2-complete/coverage.json', url).href)).json();
  assert.equal(await page.locator('.requirement-card').count(), coverage.requirements.length);
  await page.locator('#plan-group').selectOption('ui');
  assert.equal(await page.locator('.requirement-card').count(), coverage.requirements.filter(r => r.group === 'ui').length);
  await page.getByText('场景与状态拼装预览', { exact: true }).click();
  await page.waitForFunction(() => [...document.querySelectorAll('#assembly-previews img')].every(img => img.complete && img.naturalWidth > 0));
  assert.equal(await page.locator('#assembly-previews img').count(), coverage.previews.length);
  await page.getByRole('link', { name: '查看已入库素材' }).click();
  await page.waitForSelector('body[data-ready=true]');
  await page.reload();
  await page.waitForSelector('body[data-ready=true]');
  cases.push(`${coverage.requirements.length} 个需求家族、${coverage.previews.length} 项拼装预览、页面往返与刷新`);

  await page.setViewportSize({ width: 390, height: 844 });
  assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), 390);
  assert.deepEqual(errors, []);
  assert.deepEqual(failures, []);
  assert.deepEqual(writes, []);
  const evidence = new URL('../../../game/build/qa/art-preview/', import.meta.url);
  await fs.mkdir(evidence, { recursive: true });
  await page.screenshot({ path: new URL('mobile.png', evidence).pathname.replace(/^\/(\w:)/, '$1') });
  await page.setViewportSize({ width: 1480, height: 1100 });
  await page.screenshot({ path: new URL('desktop.png', evidence).pathname.replace(/^\/(\w:)/, '$1') });
  cases.push('390px 页面无横溢，无脚本错误、失败请求或写请求');
  console.log(JSON.stringify({ url, cases, errors, failures, writes }, null, 2));
} finally {
  await browser?.close();
  if (server) { server.closeAllConnections(); await new Promise(resolve => server.close(resolve)); }
}
