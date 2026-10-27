#!/usr/bin/env node
// Rebuild static component review boards from the project catalog and recipe.
const fs = require('node:fs');
const path = require('node:path');
const projectRoot = path.resolve(__dirname, '..');
const reviewRoot = path.join(projectRoot, 'assets/source/whalefall-v5-2-complete/review/components');
const outputRoot = process.argv[2] ? path.resolve(projectRoot, process.argv[2]) : reviewRoot;
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const recipe = readJson(path.join(reviewRoot, 'components-recipe.json'));
const catalog = readJson(path.join(projectRoot, 'assets/catalog.json'));

function loadReferencedAssets() {
  const byId = new Map(catalog.assets.map(asset => [asset.id, asset]));
  const used = new Set();
  for (const group of [...recipe.componentRecipes, ...recipe.habitatRecipes]) {
    for (const state of group.states) {
      used.add(state.baseAssetId || group.baseAssetId);
      for (const part of state.parts) used.add(part.assetId);
    }
  }
  const assets = {};
  for (const id of used) {
    const asset = byId.get(id);
    if (!asset) throw new Error(`Recipe asset missing from catalog: ${id}`);
    const file = path.resolve(projectRoot, asset.file);
    if (!fs.existsSync(file)) throw new Error(`PNG missing for ${id}: ${asset.file}`);
    assets[id] = { ...asset, data: `data:image/png;base64,${fs.readFileSync(file).toString('base64')}` };
  }
  return assets;
}

// This function runs only in the isolated browser page. It does not change PNGs.
function renderBoard({ groups, registry, recipe }) {
  const canvas = document.querySelector('canvas');
  const width = 440, height = 340, ppu = recipe.pixelsPerUnit;
  canvas.width = width * 3;
  canvas.height = height * groups.length;
  const ctx = canvas.getContext('2d');
  const reports = [];
  function scale(asset, override, basis) {
    const world = override || asset.world || { axis: 'width', units: 0.4 };
    const box = basis === 'canvas' ? [0, 0, asset.width, asset.height] : asset.bbox;
    const length = world.axis === 'height' ? box[3] - box[1] : box[2] - box[0];
    return world.units * ppu / length;
  }
  function build(group, state) {
    const base = registry[state.baseAssetId || group.baseAssetId];
    let pivot = base.pivot, baseScale = scale(base);
    const rotation = (state.baseRotationDeg || 0) * Math.PI / 180;
    const registration = recipe.stateRegistration[group.id];
    if (registration) {
      const registered = Object.values(registration.states).find(item => item.assetId === base.id);
      if (registered) {
        pivot = registered.pivot;
        if (registered.pixelScaleRelativeToClosed) {
          baseScale = scale(registry[registration.states.closed.assetId]) * registered.pixelScaleRelativeToClosed;
        }
      }
    }
    const parts = [{ id: base.id, pos: [0, 0], anchor: pivot, scale: baseScale, rot: rotation, z: 0, opacity: 1, brightness: state.baseBrightness || 1 }];
    for (const part of state.parts) {
      const asset = registry[part.assetId];
      const dx = (part.atBasePixel[0] - pivot[0]) * baseScale;
      const dy = (part.atBasePixel[1] - pivot[1]) * baseScale;
      const inherited = part.inheritBaseRotation === false ? 0 : rotation;
      parts.push({
        id: part.assetId,
        pos: [dx * Math.cos(inherited) - dy * Math.sin(inherited), dx * Math.sin(inherited) + dy * Math.cos(inherited)],
        anchor: part.anchorPixel || asset.pivot,
        scale: scale(asset, part.worldOverride, part.scaleBasis),
        rot: (part.rotationDeg || 0) * Math.PI / 180 + inherited,
        z: part.z ?? 1, opacity: part.opacity ?? 1, brightness: 1,
      });
    }
    const bounds = [Infinity, Infinity, -Infinity, -Infinity];
    for (const part of parts) {
      const box = registry[part.id].bbox;
      for (const [x, y] of [[box[0], box[1]], [box[2], box[1]], [box[2], box[3]], [box[0], box[3]]]) {
        const dx = (x - part.anchor[0]) * part.scale, dy = (y - part.anchor[1]) * part.scale;
        const px = part.pos[0] + dx * Math.cos(part.rot) - dy * Math.sin(part.rot);
        const py = part.pos[1] + dx * Math.sin(part.rot) + dy * Math.cos(part.rot);
        bounds[0] = Math.min(bounds[0], px); bounds[1] = Math.min(bounds[1], py);
        bounds[2] = Math.max(bounds[2], px); bounds[3] = Math.max(bounds[3], py);
      }
    }
    return { parts, bounds, pivot };
  }
  function backdrop(x, y, light) {
    ctx.fillStyle = light ? '#e8e3d8' : '#142b39'; ctx.fillRect(x, y, width, height);
    ctx.strokeStyle = light ? '#c9c8be' : '#284657';
    for (let gx = 0; gx < width; gx += 32) { ctx.beginPath(); ctx.moveTo(x + gx, y + 32); ctx.lineTo(x + gx, y + height); ctx.stroke(); }
    for (let gy = 32; gy < height; gy += 32) { ctx.beginPath(); ctx.moveTo(x, y + gy); ctx.lineTo(x + width, y + gy); ctx.stroke(); }
  }
  for (const [row, group] of groups.entries()) {
    const built = group.states.map(state => build(group, state));
    const union = built.reduce((sum, item) => [Math.min(sum[0], item.bounds[0]), Math.min(sum[1], item.bounds[1]), Math.max(sum[2], item.bounds[2]), Math.max(sum[3], item.bounds[3])], [Infinity, Infinity, -Infinity, -Infinity]);
    const fit = Math.min(1.5, (width - 50) / (union[2] - union[0]), (height - 75) / (union[3] - union[1]));
    for (let col = 0; col < 3; col++) {
      const x = col * width, y = row * height, state = group.states[col];
      backdrop(x, y, col % 2);
      if (!state) continue;
      const { parts, bounds, pivot } = built[col];
      const ox = x + width / 2 - (union[0] + union[2]) / 2 * fit;
      const oy = y + 50 + (height - 62) / 2 - (union[1] + union[3]) / 2 * fit;
      for (const part of parts.sort((a, b) => a.z - b.z)) {
        ctx.save(); ctx.translate(ox + part.pos[0] * fit, oy + part.pos[1] * fit);
        ctx.rotate(part.rot); ctx.scale(part.scale * fit, part.scale * fit);
        ctx.globalAlpha = part.opacity; ctx.filter = `brightness(${part.brightness})`;
        ctx.drawImage(window.componentImages[part.id], -part.anchor[0], -part.anchor[1]); ctx.restore();
      }
      ctx.fillStyle = col % 2 ? '#243d48' : '#d4e8ef'; ctx.font = '15px sans-serif';
      ctx.fillText(`${group.id} · ${state.id}`, x + 12, y + 23); ctx.font = '11px sans-serif';
      ctx.fillText(`128 px/U × ${fit.toFixed(3)} / fixed state registration`, x + 12, y + height - 10);
      reports.push({ recipe: group.id, state: state.id, relativePPU: 128 * fit, bounds, unionBounds: union, basePivot: pivot, partCount: parts.length, parts: parts.map(part => ({ id: part.id, position: part.pos, anchor: part.anchor, scale: part.scale, rotation: part.rot })) });
    }
  }
  return reports;
}

