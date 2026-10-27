import { ART_ASSETS, REGION_ART } from './art-manifest.js';

// V5.2 source units become V2 pixels; physics remains in levels.js.
const UNIT = 48;
export class RuntimeArt {
  constructor(renderer) { this.renderer = renderer; }
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
  platform(p, room, state) {
    if (p.kind === 'safety') return false;
    let id = REGION_ART[room.id]?.platform;
    if (p.kind === 'bone') id = 'r4-bone-platform';
    if (p.kind === 'membrane' || p.kind === 'raft') id = 'r2-membrane-platform';
    if (p.kind === 'soft') id = state.softDown > 0 ? 'r1-weight-membrane-pressed' : 'r1-weight-membrane';
    const image = this.image(id), a = ART_ASSETS[id];
    if (!image) return false;
    // Cut below each irregular skyline so the painted rim meets collision y.
    const top = {
      'r1-tongue-ledge': 220, 'r1-weight-membrane': 320,
      'r1-weight-membrane-pressed': 340, 'r2-membrane-platform': 280,
      'r3-bank-platform': 275, 'r4-bone-platform': 295,
    }[id];
    const scale = this.scale(id), sx = a.bbox[0] + 80;
    const sw = a.bbox[2] - sx - 80, sh = a.bbox[3] - top;
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
  valve(base, handle, x, y, done) {
    if (!this.image(base) || !this.image(handle)) return false;
    this.sprite(base, x, y);
    const pressure = base === 'pressure-valve-base';
    const at = pressure ? [735, 555] : [768, done ? 300 : 251];
    const pivot = ART_ASSETS[base].pivot, scale = this.scale(base);
    this.sprite(handle, x + (at[0] - pivot[0]) * scale, y + (at[1] - pivot[1]) * scale,
      { angle: pressure ? (done ? Math.PI / 3 : -Math.PI / 6) : 0, ...(pressure ? { anchor: [684, 906] } : {}) });
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
