// Terrain tops are one-way, piecewise-linear surfaces in the same pixels as levels.js.
const EPSILON = 0.001;
const enabled = (surface, flags) => !surface.requires || flags.has(surface.requires);
const at = (segment, x) => segment.a.y + (segment.b.y - segment.a.y) * (x - segment.a.x) / (segment.b.x - segment.a.x);

export function terrainHeightAt(terrain, x) {
  for (let i = 1; i < terrain.points.length; i++) {
    const a = terrain.points[i - 1], b = terrain.points[i];
    if (b.x > a.x && x >= a.x - EPSILON && x <= b.x + EPSILON) return at({ a, b }, x);
  }
  return null;
}

export function terrainLanding(terrain, flags, previous, player) {
  if (player.vy < 0) return null;
  const x = player.x + player.w / 2, oldX = previous.x + player.w / 2;
  let landing = null;
  for (const surface of terrain || []) {
    if (!enabled(surface, flags)) continue;
    const top = terrainHeightAt(surface, x);
    if (top === null) continue;
    const oldTop = terrainHeightAt(surface, oldX) ?? top;
    if (previous.y + player.h <= oldTop + 2 && player.y + player.h >= top && (landing === null || top < landing)) landing = top;
  }
  return landing;
}

// Follow only a continuous route from the previous support. Every intervening
// endpoint is checked, so even a narrow gap or vertical ledge breaks contact.
export function followTerrain(terrain, platforms, flags, previous, x, height) {
  const segments = [];
  for (const surface of terrain || []) {
    if (!enabled(surface, flags)) continue;
    for (let i = 1; i < surface.points.length; i++) {
      const a = surface.points[i - 1], b = surface.points[i];
      if (b.x > a.x) segments.push({ a, b, terrain: true });
    }
  }
  if (!segments.length) return null;
  for (const platform of platforms) if (enabled(platform, flags) && platform.w > 0) {
    segments.push({ a: { x: platform.x, y: platform.y }, b: { x: platform.x + platform.w, y: platform.y }, terrain: false });
  }
  const oldX = previous.x, foot = previous.y + height;
  let support = segments.find(segment => oldX >= segment.a.x - EPSILON && oldX <= segment.b.x + EPSILON && Math.abs(at(segment, oldX) - foot) <= 2);
  if (!support) return null;
  let y = at(support, oldX), touchedTerrain = support.terrain;
  const cuts = [...new Set([oldX, x, ...segments.flatMap(segment => [segment.a.x, segment.b.x])
    .filter(cut => cut > Math.min(oldX, x) && cut < Math.max(oldX, x))])].sort((a, b) => x >= oldX ? a - b : b - a);
  for (let i = 1; i < cuts.length; i++) {
    const a = cuts[i - 1], b = cuts[i];
    support = segments.find(segment => segment.a.x <= Math.min(a, b) + EPSILON && segment.b.x >= Math.max(a, b) - EPSILON && Math.abs(at(segment, a) - y) <= EPSILON);
    if (!support) return null;
    y = at(support, b); touchedTerrain ||= support.terrain;
  }
  return touchedTerrain ? y : null;
}
