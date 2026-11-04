import { readFileSync, writeFileSync, readdirSync, unlinkSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { buildDownloadEntry } from './web-download-parts.mjs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

export function prepareStoryShell(html, mainScene, projectConfig) {
  if (!/^res:\/\/[a-zA-Z0-9_/-]+\.tscn$/.test(mainScene)) throw new Error('Invalid Web main scene.');
  if (!projectConfig || !readFileSync(projectConfig, 'utf8').includes(`run/main_scene="${mainScene}"`)) {
    throw new Error('Chapter must be exported from its isolated project with the baked main scene.');
  }
  const pattern = /const GODOT_CONFIG = (\{[^\n]*\});/;
  const match = html.match(pattern);
  if (!match) throw new Error('Godot shell has no recognizable GODOT_CONFIG; scene selection refused.');
  const config = JSON.parse(match[1]);
  if (!Array.isArray(config.args)) throw new Error('Godot shell does not expose its argument list.');
  if (config.args.some(arg => typeof arg !== 'string' || (arg.endsWith('.tscn') && arg !== mainScene))) {
    throw new Error('Godot shell already selects another scene.');
  }
  // Official release templates disable CLI scene overrides. The PCK owns its main scene.
  // Also remove a retained argument from HTML left by the earlier incremental export.
  config.args = config.args.filter(arg => arg !== mainScene);
  return html.replace(pattern, () => `const GODOT_CONFIG = ${JSON.stringify(config)};`);
}

export function prepareWeb({ web = path.join(root, 'game/build/web'), mainScene = '', projectConfig = '' } = {}) {
  const target = path.join(web, 'index.html');
  let html = readFileSync(target, 'utf8');
  if (mainScene) html = prepareStoryShell(html, mainScene, projectConfig);
  for (const file of readdirSync(web)) if (/^(wasm|pck)\.[0-9a-f]{16}\.(gz|(?:gzip|raw)\.part-\d+\.bin)$/.test(file)) unlinkSync(path.join(web, file));
  const manifest = {};
  for (const extension of ['wasm', 'pck']) {
    const data = readFileSync(path.join(web, `index.${extension}`));
    manifest[`index.${extension}`] = buildDownloadEntry(data, extension, (file, bytes) => writeFileSync(path.join(web, file), bytes));
  }
  const loader = readFileSync(path.join(root, 'game/web/preload.js'), 'utf8');
  const marker = '<script src="index.js"></script>';
  // Godot can retain its HTML shell on incremental exports. Replace the previous
  // generated loader so the page cannot keep hashes of files removed above.
  if (html.includes('BOB_WEB_FILES')) {
    html = html.replace(/<script>window\.BOB_WEB_FILES = [\s\S]*?<\/script>\s*(?=<script src="index\.js"><\/script>)/, '');
    html = html.replace(/\n<div id="status-detail"[^>]*>[\s\S]*?<\/div>/, '');
  }
  if (!html.includes(marker) || html.includes('BOB_WEB_FILES')) throw new Error('Unexpected Godot Web HTML; inspect before patching.');
  html = html.replace(marker, `<script>window.BOB_WEB_FILES = ${JSON.stringify(manifest)};\n${loader}</script>\n${marker}`);
  html = html.replace('<progress id="status-progress"></progress>', '<progress id="status-progress"></progress>\n<div id="status-detail" role="status" style="position:absolute;bottom:calc(10% + 24px);width:100%;text-align:center;color:#ddd;font:16px sans-serif">正在准备游戏…</div>');
  writeFileSync(target, html);
  writeFileSync(path.join(web, 'downloads.json'), JSON.stringify(manifest, null, 2));
  if (mainScene) {
    const source = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
    writeFileSync(path.join(web, 'build.json'), JSON.stringify({
      source, exportedAt: new Date().toISOString(), engine: '4.7.2', threads: false,
      entry: 'story-c01', mainScene, sceneSelection: 'isolated-project-setting',
    }, null, 2));
  }
  const totals = Object.values(manifest).reduce((a, f) => ({ raw: a.raw + f.rawBytes, packed: a.packed + f.packedBytes }), { raw: 0, packed: 0 });
  console.log(`Web boot downloads: ${(totals.raw / 1048576).toFixed(2)} MiB → ${(totals.packed / 1048576).toFixed(2)} MiB`);
  return manifest;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const options = {};
  for (let index = 0; index < args.length; index += 2) {
    const key = args[index];
    const value = args[index + 1];
    if (!['--directory', '--main-scene', '--project-config'].includes(key) || !value || value.startsWith('--')) {
      throw new Error('Usage: prepare-web.mjs [--directory output] [--main-scene res://path.tscn --project-config isolated/project.godot]');
    }
    if (key === '--directory') options.web = path.resolve(root, value);
    else if (key === '--main-scene') options.mainScene = value;
    else options.projectConfig = path.resolve(root, value);
  }
  prepareWeb(options);
}
