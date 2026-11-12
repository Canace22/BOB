// Builds kit rooms for regions beyond R1.
// Input: content/whalebelly/world/recipes/*.json (layout in U) + assets/catalog.json (art metrics).
// Output: content/whalebelly/<region>/<id>.tscn, content/whalebelly/world/rooms.json, art/manifest.json entries.
// Run from the repo root: node game/tools/build_world_rooms.mjs && node tools/godot.mjs sync-art
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repo = path.resolve(game, '..');
const recipes = path.join(game, 'content/whalebelly/world/recipes');
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const catalog = new Map(readJson(path.join(repo, 'assets/catalog.json')).assets.map(asset => [asset.id, asset]));
const world = readJson(path.join(recipes, '_world.json'));
const VIEW = [1280, 720];
const COVER = 1.08; // dash zoom-out and shake stay inside parallax layers
const THICKNESS = 35;
const round = value => Math.round(value * 10) / 10;
const vec = (x, y) => `Vector2(${round(x)}, ${round(y)})`;
const ratio = value => `Vector2(${value.toFixed(4)}, ${value.toFixed(4)})`;
const used = new Map(); // art id -> max texture side (0 keeps the source size)

// Catalog metrics scaled to the synced texture: bbox is the visible alpha box, pivot the authored anchor.
function art(id, max = 0) {
  const asset = catalog.get(id);
  if (!asset) throw new Error(`Unknown catalog asset: ${id}`);
  used.set(id, Math.max(used.get(id) ?? 0, max));
  const shrink = max > 0 ? Math.min(1, max / Math.max(asset.width, asset.height)) : 1;
  const [x0, y0, x1, y1] = asset.bbox.map(value => value * shrink);
  return {id, x0, y0, x1, y1, width: asset.width * shrink, pivot: asset.pivot.map(value => value * shrink), shrink, units: asset.world.units, axis: asset.world.axis};
}

// A strip of equal pieces whose visible tops line up on y; alternate pieces are mirrored.
function strip(scene, parent, prefix, piece, rule, x, y, w, unit) {
  const count = Math.max(1, Math.round(w / rule.split));
  const span = w / count;
  for (let i = 0; i < count; i++) {
    const overlap = count > 1 ? 0.3 : 0;
    const scale = (span + overlap) * unit / (piece.x1 - piece.x0);
    const flip = i % 2 === 1;
    const left = flip ? piece.width - piece.x1 : piece.x0;
    const position = vec((x + i * span - overlap / 2) * unit - left * scale, y * unit - (piece.y0 + rule.surface * piece.shrink) * scale);
    scene.sprite(parent, `${prefix}_${i}`, piece.id, {position, scale: ratio(scale), centered: 'false', flip_h: flip});
  }
}

function sceneWriter(id) {
  const resources = [];
  const nodes = [];
  const ext = (type, file) => {
    let entry = resources.find(item => item.file === file);
    if (!entry) resources.push(entry = {type, file, id: `r${resources.length + 1}`});
    return `ExtResource("${entry.id}")`;
  };
  const node = (name, type, parent, props = {}) => {
    const header = parent === null ? `[node name="${name}" type="${type}"]` : `[node name="${name}" type="${type}" parent="${parent}"]`;
    nodes.push([header, ...Object.entries(props).filter(([, value]) => value !== false && value !== undefined).map(([key, value]) => `${key} = ${value}`)].join('\n'));
  };
  return {
    ext, node,
    sprite: (parent, name, artId, props) => node(name, 'Sprite2D', parent, {...props, texture: ext('Texture2D', `res://art/world-kit/${artId}.png`)}),
    text: () => `[gd_scene format=3]\n\n${resources.map(item => `[ext_resource type="${item.type}" path="${item.file}" id="${item.id}"]`).join('\n')}\n\n${nodes.join('\n\n')}\n`,
    id,
  };
}

