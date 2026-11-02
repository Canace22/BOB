import { readFile, writeFile, copyFile, mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Calls Framecraft's exported functions unchanged. FFmpeg only decodes/encodes.
const platform = process.argv[2];
const ffmpeg = process.argv[3];
const oldFrame = process.argv[4];
if (!platform || !ffmpeg || !oldFrame) throw new Error('Usage: node run-platform-rekey.mjs <Framecraft checkout> <ffmpeg> <old retreat frame PNG>');
const out = path.dirname(fileURLToPath(import.meta.url));
const source = path.resolve(out, '../reference/user-crab-source-20261030.mp4');
const require = createRequire(path.join(platform, 'package.json'));
const { transformSync } = require('esbuild');
const hash = data => createHash('sha256').update(data).digest('hex');
const mediaSource = await readFile(path.join(platform, 'src/lib/media.ts'), 'utf8');
const compiled = transformSync(mediaSource, { loader: 'ts', format: 'esm', target: 'es2022' }).code;
const { chromaKeyPixels, lumaKeyPixels } = await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
await mkdir(out, { recursive: true });
const width = 1520, height = 608;
const raw = execFileSync(ffmpeg, ['-v', 'error', '-ss', '24.5', '-i', source, '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgba', 'pipe:1'], { maxBuffer: 8_000_000 });
if (raw.length !== width * height * 4) throw new Error('Unexpected decoded frame size');
execFileSync(ffmpeg, ['-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${width}x${height}`, '-i', 'pipe:0', '-frames:v', '1', path.join(out, 'retreat-source-frame588.png')], { input: raw, maxBuffer: 4_000_000 });
const sample = [650, 180];
const pixel = (sample[1] * width + sample[0]) * 4;
const keyColor = '#' + [...raw.subarray(pixel, pixel + 3)].map(n => n.toString(16).padStart(2, '0')).join('');
const options = { removeBackground: true, keyColor, tolerance: 12, softness: 10, spill: 70, cleanup: 'none' };
const cases = [
  { id: 'chroma-t12-s10', fn: chromaKeyPixels, options },
  { id: 'chroma-t25-s15', fn: chromaKeyPixels, options: { ...options, tolerance: 25, softness: 15 } },
  { id: 'chroma-t38-s20', fn: chromaKeyPixels, options: { ...options, tolerance: 38, softness: 20 } },
  { id: 'luma-default-black', fn: lumaKeyPixels, options: { removeBackground: true, keyColor: '#000000', spill: 70, lumaBlack: 0, lumaWhite: 85, lumaGamma: .55, lumaStrength: 1.7, lumaPolarity: 'bright' } },
];
const results = [];
for (const test of cases) {
  const pixels = test.fn(new Uint8ClampedArray(raw), test.options);
  const file = `${test.id}.png`;
  execFileSync(ffmpeg, ['-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', `${width}x${height}`, '-i', 'pipe:0', '-frames:v', '1', path.join(out, file)], { input: Buffer.from(pixels), maxBuffer: 4_000_000 });
  // Opaque QA composition only: some viewers show invisible RGB under zero alpha.
  execFileSync(ffmpeg, ['-v', 'error', '-y', '-f', 'lavfi', '-i', `color=c=0xd3d7db:s=${width}x${height}`, '-i', path.join(out, file), '-filter_complex', '[0:v][1:v]overlay=shortest=1,format=rgb24', '-frames:v', '1', path.join(out, `${test.id}-opaque-review.png`)], { maxBuffer: 4_000_000 });
  const probes = Object.fromEntries(Object.entries({ leftClaw: [740, 330], shell: [920, 270], background: [650, 180], terrain: [400, 500] }).map(([name, [x, y]]) => [name, { xy: [x, y], alpha: pixels[(y * width + x) * 4 + 3] }]));
  let clear = 0, opaque = 0;
  for (let i = 3; i < pixels.length; i += 4) { if (pixels[i] === 0) clear++; if (pixels[i] === 255) opaque++; }
  results.push({ file, exportedFunction: test.fn.name, options: test.options, probes, transparentPixels: clear, opaquePixels: opaque, outputSha256: hash(await readFile(path.join(out, file))) });
}
await copyFile(oldFrame, path.join(out, 'old-retreat-000-missing-claw.png'));
await writeFile(path.join(out, 'platform-rekey-results.json'), JSON.stringify({
  source: { url: 'https://xsj-ai-orange.seasungame.com/prod/video/20261030/ae2e5406-53a1-4150-b5e0-ff0cfe9fb254.mp4', file: '../reference/user-crab-source-20261030.mp4', sha256: hash(await readFile(source)), frameZeroBased: 588, timeSeconds: 24.5, fps: 24, size: [width, height] },
  platform: { repository: 'https://github.com/Canace22/sprite-workbench', commit: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: platform, encoding: 'utf8' }).trim(), sourceFile: 'src/lib/media.ts', sourceSha256: hash(mediaSource), invocation: 'Imported unchanged exported TypeScript pure functions through esbuild; no HTTP or UI export. FFmpeg decode and PNG encode only.' },
  keySample: { xy: sample, color: keyColor },
  oldReference: { file: 'old-retreat-000-missing-claw.png', size: [896, 512], pivot: [512, 448], sourceRoot: [880, 480], sourceScale: .8 },
  candidates: results,
  status: 'single-frame candidates requiring visual inspection; not a game animation asset',
}, null, 2) + '\n');
console.log(JSON.stringify({ keyColor, files: results.map(x => x.file), output: out }));
