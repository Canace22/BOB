// Conservative dependency audit for the current campaign, including dynamic path families.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const release = process.argv.includes('--release');
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
const roots = ['project.godot', 'content/whalebelly/main.tscn', 'art/fonts/OFL.txt'];
if (!release) roots.push('content/whalebelly/tide_demo.tscn', 'content/whalebelly/test/PlayerTest.tscn', 'content/whalebelly/characters/run_preview.tscn', 'content/whalebelly/environment/motion_preview.tscn', 'art/whalebelly/runtime/tide-picker-run-v03/manifest.json');
// The campaign uses atlas_coverage, while local legacy parameter scenes still use
// individual frames. Only the original idle seed is required by the shared scene.
if (release) {
  const player = fs.readFileSync(path.join(game, 'src/campaign/tide_player.gd'), 'utf8');
  const mapping = JSON.parse(player.match(/var mapping: Dictionary=(\{[^\n]+\})/)[1]);
  const clips = JSON.parse(player.match(/const CLIPS := (\{[\s\S]*?\n\})/)[1]);
  const actions = JSON.parse(fs.readFileSync(path.join(game, 'art/tide-picker-action36/animations.json'), 'utf8')).actions;
  for (const legacy of Object.keys(clips)) {
    const key = mapping[legacy];
    const clip = actions[key];
    if (!clip?.body || [clip.body, clip.fx].filter(Boolean).some(layer => !files.has(layer.texture.replace('res://', '')))) {
      throw new Error(`Release cannot omit legacy frames: missing atlas coverage for ${legacy}`);
    }
  }
}
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
      if (release && file === 'src/campaign/tide_player.gd' && resource.startsWith('art/whalebelly/animations/player/')) {
        include('art/whalebelly/animations/player/body/idle/000.png', file);
        continue;
      }
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
const output = path.join(game, release ? 'build/qa/package-audit/release-resources.json' : 'build/qa/framecraft-compression/usage.json');
fs.mkdirSync(path.dirname(output), {recursive: true});
fs.writeFileSync(output, JSON.stringify(inventory, null, 2) + '\n');
console.log(JSON.stringify({current: current.length, retired: retired.length, currentMiB: bytes(current) / 1048576, retiredMiB: bytes(retired) / 1048576, reachable: reached.size, missing: inventory.missing, dynamic}, null, 2));
if (inventory.missing.length) process.exitCode = 1;
