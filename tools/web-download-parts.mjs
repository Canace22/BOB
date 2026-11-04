import { createHash } from 'node:crypto';
import { gzipSync, gunzipSync } from 'node:zlib';

export const PART_BYTES = 64 * 1024 * 1024;
export const sha256 = data => createHash('sha256').update(data).digest('hex');

// Original export files remain local. Both compressed and raw paths have an
// independently verified, Pages-safe representation; no art is recompressed.
export function buildDownloadEntry(data, extension, write, partBytes = PART_BYTES) {
  if (!Number.isInteger(partBytes) || partBytes < 1) throw new Error('Invalid part size');
  const packed = gzipSync(data, { level: 9 });
  if (!gunzipSync(packed).equals(data)) throw new Error(`Compression verification failed: ${extension}`);
  const packedHash = sha256(packed);
  const rawHash = sha256(data);
  function split(bytes, kind, hash) {
    const parts = [];
    for (let at = 0; at < bytes.length; at += partBytes) {
      const part = bytes.subarray(at, Math.min(at + partBytes, bytes.length));
      const file = `${extension}.${hash.slice(0, 16)}.${kind}.part-${String(parts.length).padStart(3, '0')}.bin`;
      write(file, part);
      parts.push({ file, bytes: part.length, sha256: sha256(part) });
    }
    return parts;
  }
  const result = {
    packedBytes: packed.length, rawBytes: data.length,
    packedSha256: packedHash, rawSha256: rawHash,
    type: extension === 'wasm' ? 'application/wasm' : 'application/octet-stream',
  };
  if (packed.length > partBytes) result.parts = split(packed, 'gzip', packedHash);
  else {
    result.file = `${extension}.${packedHash.slice(0, 16)}.gz`;
    write(result.file, packed);
  }
  if (data.length > partBytes) result.rawParts = split(data, 'raw', rawHash);
  return result;
}

export function publicationOmissions(manifest) {
  return new Set(Object.entries(manifest).filter(([, info]) => info.rawParts?.length).map(([name]) => name));
}