function parallax(scene, parent, name, artId, factor, size, vertical = true) {
  const piece = art(artId);
  const asset = catalog.get(artId);
  const need = size.map((side, axis) => (VIEW[axis] + Math.abs(factor) * Math.max(0, side - VIEW[axis])) * COVER);
  const scale = Math.max(need[0] / asset.width, need[1] / asset.height);
  scene.node(name, 'Node2D', parent, {script: scene.ext('Script', 'res://src/world/scenery/kit/kit_parallax.gd'), factor, room_center: vec(size[0] / 2, size[1] / 2), vertical: vertical ? undefined : 'false'});
  scene.sprite(`${parent}/${name}`, 'Art', piece.id, {position: vec(size[0] / 2, size[1] / 2), scale: ratio(scale)});
}

function buildRoom(recipe) {
  const kit = world.kits[recipe.kit_variant ?? recipe.kit];
  const unit = recipe.unit;
  const size = recipe.size.map(value => value * unit);
  const px = point => point.map(value => round(value * unit));
  const scene = sceneWriter(recipe.id);
  const surfaces = [];
  scene.node(recipe.id, 'Node2D', null);
  scene.node('Far', 'Node2D', '.', {z_index: -30});
  parallax(scene, 'Far', 'Water', kit.water.art, kit.water.parallax, size);
  parallax(scene, 'Far', 'Organs', kit.far.art, kit.far.parallax, size);
  scene.node('Middle', 'Node2D', '.', {z_index: -15});
  scene.node('Ambient', 'Node2D', 'Middle');
  (recipe.bubbles ?? []).forEach((zone, i) => scene.node(`Bubbles${i}`, 'Node2D', 'Middle/Ambient', {
    script: scene.ext('Script', 'res://src/world/scenery/local_environment/elements/bubble_emitter.gd'),
    bounds: `Rect2(${px(zone.rect).join(', ')})`, population: zone.count, seed_id: i + 1, size_range: 'Vector2(4, 9)'}));
  const color = hex => `Color(${[0, 2, 4].map(i => (parseInt(hex.slice(i, i + 2), 16) / 255).toFixed(3)).join(', ')}, 1)`;
  (recipe.beams ?? []).forEach((beam, i) => {
    const piece = art(beam.art ?? 'fx-cold-beam');
    const side = catalog.get(piece.id).width;
    scene.sprite('Middle/Ambient', `Beam${i}`, piece.id, {script: scene.ext('Script', 'res://src/world/scenery/kit/kit_pulse.gd'), position: vec(beam.at[0] * unit, beam.at[1] * unit),
      scale: `Vector2(${(beam.size[0] * unit / side).toFixed(4)}, ${(beam.size[1] * unit / side).toFixed(4)})`, modulate: color(beam.tint ?? 'ffffff'), base_alpha: beam.opacity, phase: (i * 1.7).toFixed(1)});
  });
  (recipe.drift ?? []).forEach((field, i) => scene.node(`Drift${i}`, 'Node2D', 'Middle/Ambient', {
    script: scene.ext('Script', 'res://src/world/scenery/kit/kit_drift.gd'), texture: scene.ext('Texture2D', `res://art/world-kit/${art(field.art).id}.png`),
    bounds: `Rect2(${px(field.rect).join(', ')})`, population: field.count, velocity: `Vector2(${field.velocity.join(', ')})`, sway: field.sway ?? 8,
    size_range: `Vector2(${field.size.join(', ')})`, opacity: field.opacity, tint: color(field.tint ?? 'ffffff'), turn_degrees: field.turn ?? 0, seed_id: i + 1}));
  scene.node('World', 'Node2D', '.', {z_index: 0});
  scene.node('Art', 'Node2D', 'World');
  scene.node('Terrain', 'Node2D', 'World');
  const collider = (name, x, y, w, depth, oneWay) => {
    const [x0, x1, top] = [x * unit, (x + w) * unit, y * unit];
    scene.node(name, 'StaticBody2D', 'World/Terrain');
    scene.node('Contour', 'CollisionPolygon2D', `World/Terrain/${name}`, {
      polygon: `PackedVector2Array(${[x0, top, x1, top, x1, top + depth, x0, top + depth].map(round).join(', ')})`,
      one_way_collision: oneWay ? 'true' : false, one_way_collision_margin: oneWay ? '6.0' : false});
    surfaces.push([[round(x0), round(top)], [round(x1), round(top)]]);
  };
  const bed = art(kit.bed.art, 1280);
  (recipe.beds ?? []).forEach((item, i) => {
    strip(scene, 'World/Art', `Bed${i}`, bed, kit.bed, item.x, item.y, item.w, unit);
    collider(`Bed${i}`, item.x, item.y, item.w, (recipe.size[1] - item.y) * unit, false);
  });
  const platform = art(kit.platform.art, 1280);
  recipe.platforms.forEach(item => {
    strip(scene, 'World/Art', item.id, platform, kit.platform, item.x, item.y, item.w, unit);
    // Rounded rims are not footing: the collider stops short of each visible end.
    const inset = Math.min(0.25, item.w * 0.04);
    collider(`Surface_${item.id}`, item.x + inset, item.y, item.w - inset * 2, THICKNESS, !item.solid);
  });
  const anchored = (parent, name, artId, at, units, max, extra = {}) => {
    const piece = art(artId, max);
    const visible = piece.axis === 'height' ? piece.y1 - piece.y0 : piece.x1 - piece.x0;
    const scale = units * unit / visible;
    scene.sprite(parent, name, artId, {position: vec(at[0] * unit - piece.pivot[0] * scale, at[1] * unit - piece.pivot[1] * scale), scale: ratio(scale), centered: 'false', z_index: 1, ...extra});
  };
  (recipe.props ?? []).forEach((item, i) => {
    // The host hides World/RewardArt once the room's reward is taken, revealing whatever sits behind it.
    if (item.node === 'RewardArt') scene.node('RewardArt', 'Node2D', 'World');
    anchored(item.node === 'RewardArt' ? 'World/RewardArt' : 'World/Art', `Prop${i}_${item.art}`, item.art, item.at, item.units ?? catalog.get(item.art).world.units, 640);
  });
  (recipe.rings ?? []).forEach((ring, i) => anchored('World/Art', `Ring${i}`, kit.ring.art, ring, kit.ring.units, 256));
  scene.node('Foreground', 'Node2D', '.', {z_index: 10});
  if (recipe.foreground?.length) {
    const fold = art(kit.foreground.art, 1280);
    scene.node('Folds', 'Node2D', 'Foreground', {script: scene.ext('Script', 'res://src/world/scenery/kit/kit_parallax.gd'), factor: kit.foreground.parallax, room_center: vec(size[0] / 2, size[1] / 2), vertical: 'false'});
    recipe.foreground.forEach((item, i) => {
      const scale = item.w * unit / (fold.x1 - fold.x0);
      // Only the top band shows: the fold hangs below the lowest footing.
      scene.sprite('Foreground/Folds', `Fold${i}`, fold.id, {position: vec(item.x * unit - fold.x0 * scale, (recipe.size[1] - 1.1) * unit - fold.y0 * scale), scale: ratio(scale), centered: 'false', flip_h: i % 2 === 1});
    });
  }
  scene.node('Doorways', 'Node2D', '.');
  const doors = recipe.doors.map((door, i) => {
    scene.node(`Entrance${i + 1}`, 'Node2D', 'Doorways', {script: scene.ext('Script', 'res://src/campaign/campaign_doorway.gd'), destination_id: `"${door.to_id}"`, kind: `"${door.kind}"`, direction: door.direction.toFixed(1), height: (door.art ? 0 : door.height ?? 155).toFixed(1), prompt_offset: `Vector2(0, ${door.art ? -250 : -171})`});
    if (door.art) anchored(`Doorways/Entrance${i + 1}`, 'Closed', door.art, [0, 0], catalog.get(door.art).world.units, 512);
    if (door.art_open) anchored(`Doorways/Entrance${i + 1}`, 'Open', door.art_open, [0, 0], catalog.get(door.art_open).world.units, 512, {visible: 'false'});
    const data = {pos: px(door.at), to_id: door.to_id, to: -2, spawn: door.spawn ?? [0, 0], ability: door.ability ?? ''};
    for (const key of ['requires', 'locked', 'locked_message']) if (door[key]) data[key] = door[key];
    return data;
  });
  const directory = path.join(game, 'content/whalebelly', recipe.kit.toLowerCase());
  fs.mkdirSync(directory, {recursive: true});
  fs.writeFileSync(path.join(directory, `${recipe.id}.tscn`), scene.text());
  // Enemy layout is authored in U; sprite scales come from the ledger like every other piece.
  const lengths = ['lane', 'lanes', 'radius', 'engage', 'speed', 'offset', 'hurt', 'mouth', 'floor'];
  const scaled = value => Array.isArray(value) ? value.map(item => round(item * unit)) : round(value * unit);
  const enemies = (recipe.enemies ?? []).map(enemy => {
    const sprites = Object.fromEntries(Object.entries(enemy.sprites).map(([role, spec]) => {
      const piece = art(spec.art, spec.max ?? 256);
      const visible = piece.axis === 'height' ? piece.y1 - piece.y0 : piece.x1 - piece.x0;
      return [role, {path: `res://art/world-kit/${spec.art}.png`, scale: Number(((spec.units ?? piece.units) * unit / visible).toFixed(4))}];
    }));
    const config = Object.fromEntries(Object.entries(enemy).filter(([key]) => !['at', 'boss', 'name', 'grants', 'defeat_notice', 'sprites'].includes(key)).map(([key, value]) => [key, lengths.includes(key) ? scaled(value) : value]));
    if (config.enraged) config.enraged = Object.fromEntries(Object.entries(config.enraged).map(([key, value]) => [key, lengths.includes(key) ? scaled(value) : value]));
    return {type: 'kit', pos: px(enemy.at), boss: Boolean(enemy.boss), name: enemy.name, ...(enemy.grants ? {grants: enemy.grants, defeat_notice: enemy.defeat_notice} : {}), config: {...config, sprites}};
  });
  const passthrough = Object.fromEntries(['hint', 'about', 'next', 'reward_grants', 'reward_prompt', 'reward_notice', 'reward_requires', 'reward_locked'].filter(key => recipe[key] !== undefined).map(key => [key, recipe[key]]));
  return {id: recipe.id, name: recipe.name, kit: true, size, spawn: px(recipe.spawn), surfaces, holes: [], enemies, rings: (recipe.rings ?? []).map(px), reward: recipe.reward ? px(recipe.reward) : [], ...(recipe.camp ? {camp: px(recipe.camp)} : {}), ...passthrough, doors};
}

