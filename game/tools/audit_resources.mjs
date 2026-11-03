// Conservative dependency audit for the current campaign, including dynamic path families.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const all = [];
function walk(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
    if (entry.name.startsWith('.') || ['build', 'production_sources'].includes(entry.name)) continue;
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (!/\.(import|uid)$/.test(entry.name)) all.push(path.relative(game, full).replaceAll('\\', '/'));
  }
}
walk(game);
const files = new Set(all);
const classes = new Map();
for (const file of all.filter(file => file.endsWith('.gd'))) {
  const match = fs.readFileSync(path.join(game, file), 'utf8').match(/^class_name\s+(\w+)/m);
  if (match) classes.set(match[1], file);
}
const roots = ['project.godot', 'content/whalebelly/main.tscn', 'content/whalebelly/tide_demo.tscn', 'content/whalebelly/test/PlayerTest.tscn', 'content/whalebelly/characters/run_preview.tscn', 'content/whalebelly/environment/motion_preview.tscn', 'art/fonts/OFL.txt', 'art/whalebelly/runtime/tide-picker-run-v03/manifest.json'];
const reached = new Map(roots.map(root => [root, 'current entry']));
const queue = [...roots];
const missing = [];
const dynamic = [];
function include(file, owner) {
  if (file.startsWith('tests/') || file.startsWith('build/')) return;
  if (!reached.has(file)) { reached.set(file, owner); queue.push(file); }
}
for (let i = 0; i < queue.length; i++) {
  const file = queue[i];
  if (!files.has(file)) { missing.push(file); continue; }
  if (!/\.(gd|tscn|tres|gdshader|json|godot)$/.test(file)) continue;
  const text = fs.readFileSync(path.join(game, file), 'utf8');
  for (const match of text.matchAll(/res:\/\/([^"'\s]+)/g)) {
    const resource = match[1];
    if (resource.startsWith('tests/') || resource.startsWith('build/')) continue;
    if (files.has(resource)) include(resource, file);
    else if (resource.endsWith('/')) {
      for (const candidate of all) if (candidate.startsWith(resource)) include(candidate, file);
      dynamic.push({owner: file, pattern: resource + '**'});
    } else if (/%(?:0?\d*)?[sd]/.test(resource)) {
      const regex = new RegExp('^' + resource.split(/%(?:0?\d*)?[sd]/).map(part => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('[^/]+') + '$');
      for (const candidate of all) if (regex.test(candidate)) include(candidate, file);
      dynamic.push({owner: file, pattern: resource});
    } else if (!resource.includes('%')) missing.push(file + ' -> ' + resource);
  }
  if (file.endsWith('.gd')) {
    const code = text.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|#[^\n]*/g, ' ');
    for (const [name, source] of classes) if (new RegExp('\\b' + name + '\\b').test(code)) include(source, file);
  }
}
const assets = all.filter(file => file.startsWith('art/') && file !== 'art/manifest.json');
const current = assets.filter(file => reached.has(file));
const retired = assets.filter(file => !reached.has(file));
const bytes = list => list.reduce((sum, file) => sum + fs.statSync(path.join(game, file)).size, 0);
const inventory = {roots, dynamic, missing: [...new Set(missing)], current: current.map(file => ({path: file, owner: reached.get(file)})), retired, reachable: [...reached.keys()].sort(), currentBytes: bytes(current), retiredBytes: bytes(retired)};
const output = path.join(game, 'build/qa/framecraft-compression/usage.json');
fs.mkdirSync(path.dirname(output), {recursive: true});
fs.writeFileSync(output, JSON.stringify(inventory, null, 2) + '\n');
console.log(JSON.stringify({current: current.length, retired: retired.length, currentMiB: bytes(current) / 1048576, retiredMiB: bytes(retired) / 1048576, reachable: reached.size, missing: inventory.missing, dynamic}, null, 2));
if (inventory.missing.length) process.exitCode = 1;
