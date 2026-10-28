#!/usr/bin/env node
// Merge only /godot/ into the current Pages tree. The root V2 entry remains intact.
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, lstatSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const staging = path.join(root, '.pages-dist-godot');
const exported = path.join(root, 'game/build/web');
const run = (command, args, cwd = root) => execFileSync(command, args, { cwd, stdio: 'inherit' });
const read = (args, cwd = root) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();

function assertLocalDirectory(target, parent) {
  if (path.dirname(target) !== parent || !existsSync(parent)) throw new Error(`Unsafe target: ${target}`);
  if (existsSync(target) && (lstatSync(target).isSymbolicLink() || path.dirname(realpathSync(target)) !== realpathSync(parent))) {
    throw new Error(`Linked output directory: ${target}`);
  }
}

function prepare() {
  run(process.execPath, ['tools/godot.mjs', 'export-web']);
  const remote = read(['remote', 'get-url', 'origin']);
  const source = read(['rev-parse', 'HEAD']);
  assertLocalDirectory(staging, root);
  if (!existsSync(path.join(staging, '.git'))) {
    if (existsSync(staging)) throw new Error('Staging exists without .git; inspect it before reuse.');
    run('git', ['clone', '--depth=1', '--single-branch', '--branch', 'gh-pages', remote, staging]);
  } else {
    if (read(['status', '--porcelain'], staging)) throw new Error('Staging has uncommitted changes; inspect before reuse.');
    run('git', ['pull', '--ff-only', remote, 'gh-pages'], staging);
  }
  const dest = path.join(staging, 'godot');
  assertLocalDirectory(dest, staging);
  if (existsSync(dest)) rmSync(dest, { recursive: true });
  mkdirSync(dest);
  cpSync(exported, dest, { recursive: true, filter: file => !/\.(import|uid|log)$/.test(file) });
  writeFileSync(path.join(dest, 'build.json'), JSON.stringify({ source, exportedAt: new Date().toISOString(), engine: '4.7.2', threads: false }, null, 2));
  writeFileSync(path.join(staging, '.nojekyll'), '');
  return { remote, source };
}

try {
  const { remote, source } = prepare();
  if (process.argv.includes('--build-only')) {
    console.log(`Prepared ${staging}/godot/ from ${source}; not committed or pushed.`);
  } else {
    for (const key of ['user.name', 'user.email']) run('git', ['config', key, read(['config', key])], staging);
    run('git', ['add', '--', 'godot', '.nojekyll'], staging);
    const changed = read(['diff', '--cached', '--name-only'], staging).split('\n').filter(Boolean);
    if (changed.some(file => file !== '.nojekyll' && !file.startsWith('godot/'))) throw new Error('Unexpected staged files outside /godot/.');
    if (changed.length) run('git', ['commit', '-m', `发布 Godot 首关 ${source.slice(0, 7)}`], staging);
    run('git', ['push', remote, 'HEAD:gh-pages'], staging);
    console.log(`Pages publication commit: ${read(['rev-parse', 'HEAD'], staging)}. Verify deployment and https://canace22.github.io/BOB/godot/.`);
  }
} catch (error) {
  console.error(`Pages build/publication failed: ${error.message}. Stable remote kept; local output retained.`);
  process.exitCode = 1;
}
