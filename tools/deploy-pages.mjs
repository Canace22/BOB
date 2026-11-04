#!/usr/bin/env node
// Publish /godot/ and its default root entry; preserve historical version directories.
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, lstatSync, realpathSync, rmSync, writeFileSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { publicationOmissions } from './web-download-parts.mjs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const staging = path.join(root, '.pages-dist-godot');
const exported = path.join(root, 'game/build/web');
const entryOnly = process.argv.includes('--entry-only');
const run = (command, args, cwd = root) => execFileSync(command, args, { cwd, stdio: 'inherit' });
const read = (args, cwd = root) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();

function assertLocalDirectory(target, parent) {
  if (path.dirname(target) !== parent || !existsSync(parent)) throw new Error(`Unsafe target: ${target}`);
  if (existsSync(target) && (lstatSync(target).isSymbolicLink() || path.dirname(realpathSync(target)) !== realpathSync(parent))) {
    throw new Error(`Linked output directory: ${target}`);
  }
}

function prepare() {
  if (!entryOnly) run(process.execPath, ['tools/godot.mjs', 'export-web']);
  const remote = read(['remote', 'get-url', 'origin']);
  const source = read(['rev-parse', 'HEAD']);
  assertLocalDirectory(staging, root);
  const freshCheckout = !existsSync(path.join(staging, '.git'));
  if (freshCheckout) {
    if (existsSync(staging)) throw new Error('Staging exists without .git; inspect it before reuse.');
    run('git', ['clone', '--filter=blob:none', '--sparse', '--depth=1', '--single-branch', '--branch', 'gh-pages', remote, staging]);
  } else {
    if (read(['status', '--porcelain'], staging)) throw new Error('Staging has uncommitted changes; inspect before reuse.');
  }
  // Keep every published version in Git without downloading unrelated art blobs.
  run('git', ['config', 'remote.origin.promisor', 'true'], staging);
  run('git', ['config', 'remote.origin.partialclonefilter', 'blob:none'], staging);
  // Rename inference can lazily fetch obsolete package blobs, even for --name-only.
  run('git', ['config', 'diff.renames', 'false'], staging);
  run('git', ['sparse-checkout', 'init', '--no-cone'], staging);
  // Full publication replaces this subtree, so do not fetch its obsolete blobs.
  run('git', ['sparse-checkout', 'set', ...(entryOnly ? ['/godot/'] : []), '/index.html', '/.nojekyll'], staging);
  if (!freshCheckout) {
    run('git', ['fetch', '--filter=blob:none', remote, 'gh-pages'], staging);
    // Diffstat can lazily download unrelated blobs on older Git versions.
    run('git', ['merge', '--ff-only', '--no-stat', 'FETCH_HEAD'], staging);
  }
  if (!entryOnly) {
    const previous = execFileSync('git', ['ls-files', '-z', '--', 'godot/'], { cwd: staging });
    if (previous.length) execFileSync('git', ['update-index', '--force-remove', '-z', '--stdin'], { cwd: staging, input: previous });
    // New files are copied below; adding the sparse pattern needs no checkout.
    writeFileSync(path.join(staging, '.git/info/sparse-checkout'), '/godot/\n/index.html\n/.nojekyll\n');
  }
  const dest = path.join(staging, 'godot');
  if (entryOnly && !existsSync(path.join(dest, 'index.html'))) throw new Error('Publish the Godot game before updating its default entry.');
  if (!entryOnly) {
    assertLocalDirectory(dest, staging);
    if (existsSync(dest)) rmSync(dest, { recursive: true });
    mkdirSync(dest);
    const downloads = JSON.parse(readFileSync(path.join(exported, 'downloads.json'), 'utf8'));
    const omitted = publicationOmissions(downloads);
    cpSync(exported, dest, { recursive: true, filter: file => !/\.(import|uid|log)$/.test(file) && !(path.dirname(file) === exported && omitted.has(path.basename(file))) });
    for (const file of readdirSync(dest)) {
      const item = statSync(path.join(dest, file));
      if (item.isFile() && item.size >= 100 * 1024 * 1024) throw new Error(`Publication file exceeds GitHub limit: ${file}`);
    }
    writeFileSync(path.join(dest, 'build.json'), JSON.stringify({ source, exportedAt: new Date().toISOString(), engine: '4.7.2', threads: false }, null, 2));
  }
  cpSync(path.join(root, 'game/pages/index.html'), path.join(staging, 'index.html'));
  writeFileSync(path.join(staging, '.nojekyll'), '');
  return { remote, source };
}

try {
  const { remote, source } = prepare();
  if (process.argv.includes('--build-only')) {
    console.log(`Prepared ${entryOnly ? 'default entry' : 'Godot and default entry'} in ${staging} from ${source}; not committed or pushed.`);
  } else {
    for (const key of ['user.name', 'user.email']) run('git', ['config', key, read(['config', key])], staging);
    run('git', ['add', '--', ...(entryOnly ? [] : ['godot']), 'index.html', '.nojekyll'], staging);
    const changed = read(['diff', '--cached', '--name-only'], staging).split('\n').filter(Boolean);
    if (changed.some(file => !['.nojekyll', 'index.html'].includes(file) && (entryOnly || !file.startsWith('godot/')))) throw new Error('Unexpected staged files outside the publication scope.');
    // A commit's default summary also fetches deleted binary blobs for diffstat.
    if (changed.length) run('git', ['commit', '--quiet', '-m', `发布 Godot ${entryOnly ? '默认入口' : '首关'} ${source.slice(0, 7)}`], staging);
    run('git', ['push', remote, 'HEAD:gh-pages'], staging);
    console.log(`Pages publication commit: ${read(['rev-parse', 'HEAD'], staging)}. Verify deployment and https://canace22.github.io/BOB/.`);
  }
} catch (error) {
  console.error(`Pages build/publication failed: ${error.message}. Stable remote kept; local output retained.`);
  process.exitCode = 1;
}
