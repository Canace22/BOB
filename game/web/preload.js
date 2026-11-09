/* Content-addressed, verified startup streams. Large exports use 64 MiB parts;
 * raw parts also support browsers without DecompressionStream. Saves are untouched.
 */
(() => {
  const files = window.BOB_WEB_FILES;
  if (!files) return;
  const fetchOriginal = window.fetch.bind(window);
  const base = new URL('.', document.baseURI);
  const paths = new Map(Object.entries(files).map(([name, info]) => [new URL(name, base).href, info]));
  const names = new Map(Object.entries(files).map(([name, info]) => [info, name]));
  const compressed = typeof DecompressionStream !== 'undefined';
  const loaded = new Map();
  const budgets = new Map(Object.entries(files).map(([name, file]) => [name, compressed ? file.packedBytes : file.rawBytes]));
  const report = (key, bytes) => {
    loaded.set(key, bytes);
    const current = [...loaded.values()].reduce((a, b) => a + b, 0);
    const total = [...budgets.values()].reduce((a, b) => a + b, 0);
    const label = document.getElementById('status-detail');
    if (label) label.textContent = current >= total ? '下载完成，正在启动游戏…' : '正在下载游戏 · ' + Math.min(100, Math.floor(current / total * 100)) + '% · ' + (current / 1048576).toFixed(1) + ' / ' + (total / 1048576).toFixed(1) + ' MB';
  };
  const partsFor = (info, raw = false) => raw ? info.rawParts || [{ file: names.get(info), bytes: info.rawBytes, sha256: info.rawSha256 }] : info.parts || [{ file: info.file, bytes: info.packedBytes, sha256: info.packedSha256 }];
  const digest = async data => {
    if (!window.crypto?.subtle) throw new Error('资源校验需要 HTTPS 或 localhost');
    const bytes = await window.crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(bytes), byte => byte.toString(16).padStart(2, '0')).join('');
  };
  const cachePromise = Promise.resolve().then(() => window.caches?.open('bob-web-downloads-v2')).catch(() => undefined);

  async function verifiedPart(part, init) {
    const url = new URL(part.file, base).href;
    const cache = await cachePromise;
    // A stale or corrupted cache entry is removed before one network retry.
    for (let attempt = 0; attempt < 2; attempt++) {
      let cached;
      if (attempt === 0) try { cached = await cache?.match(url); } catch { /* Optional storage. */ }
      const response = cached || await fetchOriginal(url, init);
      if (!response.ok) throw new Error('资源下载失败 ' + response.status + ': ' + part.file);
      const reader = response.body.getReader();
      const chunks = [];
      let count = 0;
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        chunks.push(value); count += value.byteLength; report(url, count);
        if (count > part.bytes) { await reader.cancel(); break; }
      }
      const data = new Uint8Array(count);
      let at = 0;
      for (const chunk of chunks) { data.set(chunk, at); at += chunk.byteLength; }
      const valid = count === part.bytes && (!part.sha256 || await digest(data) === part.sha256);
      if (!valid) {
        try { await cache?.delete(url); } catch { /* Optional storage. */ }
        if (cached) continue;
        throw new Error('资源校验失败: ' + part.file);
      }
      if (!cached && cache) cache.put(url, new Response(data)).catch(() => {});
      return data;
    }
    throw new Error('资源校验失败: ' + part.file);
  }

  async function streamResponse(info, raw, init) {
    budgets.set(names.get(info), raw ? info.rawBytes : info.packedBytes);
    for (const part of [...partsFor(info), ...partsFor(info, true)]) loaded.delete(new URL(part.file, base).href);
    const parts = partsFor(info, raw);
    // Verify the first part before returning a response, allowing raw fallback.
    let first = await verifiedPart(parts[0], init);
    let index = 0;
    let cancelled = false;
    const stream = new ReadableStream({
      async pull(controller) {
        try {
          if (cancelled) return;
          const bytes = index === 0 ? first : await verifiedPart(parts[index], init);
          first = null;
          if (cancelled) return;
          controller.enqueue(bytes);
          index++;
          if (index === parts.length) controller.close();
        } catch (error) {
          const label = document.getElementById('status-detail');
          if (label) label.textContent = '资源下载或校验失败，请刷新重试';
          controller.error(error);
        }
      },
      cancel() { cancelled = true; first = null; },
    });
    const decoded = raw ? stream : stream.pipeThrough(new DecompressionStream('gzip'));
    return new Response(decoded, { headers: { 'Content-Type': info.type, 'Content-Length': String(info.rawBytes) } });
  }

  window.fetch = async (input, init) => {
    const requested = new URL(input instanceof Request ? input.url : String(input), base);
    const info = paths.get(requested.href);
    const method = init?.method || (input instanceof Request ? input.method : 'GET');
    if (!info || method !== 'GET') return fetchOriginal(input, init);
    const options = { ...init, signal: init?.signal || (input instanceof Request ? input.signal : undefined) };
    if (!compressed) return streamResponse(info, true, options);
    try { return await streamResponse(info, false, options); }
    catch (error) {
      if (options.signal?.aborted) throw error;
      return streamResponse(info, true, options);
    }
  };
  cachePromise.then(async cache => {
    if (!cache) return;
    const keep = new Set(Object.values(files).flatMap(info => [...partsFor(info), ...partsFor(info, true)]).map(part => new URL(part.file, base).href));
    for (const request of await cache.keys()) if (!keep.has(request.url)) await cache.delete(request);
  }).catch(() => {});
})();
