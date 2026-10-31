/* Compressed, content-addressed downloads for hosts without Content-Encoding support.
 * The manifest is inserted by tools/prepare-web.mjs. Only Godot's two boot files match.
 */
(() => {
  const files = window.BOB_WEB_FILES;
  if (!files || typeof DecompressionStream === 'undefined') return;
  const fetchOriginal = window.fetch.bind(window);
  const base = new URL('.', document.baseURI);
  const paths = new Map(Object.entries(files).map(([name, info]) => [new URL(name, base).href, info]));
  const loaded = new Map();
  const total = Object.values(files).reduce((sum, file) => sum + file.packedBytes, 0);
  const report = (key, bytes) => {
    loaded.set(key, bytes);
    const current = [...loaded.values()].reduce((a, b) => a + b, 0);
    const label = document.getElementById('status-detail');
    if (label) label.textContent = current >= total ? '下载完成，正在启动游戏…' : `正在下载游戏 · ${Math.floor(current / total * 100)}% · ${(current / 1048576).toFixed(1)} / ${(total / 1048576).toFixed(1)} MB`;
  };
  window.fetch = async (input, init) => {
    const requested = new URL(input instanceof Request ? input.url : String(input), base);
    const info = paths.get(requested.href);
    if (!info || (init?.method && init.method !== 'GET')) return fetchOriginal(input, init);
    const packed = new URL(info.file, base).href;
    let cache;
    let response;
    try { cache = await window.caches?.open('bob-web-downloads-v1'); response = await cache?.match(packed); } catch { /* Cache is optional. */ }
    if (!response) {
      response = await fetchOriginal(packed, init);
      if (!response.ok) return fetchOriginal(input, init);
      if (cache) cache.put(packed, response.clone()).catch(() => {});
    }
    let count = 0;
    const stream = response.body.pipeThrough(new TransformStream({
      transform(chunk, controller) { count += chunk.byteLength; report(packed, count); controller.enqueue(chunk); },
    }));
    const decoded = response.headers.get('content-encoding')?.includes('gzip') ? stream : stream.pipeThrough(new DecompressionStream('gzip'));
    return new Response(decoded, { headers: { 'Content-Type': info.type, 'Content-Length': String(info.rawBytes) } });
  };
  // This cache is exclusively ours. Keep the current engine and game package only.
  window.caches?.open('bob-web-downloads-v1').then(async cache => {
    const keep = new Set(Object.values(files).map(file => new URL(file.file, base).href));
    for (const request of await cache.keys()) if (!keep.has(request.url)) await cache.delete(request);
  }).catch(() => {});
})();
