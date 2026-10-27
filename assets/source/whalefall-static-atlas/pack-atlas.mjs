import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createServer } from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Optional build dependency: use Playwright's Chromium canvas for deterministic packing.
// This does not redraw artwork or create animation frames.
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = path.resolve(fileURLToPath(new URL('../../../', import.meta.url)));
const catalog = JSON.parse(await readFile(path.join(root, 'assets/catalog.json'), 'utf8'));
const width = 4096, padding = 4, extrusion = 2, ppu = 128;
const entries = catalog.assets.filter(asset => asset.spriteType === 'static' && asset.status === 'accepted').map(asset => {
  const [left, top, right, bottom] = asset.bbox;
  const factor = asset.world.units * ppu / (asset.world.axis === 'height' ? bottom - top : right - left);
  return { asset, w: Math.round((right - left) * factor), h: Math.round((bottom - top) * factor) };
}).sort((a, b) => b.h - a.h || a.asset.id.localeCompare(b.asset.id, 'en'));
let x = 0, y = 0, rowHeight = 0;
for (const entry of entries) {
  if (entry.w + padding * 2 > width) throw new Error(`${entry.asset.id} exceeds atlas width`);
  if (x + entry.w + padding * 2 > width) { x = 0; y += rowHeight; rowHeight = 0; }
  entry.x = x + padding; entry.y = y + padding;
  x += entry.w + padding * 2;
  rowHeight = Math.max(rowHeight, entry.h + padding * 2);
}
if (!entries.length) throw new Error('No accepted static sprites to pack');
const height = 2 ** Math.ceil(Math.log2(y + rowHeight));
const allowed = new Map(entries.map(entry => [`/${entry.asset.file}`, path.join(root, entry.asset.file)]));
const server = createServer(async (req, res) => {
  if (req.url === '/') { res.writeHead(200, { 'Content-Type': 'text/html' }).end('<canvas id="atlas"></canvas>'); return; }
  const file = allowed.get(req.url);
  if (!file) { res.writeHead(404).end(); return; }
  try { res.writeHead(200, { 'Content-Type': 'image/png' }).end(await readFile(file)); }
  catch { res.writeHead(500).end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
let browser;
try {
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  const encoded = await page.evaluate(async ({ entries, width, height, extrusion }) => {
    const canvas = document.querySelector('#atlas'); canvas.width = width; canvas.height = height;
    const ctx = canvas.getContext('2d'); ctx.imageSmoothingQuality = 'high';
    for (const { asset, x, y, w, h } of entries) {
      const image = new Image(); image.src = `/${asset.file}`; await image.decode();
      const [left, top, right, bottom] = asset.bbox;
      ctx.imageSmoothingEnabled = true;
      ctx.drawImage(image, left, top, right - left, bottom - top, x, y, w, h);
      // Extend the outermost rendered pixels into a two-pixel gutter for filtering.
      ctx.imageSmoothingEnabled = false;
      ctx.drawImage(canvas, x, y, w, 1, x, y - extrusion, w, extrusion);
      ctx.drawImage(canvas, x, y + h - 1, w, 1, x, y + h, w, extrusion);
      ctx.drawImage(canvas, x, y - extrusion, 1, h + extrusion * 2, x - extrusion, y - extrusion, extrusion, h + extrusion * 2);
      ctx.drawImage(canvas, x + w - 1, y - extrusion, 1, h + extrusion * 2, x + w, y - extrusion, extrusion, h + extrusion * 2);
    }
    return canvas.toDataURL('image/png').split(',')[1];
  }, { entries, width, height, extrusion });
  const frames = {};
  for (const { asset, x, y, w, h } of entries) {
    const [left, top, right, bottom] = asset.bbox;
    frames[asset.id] = {
      frame: { x, y, w, h }, rotated: false, trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w, h }, sourceSize: { w, h },
      pivot: { x: (asset.pivot[0] - left) / (right - left), y: (asset.pivot[1] - top) / (bottom - top) },
      bob: { originalFile: asset.file, originalSize: { w: asset.width, h: asset.height },
        sourceRect: { x: left, y: top, w: right - left, h: bottom - top }, originalPivot: asset.pivot,
        world: asset.world, spriteType: 'static', pixelsPerUnit: ppu }
    };
  }
  const metadata = { frames, animations: {}, meta: {
    app: 'BOB static sprite packer', image: 'atlas.png', format: 'RGBA8888', size: { w: width, h: height },
    scale: '1', pixelsPerUnit: ppu, padding, extrusion, type: 'static-atlas',
    note: 'Each frame is one different static asset, not consecutive animation frames. Background stays separate. The frame contains a normalized visible crop; original pixels remain in individual PNGs.'
  } };
  const destination = path.join(root, 'assets/runtime/sprites/whalefall-static-atlas');
  await mkdir(destination, { recursive: true });
  await writeFile(path.join(destination, 'atlas.png'), Buffer.from(encoded, 'base64'));
  await writeFile(path.join(destination, 'atlas.json'), JSON.stringify(metadata, null, 2) + '\n');
  console.log(`Packed ${entries.length} static sprites at ${ppu}px/U into ${width}×${height}; no animation sequences.`);
} finally {
  await browser?.close();
  await new Promise(resolve => server.close(resolve));
}
