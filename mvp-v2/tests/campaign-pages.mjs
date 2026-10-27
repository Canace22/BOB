import { mkdir, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn, spawnSync } from 'node:child_process';
import { startPagesServer } from './pages-server.mjs';

if (Number(process.versions.node.split('.')[0]) < 20) {
  const runtime = join(homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin', process.platform === 'win32' ? 'node.exe' : 'node');
  const result = spawnSync(runtime, [fileURLToPath(import.meta.url)], { stdio: 'inherit', env: process.env });
  if (result.error) console.error(`Node.js 20+ is required: ${result.error.message}`);
  process.exit(result.status ?? 1);
}

const testRoot = dirname(fileURLToPath(import.meta.url));
const gameRoot = resolve(testRoot, '..');
const output = resolve(process.env.TEST_OUTPUT || join(gameRoot, 'output/campaign-pages'));
await mkdir(output, { recursive: true });
const served = await startPagesServer();
const report = { url: served.url, startedAt: new Date().toISOString(), checks: [], passed: false };

// Use asynchronous spawn: the parent must keep serving static HTTP requests.
async function run(script, directory) {
  const check = { script, output: join(output, directory), passed: false };
  report.checks.push(check);
  await new Promise((accept, reject) => {
    const child = spawn(process.execPath, [join(testRoot, script)], {
      cwd: gameRoot, stdio: 'inherit', env: { ...process.env, GAME_URL: served.url, TEST_OUTPUT: check.output },
    });
    child.once('error', reject);
    child.once('exit', (code, signal) => code === 0 ? accept() : reject(new Error(`${script} failed (${signal || code}).`)));
  });
  check.passed = true;
}

try {
  await run('campaign-ui.mjs', 'ui');
  await run('campaign-playthrough.mjs', 'route');
  report.passed = true;
  console.log(`Campaign UI and real-input route passed beneath ${served.url}`);
} catch (error) {
  report.error = error.stack; process.exitCode = 1; console.error(error.stack);
} finally {
  await served.close();
  await writeFile(join(output, 'result.json'), JSON.stringify(report, null, 2));
}
