import { ART_ASSETS, REGION_ART } from './art-manifest.js';
import { terrainHeightAt } from './terrain.js';

// V5.2 source units become V2 pixels; physics remains in levels.js.
const UNIT = 48;
export class RuntimeArt {
  constructor(renderer) { this.renderer = renderer; this.terrainCache = new Map(); }
  image(id) { return this.renderer.images.get(ART_ASSETS[id]?.src); }
  scale(id, units = UNIT) {
    const a = ART_ASSETS[id];
    return a.world.units * units / (a.world.axis === 'width' ? a.bbox[2] - a.bbox[0] : a.bbox[3] - a.bbox[1]);
  }
  sprite(id, x, y, { units = UNIT, angle = 0, anchor, alpha = 1 } = {}) {
    const image = this.image(id), a = ART_ASSETS[id];
    if (!image) return false;
    const c = this.renderer.ctx, scale = this.scale(id, units), pivot = anchor || a.pivot;
    c.save(); c.translate(x, y); c.rotate(angle); c.scale(scale, scale); c.globalAlpha *= alpha;
    c.drawImage(image, -pivot[0], -pivot[1]); c.restore();
    return true;
  }
  backgrounds(room) {
    const region = REGION_ART[room.id], c = this.renderer.ctx;
    if (!region || !this.image(region.water) || !this.image(region.organ)) return false;
    for (const [id, parallax] of [[region.water, .10], [region.organ, .25]]) {
      const image = this.image(id);
      // Full native canvas, including transparent margins; no bbox stretching.
      const scale = Math.max(1600 / image.width, 900 / image.height);
      const width = image.width * scale, height = image.height * scale;
      const travel = room.width - 1280;
      const shift = travel > 0 ? this.renderer.camera / travel * Math.min(width - 1280, travel * parallax) : 0;
      c.drawImage(image, -shift, (720 - height) / 2, width, height);
    }
    c.fillStyle = '#071d2738'; c.fillRect(0, 0, 1280, 720);
    return true;
  }
  terrain(surface, room) {
    let cached = this.terrainCache.get(surface.id);
    if (!cached) {
      const first = surface.points[0], last = surface.points.at(-1);
      const top = Math.floor(Math.min(...surface.points.map(p => p.y)));
      const canvas = document.createElement('canvas');
      canvas.width = Math.ceil(last.x - first.x); canvas.height = surface.bottom - top;
      const c = canvas.getContext('2d'); c.translate(-first.x, -top);
      c.beginPath(); surface.points.forEach((p, i) => i ? c.lineTo(p.x, p.y) : c.moveTo(p.x, p.y));
      c.lineTo(last.x, surface.bottom); c.lineTo(first.x, surface.bottom); c.closePath(); c.clip();
      const warm = room.id === 'stomach', gradient = c.createLinearGradient(0, top, 0, surface.bottom);
      gradient.addColorStop(0, warm ? '#94735b' : '#648282'); gradient.addColorStop(1, '#102b34');
      c.fillStyle = gradient; c.fillRect(first.x, top, canvas.width, canvas.height);
      const id = REGION_ART[room.id].platform, image = this.image(id), a = ART_ASSETS[id];
      if (image) {
        const scale = this.scale(id), cropY = ({ mouth: 220, stomach: 275, lung: 280 }[room.id] || 295) * (a.exportScaleY || 1);
        const left = a.bbox[0] + 80 * (a.exportScale || 1), sourceWidth = a.bbox[2] - left - 80 * (a.exportScale || 1);
        const sourceHeight = a.bbox[3] - cropY;
        // Bake vertical slices once. Every visible crest follows the exact
        // collision profile; none is flattened back into a rectangle.
        for (let x = first.x; x < last.x; x += 4) {
          const width = Math.min(4, last.x - x), y = terrainHeightAt(surface, x + width / 2);
          const sx = left + ((x - first.x) / scale % Math.max(1, sourceWidth - width / scale));
          c.drawImage(image, sx, cropY, width / scale, sourceHeight, x, y, width + .5, sourceHeight * scale);
          // Use the dense interior material, not a second hanging silhouette.
          c.save(); c.globalAlpha = .35;
          c.drawImage(image, sx, cropY + sourceHeight * .12, width / scale, sourceHeight * .20,
            x, y + sourceHeight * scale * .65, width + .5, Math.max(20, surface.bottom - y));
          c.restore();
        }
      }
      c.beginPath(); surface.points.forEach((p, i) => i ? c.lineTo(p.x, p.y + .5) : c.moveTo(p.x, p.y + .5));
      c.strokeStyle = '#d1d0ad'; c.lineWidth = 1.4; c.stroke();
      cached = { canvas, x: first.x, y: top }; this.terrainCache.set(surface.id, cached);
    }
    this.renderer.ctx.drawImage(cached.canvas, cached.x, cached.y);
  }
  platform(p, room, state) {
    if (p.kind === 'safety') return false;
    let id = REGION_ART[room.id]?.platform;
    if (p.kind === 'bone') id = 'r4-bone-platform';
    if (p.kind === 'membrane' || p.kind === 'raft') id = 'r2-membrane-platform';
    if (p.kind === 'soft') id = state.softDown > 0 ? 'r1-weight-membrane-pressed' : 'r1-weight-membrane';
    const image = this.image(id), a = ART_ASSETS[id];
    if (!image) return false;
    if (p.h < 90 && p.kind !== 'raft' && (room.id === 'lung' || room.id === 'ribs')) this.support(p, image, a, room);
    // Cut below each irregular skyline so the painted rim meets collision y.
    const top = ({
      'r1-tongue-ledge': 220, 'r1-weight-membrane': 320,
      'r1-weight-membrane-pressed': 340, 'r2-membrane-platform': 280,
      'r3-bank-platform': 275, 'r4-bone-platform': 295,
    }[id]) * (a.exportScaleY || 1);
    const scale = this.scale(id), margin = 80 * (a.exportScale || 1), sx = a.bbox[0] + margin;
    const sw = a.bbox[2] - sx - margin, sh = a.bbox[3] - top;
    const tile = sw * scale, height = sh * scale, c = this.renderer.ctx;
    c.save(); c.beginPath(); c.rect(p.x, p.y, p.w, Math.max(p.h, height)); c.clip();
    if (p.kind === 'soft') {
      // The pressed drawing has a deep concavity; support the collision crest
      // with tissue so a transparent cutout cannot suggest a traversable hole.
      c.fillStyle = '#76615b'; c.fillRect(p.x, p.y, p.w, Math.min(height, p.h));
    }
    if (p.h > height) {
      const g = c.createLinearGradient(0, p.y, 0, p.y + p.h);
      g.addColorStop(0, room.id === 'stomach' ? '#615045' : '#456063'); g.addColorStop(1, '#112b34');
      c.fillStyle = g; c.fillRect(p.x, p.y + height * .35, p.w, p.h);
    }
    for (let dx = 0; dx < p.w; dx += tile) {
      const width = Math.min(tile, p.w - dx);
      c.drawImage(image, sx, top, width / scale, sh, p.x + dx, p.y, width, height);
    }
    this.renderer.line([[p.x, p.y + .5], [p.x + p.w, p.y + .5]], '#d8d8b3', 1.2);
    c.restore(); return true;
  }
  support(p, image, asset, room) {
    const c = this.renderer.ctx, middle = p.x + p.w * .5;
    const bottom = Math.min(715, p.y + (room.id === 'lung' ? 240 : 150));
    // Narrow roots describe the source's suspended banks. Only the bright
    // crest is walkable; these recessed supports never add collision.
    c.save(); c.beginPath(); c.moveTo(p.x + 10, p.y + 12);
    c.bezierCurveTo(middle - 10, p.y + 55, middle - 30, bottom - 35, middle - 45, bottom);
    c.lineTo(middle + 40, bottom);
    c.bezierCurveTo(middle + 25, bottom - 30, middle + 12, p.y + 55, p.x + p.w - 10, p.y + 12);
    c.closePath(); c.clip();
    c.globalAlpha = .55;
    c.drawImage(image, asset.bbox[0], asset.bbox[1], asset.bbox[2] - asset.bbox[0], asset.bbox[3] - asset.bbox[1],
      p.x, p.y, p.w, bottom - p.y);
    c.restore();
  }
  valve(base, handle, x, y, done) {
    if (!this.image(base) || !this.image(handle)) return false;
    this.sprite(base, x, y);
    const pressure = base === 'pressure-valve-base';
    const at = pressure ? [735, 555] : [768, done ? 300 : 251];
    const a = ART_ASSETS[base], h = ART_ASSETS[handle], pivot = a.pivot, scale = this.scale(base);
    this.sprite(handle, x + (at[0] * (a.exportScale || 1) - pivot[0]) * scale, y + (at[1] * (a.exportScaleY || 1) - pivot[1]) * scale,
      { angle: pressure ? (done ? Math.PI / 3 : -Math.PI / 6) : 0,
        ...(pressure ? { anchor: [684 * (h.exportScale || 1), 906 * (h.exportScaleY || 1)] } : {}) });
    return true;
  }
  object(o, state) {
    const done = state.flags.has(o.id);
    if (o.type === 'camp') return this.sprite('shell-camp', o.x, o.y);
    if (o.type === 'crab') return this.sprite('corpse-crab', o.x, o.y, { angle: done ? -.08 : 0 });
    if (o.type === 'valve') return this.valve('pressure-valve-base', 'pressure-valve-handle', o.x, o.y, done);
    if (o.type === 'course-power') return this.valve('bypass-valve-base', 'bypass-valve-lever', o.x, o.y, done);
    if (o.type === 'float' && !done && !state.abilities.has('float'))
      return this.sprite('float-membrane', o.x, o.y - 40 + Math.sin(this.renderer.time * 1.5) * 4);
    return false;
  }
  hero(p, state) {
    const id = p.facing < 0 ? 'tide-picker-left' : 'tide-picker';
    if (!this.image(id)) return false;
    const x = p.x + p.w / 2, foot = p.y + p.h, r = this.renderer;
    // These are static facing poses. Movement/attachment cues are procedural,
    // not claimed as authored walk, climb or swing animation frames.
    this.sprite(id, x, foot);
    if (p.climbing || p.swinging) {
      r.line([[x - 7, p.y + 22], [x - 10, p.y + 2]], '#c5c1a6', 2);
      r.line([[x + 7, p.y + 22], [x + 10, p.y + 2]], '#c5c1a6', 2);
    }
    if (p.floating && state.abilities.has('float')) {
      if (!this.sprite('float-membrane', x, p.y - 10)) r.jelly(x, p.y - 12, 28, .8);
      r.line([[x - 25, p.y - 4], [x - 10, p.y + 20]], '#b8d2b5', 1);
      r.line([[x + 25, p.y - 4], [x + 10, p.y + 20]], '#b8d2b5', 1);
    }
    if (state.charge > .02) {
      r.glow(x + (p.facing || 1) * 20, p.y + 20, 28 + state.charge * 30, '255,209,130', .35);
      r.ellipse(x, p.y + 24, 24 + state.charge * 8, 24 + state.charge * 8, null, '#f5d597', 1.5);
    }
    return true;
  }
  foreground(room) {
    const id = REGION_ART[room.id]?.foreground, image = this.image(id);
    if (!image) return;
    const a = ART_ASSETS[id], c = this.renderer.ctx;
    const scale = 1280 / (a.bbox[2] - a.bbox[0]);
    // Decorative foreground stays below the lowest playable route.
    c.save(); c.beginPath(); c.rect(0, 684, 1280, 36); c.clip(); c.globalAlpha = .55;
    c.drawImage(image, -a.bbox[0] * scale, 690 - a.bbox[1] * scale, image.width * scale, image.height * scale);
    c.restore();
  }
}
