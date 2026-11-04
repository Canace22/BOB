import {createHash} from 'node:crypto';

// Godot 4.7's unencrypted PCK v4. File offsets are relative to file_base.
export function readPck(buffer) {
  if (buffer.toString('ascii', 0, 4) !== 'GDPC' || buffer.readUInt32LE(4) !== 4 || buffer.readUInt32LE(20) !== 2) {
    throw new Error('Expected unencrypted Godot 4.7 PCK v4; review the reader after engine upgrades');
  }
  const base = Number(buffer.readBigUInt64LE(24));
  let offset = Number(buffer.readBigUInt64LE(32));
  const count = buffer.readUInt32LE(offset);
  offset += 4;
  const entries = [];
  for (let i = 0; i < count; i++) {
    const length = buffer.readUInt32LE(offset);
    offset += 4;
    if (length > 65536 || offset + length + 36 > buffer.length) throw new Error('Invalid PCK index');
    const file = buffer.toString('utf8', offset, offset + length).replace(/\0+$/, '');
    offset += length;
    const position = base + Number(buffer.readBigUInt64LE(offset));
    const bytes = Number(buffer.readBigUInt64LE(offset + 8));
    const md5 = buffer.toString('hex', offset + 16, offset + 32);
    const flags = buffer.readUInt32LE(offset + 32);
    offset += 36;
    if (flags || position < base || position + bytes > buffer.length) throw new Error(`Invalid PCK entry: ${file}`);
    const data = buffer.subarray(position, position + bytes);
    if (createHash('md5').update(data).digest('hex') !== md5) throw new Error(`PCK hash mismatch: ${file}`);
    entries.push({path:file, position, bytes, md5});
  }
  return entries;
}
