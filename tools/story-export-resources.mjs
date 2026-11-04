// Auditable chapter closure. Unrecognized dynamic resource expressions fail closed.
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';

const ROOT_SCENE = 'content/story/main.tscn';
const LEGACY_MAP = { idle: 'idle', run: 'run', jump_land: 'jump', strike_02: 'double_jump',
  strike_01: 'strike1', heavy: 'heavy', hit: 'hurt', recover: 'heal', interact: 'interact',
  defeat: 'defeat', A1_dash: 'dash', A2_float: 'float', A3_anchor: 'pogo', A4_parry: 'orb', A5_slit: 'slit' };
const DYNAMIC = {
  'src/campaign/action_visual.gd': ['art/tide-picker-action36/'],
  'src/campaign/tide_world_effects.gd': ['art/tide-picker-action36/'],
  'src/ui/ui_style.gd': ['art/ui/'],
  'src/world/scenery/chapter/fish_group.gd': ['art/whalebelly/fish_schools/'],
};

function inventory(game) {
  const files = [];
  function walk(directory) {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      if (entry.name.startsWith('.') || ['build', 'tests', 'tools', 'production_sources'].includes(entry.name)) continue;
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (!/\.(import|uid)$/.test(entry.name)) files.push(path.relative(game, full).replaceAll('\\', '/'));
    }
  }
  walk(game);
  return files;
}

function verifyAtlasCoverage(game) {
  const player = readFileSync(path.join(game, 'src/story/story_player.gd'), 'utf8');
  const base = readFileSync(path.join(game, 'src/campaign/tide_player.gd'), 'utf8');
  if (!player.includes('atlas_visual_enabled = true') || !player.includes('preload_actions = false')
    || !base.includes('textures[source_id]=textures.idle') || !base.includes('0 if source_id=="idle"')) {
    throw new Error('Player atlas fallback contract changed; review old-frame export exclusions.');
  }
  const actions = JSON.parse(readFileSync(path.join(game, 'art/tide-picker-action36/animations.json'), 'utf8')).actions;
  const clipBlock = base.match(/const CLIPS := \{([\s\S]*?)\n\}/)?.[1] ?? '';
  const clipNames = [...clipBlock.matchAll(/"([^"]+)"\s*:\[/g)].map(match => match[1]).sort();
  if (JSON.stringify(clipNames) !== JSON.stringify(Object.keys(LEGACY_MAP).sort())) {
    throw new Error('Legacy CLIPS changed; audit the atlas exclusion map before exporting.');
  }
  for (const key of Object.values(LEGACY_MAP)) {
    if (!actions[key]?.body?.texture) throw new Error(`Atlas replacement missing: ${key}`);
    for (const layer of [actions[key].body, actions[key].fx].filter(Boolean)) {
      if (!existsSync(path.join(game, layer.texture.replace(/^res:\/\//, '')))) throw new Error(`Missing atlas ${layer.texture}`);
    }
  }
  return { rule: 'All 15 legacy clip IDs have real atlas replacements; idle initialization needs only frame 000.', mapping: LEGACY_MAP };
}

export function collectStoryResources(game) {
  const all = inventory(game);
  const files = new Set(all);
  const classes = new Map();
  for (const file of all.filter(file => file.endsWith('.gd'))) {
    const match = readFileSync(path.join(game, file), 'utf8').match(/^class_name\s+(\w+)/m);
    if (match) classes.set(match[1], file);
  }
  const reached = new Map();
  const queue = [];
  const dynamic = [];
  function include(file, owner) {
    if (!files.has(file)) throw new Error(`Missing chapter dependency: ${owner} -> ${file}`);
    if (!reached.has(file)) { reached.set(file, owner); queue.push(file); }
  }
  include(ROOT_SCENE, 'chapter entry');
  include('art/fonts/OFL.txt', 'font license');
  const project = readFileSync(path.join(game, 'project.godot'), 'utf8');
  const autoload = project.match(/^\[autoload\]\s*$([\s\S]*?)(?=^\[|$(?![\s\S]))/m)?.[1] ?? '';
  for (const match of autoload.matchAll(/res:\/\/([^"\r\n]+)/g)) include(match[1], 'autoload');
  const atlasExclusion = verifyAtlasCoverage(game);
  for (let index = 0; index < queue.length; index++) {
    const file = queue[index];
    if (!/\.(gd|tscn|tres|gdshader|json)$/.test(file)) continue;
    const text = readFileSync(path.join(game, file), 'utf8');
    for (const match of text.matchAll(/["'](res:\/\/[^"'\r\n]+)["']/g)) {
      const resource = match[1].slice(6);
      if (files.has(resource)) { include(resource, file); continue; }
      if (file === 'src/campaign/tide_player.gd' && resource.startsWith('art/whalebelly/animations/player/') && resource.includes('%')) {
        dynamic.push({ owner: file, expression: resource, resolution: 'atlas replacements verified; only initial idle/000.png required' });
        include('art/whalebelly/animations/player/body/idle/000.png', file);
        continue;
      }
      const allowed = (DYNAMIC[file] ?? []).find(prefix => prefix === resource);
      if (allowed) {
        const selected = all.filter(candidate => candidate.startsWith(allowed));
        if (!selected.length) throw new Error(`Empty dynamic chapter family: ${allowed}`);
        selected.forEach(candidate => include(candidate, file));
        dynamic.push({ owner: file, expression: resource, files: selected.length, resolution: 'conservative complete resource family' });
        continue;
      }
      throw new Error(`Unresolved chapter resource expression: ${file} -> ${resource}`);
    }
    if (file.endsWith('.gd')) {
      const code = text.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|#[^\n]*/g, ' ');
      for (const [name, source] of classes) if (new RegExp(`\\b${name}\\b`).test(code)) include(source, file);
    }
  }
  const resources = [...reached].map(([file, owner]) => ({ file, owner, sourceBytes: statSync(path.join(game, file)).size })).sort((a, b) => a.file.localeCompare(b.file));
  return { entry: ROOT_SCENE, resources, dynamic, atlasExclusion,
    sourceBytes: resources.reduce((sum, item) => sum + item.sourceBytes, 0),
    excludedArtFiles: all.filter(file => file.startsWith('art/') && !reached.has(file)).length };
}

export function storyExportPreset(text, report) {
  const section = /^\[preset\.0\]\s*$([\s\S]*?)(?=^\[|$(?![\s\S]))/m;
  if (!section.test(text) || !text.includes('name="Web"')) throw new Error('Expected Web preset 0.');
  return text.replace(section, (_match, body) => {
    const clean = body.replace(/^export_filter=.*$/m, 'export_filter="resources"')
      .replace(/^export_files=.*\r?\n?/m, '')
      .replace(/^include_filter=.*$/m, `include_filter="${report.resources.filter(item => /\.(json|txt)$/.test(item.file)).map(item => item.file).join(',')}"`);
    const selected = report.resources.filter(item => !/\.(json|txt|md)$/.test(item.file)).map(item => `"res://${item.file}"`).join(', ');
    return `[preset.0]\nexport_files=PackedStringArray(${selected})\n${clean}`;
  });
}
