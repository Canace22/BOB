import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { collectStoryResources, storyExportPreset } from './story-export-resources.mjs';
import { readPckDirectory } from './story-pck-audit.mjs';

const game = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../game');
const actual = collectStoryResources(game);

function fixture(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), 'bob-story-selection-'));
  t.after(() => {
    const target = realpathSync(directory);
    assert.equal(path.dirname(target).toLowerCase(), realpathSync(os.tmpdir()).toLowerCase());
    assert.ok(path.basename(target).startsWith('bob-story-selection-'));
    rmSync(target, { recursive: true, force: true });
  });
  return directory;
}

test('actual chapter closure preserves dynamic assets and omits old campaign content', () => {
  const selected = new Set(actual.resources.map(item => item.file));
  for (const required of ['content/story/main.tscn', 'art/story-c01/characters/animations.json',
    'art/story-c01/characters/forager-atlas.png', 'art/story-c01/characters/mender-atlas.png',
    'art/fonts/WhalefallUI.ttf', 'art/fonts/OFL.txt', 'art/story-c01/audio/whale-call.wav',
    'art/whalebelly/runtime/audio/water_bed.wav', 'art/whalebelly/baleen_loop_v3/baleen-sway-atlas.png',
    'art/whalebelly/reference_environment/bubble.png', 'art/whalebelly/fish_schools/silverfin/swim_atlas.png',
    'art/whalebelly/fish_schools/tealback/swim_atlas.png', 'art/whalebelly/animations/player/body/idle/000.png']) {
    assert.ok(selected.has(required), required);
  }
  assert.ok(!selected.has('content/whalebelly/main.tscn'));
  assert.ok(!selected.has('src/campaign/main.gd'));
  assert.ok(![...selected].some(file => file.startsWith('art/enemies/') || file.startsWith('art/r1-chapter-scenes/')));
  assert.equal([...selected].filter(file => file.startsWith('art/whalebelly/animations/')).length, 1);
  const atlas = JSON.parse(readFileSync(path.join(game, 'art/tide-picker-action36/animations.json')));
  for (const spec of Object.values(atlas.actions)) {
    for (const layer of [spec.body, spec.fx].filter(Boolean)) assert.ok(selected.has(layer.texture.slice(6)), layer.texture);
  }
  assert.ok(actual.dynamic.length > 0);
  assert.ok(actual.resources.every(item => item.owner && existsSync(path.join(game, item.file))));
});

test('selected preset keeps options, explicitly includes metadata, and changes only its input copy', () => {
  const original = readFileSync(path.join(game, 'export_presets.cfg'), 'utf8');
  const selected = storyExportPreset(original, actual);
  assert.match(selected, /export_filter="resources"/);
  assert.match(selected, /export_files=PackedStringArray\("res:\/\//);
  assert.match(selected, /include_filter="[^"]*art\/story-c01\/characters\/animations\.json/);
  assert.doesNotMatch(selected, /art\/whalebelly\/\*\*\/\*\.json/);
  assert.equal(selected.split('[preset.0.options]')[1], original.split('[preset.0.options]')[1]);
  assert.equal(readFileSync(path.join(game, 'export_presets.cfg'), 'utf8'), original);
});

test('unknown dynamic paths and broken atlas fallback assumptions block export', t => {
  const directory = fixture(t);
  for (const file of ['project.godot', ...actual.resources.map(item => item.file)]) {
    const destination = path.join(directory, file);
    mkdirSync(path.dirname(destination), { recursive: true });
    const textual = /\.(gd|tscn|tres|json|gdshader|godot)$/.test(file);
    writeFileSync(destination, textual ? readFileSync(path.join(game, file)) : Buffer.from('fixture'));
  }
  const owner = path.join(directory, 'src/story/story_art.gd');
  const original = readFileSync(owner, 'utf8');
  writeFileSync(owner, original + '\nconst UNREVIEWED = "res://art/unreviewed/"\n');
  assert.throws(() => collectStoryResources(directory), /Unresolved chapter resource expression/);
  writeFileSync(owner, original);
  const player = path.join(directory, 'src/story/story_player.gd');
  writeFileSync(player, readFileSync(player, 'utf8').replace('atlas_visual_enabled = true', 'atlas_visual_enabled = false'));
  assert.throws(() => collectStoryResources(directory), /atlas fallback contract/);
});

test('PCK size audit reads the directory and rejects unknown format', t => {
  const directory = fixture(t);
  const tableName = Buffer.from('fixture.txt\0');
  const table = Buffer.alloc(4 + 4 + tableName.length + 36);
  table.writeUInt32LE(1, 0);
  table.writeUInt32LE(tableName.length, 4);
  tableName.copy(table, 8);
  table.writeBigUInt64LE(12n, 8 + tableName.length + 8);
  const header = Buffer.alloc(112);
  header.write('GDPC'); header.writeUInt32LE(4, 4); header.writeBigUInt64LE(112n, 32);
  const file = path.join(directory, 'test.pck');
  writeFileSync(file, Buffer.concat([header, table]));
  assert.deepEqual(readPckDirectory(file).rows, [{ file: 'fixture.txt', bytes: 12 }]);
  header.writeUInt32LE(3, 4); writeFileSync(file, Buffer.concat([header, table]));
  assert.throws(() => readPckDirectory(file), /PCK v4/);
});
