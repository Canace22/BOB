#!/usr/bin/env node
// Publish only /art/ to the existing Pages branch, preserving all playable versions.
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, lstatSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { buildArtPreview, repository as root, previewOutput } from '../assets/manager/build.mjs';

const staging = path.join(root, '.pages-dist', 'art-publication');
const run = (args, cwd = root) => execFileSync('git', args, { cwd, stdio: 'inherit' });
const read = (args, cwd = root) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();

try {
  const source = read(['rev-parse', 'HEAD']);
  const manifest = buildArtPreview({ source });
  if (process.argv.includes('--build-only')) {
    console.log(`Built ${manifest.assetCount} assets in ${previewOutput}; not pushed.`);
  } else {
    const remote = read(['remote', 'get-url', 'origin']);
    if (existsSync(staging) && (lstatSync(staging).isSymbolicLink() || realpathSync(staging) !== staging)) throw new Error('Linked Pages checkout.');
    if (!existsSync(path.join(staging, '.git'))) {
      if (existsSync(staging)) throw new Error('Pages checkout exists without .git; inspect before reuse.');
      run(['clone', '--filter=blob:none', '--sparse', '--depth=1', '--single-branch', '--branch', 'gh-pages', remote, staging]);
    } else {
      if (read(['status', '--porcelain'], staging)) throw new Error('Pages checkout has pending changes; inspect before reuse.');
      run(['pull', '--ff-only', remote, 'gh-pages'], staging);
    }
    // Keep other version trees in the index without downloading their game packages.
    run(['sparse-checkout', 'set', 'art'], staging);
    const destination = path.join(staging, 'art');
    if (existsSync(destination)) {
      if (lstatSync(destination).isSymbolicLink() || realpathSync(destination) !== destination) throw new Error('Linked art directory.');
      rmSync(destination, { recursive: true });
    }
    cpSync(previewOutput, destination, { recursive: true });
    writeFileSync(path.join(staging, '.nojekyll'), '');
    for (const key of ['user.name', 'user.email']) run(['config', key, read(['config', key])], staging);
    run(['add', '--', 'art', '.nojekyll'], staging);
    const changed = read(['diff', '--cached', '--name-only', '-z'], staging).split('\0').filter(Boolean);
    if (changed.some(file => file !== '.nojekyll' && !file.startsWith('art/'))) throw new Error('Changes outside art publication.');
    if (changed.length) run(['commit', '-m', `发布美术资源预览 ${source.slice(0, 7)}`], staging);
    run(['push', remote, 'HEAD:gh-pages'], staging);
    console.log(`Pages publication commit: ${read(['rev-parse', 'HEAD'], staging)}`);
    console.log('Verify deployment: https://canace22.github.io/BOB/art/');
  }
} catch (error) {
  console.error(`Art preview publication failed: ${error.message}. Local output retained.`);
  process.exitCode = 1;
}
