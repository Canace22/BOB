// Check the exported artifact, rather than assuming editor filters excluded files.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {readPck} from './pck-index.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const game = path.join(root, 'game');
const pack = fs.readFileSync(path.join(game, 'build/web/index.pck'));
const files = readPck(pack);
const inventory = JSON.parse(fs.readFileSync(path.join(game, 'build/qa/package-audit/release-resources.json'), 'utf8'));
const selected = new Set(inventory.reachable);
const aliases = new Map();
for (const entry of files) {
  if (!/\.(remap|import)$/.test(entry.path)) continue;
  const text = pack.toString('utf8', entry.position, entry.position + entry.bytes);
  const match = text.match(/^path="res:\/\/([^"]+)"/m);
  if (match) aliases.set(match[1], entry.path.replace(/\.(remap|import)$/, ''));
}
for (const entry of files) entry.source = aliases.get(entry.path) ?? entry.path.replace(/\.(import|remap)$/, '');
const sources = new Set(files.map(entry => entry.source));
const missing = inventory.reachable.filter(file => file !== 'project.godot' && !sources.has(file));
const unexpected = files.filter(entry => !selected.has(entry.source) && !entry.path.startsWith('.godot/') && entry.path !== 'project.binary');
const development = files.filter(entry => /^(tests|tools|build)\//.test(entry.source) || /(?:preview|PlayerTest|tide_demo)/.test(entry.source));
const legacy = files.filter(entry => entry.source.startsWith('art/whalebelly/animations/player/') && entry.source !== 'art/whalebelly/animations/player/body/idle/000.png');
const oldRun = files.filter(entry => entry.source.startsWith('art/whalebelly/runtime/tide-picker-run-v03/'));
const byHash = new Map();
for (const entry of files) {
  if (entry.bytes < 16384) continue;
  if (!byHash.has(entry.md5)) byHash.set(entry.md5, []);
  byHash.get(entry.md5).push(entry);
}
const duplicates = [...byHash.values()].filter(group => group.length > 1);
const groups = new Map();
for (const entry of files) {
  const group = entry.source.startsWith('art/tide-picker-action36/') ? 'current character atlases'
    : entry.source.startsWith('art/enemies/') ? 'current mother crab'
    : entry.source.startsWith('art/whalebelly/reference/') || entry.source.endsWith('/source-reference.png') ? 'F2 source comparison'
    : entry.source.startsWith('art/') && /\.(png|svg)$/.test(entry.source) ? 'room art and environment motion'
    : 'audio, fonts, scenes, scripts and metadata';
  groups.set(group, (groups.get(group) ?? 0) + entry.bytes);
}
const report = {bytes:pack.length, entries:files.length, groups:Object.fromEntries(groups), missing, unexpected, development, legacy, oldRun, duplicates, files};
fs.writeFileSync(path.join(game, 'build/qa/package-audit/exported-pck.json'), JSON.stringify(report, null, 2) + '\n');
if ([missing, unexpected, development, legacy, oldRun, duplicates].some(items => items.length)) {
  console.error(JSON.stringify({missing,unexpected,development,legacy,oldRun,duplicates}, null, 2));
  throw new Error('Web package audit failed; inspect game/build/qa/package-audit/exported-pck.json');
}
console.log(`PCK audit: ${files.length} entries, ${(pack.length / 1048576).toFixed(2)} MiB; production dependencies complete; no development files, redundant legacy frames or duplicate large payloads`);
