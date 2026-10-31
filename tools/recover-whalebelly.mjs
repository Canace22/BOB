// One-time, reviewable recovery of the authored campaign into the active project.
// Refuses to overwrite the recovered module unless --refresh is explicitly given.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.join(root, 'legacy/godot/WhalebellyRuins');
const refresh = process.argv.includes('--refresh');
const mappings = {
  'res://assets/': 'res://art/whalebelly/',
  'res://scripts/': 'res://src/campaign/',
  'res://scenes/': 'res://content/whalebelly/',
  'res://tests/': 'res://tests/whalebelly/',
  'res://tools/': 'res://tools/whalebelly/',
  'res://.production/': 'res://build/qa/whalebelly/',
  'res://evidence/': 'res://build/qa/whalebelly/evidence/',
  'user://': 'user://whalebelly/',
};
const inventory = [];
const placeholders = [];
const manifestPath = path.join(root, 'game/art/manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
manifest.entries = manifest.entries.filter(e => !e.dest.startsWith('whalebelly/'));
manifest.whalebelly_resource_paths = mappings;
function rewrite(text) {
  // Avoid replacing the user:// prefix twice.
  return text.replace(/res:\/\/(assets|scripts|scenes|tests|tools|\.production|evidence)\/|user:\/\//g, prefix => mappings[prefix]);
}
function files(dir) {
  return fs.readdirSync(dir, {withFileTypes: true}).flatMap(e => e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]);
}
function emit(src, dest, text = null) {
  const dst = path.join(root, 'game', dest);
  if (fs.existsSync(dst) && !refresh) throw new Error(`Refusing to overwrite ${dst}`);
  fs.mkdirSync(path.dirname(dst), {recursive: true});
  const bytes = fs.readFileSync(src);
  fs.writeFileSync(dst, text === null ? bytes : text);
  inventory.push({source: path.relative(root, src).replaceAll('\\', '/'), destination: 'game/' + dest, source_sha256: crypto.createHash('sha256').update(bytes).digest('hex')});
}
for (const [folder, dest] of [['scripts', 'src/campaign'], ['scenes', 'content/whalebelly'], ['tests', 'tests/whalebelly'], ['tools', 'tools/whalebelly']]) {
  for (const src of files(path.join(source, folder))) {
    if (!/\.(gd|tscn|tres|gdshader)$/.test(src)) continue;
    let text = fs.readFileSync(src, 'utf8');
    if (!text.trim()) { placeholders.push(path.relative(source, src).replaceAll('\\', '/')); continue; }
    text = rewrite(text).replace(/ uid="uid:\/\/[^\"]+"/g, '');
    if (src.endsWith('.gd')) text = '@warning_ignore_start("untyped_declaration")\n' + text;
    emit(src, dest + '/' + path.relative(path.join(source, folder), src).replaceAll('\\', '/'), text);
  }
}
const assetRoots = new Set(['rooms.json']);
for (const folder of ['scripts', 'scenes']) {
  for (const src of files(path.join(source, folder))) {
    if (!/\.(gd|tscn|tres|gdshader)$/.test(src)) continue;
    for (const m of fs.readFileSync(src, 'utf8').matchAll(/res:\/\/assets\/([^"\s]+)/g)) assetRoots.add(m[1].split('/')[0]);
  }
}
for (const item of [...assetRoots].sort()) {
  const base = path.join(source, 'assets', item);
  const list = fs.statSync(base).isDirectory() ? files(base) : [base];
  for (const src of list) {
    if (!/\.(png|jpg|jpeg|webp|svg|wav|ogg|ttf|json|tres)$/.test(src)) continue;
    const rel = path.relative(path.join(source, 'assets'), src).replaceAll('\\', '/');
    const textual = /\.(json|tres|svg)$/.test(src);
    emit(src, 'art/whalebelly/' + rel, textual ? rewrite(fs.readFileSync(src, 'utf8')) : null);
    manifest.entries.push({src: 'legacy/godot/WhalebellyRuins/assets/' + rel, dest: 'whalebelly/' + rel, ...(textual ? {rewrite_whalebelly_paths: true} : {})});
  }
}
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
fs.mkdirSync(path.join(root, 'game/content/whalebelly'), {recursive: true});
fs.writeFileSync(path.join(root, 'game/content/whalebelly/recovery-manifest.json'), JSON.stringify({source_revision: 'backup/before-godot-sync-20261031', path_mappings: mappings, empty_source_placeholders: placeholders, files: inventory}, null, 2) + '\n');
console.log(`Recovered ${inventory.length} files; ${placeholders.length} empty source placeholders recorded.`);