// Checkpoints store room indices, so the order is explicit and append-only.
const listed = fs.readdirSync(recipes).filter(name => name.endsWith('.json') && !name.startsWith('_')).map(name => name.replace('.json', ''));
const unordered = listed.filter(id => !world.order.includes(id));
if (unordered.length) throw new Error(`Append these rooms to "order" in _world.json: ${unordered.join(', ')}`);
const rooms = world.order.map(id => buildRoom(readJson(path.join(recipes, `${id}.json`))));
fs.writeFileSync(path.join(game, 'content/whalebelly/world/rooms.json'), JSON.stringify({rooms, links: world.links, map: world.map}, null, 2) + '\n');

// Runtime copies come from the asset library through the sync manifest.
const manifestPath = path.join(game, 'art/manifest.json');
const manifest = readJson(manifestPath);
let added = 0;
// Entries of pieces no room uses any more are dropped together with their runtime copy.
const stale = manifest.entries.filter(item => item.dest.startsWith('world-kit/') && !used.has(path.basename(item.dest, '.png')));
for (const item of stale) for (const suffix of ['', '.import']) fs.rmSync(path.join(game, 'art', item.dest + suffix), {force: true});
manifest.entries = manifest.entries.filter(item => !stale.includes(item));
added += stale.length;
for (const [id, max] of used) {
  const dest = `world-kit/${id}.png`;
  const entry = {src: catalog.get(id).file, dest, ...(max > 0 ? {max} : {})};
  const index = manifest.entries.findIndex(item => item.dest === dest);
  if (index < 0) { manifest.entries.push(entry); added++; }
  else if (JSON.stringify(manifest.entries[index]) !== JSON.stringify(entry)) { manifest.entries[index] = entry; added++; }
}
if (added) fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({rooms: rooms.map(room => room.id), art: [...used.keys()], manifestChanged: added}, null, 2));
