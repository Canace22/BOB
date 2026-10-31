import { readFileSync, writeFileSync, readdirSync, unlinkSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { gzipSync, gunzipSync } from 'node:zlib';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const web = path.join(root, 'game/build/web');
for (const file of readdirSync(web)) if (/^(wasm|pck)\.[0-9a-f]{16}\.gz$/.test(file)) unlinkSync(path.join(web, file));
const manifest = {};
for (const extension of ['wasm', 'pck']) {
  const data = readFileSync(path.join(web, `index.${extension}`));
  const packed = gzipSync(data, { level: 9 });
  if (!gunzipSync(packed).equals(data)) throw new Error(`Compression verification failed: ${extension}`);
  const hash = createHash('sha256').update(packed).digest('hex').slice(0, 16);
  const file = `${extension}.${hash}.gz`;
  writeFileSync(path.join(web, file), packed);
  manifest[`index.${extension}`] = { file, packedBytes: packed.length, rawBytes: data.length, type: extension === 'wasm' ? 'application/wasm' : 'application/octet-stream' };
}
const loader = readFileSync(path.join(root, 'game/web/preload.js'), 'utf8');
const target = path.join(web, 'index.html');
let html = readFileSync(target, 'utf8');
const marker = '<script src="index.js"></script>';
if (!html.includes(marker) || html.includes('BOB_WEB_FILES')) throw new Error('Unexpected Godot Web HTML; inspect before patching.');
html = html.replace(marker, `<script>window.BOB_WEB_FILES = ${JSON.stringify(manifest)};\n${loader}</script>\n${marker}`);
html = html.replace('<progress id="status-progress"></progress>', '<progress id="status-progress"></progress>\n<div id="status-detail" role="status" style="position:absolute;bottom:calc(10% + 24px);width:100%;text-align:center;color:#ddd;font:16px sans-serif">正在准备游戏…</div>');
writeFileSync(target, html);
writeFileSync(path.join(web, 'downloads.json'), JSON.stringify(manifest, null, 2));
const totals = Object.values(manifest).reduce((a, f) => ({ raw: a.raw + f.rawBytes, packed: a.packed + f.packedBytes }), { raw: 0, packed: 0 });
console.log(`Web boot downloads: ${(totals.raw / 1048576).toFixed(2)} MiB → ${(totals.packed / 1048576).toFixed(2)} MiB`);
