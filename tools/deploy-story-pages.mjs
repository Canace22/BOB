#!/usr/bin/env node
// Publish only /godot-story/. No default entry or historical game tree is rewritten.
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, lstatSync, realpathSync, rmSync, writeFileSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { publicationOmissions, includePublicationFile } from './web-download-parts.mjs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ENTRY = 'godot-story';
const MAIN_SCENE = 'res://content/story/main.tscn';
const gitRead = (args, cwd) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();
const gitRun = (args, cwd) => execFileSync('git', args, { cwd, stdio: 'inherit' });

function assertChild(target, parent) {
  if (path.dirname(path.resolve(target)) !== path.resolve(parent) || !existsSync(parent)) {
    throw new Error(`Unsafe publication target: ${target}`);
  }
  if (existsSync(target)) {
    const actual = path.relative(path.toNamespacedPath(realpathSync(parent)), path.toNamespacedPath(realpathSync(target)));
    if (lstatSync(target).isSymbolicLink() || actual !== path.basename(target)) throw new Error(`Linked publication target: ${target}`);
  }
}

function validateExport(exported, source) {
  const build = JSON.parse(readFileSync(path.join(exported, 'build.json'), 'utf8'));
  if (build.source !== source || build.entry !== 'story-c01' || build.mainScene !== MAIN_SCENE || build.sceneSelection !== 'isolated-project-setting') {
    throw new Error('Chapter export metadata does not match this source commit and entry.');
  }
  const html = readFileSync(path.join(exported, 'index.html'), 'utf8');
  const match = html.match(/const GODOT_CONFIG = (\{[^\n]*\});/);
  if (!match || !Array.isArray(JSON.parse(match[1]).args) || JSON.parse(match[1]).args.some(arg => arg.endsWith('.tscn'))) {
    throw new Error('Chapter HTML must not use scene path overrides unsupported by official release templates.');
  }
}

export function prepareStoryPublication({ root = ROOT, exported = path.join(root, 'game/build/story-web'),
  staging = path.join(root, '.pages-dist-story'), remote, source }) {
  validateExport(exported, source);
  assertChild(staging, root);
  const fresh = !existsSync(path.join(staging, '.git'));
  if (fresh) {
    if (existsSync(staging)) throw new Error('Story staging exists without .git; inspect it before reuse.');
    gitRun(['clone', '--no-checkout', '--filter=blob:none', '--depth=1', '--single-branch', '--branch', 'gh-pages', remote, staging], root);
  } else if (gitRead(['status', '--porcelain'], staging)) {
    throw new Error('Story staging has uncommitted changes; inspect before reuse.');
  }
  gitRun(['config', 'remote.origin.promisor', 'true'], staging);
  gitRun(['config', 'remote.origin.partialclonefilter', 'blob:none'], staging);
  gitRun(['sparse-checkout', 'init', '--no-cone'], staging);
  // Keep only the small control file present until replacing the complete game subtree.
  gitRun(['sparse-checkout', 'set', '/.nojekyll'], staging);
  if (fresh) {
    // --no-checkout leaves an empty index. Populate it after the narrow sparse rule.
    gitRun(['read-tree', '-mu', 'HEAD'], staging);
  } else {
    gitRun(['fetch', '--filter=blob:none', remote, 'gh-pages'], staging);
    gitRun(['merge', '--ff-only', '--no-stat', 'FETCH_HEAD'], staging);
  }
  const baseline = gitRead(['rev-parse', 'HEAD'], staging);
  const previous = execFileSync('git', ['ls-files', '-z', '--', `${ENTRY}/`], { cwd: staging });
  if (previous.length) execFileSync('git', ['update-index', '--force-remove', '-z', '--stdin'], { cwd: staging, input: previous });
  writeFileSync(path.join(staging, '.git/info/sparse-checkout'), `/${ENTRY}/\n/.nojekyll\n`);
  const destination = path.join(staging, ENTRY);
  assertChild(destination, staging);
  if (existsSync(destination)) rmSync(destination, { recursive: true });
  mkdirSync(destination);
  const manifest = JSON.parse(readFileSync(path.join(exported, 'downloads.json'), 'utf8'));
  const omitted = publicationOmissions(manifest);
  cpSync(exported, destination, { recursive: true, filter: file => includePublicationFile(file, exported, omitted) });
  for (const file of readdirSync(destination)) {
    const info = statSync(path.join(destination, file));
    if (info.isFile() && info.size >= 100 * 1024 * 1024) throw new Error(`Chapter publication exceeds GitHub file limit: ${file}`);
  }
  gitRun(['add', '--', ENTRY], staging);
  const changed = gitRead(['diff', '--cached', '--name-only'], staging).split('\n').filter(Boolean);
  if (changed.some(file => !file.startsWith(`${ENTRY}/`))) throw new Error('Staged changes outside chapter publication.');
  // Tree IDs require no unrelated large blobs, unlike file diffs and commit statistics.
  const before = gitRead(['ls-tree', baseline], staging).split('\n').filter(line => !line.endsWith(`\t${ENTRY}`));
  const afterTree = gitRead(['write-tree'], staging);
  const after = gitRead(['ls-tree', afterTree], staging).split('\n').filter(line => !line.endsWith(`\t${ENTRY}`));
  if (JSON.stringify(before) !== JSON.stringify(after)) throw new Error('Publication would change another Pages tree.');
  return { staging, changed, baseline };
}

export function deployStoryPages() {
  try {
    execFileSync(process.execPath, ['tools/godot.mjs', 'export-story-web'], { cwd: ROOT, stdio: 'inherit' });
    const source = gitRead(['rev-parse', 'HEAD'], ROOT);
    const exported = path.join(ROOT, 'game/build/story-web');
    validateExport(exported, source);
    if (process.argv.includes('--build-only')) {
      console.log(`Prepared chapter Web export in ${exported} from ${source}; no Pages checkout or push.`);
      return;
    }
    const remote = gitRead(['remote', 'get-url', 'origin'], ROOT);
    const { staging, changed } = prepareStoryPublication({ remote, source });
    for (const key of ['user.name', 'user.email']) gitRun(['config', key, gitRead(['config', key], ROOT)], staging);
    if (changed.length) gitRun(['commit', '--quiet', '-m', `发布须庭第一章 ${source.slice(0, 8)}`], staging);
    // Concurrent deployment fails non-fast-forward; retain both histories for review.
    gitRun(['push', remote, 'HEAD:gh-pages'], staging);
    const publication = gitRead(['rev-parse', 'HEAD'], staging);
    const remoteHead = gitRead(['ls-remote', remote, 'refs/heads/gh-pages'], ROOT).split(/\s+/)[0];
    if (remoteHead !== publication) throw new Error('Remote Pages head differs after push; verify concurrent publication.');
    console.log(`Chapter Pages publication commit: ${publication}. Verify deployment and https://canace22.github.io/BOB/godot-story/.`);
  } catch (error) {
    console.error(`Chapter build/publication failed: ${error.message}. Local output retained; no forced update.`);
    process.exitCode = 1;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) deployStoryPages();
