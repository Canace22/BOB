// GitHub Pages 仅发布当前 V2；本地初版与 nightmare 源码不参与构建。
// npm run deploy 发布；npm run build:pages 仅构建，保留产物供检查。
import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const mvpDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(mvpDir, '..');
const v2Dir = path.join(repoRoot, 'mvp-v2');
const outDir = path.join(repoRoot, '.pages-dist');
const branch = 'gh-pages';
const coverPath = 'docs/鲸腹遗城原画集/V2/images/A01_鲸落万物生_世界主视觉.png';
const run = (cmd, args, cwd = repoRoot) => execFileSync(cmd, args, { cwd, stdio: 'inherit' });
const read = (cmd, args, cwd = repoRoot) => execFileSync(cmd, args, { cwd, encoding: 'utf8' }).trim();

function clearBuild() {
  // Recursively remove only this fixed output directory, never a linked external target.
  if (path.dirname(outDir) !== repoRoot || path.basename(outDir) !== '.pages-dist') throw new Error('构建输出目录越界，已停止清理。');
  if (!existsSync(outDir)) return;
  if (lstatSync(outDir).isSymbolicLink() || path.dirname(realpathSync(outDir)) !== realpathSync(repoRoot)) {
    throw new Error('.pages-dist 指向其他目录，已停止清理。');
  }
  rmSync(outDir, { recursive: true, force: true });
}

function build() {
  clearBuild();
  const dest = path.join(outDir, 'mvp-v2');
  mkdirSync(dest, { recursive: true });
  for (const file of readdirSync(v2Dir, { withFileTypes: true })) {
    if (!file.isFile() || !/\.(js|css|html)$/.test(file.name)) continue;
    const source = path.join(v2Dir, file.name), target = path.join(dest, file.name);
    if (file.name.endsWith('.html')) {
      // Relative imports work under both a project prefix (/BOB/) and a custom domain.
      const html = readFileSync(source, 'utf8').replace(/\s*<base\b[^>]*>/gi, '');
      writeFileSync(target, html);
    } else cpSync(source, target);
  }
  cpSync(path.join(v2Dir, 'assets'), path.join(dest, 'assets'), { recursive: true });
  for (const file of ['README.md', 'SCENE_PIPELINE.md']) cpSync(path.join(v2Dir, file), path.join(dest, file));
  const coverTarget = path.join(outDir, coverPath);
  mkdirSync(path.dirname(coverTarget), { recursive: true });
  cpSync(path.join(repoRoot, coverPath), coverTarget);
  writeFileSync(path.join(outDir, 'index.html'), '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=mvp-v2/"><title>鲸落万物生 · V2</title><a href="mvp-v2/">进入 V2 游戏</a></html>');
  writeFileSync(path.join(outDir, '.nojekyll'), '');
}

function pagesUrl(remote) {
  const match = remote.match(/github\.com[:/]([^/]+)\/([^/]+?)(?:\.git)?\/?$/);
  if (!match) throw new Error('origin 不是可识别的 GitHub 仓库地址，无法确认 Pages 发布地址。');
  const owner = match[1].toLowerCase(), repo = match[2];
  const prefix = repo.toLowerCase() === `${owner}.github.io` ? '' : `${repo}/`;
  return `https://${owner}.github.io/${prefix}mvp-v2/`;
}

function publish() {
  const remote = read('git', ['remote', 'get-url', 'origin']);
  const url = pagesUrl(remote);
  // Read identity from the source repo so repository-local configuration is honored.
  const name = read('git', ['config', 'user.name']);
  const email = read('git', ['config', 'user.email']);
  if (!name || !email) throw new Error('请先配置 Git user.name 和 user.email，再发布。');
  const existing = read('git', ['ls-remote', '--heads', remote, `refs/heads/${branch}`]);
  run('git', ['init', '-q', '-b', branch], outDir);
  run('git', ['config', 'user.name', name], outDir);
  run('git', ['config', 'user.email', email], outDir);
  if (existing) {
    run('git', ['fetch', '--depth=1', remote, `refs/heads/${branch}`], outDir);
    // Keep the freshly built files while using the existing deployment as parent.
    run('git', ['reset', '--mixed', 'FETCH_HEAD'], outDir);
  }
  run('git', ['add', '-A'], outDir);
  if (!existing || read('git', ['diff', '--cached', '--name-only'], outDir)) {
    run('git', ['commit', '-q', '-m', `发布 V2 ${new Date().toISOString()}`], outDir);
    // A concurrent deployment causes a normal non-fast-forward failure; never overwrite it.
    run('git', ['push', remote, `${branch}:${branch}`], outDir);
  } else console.log('发布产物没有变化，保留当前 gh-pages 提交。');
  // This repository already has Pages enabled on gh-pages. No gh CLI/config mutation needed.
  console.log(`\nV2 产物已更新至 gh-pages；GitHub Pages 完成部署后访问：${url}`);
}

try {
  build();
  console.log(`仅 V2 构建完成：${outDir}`);
  if (!process.argv.includes('--build-only')) {
    publish();
    clearBuild();
  }
} catch (error) {
  console.error(`构建或发布失败：${error.message}\n已保留构建产物，未执行强制推送。`);
  process.exitCode = 1;
}
