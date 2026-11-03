import { createHash } from 'node:crypto';
import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, realpathSync, rmSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const repository = fileURLToPath(new URL('../../', import.meta.url));
export const previewOutput = path.join(repository, 'game/build/art-site');
const coverageFile = 'assets/source/whalefall-v5-2-complete/coverage.json';
const uiFiles = ['index.html', 'app.js', 'styles.css', 'requirements.html', 'requirements.js', 'runtime.js'];
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

export function buildArtPreview({ root = repository, output = previewOutput, source = null } = {}) {
  root = realpathSync(root);
  output = path.resolve(output);
  // Only this dedicated build folder may be replaced, including when used by tests.
  const buildRoot = path.join(root, 'game/build');
  if (output !== path.join(buildRoot, 'art-site')) throw new Error(`Unsafe preview output: ${output}`);
  mkdirSync(buildRoot, { recursive: true });
  if (realpathSync(buildRoot) !== buildRoot || (existsSync(output) && (lstatSync(output).isSymbolicLink() || realpathSync(output) !== output))) {
    throw new Error('Preview output must not pass through a linked directory.');
  }
  const catalogBytes = readFileSync(path.join(root, 'assets/catalog.json'));
  const catalog = JSON.parse(catalogBytes);
  const coverage = JSON.parse(readFileSync(path.join(root, coverageFile)));
  const files = new Set([coverageFile]);
  const omitted = [];

  function include(file, optional = false) {
    if (typeof file !== 'string' || !/^assets\/(source|runtime)\//.test(file) || file.includes('\\') || file.split('/').includes('..')) {
      throw new Error(`Unsafe asset path: ${file}`);
    }
    const absolute = path.resolve(root, file);
    if (optional && !existsSync(absolute)) { omitted.push(file); return false; }
    if (!realpathSync(absolute).startsWith(root + path.sep) || !statSync(absolute).isFile()) throw new Error(`Invalid asset file: ${file}`);
    if (readFileSync(absolute).subarray(0, 80).toString().startsWith('version https://git-lfs.github.com/spec/v1')) {
      throw new Error(`Git LFS content missing; run git lfs pull: ${file}`);
    }
    files.add(file);
    return true;
  }

  for (const asset of catalog.assets) {
    include(asset.file);
    if (asset.thumbnail) include(asset.thumbnail);
    for (const key of ['prompts', 'references', 'sourceFiles']) {
      if (asset.source?.[key]) asset.source[key] = asset.source[key].filter(file => include(file, true));
    }
  }
  // ZIPs are reproducible local outputs. Publish every individual atlas page instead.
  if (catalog.atlas?.ready) {
    delete catalog.atlas.zip;
    include(catalog.atlas.image);
    include(catalog.atlas.json);
    const atlas = JSON.parse(readFileSync(path.join(root, catalog.atlas.json)));
    for (const page of atlas.pages || []) {
      include(path.posix.join(path.posix.dirname(catalog.atlas.json), page.image));
      include(path.posix.join(path.posix.dirname(catalog.atlas.json), page.json));
    }
  }
  for (const preview of coverage.previews || []) include(preview.file);
  for (const row of coverage.requirements) if (row.recipeFile) include(row.recipeFile);

  // Validate the entire input before replacing a previous local build.
  if (existsSync(output)) rmSync(output, { recursive: true });
  mkdirSync(output);
  for (const name of uiFiles) {
    let content = readFileSync(path.join(root, 'assets/manager', name), 'utf8');
    if (name.endsWith('.html')) content = content.replace('<html lang="zh-CN">', '<html lang="zh-CN" data-mode="preview">');
    writeFileSync(path.join(output, name), content);
  }
  for (const file of files) {
    const destination = path.join(output, file);
    mkdirSync(path.dirname(destination), { recursive: true });
    cpSync(path.join(root, file), destination);
  }
  writeFileSync(path.join(output, 'catalog.json'), JSON.stringify(catalog, null, 2) + '\n');
  const manifest = {
    source, builtAt: new Date().toISOString(), mode: 'preview', assetCount: catalog.assets.length,
    catalogSha256: sha256(catalogBytes), publishedCatalogSha256: sha256(readFileSync(path.join(output, 'catalog.json'))),
    omittedReferences: [...new Set(omitted)],
    files: [...files].sort().map(file => ({ file, bytes: statSync(path.join(output, file)).size, sha256: sha256(readFileSync(path.join(output, file))) })),
  };
  writeFileSync(path.join(output, 'build.json'), JSON.stringify(manifest, null, 2) + '\n');
  return manifest;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const manifest = buildArtPreview();
  console.log(`Art preview: ${manifest.assetCount} assets, ${manifest.files.length} files -> ${previewOutput}`);
}
