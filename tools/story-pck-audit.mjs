// Read only the PCK v4 directory and import remaps, never inflate/copy payload blobs.
import { closeSync, existsSync, openSync, readFileSync, readSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';

export function readPckDirectory(file) {
  const descriptor = openSync(file, 'r');
  try {
    const header = Buffer.alloc(112);
    if (readSync(descriptor, header, 0, 112, 0) !== 112 || header.toString('ascii', 0, 4) !== 'GDPC' || header.readUInt32LE(4) !== 4) {
      throw new Error('Expected unencrypted Godot PCK v4 for the chapter size audit.');
    }
    if (header.readUInt32LE(20) & 1) throw new Error('Encrypted PCK directories are unsupported.');
    const size = statSync(file).size;
    const tableAt = Number(header.readBigUInt64LE(32));
    if (tableAt < 112 || tableAt >= size || size - tableAt > 32 * 1024 * 1024) throw new Error('Invalid PCK directory bounds.');
    const table = Buffer.alloc(size - tableAt);
    if (readSync(descriptor, table, 0, table.length, tableAt) !== table.length) throw new Error('Truncated PCK directory.');
    let cursor = 4;
    const rows = [];
    for (let index = 0; index < table.readUInt32LE(0); index++) {
      const length = table.readUInt32LE(cursor); cursor += 4;
      if (length < 1 || cursor + length + 36 > table.length) throw new Error('Malformed PCK entry.');
      const name = table.toString('utf8', cursor, cursor + length).replace(/\0+$/, ''); cursor += length;
      const bytes = Number(table.readBigUInt64LE(cursor + 8)); cursor += 36;
      rows.push({ file: name, bytes });
    }
    if (cursor !== table.length) throw new Error('Unexpected trailing PCK table data.');
    return { bytes: size, rows };
  } finally { closeSync(descriptor); }
}

export function auditStoryPck(file, game, selected) {
  const remaps = new Map();
  function walk(directory) {
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const full = path.join(directory, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith('.import')) {
        const source = path.relative(game, full).replaceAll('\\', '/').slice(0, -7);
        for (const match of readFileSync(full, 'utf8').matchAll(/res:\/\/(\.godot\/imported\/[^"\r\n]+)/g)) remaps.set(match[1], source);
      }
    }
  }
  if (existsSync(path.join(game, 'art'))) walk(path.join(game, 'art'));
  const pack = readPckDirectory(file);
  const groups = {};
  let retainedBytes = 0;
  for (const row of pack.rows) {
    const source = remaps.get(row.file) ?? row.file.replace(/\.(import|remap)$/, '').replace(/\.gdc$/, '.gd');
    const group = source.startsWith('art/') ? source.split('/').slice(0, 3).join('/') : source.split('/')[0];
    groups[group] = (groups[group] ?? 0) + row.bytes;
    // Keep unclassified engine settings/compiled scene metadata in the conservative estimate.
    if (selected.has(source) || source.startsWith('.godot/') || !source.includes('/')) retainedBytes += row.bytes;
  }
  return { pckBytes: pack.bytes, files: pack.rows.length, estimatedRetainedPayloadBytes: retainedBytes,
    estimatedOmittedPayloadBytes: pack.rows.reduce((sum, row) => sum + row.bytes, 0) - retainedBytes,
    note: 'Estimate from the previous actual PCK. New export and compressed transfer size require separate measurement.',
    groups: Object.entries(groups).sort((a, b) => b[1] - a[1]).map(([category, bytes]) => ({ category, bytes })) };
}
