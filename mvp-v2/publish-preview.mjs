import { copyFile, mkdir, readFile, readdir, rename, writeFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { dirname, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const sourceRoot = dirname(fileURLToPath(import.meta.url));
const previewRoot = resolve(sourceRoot, '.preview');
const id = `${new Date().toISOString().replace(/[-:.]/g, '').toLowerCase()}-${randomBytes(3).toString('hex')}`;
const staging = resolve(previewRoot, `staging-${id}`);
const release = resolve(previewRoot, 'releases', id);
const entry = `/build/${id}/mvp-v2/`;
const files = [];

async function copy(source, relativePath) {
  const destination = resolve(staging, relativePath);
  await mkdir(dirname(destination), { recursive: true });
  if (extname(source) === '.html') {
    let html = await readFile(source, 'utf8');
    const base = `<base href="${entry}" />`;
    html = /<base\b[^>]*>/i.test(html) ? html.replace(/<base\b[^>]*>/i, base) : html.replace(/<head([^>]*)>/i, `<head$1>\n  ${base}`);
    await writeFile(destination, html, 'utf8');
  } else await copyFile(source, destination);
  files.push(relativePath.replaceAll('\\', '/'));
}

async function copyAssets(source, relativePath) {
  for (const item of await readdir(source, { withFileTypes: true })) {
    if (item.name.startsWith('.')) continue;
    const path = resolve(source, item.name), target = `${relativePath}/${item.name}`;
    if (item.isDirectory()) await copyAssets(path, target);
    else if (item.isFile()) await copy(path, target);
    else throw new Error(`Asset links are not allowed in snapshots: ${path}`);
  }
}

await mkdir(resolve(previewRoot, 'releases'), { recursive: true });
await mkdir(staging);
// Runtime modules live at the game root. Tool/server scripts use .mjs and never ship.
for (const item of await readdir(sourceRoot, { withFileTypes: true })) {
  if (item.isFile() && ['.js', '.html', '.css'].includes(extname(item.name))) {
    await copy(resolve(sourceRoot, item.name), `mvp-v2/${item.name}`);
  }
}
for (const required of ['index.html', 'game.js', 'engine.js', 'levels.js', 'renderer.js', 'style.css']) {
  if (!files.includes(`mvp-v2/${required}`)) throw new Error(`Missing runtime file: ${required}`);
}
await copyAssets(resolve(sourceRoot, 'assets'), 'mvp-v2/assets');
for (const doc of ['README.md', 'SCENE_PIPELINE.md']) await copy(resolve(sourceRoot, doc), `mvp-v2/${doc}`);
const title = 'docs/鲸腹遗城原画集/V2/images/A01_鲸落万物生_世界主视觉.png';
await copy(resolve(sourceRoot, '..', title), title);

const marker = { id, publishedAt: new Date().toISOString(), entry, files: files.sort() };
await writeFile(resolve(staging, 'release.json'), JSON.stringify(marker, null, 2), 'utf8');
// A release becomes addressable only after every file exists; old builds are retained.
await rename(staging, release);
const markerTemp = resolve(previewRoot, `active-${id}.tmp`);
await writeFile(markerTemp, JSON.stringify(marker, null, 2), 'utf8');
await rename(markerTemp, resolve(previewRoot, 'active.json'));
console.log(JSON.stringify({ id, entry, files: files.length, url: `http://127.0.0.1:4175${entry}` }, null, 2));
