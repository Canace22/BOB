// Publish the reading tool independently, keeping all game/art trees intact.
import {execFileSync} from 'node:child_process';
import {cpSync, existsSync, lstatSync, realpathSync} from 'node:fs';
import path from 'node:path';
import {root, output, buildLore} from '../game/pages/lore/build.mjs';
const staging = path.join(root, '.pages-dist', 'lore-publication');
const run = (args, cwd = root) => execFileSync('git', args, {cwd, stdio:'inherit'});
const read = (args, cwd = root) => execFileSync('git', args, {cwd, encoding:'utf8'}).trim();
function assertDirectory(directory) {
  if (!directory.startsWith(root + path.sep)) throw new Error('Publication path is outside workspace.');
  if (existsSync(directory) && (lstatSync(directory).isSymbolicLink() || realpathSync(directory).toLowerCase() !== directory.toLowerCase())) throw new Error('Linked publication path.');
}
try {
  const source = read(['rev-parse', 'HEAD']);
  buildLore(source);
  if (!process.argv.includes('--build-only')) {
    const remote = read(['remote', 'get-url', 'origin']);
    assertDirectory(path.dirname(staging)); assertDirectory(staging);
    if (!existsSync(path.join(staging, '.git'))) {
      if (existsSync(staging)) throw new Error('Existing output is not a Git checkout.');
      run(['clone', '--filter=blob:none', '--sparse', '--depth=1', '--single-branch', '--branch', 'gh-pages', remote, staging]);
    } else {
      if (read(['status', '--porcelain'], staging)) throw new Error('Publication checkout has uncommitted changes.');
      run(['fetch', '--filter=blob:none', remote, 'gh-pages'], staging);
      run(['merge', '--ff-only', '--no-stat', 'FETCH_HEAD'], staging);
    }
    run(['sparse-checkout', 'init', '--no-cone'], staging);
    run(['sparse-checkout', 'set', '/lore/'], staging);
    const destination = path.join(staging, 'lore'); assertDirectory(destination);
    cpSync(output, destination, {recursive:true});
    for (const key of ['user.name', 'user.email']) run(['config', key, read(['config', key])], staging);
    run(['add', '--', 'lore'], staging);
    const changed = read(['diff', '--cached', '--name-only'], staging).split('\n').filter(Boolean);
    if (changed.some(file => !file.startsWith('lore/'))) throw new Error('Changes outside lore publication.');
    if (changed.length) run(['commit', '-m', `发布世界观数据库 ${source.slice(0, 8)}`], staging);
    // Refuse to hide a concurrent publication: a non-fast-forward push preserves both checkouts for review.
    run(['push', remote, 'HEAD:gh-pages'], staging);
    console.log(`Lore publication: ${read(['rev-parse','HEAD'], staging)}\nhttps://canace22.github.io/BOB/lore/`);
  }
} catch (error) {
  console.error(`Lore publication failed: ${error.message}. Local output retained.`);
  process.exitCode = 1;
}
