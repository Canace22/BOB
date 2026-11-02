// Calls Framecraft's existing compression API and its own project/export modules.
// Usage: node process.mjs <framecraft-repo> <source-directory> [options.json]
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const [platform, source, optionsFile] = process.argv.slice(2).map(value => path.resolve(value));
if (!platform || !source) throw new Error('Provide the Framecraft repository and existing scale-repaired source.');
const options = optionsFile ? JSON.parse(await fs.readFile(optionsFile, 'utf8')) : {};
const output = options.output ? path.resolve(options.output) : path.dirname(fileURLToPath(import.meta.url));
const inputFrames = path.join(source, options.framesDirectory ?? '播放帧');
const names = (await fs.readdir(inputFrames)).filter(name => name.endsWith('.png')).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
if (!names.length || names.length > 400) throw new Error('Expected 1–400 PNG frames.');
const fps = options.fps ?? 24;
const durationMs = names.length * 1000 / fps;
const firstPng = await fs.readFile(path.join(inputFrames, names[0]));
const sourceCanvas = [firstPng.readUInt32BE(16), firstPng.readUInt32BE(20)];
const api = 'http://127.0.0.1:8765';
const settings = { scale: 0.75, algorithm: 'lanczos', resizeMode: 'soft', alphaThreshold: 2, sharpen: 20, colors: 256, ...options.settings };
const outputCanvas = sourceCanvas.map(size => Math.floor(size * settings.scale + 0.5));
const exportName = options.exportName ?? 'crab-slam-384-platform';
const projectName = options.name ?? '巨蟹双钳重砸_75%保真PNG_透明阈值2_v1';
const loop = options.loop ?? false;
const copySourceFrames = options.copySourceFrames !== false;
const pivot = options.pivot ?? (optionsFile ? null : [264.47, 363.29]);
const limitations = options.limitations ?? ['Timing and drawing are inherited; compression adds no poses and does not repair local anatomy.', ...(optionsFile ? [] : ['512px source was previously resampled from an approximately 324px generated cell.']), 'Godot integration and user artistic acceptance are not performed here.'];
const digest = value => createHash('sha256').update(value).digest('hex');
const json = async (name, value) => fs.writeFile(path.join(output, name), `${JSON.stringify(value, null, 2)}\n`);
for (const folder of ['source', 'processed', 'exports', 'projects', 'review']) await fs.mkdir(path.join(output, folder), { recursive: true });

