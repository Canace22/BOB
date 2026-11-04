import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';

export function reviewSizes(currentBytes, previousBytes, budget) {
  const delta = currentBytes - previousBytes;
  return {
    overBudget: currentBytes > budget.maxStartupMiB * 1048576,
    growthNeedsReview: delta > budget.reviewGrowthMiB * 1048576 && delta / previousBytes * 100 > budget.reviewGrowthPercent,
    deltaBytes:delta,
    deltaPercent:delta / previousBytes * 100,
  };
}

async function main() {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  const read = file => JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
  const downloads = read('game/build/web/downloads.json');
  const audit = read('game/build/qa/package-audit/exported-pck.json');
  const source = execFileSync('git', ['rev-parse', 'HEAD'], {cwd:root, encoding:'utf8'}).trim();
  const site = 'https://canace22.github.io/BOB/godot/';
  const fetchJson = async file => {
    const response = await fetch(site + file + '?releaseReview=' + Date.now(), {signal:AbortSignal.timeout(30000), cache:'no-store'});
    if (!response.ok) throw new Error(`Cannot compare published ${file}: HTTP ${response.status}`);
    return response.json();
  };
  const [liveBuild, liveDownloads] = await Promise.all([fetchJson('build.json'), fetchJson('downloads.json')]);
  if (!/^[0-9a-f]{40}$/.test(liveBuild.source)) throw new Error('Invalid published source revision');
  if (downloads['index.pck'].rawBytes !== audit.bytes) throw new Error('Download metadata and audited PCK differ');
  const startup = files => Object.values(files).reduce((n, file) => n + file.packedBytes, 0);
  const currentBytes = startup(downloads), previousBytes = startup(liveDownloads);
  if (![currentBytes,previousBytes].every(n=>Number.isFinite(n)&&n>0)) throw new Error('Invalid startup byte count');
  const sizes = reviewSizes(currentBytes, previousBytes, read('game/web/release-budget.json'));
  const report = {source, previousSource:liveBuild.source, pckBytes:downloads['index.pck'].rawBytes,
    startupBytes:currentBytes, previousStartupBytes:previousBytes, groups:audit.groups, ...sizes};
  fs.writeFileSync(path.join(root, 'game/build/qa/package-audit/release-review.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(`Release ${source.slice(0,8)}: PCK ${(report.pckBytes/1048576).toFixed(2)} MiB, startup ${(currentBytes/1048576).toFixed(2)} MiB; live ${liveBuild.source.slice(0,8)} ${(previousBytes/1048576).toFixed(2)} MiB; change ${sizes.deltaPercent.toFixed(2)}%`);
  if (sizes.overBudget) throw new Error('Startup exceeds game/web/release-budget.json. Inspect package contents and optimize; change the budget only for justified content growth.');
  if (sizes.growthNeedsReview) console.warn('Package growth needs review: inspect release-review.json and account for the added bytes before publishing.');
  try {
    execFileSync('git', ['merge-base', '--is-ancestor', liveBuild.source, source], {cwd:root, stdio:'pipe'});
  } catch {
    throw new Error(`Published game ${liveBuild.source} is newer or divergent; integrate it before replacing the live game.`);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
