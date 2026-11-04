import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync, realpathSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import os from 'node:os';
import { pathToFileURL } from 'node:url';
import { prepareWeb, prepareStoryShell } from './prepare-web.mjs';
import { prepareStoryPublication } from './deploy-story-pages.mjs';
import { prepareStoryProject, storyProjectSettings } from './story-export-project.mjs';

const SCENE = 'res://content/story/main.tscn';
const SHELL = '<script src="index.js"></script>\n<script>\nconst GODOT_CONFIG = {"args":[],"executable":"index"};\nconst engine = new Engine(GODOT_CONFIG);\n</script>\n<progress id="status-progress"></progress>';
const git = (directory, ...args) => execFileSync('git', args, { cwd: directory, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();

function fixture(t) {
  const directory = mkdtempSync(path.join(os.tmpdir(), 'bob-story-web-'));
  t.after(() => {
    const actual = realpathSync(directory);
    const parent = realpathSync(os.tmpdir());
    assert.equal(path.dirname(actual).toLowerCase(), parent.toLowerCase());
    assert.ok(path.basename(actual).startsWith('bob-story-web-'));
    rmSync(actual, { recursive: true, force: true });
  });
  return directory;
}

function file(directory, name, value) {
  const target = path.join(directory, name);
  mkdirSync(path.dirname(target), { recursive: true });
  writeFileSync(target, value);
}

function exportFixture(directory, mainScene = SCENE) {
  file(directory, 'index.html', SHELL);
  file(directory, 'index.wasm', Buffer.from([0, 97, 115, 109, 1, 0, 0, 0]));
  file(directory, 'index.pck', 'test pack');
  file(directory, 'index.js', '// isolated test engine placeholder');
  const projectConfig = path.join(directory, 'project.godot.fixture');
  file(directory, 'project.godot.fixture', `[application]\nrun/main_scene="${SCENE}"\n`);
  return prepareWeb({ web: directory, mainScene, projectConfig });
}

test('chapter shell has no unsupported scene args and rejects missing baked settings', t => {
  const directory = fixture(t);
  const configPath = path.join(directory, 'project.godot');
  file(directory, 'project.godot', `[application]\nrun/main_scene="${SCENE}"\n`);
  const retained = SHELL.replace('"args":[]', `"args":["${SCENE}"]`);
  const selected = prepareStoryShell(retained, SCENE, configPath);
  const config = JSON.parse(selected.match(/const GODOT_CONFIG = (\{[^\n]*\});/)[1]);
  assert.deepEqual(config.args, []);
  assert.equal(config.executable, 'index');
  assert.equal(prepareStoryShell(selected, SCENE, configPath), selected);
  assert.throws(() => prepareStoryShell('missing shell config', SCENE, configPath), /GODOT_CONFIG/);
  assert.throws(() => prepareStoryShell(SHELL, 'res://bad<script>.tscn', configPath), /Invalid/);
  assert.throws(() => prepareStoryShell(SHELL, SCENE), /isolated project/);
  assert.throws(() => prepareStoryShell(SHELL, 'res://other/main.tscn', configPath), /isolated project/);
});

test('isolated project bakes chapter entry and copies cache without altering source', t => {
  const game = fixture(t);
  const original = '[application]\nconfig/name="Fixture"\nrun/main_scene="res://old/main.tscn"\n\n[rendering]\nsetting=true\n';
  file(game, 'project.godot', original);
  const preset = '[preset.0]\nname="Web"\nexport_filter="all_resources"\ninclude_filter="art/**/*.json"\n\n[preset.0.options]\nvariant/thread_support=false\n';
  file(game, 'export_presets.cfg', preset);
  file(game, 'content/story/main.tscn', 'scene');
  file(game, '.godot/imported/fixture.ctex', 'cached texture');
  file(game, '.godot/editor/layout.cfg', 'editor state');
  file(game, 'build/old-export.pck', 'exclude recursive build');
  const resourceReport = { resources: [{ file: 'content/story/main.tscn', owner: 'fixture' }] };
  const isolated = prepareStoryProject(game, { resourceReport });
  assert.equal(readFileSync(path.join(game, 'project.godot'), 'utf8'), original);
  assert.equal(readFileSync(path.join(game, 'export_presets.cfg'), 'utf8'), preset);
  assert.match(readFileSync(path.join(isolated, 'export_presets.cfg'), 'utf8'), /export_filter="resources"/);
  assert.equal(readFileSync(path.join(isolated, 'project.godot'), 'utf8'), storyProjectSettings(original));
  assert.equal(existsSync(path.join(isolated, 'build')), false);
  assert.equal(existsSync(path.join(isolated, '.godot/editor')), false);
  assert.equal(readFileSync(path.join(isolated, '.godot/imported/fixture.ctex'), 'utf8'), 'cached texture');
  file(isolated, '.godot/imported/fixture.ctex', 'changed isolated cache');
  assert.equal(readFileSync(path.join(game, '.godot/imported/fixture.ctex'), 'utf8'), 'cached texture');
  prepareStoryProject(game, { resourceReport });
  assert.equal(readFileSync(path.join(isolated, '.godot/imported/fixture.ctex'), 'utf8'), 'cached texture');
});

test('preparation refreshes loader without changing the default entry', t => {
  const directory = fixture(t);
  exportFixture(directory, '');
  const original = readFileSync(path.join(directory, 'index.html'), 'utf8');
  assert.match(original, /"args":\[\]/);
  assert.equal(existsSync(path.join(directory, 'build.json')), false);
  prepareWeb({ web: directory });
  assert.equal(readFileSync(path.join(directory, 'index.html'), 'utf8'), original);
  const manifest = JSON.parse(readFileSync(path.join(directory, 'downloads.json')));
  assert.equal(manifest['index.pck'].rawBytes, 9);
});

test('chapter preparation stamps source and keeps one loader on repeated builds', t => {
  const directory = fixture(t);
  exportFixture(directory);
  prepareWeb({ web: directory, mainScene: SCENE, projectConfig: path.join(directory, 'project.godot.fixture') });
  const html = readFileSync(path.join(directory, 'index.html'), 'utf8');
  assert.equal(html.match(/window\.BOB_WEB_FILES =/g).length, 1);
  assert.equal(html.match(/id="status-detail"/g).length, 1);
  const build = JSON.parse(readFileSync(path.join(directory, 'build.json')));
  assert.equal(build.entry, 'story-c01');
  assert.equal(build.mainScene, SCENE);
  assert.equal(build.sceneSelection, 'isolated-project-setting');
  assert.match(build.source, /^[0-9a-f]{40}$/);
});

test('chapter publication replaces its subtree while preserving every other Pages tree', t => {
  const workspace = fixture(t);
  const seed = path.join(workspace, 'seed');
  mkdirSync(seed);
  git(seed, 'init', '-b', 'gh-pages');
  git(seed, 'config', 'user.name', 'Publication Fixture');
  git(seed, 'config', 'user.email', 'publication-fixture@example.invalid');
  for (const name of ['index.html', '.nojekyll', 'godot/index.html', 'godot-chapters/index.html', 'mvp-v2/index.html', 'lore/index.html', 'art/old.dat']) {
    file(seed, name, `preserve ${name}`);
  }
  file(seed, 'godot-story/obsolete.bin', 'old chapter file');
  git(seed, 'add', '.');
  git(seed, '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Fixture Pages');
  const baseline = git(seed, 'ls-tree', 'HEAD').split('\n').filter(line => !line.endsWith('\tgodot-story'));
  const remotePath = path.join(workspace, 'remote.git');
  git(workspace, 'clone', '--bare', seed, remotePath);
  const remote = pathToFileURL(remotePath).href;
  const exported = path.join(workspace, 'exported');
  exportFixture(exported);
  const source = JSON.parse(readFileSync(path.join(exported, 'build.json'))).source;
  const options = { root: workspace, exported, remote, source };
  const first = prepareStoryPublication(options);
  assert.ok(first.changed.includes('godot-story/obsolete.bin'));
  assert.ok(first.changed.every(name => name.startsWith('godot-story/')));
  assert.equal(existsSync(path.join(first.staging, 'godot-story/obsolete.bin')), false);
  const tree = git(first.staging, 'write-tree');
  assert.deepEqual(git(first.staging, 'ls-tree', tree).split('\n').filter(line => !line.endsWith('\tgodot-story')), baseline);
  assert.throws(() => prepareStoryPublication(options), /uncommitted changes/);
  git(first.staging, 'config', 'user.name', 'Publication Fixture');
  git(first.staging, 'config', 'user.email', 'publication-fixture@example.invalid');
  git(first.staging, '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Fixture chapter');
  git(first.staging, 'push', remote, 'HEAD:gh-pages');
  file(exported, 'index.js', '// updated isolated test engine placeholder');
  const second = prepareStoryPublication(options);
  assert.deepEqual(second.changed, ['godot-story/index.js']);
  const secondTree = git(second.staging, 'write-tree');
  assert.deepEqual(git(second.staging, 'ls-tree', secondTree).split('\n').filter(line => !line.endsWith('\tgodot-story')), baseline);
  assert.throws(() => prepareStoryPublication({ ...options, source: 'stale' }), /metadata/);
  assert.throws(() => prepareStoryPublication({ ...options, staging: path.join(workspace, 'nested', 'unsafe') }), /Unsafe/);
});