// Retain provenance and untouched platform exports. Input pixels are copied too.
for (const name of ['timeline.json', '修正说明.txt', '检查结果.json', '身体宽度测量.json', '修正原始图集.png', '平台导出_PNG序列.zip', '平台导出_图集.zip']) {
  try { await fs.copyFile(path.join(source, name), path.join(output, 'source', name)); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
}
await fs.mkdir(path.join(output, 'source', 'frames'), { recursive: true });
if (copySourceFrames) for (const name of names) await fs.copyFile(path.join(inputFrames, name), path.join(output, 'source', 'frames', name));

const { build } = await import(pathToFileURL(path.join(platform, 'node_modules/esbuild/lib/main.js')));
const temp = await fs.mkdtemp(path.join(os.tmpdir(), 'bob-framecraft-'));
const moduleFile = path.join(temp, 'platform.mjs');
await build({
  stdin: { contents: "export { saveProject, loadProject, listProjects, releaseLoadedProject } from './src/lib/projects'; export { exportCompressionZip } from './src/lib/compressionExport'; export { defaultOptions } from './src/types';", resolveDir: platform, loader: 'ts' },
  bundle: true, platform: 'node', format: 'esm', outfile: moduleFile, logLevel: 'silent',
});
const runtime = await import(pathToFileURL(moduleFile));
const fetchActual = globalThis.fetch;
globalThis.fetch = (url, options) => fetchActual(typeof url === 'string' && url.startsWith('/api/') ? `${api}${url}` : url, options);

// Capture the platform's own downloadBlob result; there is no ZIP export API.
// No UI, atlas drawing, image encoding, or substitute export algorithm is used.
const downloads = [];
globalThis.document = {
  body: { appendChild() {} },
  createElement(tag) {
    if (tag !== 'a') throw new Error(`Unsupported DOM operation: ${tag}`);
    return { href: '', download: '', remove() {}, click() {
      downloads.push(fetchActual(this.href).then(response => response.arrayBuffer()).then(data => fs.writeFile(path.join(output, 'exports', this.download), Buffer.from(data))));
    } };
  },
};
const setTimeoutActual = globalThis.setTimeout;
globalThis.setTimeout = (callback, delay, ...args) => { const timer = setTimeoutActual(callback, delay, ...args); timer.unref(); return timer; };

const frames = [], results = [], records = [];
for (const [index, name] of names.entries()) {
  const input = await fs.readFile(path.join(inputFrames, name));
  if (input.readUInt32BE(16) !== sourceCanvas[0] || input.readUInt32BE(20) !== sourceCanvas[1]) throw new Error('All frames must share a canvas; register them before compression.');
  const form = new FormData();
  form.set('image', new Blob([input], { type: 'image/png' }), name);
  for (const [key, value] of Object.entries({ scale: settings.scale, algorithm: settings.algorithm, resize_mode: settings.resizeMode, alpha_threshold: settings.alphaThreshold, sharpen: settings.sharpen, colors: settings.colors })) form.set(key, String(value));
  const response = await fetchActual(`${api}/api/compression/frame`, { method: 'POST', body: form });
  if (!response.ok) throw new Error(`${name}: ${response.status} ${await response.text()}`);
  const data = Buffer.from(await response.arrayBuffer());
  const width = data.readUInt32BE(16), height = data.readUInt32BE(20);
  if (width !== outputCanvas[0] || height !== outputCanvas[1]) throw new Error(`Unexpected dimensions for ${name}: ${width} x ${height}`);
  await fs.writeFile(path.join(output, 'processed', name), data);
  const frame = { id: `source-${index}`, name, sourceIndex: index + 1, time: index / fps, width: sourceCanvas[0], height: sourceCanvas[1], blob: new Blob([input], { type: 'image/png' }), selected: true, anchor: 'bottom' };
  frame.url = URL.createObjectURL(frame.blob);
  const result = { ...frame, id: `processed-${index}`, width, height, blob: new Blob([data], { type: 'image/png' }) };
  result.url = URL.createObjectURL(result.blob);
  frames.push(frame); results.push(result);
  records.push({ name, inputBytes: input.length, outputBytes: data.length, inputSha256: digest(input), outputSha256: digest(data), width, height, headers: Object.fromEntries([...response.headers].filter(([key]) => key.startsWith('x-compression-'))) });
}

const processOptions = { ...runtime.defaultOptions, removeBackground: false, watermarkRemoval: false, layout: 'original' };
const snapshot = {
  name: projectName, fps, source: null, frames,
  workspace: { options: processOptions, start: 1, end: names.length, cursor: 1, stride: 1, loopMode: loop ? 'loop' : 'once', sequenceMode: true, sheetColumns: 7, sheetRows: Math.ceil(names.length / 7), background: 'checker' },
  matting: { options: processOptions, frames: null },
  smoothing: { enabled: false, options: processOptions, frames: null },
  compression: { settings, lastSettings: settings, sourceLabel: `${sourceCanvas.join('×')} 原帧`, sourceMode: 'workbench', fps, sources: frames, results },
};
const saved = await runtime.saveProject(path.join(output, 'projects'), snapshot);
const reopened = await runtime.loadProject(saved.directory, saved.id);
if (reopened.fps !== fps || reopened.workspace.loopMode !== snapshot.workspace.loopMode || reopened.frames.length !== names.length || reopened.compression.results.length !== names.length) throw new Error('Project reopening changed timing or frame count.');
for (const [index, frame] of reopened.compression.results.entries()) {
  if (digest(Buffer.from(await frame.blob.arrayBuffer())) !== records[index].outputSha256) throw new Error(`Reopened frame differs: ${index}`);
}
const inputBytes = records.reduce((sum, frame) => sum + frame.inputBytes, 0);
const outputBytes = records.reduce((sum, frame) => sum + frame.outputBytes, 0);
await runtime.exportCompressionZip(results, exportName, fps, { variant: 'compressed', settings, inputBytes, inputFrames: frames.map(frame => ({ name: frame.name, bytes: frame.blob.size, width: frame.width, height: frame.height })) });
await Promise.all(downloads);
await json('game-metadata.json', {
  name: exportName, candidate: true, fps, loop, durationMs,
  exportFile: `exports/${exportName}.zip`,
  sourceFramesDirectory: copySourceFrames ? 'source/frames' : inputFrames,
  canvas: outputCanvas, sourceCanvas, scale: settings.scale,
  pivot: pivot?.map(value => value * settings.scale) ?? null, sourcePivot: pivot,
  direction: options.direction ?? 'source-front-three-quarter-only', frameFiles: results.map(frame => `processed/${frame.name}`),
  frameDurationMs: 1000 / fps,
  overrides: ['Platform manifest loop:true is overridden by the source action loop flag.', pivot ? `Platform bottom-center pivot is replaced with the known source root scaled by ${settings.scale}.` : 'Root is unknown; calibrate before integration.'],
  limitations,
});
await json('review/platform-run.json', {
  platformCommit: 'e5dc689', api, operation: `POST /api/compression/frame for each of ${names.length} frames`,
  settings, nativeSourceCanvas: sourceCanvas, outputCanvas, frameCount: names.length, fps,
  durationMs, inputBytes, outputBytes, savingsPercent: (1 - outputBytes / inputBytes) * 100,
  exportMethod: 'Unmodified Framecraft exportCompressionZip function, download captured in Node.',
  projectMethod: 'Unmodified Framecraft saveProject/loadProject functions calling its actual HTTP API.',
  projectId: saved.id, projectPath: path.relative(output, saved.path),
  reopened: { fps: reopened.fps, loopMode: reopened.workspace.loopMode, frameCount: reopened.frames.length, compressionCount: reopened.compression.results.length, resultBytesVerified: true },
  notPerformed: ['UI playback observation', 'Compressed atlas export (browser Canvas required)', 'AI smoothing or generation', 'Godot integration'], records,
});
runtime.releaseLoadedProject(reopened);
runtime.releaseLoadedProject(snapshot);
await fs.rm(temp, { recursive: true, force: true });
console.log(JSON.stringify({ project: saved.path, inputBytes, outputBytes, savingsPercent: (1 - outputBytes / inputBytes) * 100, frames: names.length, fps }));
