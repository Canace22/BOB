import { readFile, rename, unlink, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import path from 'node:path';

export class RequestError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

const statuses = new Set(['accepted', 'needs-review', 'needs-work', 'archived']);
const editable = new Set(['revision', 'name', 'tags', 'notes', 'status']);

function boundedText(value, label, max, required = false) {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) {
    throw new RequestError(400, `${label}应为${required ? '非空' : ''}文本，最多 ${max} 字。`);
  }
  return value.trim();
}

export function validatePatch(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new RequestError(400, '请提交资源修改对象。');
  if (Object.keys(input).some(key => !editable.has(key))) throw new RequestError(400, '只能修改名称、标签、备注与验收状态。');
  if (!Number.isSafeInteger(input.revision) || input.revision < 0) throw new RequestError(400, '缺少有效的台账版本号。');
  const patch = {};
  if ('name' in input) patch.name = boundedText(input.name, '名称', 120, true);
  if ('notes' in input) patch.notes = boundedText(input.notes, '备注', 4000);
  if ('status' in input) {
    if (!statuses.has(input.status)) throw new RequestError(400, '未知验收状态。');
    patch.status = input.status;
  }
  if ('tags' in input) {
    if (!Array.isArray(input.tags) || input.tags.length > 20) throw new RequestError(400, '标签最多 20 个。');
    patch.tags = [...new Set(input.tags.map(tag => boundedText(tag, '标签', 32, true)))];
  }
  if (!Object.keys(patch).length) throw new RequestError(400, '没有需要保存的修改。');
  return patch;
}

export function createCatalogStore(file) {
  let pending = Promise.resolve();
  async function read() {
    const data = JSON.parse(await readFile(file, 'utf8'));
    if (!Array.isArray(data.assets) || !Number.isSafeInteger(data.revision)) throw new Error('Invalid catalog');
    return data;
  }
  async function save(data) {
    const temporary = path.join(path.dirname(file), `.${path.basename(file)}.${randomUUID()}.tmp`);
    try {
      await writeFile(temporary, `${JSON.stringify(data, null, 2)}\n`, { flag: 'wx' });
      await rename(temporary, file);
    } catch (error) {
      await unlink(temporary).catch(() => {});
      throw error;
    }
  }
  function update(id, input) {
    const operation = pending.then(async () => {
      const patch = validatePatch(input);
      const data = await read();
      if (input.revision !== data.revision) throw new RequestError(409, '台账已被其他页面更新。请重新载入后再保存。');
      const asset = data.assets.find(item => item.id === id);
      if (!asset) throw new RequestError(404, '没有找到该资源。');
      Object.assign(asset, patch);
      data.revision += 1;
      data.updatedAt = new Date().toISOString();
      await save(data);
      return data;
    });
    pending = operation.catch(() => {});
    return operation;
  }
  return { read, update };
}
