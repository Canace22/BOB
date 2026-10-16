// 一键发布到 GitHub Pages：npm run deploy（只构建不推送：npm run build:pages）
import { cpSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const mvpDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(mvpDir, '..');
const outDir = path.join(repoRoot, '.pages-dist');
const artDir = path.join(repoRoot, 'docs', '鲸腹遗城原画集');
const branch = 'gh-pages';
const artFiles = ['00_鲸落全景.png', '01_鲸口门庭.png', '08_肋骨穹顶.png', '05_心室潮泵.png'];

const run = (cmd, args, cwd = repoRoot) => execFileSync(cmd, args, { cwd, stdio: 'inherit' });
const read = (cmd, args) => execFileSync(cmd, args, { cwd: repoRoot, encoding: 'utf8' }).trim();

function build() {
  rmSync(outDir, { recursive: true, force: true });
  mkdirSync(path.join(outDir, 'mvp'), { recursive: true });
  // 游戏文件放 /mvp/，原画放站点根目录，保持代码里 "../xx.png" 的相对路径有效
  for (const f of readdirSync(mvpDir)) {
    if (/\.(js|css)$/.test(f)) cpSync(path.join(mvpDir, f), path.join(outDir, 'mvp', f));
  }
  // <base href="/mvp/"> 是本地服务器用的绝对路径，Pages 项目站点有仓库名前缀，必须去掉
  const html = readFileSync(path.join(mvpDir, 'index.html'), 'utf8').replace(/\s*<base [^>]*>/, '');
  writeFileSync(path.join(outDir, 'mvp', 'index.html'), html);
  for (const f of artFiles) cpSync(path.join(artDir, f), path.join(outDir, f));
  writeFileSync(path.join(outDir, 'index.html'), '<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="0;url=mvp/"><a href="mvp/">进入游戏</a>');
  writeFileSync(path.join(outDir, '.nojekyll'), '');
}

function pagesUrl(remote) {
  const m = remote.match(/github\.com[:/]([^/]+)\/(.+?)(?:\.git)?$/);
  return m ? `https://${m[1].toLowerCase()}.github.io/${m[2]}/mvp/` : null;
}

function publish() {
  const remote = read('git', ['remote', 'get-url', 'origin']);
  // 在临时目录里建一个只含构建产物的仓库，强推到 gh-pages，不影响 main 的历史和工作区
  run('git', ['init', '-q', '-b', branch], outDir);
  run('git', ['add', '-A'], outDir);
  run('git', ['commit', '-q', '-m', `发布 ${new Date().toISOString()}`], outDir);
  run('git', ['push', '-f', remote, `${branch}:${branch}`], outDir);
  // 首次发布时尝试自动开启 Pages；已开启或没装 gh 时忽略
  try {
    execFileSync('gh', ['api', '-X', 'POST', 'repos/{owner}/{repo}/pages', '-f', `source[branch]=${branch}`, '-f', 'source[path]=/'], { cwd: repoRoot, stdio: 'ignore' });
  } catch {}
  console.log(`\n已发布。1–2 分钟后访问：${pagesUrl(remote) ?? '（请在仓库 Settings → Pages 查看地址）'}`);
}

build();
console.log(`构建完成：${outDir}`);
if (!process.argv.includes('--build-only')) {
  publish();
  rmSync(outDir, { recursive: true, force: true });
}
