import assert from 'node:assert/strict';
import { once } from 'node:events';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createAssetManager } from '../server.mjs';

// Run against a disposable copy. No save request reaches the real catalog.
const repo = fileURLToPath(new URL('../../../', import.meta.url));
const modulePath = process.env.PLAYWRIGHT_MODULE;
const specifier = modulePath && (path.isAbsolute(modulePath) || modulePath.startsWith('.'))
  ? pathToFileURL(path.resolve(modulePath)).href : modulePath || 'playwright';
const { chromium } = await import(specifier);
const realCatalogPath = path.join(repo, 'assets/catalog.json');
const originalCatalog = await fs.readFile(realCatalogPath, 'utf8');
const root = await fs.mkdtemp(path.join(os.tmpdir(), 'bob-art-ui-'));
const catalogPath = path.join(root, 'assets/catalog.json');
const cases = [];
let server, browser;

async function readCatalog() {
  return JSON.parse(await fs.readFile(catalogPath, 'utf8'));
}

async function waitUntilSaved(page) {
  await page.waitForFunction(() => document.getElementById('save-message').textContent.includes('已保存到'));
}

async function browseAssets(page, catalog) {
  const count = catalog.assets.filter(asset => asset.status !== 'archived').length;
  await page.waitForSelector('body[data-ready=true]');
  await page.waitForFunction(expected => {
    const canvases = [...document.querySelectorAll('.asset-card canvas')];
    return canvases.length === expected && canvases.every(canvas => {
      const pixels = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data;
      return pixels.some((value, index) => index % 4 === 3 && value > 0);
    });
  }, count);
  assert.equal(await page.locator('.file-error').count(), 0);
  if (catalog.assets.every(a => a.thumbnail)) {
    const originals = await page.evaluate(() => performance.getEntriesByType('resource').filter(r => /runtime\/sprites\/.+\.png$/.test(new URL(r.name).pathname)).length);
    assert.ok(originals <= 1, 'gallery should load thumbnails and at most the selected original');
  }
  assert.equal(await page.locator('#atlas-image').isVisible(), true);
  await page.locator('#search').fill('life-fragment');
  assert.equal(await page.locator('.asset-card').count(), 1);
  await page.locator('#search').fill('');
  await page.locator('#kind').selectOption('character');
  assert.equal(await page.locator('.asset-card').count(), catalog.assets.filter(asset => asset.kind === 'character' && asset.status !== 'archived').length);
  await page.locator('#kind').selectOption('');
  await page.getByRole('button', { name: '浅', exact: true }).click();
  assert.equal(await page.locator('#gallery').getAttribute('data-backdrop'), 'light');
  await page.getByRole('button', { name: '棋盘', exact: true }).click();
  cases.push(`${count} 项图片实际载入、搜索/类别筛选、图集入口、底色切换`);
}

async function protectDraft(page) {
  await page.locator('#edit-notes').fill('QA 临时草稿');
  await page.locator('[data-asset-id="corpse-crab"]').click();
  assert.equal(await page.locator('#unsaved-dialog').isVisible(), true);
  await page.locator('#keep-editing').click();
  assert.equal(await page.locator('#edit-notes').inputValue(), 'QA 临时草稿');
  await page.locator('[data-asset-id="corpse-crab"]').click();
  await page.locator('#discard').click();
  assert.notEqual(await page.locator('#edit-notes').inputValue(), 'QA 临时草稿');
  cases.push('未保存草稿支持继续编辑与放弃切换');
}

async function persistEdits(page) {
  await page.locator('#edit-name').fill('QA 尸蟹');
  await page.locator('#edit-tags').fill('检查，QA，检查');
  await page.locator('#edit-notes').fill('临时台账持久化检查');
  await page.locator('#edit-status').selectOption('needs-work');
  await page.locator('#save').click();
  await waitUntilSaved(page);
  const edited = (await readCatalog()).assets.find(asset => asset.id === 'corpse-crab');
  assert.equal(edited.name, 'QA 尸蟹');
  assert.equal(edited.status, 'needs-work');
  assert.deepEqual(edited.tags, ['检查', 'QA']);
  await page.reload();
  await page.waitForSelector('body[data-ready=true]');
  await page.getByRole('button', { name: '查看 QA 尸蟹', exact: true }).click();
  assert.equal(await page.locator('#edit-notes').inputValue(), '临时台账持久化检查');
  cases.push('保存写入临时台账、刷新保留、标签去重');
}

