// Batch orchestration only. Image processing/export are delegated to Framecraft.
// Usage: node process-all.mjs <framecraft-repo> <crab_boss_sprites-directory>
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const [platform, source] = process.argv.slice(2).map(value => path.resolve(value));
if (!platform || !source) throw new Error('Provide Framecraft and the original crab_boss_sprites directory.');
const output = path.dirname(fileURLToPath(import.meta.url));
const processor = path.resolve(output, '../crab-animation-platform-v1/process.mjs');
const verifier = path.resolve(output, '../crab-animation-platform-v1/verify.py');
const run = promisify(execFile);
const sourceJson = await fs.readFile(path.join(source, 'animations.json'));
const animations = JSON.parse(sourceJson.toString());
const expected = [18, 63, 45, 48, 48, 39, 33, 30, 36];
if (animations.fps !== 12 || JSON.stringify(animations.frame_size) !== '[896,512]' || JSON.stringify(animations.pivot_px) !== '[512,448]') throw new Error('Unexpected source timing/canvas/pivot.');
if (animations.actions.length !== expected.length) throw new Error('Expected nine source actions.');
await fs.mkdir(path.join(output, 'review'), { recursive: true });
await fs.writeFile(path.join(output, 'source-animations.json'), sourceJson.toString('utf8').replace(/\r\n/g, '\n'));
const commonLimits = [
  'Only resource size and transparency-edge processing; no redrawing or missing-limb repair.',
  'Inherits source extraction defects, dust/foreground occlusion, and source-camera direction changes.',
  'Opposite direction was not independently drawn; this is not a complete left/right set.',
  'Not integrated into Godot and not accepted as final animation art.',
];
const rows = [];
for (const [actionIndex, action] of animations.actions.entries()) {
  const folder = path.join(output, action.id);
  await fs.mkdir(folder, { recursive: true });
  const files = (await fs.readdir(path.join(source, 'frames', action.id))).filter(file => file.endsWith('.png')).sort();
  if (action.frame_count !== expected[actionIndex] || files.length !== action.frame_count || action.frames.length !== action.frame_count) throw new Error(`Frame count mismatch: ${action.id}`);
  for (const [index, frame] of action.frames.entries()) {
    if (frame.frame !== index || Math.abs(frame.source_time - (action.source_start + index / 12)) > 1e-7) throw new Error(`Source timing mismatch: ${action.id} frame ${index}`);
    if (files[index] !== `${String(index).padStart(3, '0')}.png`) throw new Error(`Source filename mismatch: ${action.id} frame ${index}`);
  }
  const limits = [...commonLimits];
  if (action.id === '08_retreat') limits.push('Known source defect: frame 000 loses the left claw; source video contains overlapping player/foreground. Compression cannot restore it.');
  if (action.id === '09_sink_fade') limits.push('Final 9 transparent frames 027–035 are intentional retained source timing, not discarded as empty frames.');
  const options = {
    output: folder, framesDirectory: `frames/${action.id}`, copySourceFrames: false,
    fps: action.fps, name: `巨蟹视频_${action.name}_75%PNG_v1`, exportName: action.id,
    loop: action.loop_recommended, pivot: animations.pivot_px,
    direction: 'original-video-view-including-turns; no-independent-opposite-direction', limitations: limits,
  };
  const config = path.join(folder, 'platform-options.json');
  await fs.writeFile(config, `${JSON.stringify(options, null, 2)}\n`);
  const completed = await run(process.execPath, [processor, platform, source, config], { maxBuffer: 1024 * 1024 });
  const verified = await run('python3', [verifier, folder], { maxBuffer: 1024 * 1024 });
  const report = JSON.parse(await fs.readFile(path.join(folder, 'review/platform-run.json'), 'utf8'));
  const checks = JSON.parse(await fs.readFile(path.join(folder, 'review/file-checks.json'), 'utf8'));
  const sourceMap = {
    sourceDirectory: source, sourceAction: action.id, sourceFps: animations.source_fps,
    outputFps: action.fps, loop: action.loop_recommended,
    sourceStart: action.source_start, sourceEndExclusive: action.source_end_exclusive,
    sourcePivot: animations.pivot_px, outputPivot: animations.pivot_px.map(value => value * .75),
    frames: action.frames.map((frame, index) => ({ file: files[index], sourceFrame: frame.source_frame, sourceTime: frame.source_time, sourceRoot: frame.source_root, sourceSha256: report.records[index].inputSha256, outputSha256: report.records[index].outputSha256 })),
  };
  await fs.writeFile(path.join(folder, 'source-map.json'), `${JSON.stringify(sourceMap, null, 2)}\n`);
  rows.push({
    id: action.id, name: action.name, frames: action.frame_count, fps: action.fps,
    durationMs: report.durationMs, loop: action.loop_recommended, sourceStart: action.source_start, sourceEndExclusive: action.source_end_exclusive,
    inputBytes: report.inputBytes, outputBytes: report.outputBytes, savingsPercent: report.savingsPercent,
    canvas: report.outputCanvas, pivot: sourceMap.outputPivot,
    project: `${action.id}/${report.projectPath}`, projectName: options.name,
    export: `${action.id}/exports/${action.id}.zip`, metadata: `${action.id}/game-metadata.json`,
    emptyFramesPreserved: checks.emptyFramesPreserved, borderContactFrames: checks.borderContactFrames,
    sourceBorderContactFrames: checks.sourceBorderContactFrames, projectReopened: report.reopened.resultBytesVerified,
    zipBytesVerified: checks.zipBytesMatchProcessed, knownLimitations: limits,
  });
  console.log(JSON.stringify({ action: action.id, frames: action.frame_count, saved: report.projectPath, bytes: report.outputBytes, emptyFrames: checks.emptyFramesPreserved }));
}
const inputBytes = rows.reduce((sum, row) => sum + row.inputBytes, 0);
const outputBytes = rows.reduce((sum, row) => sum + row.outputBytes, 0);
const summary = {
  sourceDirectory: source, sourceUrl: animations.source_url, sourceManifestSha256: createHash('sha256').update(sourceJson).digest('hex'),
  method: 'Framecraft local compression API, unchanged PNG ZIP export and project save/load functions.',
  parameters: { scale: .75, resizeMode: 'soft', algorithm: 'lanczos', alphaThreshold: 2, sharpen: 20, paletteQuantization: false },
  actionCount: rows.length, frameCount: rows.reduce((sum, row) => sum + row.frames, 0), fps: 12,
  sourceCanvas: animations.frame_size, outputCanvas: [672, 384], pivot: [384, 336],
  inputBytes, outputBytes, savingsPercent: (1 - outputBytes / inputBytes) * 100,
  gameIntegration: false, artisticAcceptance: false, directionsComplete: false,
  actions: rows,
};
await fs.writeFile(path.join(output, 'review/batch-summary.json'), `${JSON.stringify(summary, null, 2)}\n`);
console.log(JSON.stringify({ totalFrames: summary.frameCount, inputBytes, outputBytes, savingsPercent: summary.savingsPercent }));