async function main() {
  let chromium;
  try { ({ chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright')); }
  catch { throw new Error('Install Playwright or set PLAYWRIGHT_MODULE to its module path.'); }
  const registry = loadReferencedAssets();
  fs.mkdirSync(outputRoot, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1320, height: 1100 }, deviceScaleFactor: 1 });
    await page.setContent('<body style="margin:0;background:#0a1b27"><canvas></canvas></body>');
    await page.evaluate(async registry => {
      window.componentImages = {};
      for (const [id, asset] of Object.entries(registry)) {
        const image = new Image(); image.src = asset.data; await image.decode(); window.componentImages[id] = image;
      }
    }, registry);
    const groups = { mechanisms: recipe.componentRecipes.slice(0, 5), doors: recipe.componentRecipes.slice(5, 13), rewards: recipe.componentRecipes.slice(13), habitats: recipe.habitatRecipes };
    const reports = {};
    for (const [name, group] of Object.entries(groups)) {
      reports[name] = await page.evaluate(renderBoard, { groups: group, registry, recipe });
      await page.locator('canvas').screenshot({ path: path.join(outputRoot, `${name}-composition-board.png`) });
    }
    const report = { status: 'rendered', scope: 'Static component composition only; no PNG modification, animation or game runtime acceptance.', catalogAssetCount: catalog.assets.length, referencedAssetCount: Object.keys(registry).length, missingReferences: [], recipes: reports };
    fs.writeFileSync(path.join(outputRoot, 'composition-render.json'), JSON.stringify(report, null, 2) + '\n');
    console.log(JSON.stringify({ catalogAssets: catalog.assets.length, referencedAssets: Object.keys(registry).length, missingReferences: 0, output: path.relative(projectRoot, outputRoot) }));
  } finally { await browser.close(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