async function archiveAndRecover(page) {
  const initialCount = await page.locator('.asset-card').count();
  await page.locator('#edit-status').selectOption('archived');
  await page.locator('#save').click();
  await waitUntilSaved(page);
  assert.equal(await page.locator('.asset-card').count(), initialCount - 1);
  await page.locator('#status-filter').selectOption('archived');
  assert.equal(await page.locator('[data-asset-id="corpse-crab"]').count(), 1);
  await page.locator('#edit-status').selectOption('accepted');
  await page.locator('#save').click();
  await waitUntilSaved(page);
  await page.locator('#status-filter').selectOption('');
  assert.equal(await page.locator('.asset-card').count(), initialCount);

  await page.locator('#edit-notes').fill('冲突草稿要保留');
  const catalog = await readCatalog();
  catalog.revision++;
  await fs.writeFile(catalogPath, JSON.stringify(catalog));
  await page.locator('#save').click();
  await page.waitForSelector('#conflict:not([hidden])');
  assert.equal(await page.locator('#edit-notes').inputValue(), '冲突草稿要保留');
  assert.equal(await page.locator('#save').isEnabled(), true);
  await page.locator('#reload-conflict').click();
  await page.locator('#discard').click();
  await page.waitForFunction(() => document.getElementById('edit-notes').value !== '冲突草稿要保留');

  await page.route('**/api/assets/*', route => route.abort());
  await page.locator('#edit-notes').fill('断网草稿要保留');
  await page.locator('#save').click();
  await page.waitForFunction(() => document.getElementById('save-message').textContent.includes('网络连接中断'));
  assert.equal(await page.locator('#edit-notes').inputValue(), '断网草稿要保留');
  await page.unroute('**/api/assets/*');
  await page.locator('#reset').click();
  cases.push('归档筛出与恢复、版本冲突和网络失败保留草稿');
}

async function checkCoverage(page) {
  const response = await page.request.get('/assets/source/whalefall-v5-2-complete/coverage.json');
  if (!response.ok()) return;
  const coverage = await response.json();
  await page.goto('/requirements.html');
  await page.waitForSelector('body[data-ready=true]');
  assert.equal(await page.locator('.requirement-card').count(), coverage.requirements.length);
  await page.locator('#plan-group').selectOption('ui');
  assert.equal(await page.locator('.requirement-card').count(), coverage.requirements.filter(r => r.group === 'ui').length);
  await page.locator('#plan-group').selectOption('');
  await page.locator('#plan-search').fill('blood-nest-swarm');
  assert.equal(await page.locator('.requirement-card').count(), 1);
  await page.locator('#plan-search').fill('');
  assert.equal(await page.locator('.room-row').count(), coverage.rooms.length);
  assert.equal(await page.locator('#assembly-previews img').count(), (coverage.previews || []).length);
  cases.push('完整需求页家族数量、筛选、资源映射、房间映射与预览入口');
}

try {
  await fs.cp(path.join(repo, 'assets'), path.join(root, 'assets'), { recursive: true });
  server = createAssetManager({ root });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1480, height: 1100 }, baseURL: `http://127.0.0.1:${server.address().port}` });
  page.setDefaultTimeout(15000);
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  await browseAssets(page, await readCatalog());
  await protectDraft(page);
  await persistEdits(page);
  await archiveAndRecover(page);
  await checkCoverage(page);
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForFunction(() => document.documentElement.scrollWidth === 390);
  assert.deepEqual(pageErrors, []);
  assert.equal(await fs.readFile(realCatalogPath, 'utf8'), originalCatalog);
  cases.push('390px 无横溢、无浏览器异常、真实台账未修改');
  console.log(JSON.stringify({ cases, pageErrors, realCatalogModified: false }, null, 2));
} finally {
  await browser?.close();
  if (server?.listening) {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
  await fs.rm(root, { recursive: true, force: true });
}
