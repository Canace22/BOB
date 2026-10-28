#!/usr/bin/env node
// Single entry for the Godot project in game/. Usage: node tools/godot.mjs <command> [-- extra args]
// Commands: check | test | run | editor | sync-art | export-web
import { spawnSync, spawn } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const GAME = join(ROOT, 'game');
const VERSION = readFileSync(join(GAME, '.godot-version'), 'utf8').trim();
const MAX_SCRIPT_LINES = 250;
let executable;

function findGodot() {
  if (executable) return executable;
  const candidates = [
    process.env.GODOT,
    join(ROOT, '.tools', 'godot', `Godot_v${VERSION}-stable_win64_console.exe`),
    join(ROOT, '.tools', 'godot', `Godot_v${VERSION}-stable_linux.x86_64`),
    `D:/Godot_v${VERSION}-stable_win64.exe/Godot_v${VERSION}-stable_win64_console.exe`,
  ].filter(Boolean);
  const found = candidates.find((path) => existsSync(path));
  if (!found) {
    console.error(`Godot ${VERSION} not found. Set GODOT=<path to console exe> or place it in .tools/godot/.`);
    process.exit(2);
  }
  const version = spawnSync(found, ['--version'], { encoding: 'utf8' });
  if (version.status !== 0 || !version.stdout?.trim().startsWith(`${VERSION}.stable.`)) {
    console.error(`Expected Godot ${VERSION} stable, got: ${version.stdout?.trim() ?? version.error?.message}`);
    process.exit(2);
  }
  executable = found;
  return executable;
}

// Godot exits 0 even when a -s script fails to parse, so script errors in the output count as failure.
function godot(args, { headless = true } = {}) {
  const full = [...(headless ? ['--headless'] : []), '--path', GAME, ...args];
  const result = spawnSync(findGodot(), full, { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}`;
  process.stdout.write(output);
  if (/SCRIPT ERROR|Parse Error|^ERROR:/m.test(output)) return 1;
  return result.status ?? 1;
}

const importProject = () => {
  const build = join(GAME, 'build');
  mkdirSync(build, { recursive: true });
  writeFileSync(join(build, '.gdignore'), '');
  return godot(['--import']);
};

function scriptFiles(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (name.startsWith('.') || name === 'build') return [];
    if (statSync(path).isDirectory()) return scriptFiles(path);
    return name.endsWith('.gd') ? [path] : [];
  });
}

function checkScriptSizes() {
  const long = scriptFiles(GAME)
    .map((path) => ({ path, lines: readFileSync(path, 'utf8').split('\n').length }))
    .filter(({ lines }) => lines > MAX_SCRIPT_LINES);
  for (const { path, lines } of long) {
    console.warn(`WARN ${relative(ROOT, path)} has ${lines} lines (limit ${MAX_SCRIPT_LINES}); consider splitting.`);
  }
}

const extra = process.argv.includes('--') ? process.argv.slice(process.argv.indexOf('--') + 1) : [];
const commands = {
  check() {
    if (importProject() !== 0) return 1;
    const status = godot(['res://tests/check_project.tscn']);
    checkScriptSizes();
    return status;
  },
  test: () => importProject() || godot(['--fixed-fps', '60', 'res://tests/run_tests.tscn', '--', ...extra]),
  run() {
    const result = spawnSync(findGodot(), ['--path', GAME, ...extra], { stdio: 'inherit' });
    return result.status ?? 1;
  },
  editor() {
    spawn(findGodot(), ['--editor', '--path', GAME], { detached: true, stdio: 'ignore' }).unref();
    return 0;
  },
  'sync-art': () => importProject() || godot(['-s', 'res://tools/sync_art.gd']) || importProject(),
  'export-web': () => {
    mkdirSync(join(GAME, 'build', 'web'), { recursive: true });
    const result = importProject() || godot(['--export-release', 'Web', 'build/web/index.html']);
    if (result !== 0) return result;
    return spawnSync(process.execPath, [join(ROOT, 'tools', 'prepare-web.mjs')], { stdio: 'inherit' }).status ?? 1;
  },
};

const command = commands[process.argv[2]];
if (!command) {
  console.error(`Usage: node tools/godot.mjs <${Object.keys(commands).join('|')}> [-- args]`);
  process.exit(2);
}
process.exit(command());
