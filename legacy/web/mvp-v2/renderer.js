import { getLiftPosition, getSwingPosition } from './mechanics.js';
import { HABITATS, getHabitatStatus } from './ecology.js';
import { SCENES } from './scenes.js';
import { ART_ASSETS } from './art-manifest.js';
import { RuntimeArt } from './runtime-art.js';

const ART_ROOT = '../docs/鲸腹遗城原画集/V2/images/';
const TAU = Math.PI * 2;
const ART = ['A01_鲸落万物生_世界主视觉.png'];
const hash = n => { const x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };
const clamp = (n, lo, hi) => Math.max(lo, Math.min(hi, n));

/** Canvas-only world renderer. All coordinates are in the game's 1280 × 720 space. */
export class Renderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.images = new Map();
    this.art = new RuntimeArt(this);
    this.time = 0;
    this.camera = 0;
    this.texture = document.createElement('canvas');
    this.texture.width = this.texture.height = 128;
    const texture = this.texture.getContext('2d');
    for (let i = 0; i < 2100; i++) {
      texture.fillStyle = i % 2 ? 'rgba(186,213,186,.075)' : 'rgba(0,10,16,.10)';
      texture.fillRect(hash(i) * 128, hash(i + 3001) * 128, 1 + hash(i + 31) * 2, 1);
    }
    this.pattern = this.ctx.createPattern(this.texture, 'repeat');
  }

  async load() {
    const resources = [...new Set(Object.values(SCENES).flatMap(scene => [
      scene.atmosphere.src,
      ...Object.values(scene.terrain || {}).map(asset => asset.src),
    ]))];
    resources.push(...Object.values(ART_ASSETS).map(asset => asset.src));
    await Promise.all([...ART.map(name => this.loadImage(name, './assets/title-v2.webp')), ...resources.map(src => this.loadImage(src, src))]);
  }

  loadImage(name, source) {
    if (!name || this.images.has(name)) return Promise.resolve();
    this.images.set(name, null);
    return new Promise(resolve => {
      const img = new Image();
      img.onload = () => { this.images.set(name, img); resolve(); };
      img.onerror = () => resolve();
      img.src = source || ART_ROOT + encodeURIComponent(name);
    });
  }

  ellipse(x, y, rx, ry, fill, stroke, width = 1) {
    const c = this.ctx;
    c.beginPath(); c.ellipse(x, y, rx, ry, 0, 0, TAU);
    if (fill) { c.fillStyle = fill; c.fill(); }
    if (stroke) { c.lineWidth = width; c.strokeStyle = stroke; c.stroke(); }
  }

  glow(x, y, radius, color = '105,222,205', alpha = .22) {
    const c = this.ctx, g = c.createRadialGradient(x, y, 0, x, y, radius);
    g.addColorStop(0, `rgba(${color},${alpha})`); g.addColorStop(.28, `rgba(${color},${alpha * .42})`); g.addColorStop(1, `rgba(${color},0)`);
    c.fillStyle = g; c.fillRect(x - radius, y - radius, radius * 2, radius * 2);
  }

  line(points, color, width = 1) {
    const c = this.ctx;
    c.beginPath(); points.forEach(([x, y], i) => i ? c.lineTo(x, y) : c.moveTo(x, y));
    c.strokeStyle = color; c.lineWidth = width; c.stroke();
  }

  draw(state, room) {
    const c = this.ctx;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    if (this.canvas.width !== Math.round(1280 * dpr) || this.canvas.height !== Math.round(720 * dpr)) {
      this.canvas.width = Math.round(1280 * dpr); this.canvas.height = Math.round(720 * dpr);
    }
    c.setTransform(dpr, 0, 0, dpr, 0, 0);
    c.globalAlpha = 1; c.globalCompositeOperation = 'source-over';
    c.lineJoin = 'round'; c.lineCap = 'round';
    this.time = Number.isFinite(state.time) ? state.time : 0;
    this.camera = state.camera?.x || 0;
    if (state.mode === 'title') { this.title(); return; }
    if (!room) { c.fillStyle = '#12343d'; c.fillRect(0, 0, 1280, 720); return; }
    this.background(state, room);
    c.save(); c.translate(-this.camera, 0);
    for (const surface of room.terrain || []) {
      if (surface.requires && !state.flags.has(surface.requires)) continue;
      this.art.terrain(surface, room);
    }
    this.facilityStructures(room, state);
    for (const p of room.platforms || []) {
      if (p.x + p.w < this.camera - 100 || p.x > this.camera + 1380) continue;
      if (p.requires && !state.flags.has(p.requires)) { this.dormantPlatform(p); continue; }
      if (p.kind === 'soft' && state.softDown > 0) {
        c.globalAlpha = .35;
        this.platform({ ...p, y: p.y + 95 }, state, room);
        c.globalAlpha = 1;
        continue;
      }
      this.platform(p, state, room);
    }
    this.facilities(room, state);
    if (room.id === 'stomach') {
      c.save(); c.translate(0, room.objects.find(object => object.id === 'fed').y - 580);
      this.tissueBlock(state.flags.has('fed')); c.restore();
    }
    if (!state.flags.has('drain')) for (const h of room.hazards || []) this.hazard(h);
    for (const exit of room.exits || []) this.exit(exit);
    for (const gate of room.gates || []) this.gate(gate, state.flags.has(gate.id));
    for (const o of room.objects || []) this.object(o, state);
    for (const memory of room.memories || []) if (!state.memories.has(memory.id)) this.memory(memory);
    for (const p of state.pulses || []) this.pulse(p);
    this.hero(state.player, state);
    for (const p of state.particles || []) {
      c.globalAlpha = clamp(p.life ?? 1, 0, 1);
      this.ellipse(p.x, p.y, p.size || 2, p.size || 2, p.color || '#d8c484');
    }
    c.globalAlpha = 1;
    c.restore();
    this.waterParticles(state);
    this.foreground(room);
    const vignette = c.createRadialGradient(640, 340, 250, 640, 340, 780);
    vignette.addColorStop(0, '#00151b00'); vignette.addColorStop(1, '#001219a0');
    c.fillStyle = vignette; c.fillRect(0, 0, 1280, 720);
    if (state.respawnFlash > 0) {
      c.fillStyle = `rgba(173,223,214,${Math.min(.45, state.respawnFlash * .45)})`; c.fillRect(0, 0, 1280, 720);
    }
  }

  title() {
    const c = this.ctx, img = this.images.get(ART[0]);
    c.fillStyle = '#102f39'; c.fillRect(0, 0, 1280, 720);
    if (img) {
      const scale = Math.max(1280 / img.width, 720 / img.height);
      const w = img.width * scale, h = img.height * scale;
      c.drawImage(img, (1280 - w) / 2, (720 - h) / 2, w, h);
    }
    const shade = c.createLinearGradient(0, 0, 1280, 0);
    shade.addColorStop(0, 'rgba(4,20,27,.88)'); shade.addColorStop(.44, 'rgba(5,24,30,.53)'); shade.addColorStop(1, 'rgba(3,20,24,.08)');
    c.fillStyle = shade; c.fillRect(0, 0, 1280, 720);
    this.waterParticles({flags: new Set()});
  }

  background(state, room) {
    const c = this.ctx, t = this.time, cam = this.camera;
    const scene = SCENES[room.id] || SCENES.mouth;
    const base = c.createLinearGradient(0, 0, 0, 720);
    base.addColorStop(0, scene.palette.top);
    base.addColorStop(.55, scene.palette.tint);
    base.addColorStop(1, scene.palette.deep);
    c.fillStyle = base; c.fillRect(0, 0, 1280, 720);
    if (this.art.backgrounds(room)) return;
    // Gameplay uses a clean environmental plate, never the concept sheets:
    // those sheets include a painted hero, terrain and storyboard panels.
    const img = this.images.get(scene.atmosphere.src);
    if (img) {
      const scale = Math.max(1420 / img.width, 720 / img.height);
      const width = img.width * scale, height = img.height * scale;
      c.globalAlpha = .26;
      c.drawImage(img, (1280 - width) / 2 - Math.sin(cam / 1200) * scene.atmosphere.parallax * 650, (720 - height) / 2, width, height);
      c.globalAlpha = 1;
    }
    const wash = c.createLinearGradient(0, 0, 0, 720);
    wash.addColorStop(0, scene.palette.top + '60');
    wash.addColorStop(.46, '#143e4b20'); wash.addColorStop(.76, '#123b4555'); wash.addColorStop(1, '#092e36ed');
    c.fillStyle = wash; c.fillRect(0, 0, 1280, 720);

    this.anatomyLayer(scene.anatomy);
    c.save(); c.globalCompositeOperation = 'screen';
    for (let i = 0; i < 5; i++) {
      const x = 150 + i * 320 - cam * .09 + Math.sin(t * .1 + i) * 20;
      const beam = c.createLinearGradient(x, 0, x - 170, 640);
      beam.addColorStop(0, 'rgba(134,221,217,.12)'); beam.addColorStop(1, 'rgba(105,216,202,0)');
      c.fillStyle = beam; c.beginPath(); c.moveTo(x, -40); c.lineTo(x + 58, -40); c.lineTo(x - 100, 650); c.lineTo(x - 320, 650); c.closePath(); c.fill();
    }
    c.restore();
    for (let i = 0; i < 6; i++) {
      const x = ((i * 287 + 137 - cam * .23) % 1600 + 1600) % 1600 - 130;
      const y = 210 + hash(i + 72) * 270 + Math.sin(t * .3 + i) * 15;
      this.jelly(x, y, 9 + hash(i + 61) * 15, .16 + hash(i) * .12);
    }
    for (let i = 0; i < 24; i++) {
      const x = ((hash(i + 400) * 1700 + t * (5 + i % 3) - cam * .3) % 1500 + 1500) % 1500 - 100;
      const y = 165 + hash(i + 522) * 280 + Math.sin(t + i) * 3;
      c.globalAlpha = .16; this.fish(x, y, 3 + hash(i) * 4, '#a4d1be');
    }
    c.globalAlpha = 1;
  }

  // Reusable scene modules reconstructed from the V2 visual vocabulary. They
  // are non-colliding silhouettes; traversable geometry comes only from levels.
  anatomyLayer(layer) {
    const c = this.ctx, spacing = layer.spacing || 340;
    const offset = this.camera * layer.parallax;
    const first = Math.floor(offset / spacing) - 1;
    c.save();
    for (let index = first; index <= first + Math.ceil(1280 / spacing) + 2; index++) {
      const x = index * spacing - offset;
      c.save(); c.translate(x, 0);
      if (layer.type === 'baleen') this.baleenModule(index, spacing);
      else if (layer.type === 'chambers') this.chamberModule(index, spacing);
      else if (layer.type === 'bronchi') this.bronchiModule(index, spacing);
      else this.ribModule(index, spacing);
      c.restore();
    }
    c.restore();
  }

  baleenModule(seed, spacing) {
    const c = this.ctx;
    c.beginPath(); c.moveTo(-30, -50);
    c.bezierCurveTo(10, 115, spacing * .65, 120, spacing + 25, -20);
    c.strokeStyle = '#42657580'; c.lineWidth = 38; c.stroke();
    c.strokeStyle = '#8eaca92b'; c.lineWidth = 2; c.stroke();
    const count = Math.ceil(spacing / 13);
    for (let j = 0; j <= count; j++) {
      const x = j * spacing / count;
      const arch = 55 + Math.sin(j / count * Math.PI) * 36;
      const length = 90 + hash(seed * 37 + j) * 170;
      c.beginPath(); c.moveTo(x, arch);
      c.bezierCurveTo(x - 18, arch + length * .4, x + 14, arch + length * .8, x - 5, arch + length);
      c.strokeStyle = j % 3 ? '#9aaf9535' : '#bac5a547'; c.lineWidth = 2 + hash(j + seed) * 2; c.stroke();
    }
  }

  chamberModule(seed, spacing) {
    const c = this.ctx, y = 235 + hash(seed + 18) * 55;
    const radius = spacing * .58;
    c.save(); c.rotate(Math.sin(seed) * .08);
    this.ellipse(spacing * .4, y, radius, 260, '#455c432a', '#8b947232', 12);
    this.ellipse(spacing * .4 + 9, y + 12, radius * .78, 222, '#183a3440', '#a1a47d21', 2);
    for (let i = -2; i <= 2; i++) {
      c.beginPath(); c.moveTo(spacing * .4 + i * 31, y - 230);
      c.bezierCurveTo(spacing * .4 + i * 81, y - 100, spacing * .4 + i * 71, y + 100, spacing * .4 + i * 24, y + 235);
      c.strokeStyle = '#afaa7925'; c.lineWidth = 5; c.stroke();
    }
    c.restore();
  }

  bronchiModule(seed, spacing) {
    const c = this.ctx, root = spacing * .45;
    // Branching fans and transparent sacs have no horizontal landing edges.
    for (const side of [-1, 1]) for (let j = 0; j < 3; j++) {
      const bx = root + side * (50 + j * 35), by = 210 - j * 57;
      c.beginPath(); c.moveTo(root, 610);
      c.bezierCurveTo(root + side * 27, 420, bx - side * 20, by + 100, bx, by);
      c.strokeStyle = '#74b6ae32'; c.lineWidth = 9 - j * 2; c.stroke();
      c.strokeStyle = '#a3d4bf2b'; c.lineWidth = 1; c.stroke();
      for (let k = 0; k < 3; k++) {
        this.ellipse(bx + side * k * 19, by - k * 31, 29 + hash(seed + k + j) * 15, 51, '#71b8a81a', '#a0d1ba28', 1);
      }
    }
    c.beginPath(); c.moveTo(root - 4, 650); c.quadraticCurveTo(root + 18, 370, root, 240);
    c.strokeStyle = '#6dafa63d'; c.lineWidth = 13; c.stroke();
  }

  ribModule(seed, spacing) {
    const c = this.ctx, x = spacing * .5;
    c.beginPath(); c.moveTo(x - 110, 650);
    c.bezierCurveTo(x - 220, 340, x - 135, 80, x + 90, -65);
    c.strokeStyle = '#6d7b983e'; c.lineWidth = 43; c.stroke();
    c.strokeStyle = '#c4c0b125'; c.lineWidth = 2; c.stroke();
    c.beginPath(); c.moveTo(x + 65, -35);
    c.bezierCurveTo(x + 155, 65, x + 155, 225, x + 120, 410);
    c.strokeStyle = '#7b92a22d'; c.lineWidth = 19; c.stroke();
    for (let i = 0; i < 4; i++) this.ellipse(x - 104 - Math.sin(i * .6) * 33, 225 + i * 67, 9, 19, '#12364342');
  }

  facilityStructures(room, state) {
    if (room.id !== 'ribs') return;
    const c = this.ctx;
    // Suspension points make the whole route feel built into the whale ribs.
    for (const p of room.platforms || []) {
      if (p.h > 40) continue;
      for (const x of [p.x + 22, p.x + p.w - 22]) {
        this.line([[x - 5, 15], [x - 2, p.y - 8]], '#7b9d9166', 3);
        this.line([[x + 3, 15], [x + 2, p.y - 8]], '#b7c8aa77', 1);
        this.ellipse(x, 22, 14, 7, '#29444a', '#94b3a2', 3);
        this.ellipse(x, p.y - 7, 6, 10, null, '#c3bd96', 2);
      }
      // Bone outriggers taper down from the precise walkable rim.
      this.line([[p.x + 22, p.y + 6], [p.x + p.w * .4, p.y + 48], [p.x + p.w - 22, p.y + 6]], '#64877f', 7);
      this.line([[p.x + 22, p.y + 6], [p.x + p.w * .4, p.y + 48], [p.x + p.w - 22, p.y + 6]], '#c1c7a6', 1);
    }
    for (const lift of room.lifts || []) {
      const p = getLiftPosition(lift, this.time, state.flags);
      for (const x of [lift.x + 16, lift.x + lift.w - 16]) {
        this.line([[x, 48], [x, lift.maxY + 30]], '#8fafa26b', 2);
        this.line([[x + 6, 48], [x + 6, p.y]], '#c4c69a', 1.5);
        this.ellipse(x + 3, 50, 10, 10, '#233b44', '#b8c4a0', 3);
      }
      const counterY = lift.minY + lift.maxY - p.y;
      this.line([[lift.x - 30, 48], [lift.x + 14, 48]], '#b6bd9c', 3);
      this.line([[lift.x - 30, 48], [lift.x - 30, counterY]], '#c2b68d', 1.5);
      this.ellipse(lift.x - 30, counterY, 10, 24, '#658a86', '#b5bba0', 2);
    }
    c.save(); c.globalAlpha = .25;
    for (const current of room.currents || []) {
      for (let j = 0; j < 7; j++) {
        const x = current.x + 10 + j * (current.w - 20) / 6;
        c.beginPath(); c.moveTo(x, current.y + current.h);
        c.bezierCurveTo(x - 15, current.y + 180, x + 15, current.y + 90, x, current.y);
        c.strokeStyle = '#90e2d3'; c.lineWidth = 1.5; c.stroke();
      }
    }
    c.restore();
  }

  facilities(room, state) {
    const c = this.ctx, t = this.time;
    for (const net of room.climbs || []) {
      const active = state.player.climbing === net.id;
      this.glow(net.x + net.w / 2, net.y + net.h / 2, net.h * .65, '114,208,179', active ? .18 : .07);
      c.fillStyle = '#4d8b7920'; c.fillRect(net.x, net.y, net.w, net.h);
      for (let x = net.x; x <= net.x + net.w; x += 23) {
        c.beginPath(); c.moveTo(x, net.y);
        c.bezierCurveTo(x - 5, net.y + net.h * .33, x + 5, net.y + net.h * .66, x, net.y + net.h);
        c.strokeStyle = '#8db49c'; c.lineWidth = 2; c.stroke();
      }
      for (let y = net.y; y <= net.y + net.h; y += 24) {
        c.beginPath(); c.moveTo(net.x, y);
        c.quadraticCurveTo(net.x + net.w / 2, y + 8, net.x + net.w, y);
        c.strokeStyle = '#a7bfa0'; c.lineWidth = 2; c.stroke();
        for (let j = 1; j < 6; j++) {
          this.ellipse(net.x + j * 23, y + Math.sin(j / 6 * Math.PI) * 4, 2.5, 2.5, '#e1cb8e');
        }
      }
      for (const x of [net.x, net.x + net.w]) {
        this.line([[x, net.y - 10], [x, net.y + net.h + 2]], '#759a89', 7);
        this.line([[x, net.y - 10], [x, net.y + net.h + 2]], '#d3c899', 1.8);
        this.ellipse(x, net.y - 9, 9, 10, '#365e59', '#d0d0a9', 2);
      }
      this.label('01  菌丝攀网  ·  W / S', net.x + net.w / 2, net.y + net.h + 20, state.course?.climb);
    }
    for (const lift of room.lifts || []) {
      const p = getLiftPosition(lift, t, state.flags), powered = state.flags.has(lift.requires);
      this.glow(p.x + p.w / 2, p.y + 28, 105, '125,228,202', powered ? .2 : .04);
      // A soft pressure bladder hangs beneath a rigid, readable boarding edge.
      c.beginPath(); c.moveTo(p.x + 13, p.y + 7);
      c.bezierCurveTo(p.x + 4, p.y + 100, p.x + p.w - 4, p.y + 100, p.x + p.w - 13, p.y + 7);
      c.closePath(); c.fillStyle = powered ? '#639e9466' : '#466d6666'; c.fill();
      c.strokeStyle = powered ? '#9ed3b4' : '#698879'; c.lineWidth = 1.8; c.stroke();
      for (let j = 1; j < 5; j++) {
        c.beginPath(); c.moveTo(p.x + p.w * j / 5, p.y + 10);
        c.quadraticCurveTo(p.x + p.w / 2, p.y + 120, p.x + p.w / 2, p.y + 67);
        c.strokeStyle = '#a3c9ab66'; c.lineWidth = 1; c.stroke();
      }
      this.platform({ ...p, kind: 'membrane' }, state, room);
      for (const x of [p.x + 12, p.x + p.w - 12]) {
        this.line([[x, p.y], [x, p.y - 37]], '#bfc6a3', 3);
        this.lamp(x, p.y - 37, .55);
      }
      this.label(powered ? '02  浮囊升降台' : '02  等待开启浮囊', p.x + p.w / 2, lift.maxY + 103, state.course?.lift);
    }
    for (const swing of room.swings || []) {
      const p = getSwingPosition(swing, t), held = state.player.swinging === swing.id;
      c.save(); c.setLineDash([2, 12]);
      c.beginPath(); c.arc(swing.x, swing.y, swing.length, Math.PI / 2 - swing.amplitude, Math.PI / 2 + swing.amplitude);
      c.strokeStyle = '#a8c7b23d'; c.lineWidth = 1; c.stroke(); c.restore();
      this.ellipse(swing.x, swing.y, 24, 15, '#4b706e', '#b6c6a6', 4);
      this.ellipse(swing.x, swing.y, 7, 7, '#233f49', '#dbd4ad', 2);
      this.line([[swing.x - 4, swing.y + 4], [p.x - 4, p.y - 8]], '#739b8b', 5);
      this.line([[swing.x + 3, swing.y + 4], [p.x + 3, p.y - 8]], '#cbd2a7', 1.5);
      for (let i = 1; i < 6; i++) {
        const fraction = i / 6;
        this.ellipse(swing.x + (p.x - swing.x) * fraction, swing.y + (p.y - swing.y) * fraction, 3.4, 4.5, '#c3c4a0');
      }
      this.glow(p.x, p.y, 55, '243,209,133', held ? .35 : .17);
      if (!this.art.sprite('bone-anchor-ring', p.x, p.y)) {
        this.ellipse(p.x, p.y, 14, 17, '#173e4544', '#ead49d', 4);
        this.ellipse(p.x, p.y, 9, 12, null, '#7f9b82', 1);
      }
      this.label('03  摆荡骨环  ·  F 抓握 / 空格跃出', swing.x, swing.y + swing.length + 92, state.course?.swing);
    }
    if (room.id === 'ribs') {
      for (const [i, point] of (room.checkpoints || []).entries()) {
        const completed = i ? state.course?.swing : state.course?.lift;
        this.line([[point.x + 40, point.y + 48], [point.x + 40, point.y + 10]], '#b4bf9a', 2);
        c.beginPath(); c.moveTo(point.x + 41, point.y + 10); c.lineTo(point.x + 61, point.y + 16); c.lineTo(point.x + 41, point.y + 24); c.closePath();
        c.fillStyle = completed ? '#96d9b7' : '#c8ad75'; c.fill();
      }
    }
  }

  jelly(x, y, r, alpha = .5) {
    const c = this.ctx, t = this.time;
    c.save(); c.globalAlpha = alpha;
    this.glow(x, y, r * 3.5, '117,224,225', .3);
    c.beginPath(); c.ellipse(x, y, r, r * .7, 0, Math.PI, TAU); c.quadraticCurveTo(x + r * .3, y + r * .25, x - r, y);
    c.fillStyle = '#90d6ca55'; c.fill(); c.strokeStyle = '#b9e4c9'; c.lineWidth = 1; c.stroke();
    for (let j = -2; j <= 2; j++) {
      c.beginPath(); c.moveTo(x + j * r * .3, y); c.bezierCurveTo(x + j * r * .3 + Math.sin(t + j) * 7, y + r, x + j * 5 - 8, y + r * 1.4, x + j * 4 + Math.sin(t + j) * 6, y + r * 2);
      c.strokeStyle = '#95d9d090'; c.stroke();
    }
    c.restore();
  }

  boneLedge(p, asset) {
    const img = asset && this.images.get(asset.src);
    if (!img) return false;
    const c = this.ctx, crop = asset.crop, scale = asset.scale;
    const tileWidth = crop.w * scale, height = crop.h * scale;
    // Fixed uniform scale preserves the painted bone pores. Wide ledges
    // repeat cropped modules; short ledges take a centered source subsection.
    // The viewport clip also forbids decorative ledges beyond the collision x/w.
    const count = Math.max(1, Math.ceil(p.w / tileWidth));
    const width = p.w / count, sourceWidth = width / scale;
    c.save(); c.beginPath(); c.rect(p.x, p.y, p.w, height); c.clip();
    c.globalAlpha = .86;
    for (let i = 0; i < count; i++) {
      const sourceX = crop.x + (crop.w - sourceWidth) / 2;
      c.save();
      c.translate(p.x + i * width + (i % 2 ? width : 0), p.y);
      if (i % 2) c.scale(-1, 1);
      c.drawImage(img, sourceX, crop.y, sourceWidth, crop.h, 0, 0, width, height);
      c.restore();
    }
    c.globalAlpha = 1;
    // Keep the exact one-way collision crest legible against the image grain.
    this.line([[p.x, p.y + .5], [p.x + p.w, p.y + .5]], '#e4dbb8', 1.2);
    c.restore();
    return true;
  }

  platform(p, state, room) {
    const c = this.ctx, t = this.time;
    if (this.art.platform(p, room, state)) return;
    if (p.kind === 'safety') {
      c.save();
      const mist = c.createLinearGradient(0, p.y, 0, p.y + p.h);
      mist.addColorStop(0, '#6cbba53b'); mist.addColorStop(1, '#244a4e15');
      c.fillStyle = mist; c.fillRect(p.x, p.y, p.w, p.h);
      c.beginPath(); c.rect(p.x, p.y, p.w, p.h); c.clip();
      for (let x = p.x - p.h; x < p.x + p.w + p.h; x += 27) {
        this.line([[x, p.y], [x + p.h, p.y + p.h]], '#7ba79964', 1);
        this.line([[x, p.y], [x - p.h, p.y + p.h]], '#7ba79964', 1);
      }
      this.line([[p.x, p.y], [p.x + p.w, p.y]], '#a8c9a9', 2);
      for (let x = p.x; x < p.x + p.w; x += 110) this.ellipse(x, p.y + 1, 4, 4, '#c3d5af');
      c.restore();
      return;
    }
    const bone = p.kind === 'bone' || p.kind === 'bridge' || p.requires;
    if (bone && this.boneLedge(p, SCENES[room.id]?.terrain?.bone)) return;
    const material = SCENES[room.id]?.material;
    const membrane = p.kind === 'membrane' || (!bone && material === 'membrane');
    const flesh = material === 'tissue' && !bone;
    const restored = state.flags.has(`habitat-${room.id}`);
    const floor = p.h > 90;
    const palette = membrane
      ? {top:'#8eb4a0', lip:'#659c91', body:'#365f62', shade:'#123a45', edge:'#d0dfbc', vein:'#9cc8aa', hole:'#173f48'}
      : flesh
        ? {top:'#9e8770', lip:'#8b6659', body:'#674f4a', shade:'#283d3b', edge:'#d0b493', vein:'#b7977a', hole:'#3d3633'}
        : bone
          ? {top:'#c0bca0', lip:'#8e9a86', body:'#657e76', shade:'#263e44', edge:'#eee2b8', vein:'#bec6a5', hole:'#354e50'}
          : {top:'#8d9d8a', lip:'#6c8c81', body:'#416665', shade:'#143c44', edge:'#c0c9a4', vein:'#a2b6a2', hole:'#24484c'};
    const rimStep = 19;
    const count = Math.max(2, Math.ceil(p.w / rimStep));
    c.save();
    // The top remains a precise collision edge; the exposed rock below it is
    // chipped, overgrown and irregular rather than a rectangular shelf.
    c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x + p.w, p.y);
    c.quadraticCurveTo(p.x + p.w + 4, p.y + 12, p.x + p.w - 5, p.y + Math.min(22, p.h * .6));
    for (let j = 0; j <= count; j++) {
      const x = p.x + p.w * (1 - j / count);
      c.lineTo(x, p.y + p.h - hash(p.x + j * 17) * Math.min(p.h * .36, 32));
    }
    c.lineTo(p.x, p.y); c.closePath();
    const g = c.createLinearGradient(0, p.y, 0, p.y + p.h);
    g.addColorStop(0, palette.top); g.addColorStop(.17, palette.lip); g.addColorStop(.38, palette.body); g.addColorStop(1, palette.shade);
    c.fillStyle = g; c.fill();
    c.save(); c.clip();

    // Overlapping calcified scales and soft tissue folds give each region its
    // own material at a scale that reads at normal gameplay magnification.
    for (let j = 0; j < p.w / 49 + 1; j++) {
      const seed = hash(p.x + j * 19), x = p.x + j * 49;
      const depth = Math.min(p.h * .68, 35 + seed * 54), span = 29 + seed * 28;
      c.beginPath(); c.moveTo(x - 16, p.y + 7);
      c.bezierCurveTo(x - 11, p.y + depth * .45, x + span * .5, p.y + depth * .3, x + span * .3, p.y + depth);
      c.bezierCurveTo(x + span * .9, p.y + depth * .8, x + span, p.y + 16, x + span * 1.2, p.y + 8);
      c.closePath(); c.fillStyle = j % 3 === 0 ? palette.lip : palette.body; c.globalAlpha = .55; c.fill();
      c.strokeStyle = palette.vein; c.lineWidth = 1.2; c.globalAlpha = .27; c.stroke();
    }
    c.globalAlpha = 1;
    for (let j = 0; j < p.w / 35; j++) {
      const seed = hash(p.x * 3 + j * 13), x = p.x + 12 + j * 35;
      const yy = p.y + 15 + hash(j + p.x + 177) * Math.max(4, p.h - 29);
      if (seed > .4 && !membrane) {
        const rx = 4 + seed * 13, ry = 2 + hash(j + 44) * Math.min(10, p.h * .13);
        c.save(); c.translate(x, yy); c.rotate((seed - .5) * 1.4);
        this.ellipse(0, 1, rx + 1, ry + 1, palette.vein + '65');
        this.ellipse(0, -1, rx, ry, palette.hole);
        this.ellipse(-1, -ry * .3, rx * .72, ry * .48, '#0d2b323f');
        c.restore();
      }
      if (seed < .55) {
        const down = Math.min(p.h - 6, 21 + seed * 73);
        this.line([[x, p.y + 5], [x - 6, p.y + 16], [x + 4, p.y + 23], [x - 2, p.y + down]], palette.hole + 'ad', 1.4);
        this.line([[x - 5, p.y + 16], [x - 14, p.y + 22]], palette.hole + '80', .8);
      }
    }
    if (membrane) {
      for (let j = 0; j < p.w / 26; j++) {
        const x = p.x + j * 26;
        c.beginPath(); c.moveTo(x, p.y + 3); c.quadraticCurveTo(x - 11, p.y + 22, x + 18, p.y + p.h);
        c.strokeStyle = '#b3d4ac65'; c.lineWidth = 1; c.stroke();
      }
    }

    // A thick, scalloped rim breaks the geometric shelf silhouette while its
    // fine continuous crest still communicates exactly where feet will land.
    c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x + p.w, p.y);
    for (let j = count; j >= 0; j--) {
      const x = p.x + p.w * j / count, dip = 7 + hash(p.x + j * 29) * (bone ? 10 : 15);
      c.quadraticCurveTo(x + rimStep * .42, p.y + dip + 4, x, p.y + dip);
    }
    c.closePath(); c.fillStyle = palette.top; c.globalAlpha = .75; c.fill(); c.globalAlpha = 1;
    c.beginPath();
    for (let j = 0; j <= count; j++) {
      const x = p.x + p.w * j / count, dip = 8 + hash(p.x + j * 29) * (bone ? 10 : 15);
      if (!j) c.moveTo(x, p.y + dip); else c.quadraticCurveTo(x - rimStep * .42, p.y + dip + 5, x, p.y + dip);
    }
    c.strokeStyle = palette.shade + 'a0'; c.lineWidth = 3; c.stroke();
    c.fillStyle = this.pattern; c.fillRect(p.x, p.y, p.w, p.h);
    c.restore();
    this.line([[p.x + 2, p.y + .7], [p.x + p.w - 2, p.y + .7]], palette.edge, 1.3);
    for (let j = 0; j < p.w / 22; j++) {
      const x = p.x + j * 22 + 4, seed = hash(x + 9);
      this.ellipse(x, p.y + 3 + seed * 3, 3 + seed * 5, 1 + seed * 1.5, palette.edge + 'a0');
    }
    for (let j = 0; j < p.w / 33; j++) {
      const x = p.x + 10 + j * 33, seed = hash(x * 4);
      if (seed < .43) this.coral(x, p.y, 8 + seed * 30, restored ? '#a1ceb0' : flesh ? '#b9ad7e' : '#7fbaa3', hash(x) * 10);
      if (seed > .7) {
        this.ellipse(x, p.y - 2, 3, 2, '#d0d6a1');
        this.glow(x, p.y - 4, 15, '141,227,181', .15);
      }
      if (!floor && seed > .4) {
        this.line([[x, p.y + p.h - 8], [x + Math.sin(t + x) * 4, p.y + p.h + 10 + seed * 18]], '#75b4a247', 1);
        this.ellipse(x + Math.sin(t + x) * 4, p.y + p.h + 10 + seed * 18, 1.5, 2, '#a3d9b870');
      }
    }
    c.restore();
  }

  dormantPlatform(p) {
    const c = this.ctx;
    c.save(); c.setLineDash([3, 10]); c.strokeStyle = '#a3c2a239'; c.lineWidth = 1;
    c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x + p.w, p.y); c.stroke(); c.restore();
  }

  tissueBlock(cleared) {
    const c = this.ctx, top = cleared ? 564 : 440;
    c.save();
    this.ellipse(799, 580, 55, 6, '#172f32aa');
    c.beginPath(); c.moveTo(755, 580);
    c.bezierCurveTo(752, top + 49, 754, top + 12, 768, top + 4);
    c.bezierCurveTo(795, top - 3, 823, top - 3, 837, top + 18);
    c.bezierCurveTo(846, top + 40, 842, 557, 845, 580); c.closePath();
    const gradient = c.createLinearGradient(755, top, 837, 580);
    gradient.addColorStop(0, cleared ? '#6a6b51' : '#b29878');
    gradient.addColorStop(.35, '#8d6c5b'); gradient.addColorStop(.75, '#6a514a'); gradient.addColorStop(1, '#3e4b40');
    c.fillStyle = gradient; c.fill(); c.strokeStyle = '#b6a382'; c.lineWidth = 1.5; c.stroke();
    c.save(); c.clip();
    for (let i = 0; i < 8; i++) {
      const x = 755 + i * 13;
      c.beginPath(); c.moveTo(x, top + 4); c.bezierCurveTo(x - 20, top + 35, x + 30, 550, x - 1, 586);
      c.strokeStyle = i % 2 ? '#4f44448a' : '#c0a78677'; c.lineWidth = 3 + hash(i) * 4; c.stroke();
    }
    for (let i = 0; i < 20; i++) this.ellipse(758 + hash(i * 13) * 85, top + hash(i + 41) * (580 - top), 2 + hash(i) * 4, 1 + hash(i + 43) * 4, '#d2b88a50');
    c.fillStyle = this.pattern; c.fillRect(750, top, 100, 150); c.restore();
    if (!cleared) {
      this.line([[743, 566], [756, 541], [766, 529]], '#c1b08d', 2);
      for (let i = 0; i < 3; i++) this.coral(784 + i * 19, top + 5, 11 + i * 3, '#b9b58b', i);
    }
    c.restore();
  }

  coral(x, y, h, color, seed) {
    const c = this.ctx, sway = Math.sin(this.time * .7 + seed) * 3;
    c.beginPath(); c.moveTo(x, y); c.quadraticCurveTo(x - 3, y - h * .5, x + sway, y - h);
    c.moveTo(x - 1, y - h * .36); c.quadraticCurveTo(x - 10, y - h * .48, x - 9 + sway, y - h * .77);
    c.moveTo(x, y - h * .54); c.quadraticCurveTo(x + 8, y - h * .65, x + 8 + sway, y - h * .93);
    c.strokeStyle = color; c.lineWidth = 1.4; c.stroke();
    this.ellipse(x + sway, y - h, 1.7, 2.2, color);
  }

  hazard(h) {
    const c = this.ctx, t = this.time;
    const g = c.createLinearGradient(0, h.y, 0, h.y + h.h);
    g.addColorStop(0, '#c5b85470'); g.addColorStop(1, '#56753b20'); c.fillStyle = g; c.fillRect(h.x, h.y, h.w, h.h);
    c.beginPath(); for (let j = 0; j <= h.w; j += 8) { const y = h.y + Math.sin(j * .055 + t * 2) * 2; j ? c.lineTo(h.x + j, y) : c.moveTo(h.x, y); }
    c.strokeStyle = '#dcce84'; c.lineWidth = 1.5; c.stroke();
    for (let j = 0; j < h.w / 30; j++) {
      const x = h.x + hash(j + 712) * h.w, y = h.y + h.h - ((t * 16 + j * 17) % Math.max(10, h.h));
      this.ellipse(x, y, 2 + hash(j) * 2, 2 + hash(j) * 2, null, '#e0d48d66');
    }
  }

  fish(x, y, r, color) {
    const c = this.ctx;
    this.ellipse(x, y, r, r * .43, color);
    c.beginPath(); c.moveTo(x - r * .7, y); c.lineTo(x - r * 1.7, y - r * .6); c.lineTo(x - r * 1.7, y + r * .6); c.closePath(); c.fillStyle = color; c.fill();
  }

  gate(g, open) {
    const c = this.ctx, t = this.time, long = g.kind === 'long';
    c.save();
    if (!open) {
      const gradient = c.createLinearGradient(g.x, 0, g.x + g.w, 0);
      gradient.addColorStop(0, '#e5b86700'); gradient.addColorStop(.5, long ? '#dfa77227' : '#e8c98030'); gradient.addColorStop(1, '#e5b86700');
      c.fillStyle = gradient; c.fillRect(g.x - 20, g.y, g.w + 40, g.h);
      for (let j = 0; j < 13; j++) {
        const x = g.x + g.w * j / 12 + Math.sin(t * .8 + j) * 2;
        this.line([[x, g.y], [x + Math.sin(j) * 3, g.y + g.h]], '#d9c08265', 1.4);
      }
    }
    for (let i = 0; i < (open ? 18 : 35); i++) {
      const x = g.x + hash(i + 213) * g.w + Math.sin(t * 1.4 + i) * (open ? 35 : 12);
      const y = open ? g.y - 20 + hash(i + 441) * 45 : g.y + hash(i + 44) * g.h;
      c.globalAlpha = open ? .5 : .65 + Math.sin(t * 2 + i) * .2;
      this.fish(x, y, 3 + hash(i + 17) * 3, long ? '#edbc88' : '#e9ca9d');
    }
    c.globalAlpha = 1;
    if (!open) {
      const x = g.x + g.w / 2, y = g.y + Math.min(g.h * .4, 95);
      this.glow(x, y, 42, '246,197,120', .2);
      this.ellipse(x, y, 16, 16, '#153b3ddd', '#cfb681', 1);
      for (let i = 0; i < (long ? 3 : 1); i++) this.line([[x - 6 + i * 6, y - 5], [x - 6 + i * 6, y + 5]], '#f2daaa', 2);
    }
    c.restore();
  }

  object(o, state) {
    const c = this.ctx, t = this.time, done = state.flags.has(o.id), x = o.x, y = o.y;
    const color = done ? '#9dd8ba' : '#e9c88a';
    const near = Math.abs(state.player.x + state.player.w / 2 - x) < 100 && Math.abs(state.player.y + 40 - y) < 110;
    if (o.type === 'habitat') { this.habitat(o, state, near); return; }
    c.save();
    this.glow(x, y - 15, near ? 90 : 58, done ? '131,219,176' : '245,195,107', near ? .22 : .12);
    if (this.art.object(o, state)) {
      // Common status markers and interaction labels are drawn below.
    } else if (o.type === 'course-power') {
      this.line([[x - 23, y], [x - 18, y - 24], [x + 18, y - 24], [x + 23, y]], '#94aa91', 5);
      this.ellipse(x, y - 29, 22, 24, '#315d5c', color, 2);
      this.ellipse(x, y - 29, 14, 16, done ? '#79bfa5' : '#7e7e59', '#c6caa2', 1);
      for (let i = 0; i < 3; i++) this.line([[x - 8, y - 35 + i * 7], [x + 8, y - 35 + i * 7]], '#e5d59e', 1.5);
      this.line([[x + 18, y - 28], [x + 30, y - (done ? 14 : 47)]], '#ddd0a3', 4);
      this.ellipse(x + 30, y - (done ? 14 : 47), 5, 5, '#e0b970');
    } else if (o.type === 'course-reset') {
      this.ellipse(x, y - 8, 25, 8, '#3c6e66', '#a5c4a6', 2);
      this.line([[x, y - 9], [x, y - 42]], '#a9c2a2', 2);
      this.line([[x + 9, y - 39], [x - 7, y - 39], [x - 1, y - 45]], '#e2d29c', 2);
    } else if (o.type === 'course-finish') {
      this.line([[x - 22, y], [x - 22, y - 63], [x + 22, y - 63], [x + 22, y]], '#b8bea0', 5);
      this.line([[x, y - 60], [x, y - (done ? 23 : 39)]], '#e4cd97', 2);
      this.line([[x - 10, y - (done ? 23 : 39)], [x + 10, y - (done ? 23 : 39)]], color, 5);
      this.lamp(x, y - 74, .8);
      if (done) this.glow(x, y - 40, 100, '128,231,191', .25);
    } else if (o.type === 'camp') {
      this.line([[x - 24, y], [x - 13, y - 31], [x + 19, y - 2]], '#b5b58b', 3);
      c.beginPath(); c.moveTo(x - 15, y - 29); c.lineTo(x + 18, y - 2); c.lineTo(x - 20, y - 1); c.closePath(); c.fillStyle = '#497373'; c.fill();
      this.lamp(x + 16, y - 12, 1);
      this.line([[x - 16, y - 30], [x - 16, y - 49]], '#b5b58b', 2);
      c.fillStyle = '#d8c18c'; c.fillRect(x - 15, y - 49, 17, 7);
    } else if (o.type === 'food') {
      this.ellipse(x, y - 6, 15, 7, '#697e65', '#adad83');
      for (let i = 0; i < 5; i++) this.ellipse(x - 9 + i * 4, y - 10 - Math.sin(i) * 4, 4, 5, done ? '#607b67' : '#d7b76b');
    } else if (o.type === 'crab') {
      for (let side of [-1, 1]) for (let i = 0; i < 3; i++) this.line([[x + side * 9, y - 9], [x + side * (18 + i * 3), y - 12 + i * 4], [x + side * (22 + i * 4), y - 2]], '#ceab79', 2.6);
      this.ellipse(x, y - 12, 15, 11, '#927e61', '#d8c7a2', 1.5);
      this.ellipse(x - 6, y - 21, 2.5, 3.5, '#bddbc2'); this.ellipse(x + 6, y - 21, 2.5, 3.5, '#bddbc2');
      this.line([[x - 14, y - 13], [x - 25, y - 24], [x - 30, y - 29]], '#d8b885', 4);
      this.line([[x - 25, y - 24], [x - 20, y - 30]], '#d8b885', 3);
      this.ellipse(x + 2, y - 10, 6, 5, '#657d6a');
    } else if (o.type === 'valve') {
      this.line([[x - 20, y], [x - 15, y - 10], [x - 15, y - 27], [x, y - 27]], '#637c72', 9);
      this.ellipse(x, y - 30, 18, 18, '#1b4143', color, 3);
      for (let i = 0; i < 4; i++) { const a = i * Math.PI / 2 + (done ? .6 : 0); this.line([[x, y - 30], [x + Math.cos(a) * 16, y - 30 + Math.sin(a) * 16]], color, 2); }
      this.ellipse(x, y - 30, 4, 4, color);
    } else if (o.type === 'float') {
      if (!done && !state.abilities.has('float')) this.jelly(x, y - 28 + Math.sin(t * 1.5) * 5, 23, .8);
      else { this.coral(x, y, 24, '#b4d7a9', 2); this.ellipse(x, y - 2, 18, 5, '#7da48a66'); }
    } else if (o.type === 'refill') {
      this.ellipse(x, y - 17, 13, 22, '#518d87aa', '#b6d3b0', 1.4);
      this.line([[x - 3, y - 31], [x - 5, y - 15]], '#c7e5d3', 2);
      for (let i = 0; i < 4; i++) this.ellipse(x + Math.sin(i * 2) * 6, y - 8 - (t * 9 + i * 12) % 29, 1.5, 1.5, '#d8efd0');
      this.coral(x - 10, y, 19, '#a0bea2', 3);
    } else if (o.type === 'shortcut') {
      this.line([[x - 17, y], [x - 17, y - 47], [x + 17, y - 47], [x + 17, y]], '#acbba0', 4);
      for (let i = 0; i < 4; i++) this.line([[x - 15, y - 8 - i * 10], [x + 15, y - 8 - i * 10]], done ? '#8ecbb1' : '#708d7c', 2);
    }
    if (!done && o.type !== 'camp' && o.type !== 'refill') {
      c.save(); c.translate(x, y - 64 + Math.sin(t * 2) * 2); c.rotate(Math.PI / 4); c.fillStyle = '#f0d29b'; c.fillRect(-2.5, -2.5, 5, 5); c.restore();
    }
    if (near && o.label) this.label(o.label, x, y - (o.type === 'shortcut' ? 73 : 88), done);
    c.restore();
  }

  habitat(o, state, near) {
    const c = this.ctx, t = this.time, { x, y } = o;
    const habitat = HABITATS.find(item => item.id === o.id);
    const { phase, progress } = getHabitatStatus(state, o.id);
    const p = clamp(progress, 0, 1), active = phase !== 'dormant', restored = phase === 'restored';
    const room = typeof habitat?.room === 'string' ? habitat.room : o.id.replace('habitat-', '');
    c.save();
    this.glow(x, y - 12, 62 + p * 46, active ? '131,219,176' : '198,184,121', active ? .10 + p * .07 : near ? .12 : .04);
    // These low silhouettes sit above the existing rim; they add no landing edge.
    this.ellipse(x, y - 3, 33 + p * 28, 5 + p * 4, active ? '#507b6866' : '#43574b99', active ? '#93b89588' : '#81907877');
    const bed = room === 'mouth' ? 'habitat-fungus-bed' : room === 'stomach' ? 'habitat-shell-nest' : 'habitat-larva-trough';
    this.art.sprite(bed, x, y, { alpha: active ? .65 + p * .35 : .45 });
    if (room === 'mouth') {
      for (let i = 0; i < 13; i++) {
        const seed = hash(i + 842), spread = 25 + p * 35;
        const mx = x + (i / 12 * 2 - 1) * spread;
        const growth = .25 + p * (.5 + seed * .5);
        this.ellipse(mx, y - 5 - seed * 7 * p, 4 + growth * 7, 2 + growth * 3, active ? '#a6c99799' : '#7b896666');
        if (active && seed < p) this.coral(mx, y - 7, 6 + p * 11, '#b4d5a5a0', i);
      }
      if (active) for (let i = 0; i < 7; i++) {
        const arrival = clamp((p - i * .12) / .18, 0, 1);
        if (!arrival) continue;
        const travel = t * (.65 + hash(i + 15) * .35) + i * 2.4;
        const sx = x + Math.sin(travel) * (35 + i * 7);
        const sy = y - 15 - i % 3 * 8 + Math.cos(travel * 1.7) * 3;
        c.save(); c.globalAlpha = arrival * .85;
        this.habitatShrimp(sx, sy, 1 + hash(i + 39) * .25, Math.cos(travel) < 0 ? -1 : 1, i);
        c.restore();
      }
    } else if (room === 'stomach') {
      for (let i = 0; i < 5; i++) {
        const bx = x - 32 + i * 16, rise = 6 + hash(i + 26) * 12;
        this.line([[bx - 5, y - 4], [bx, y - rise * (.4 + p * .6)], [bx + 7, y - 4]], active ? '#b5c5a088' : '#8a937777', 4);
      }
      for (let i = 0; i < 7; i++) {
        const growth = active ? clamp((p - i * .11) / .3, 0, 1) : .15;
        if (!growth) continue;
        const sx = x + (i - 3) * 17, sy = y - 5 - (i % 2) * 5;
        this.habitatShell(sx, sy, 3 + growth * (8 + hash(i + 19) * 4), active ? growth : 0, i);
      }
    } else {
      const width = 26 + p * 19, height = 8 + p * 17;
      for (let side = -1; side <= 1; side++) {
        c.beginPath(); c.moveTo(x - width, y - 4);
        c.bezierCurveTo(x - width * .6, y - height * (1.2 + side * .2), x + width * .6, y - height * (1.2 - side * .2), x + width, y - 4);
        c.quadraticCurveTo(x, y - 2 - height * .35, x - width, y - 4);
        c.fillStyle = active ? '#8ebfa72b' : '#70867420'; c.fill();
        c.strokeStyle = active ? '#b3d8b399' : '#82927b77'; c.lineWidth = 1; c.stroke();
      }
      for (let i = 0; i < 5; i++) {
        const ex = x - 24 + i * 12, size = 2.5 + p * 2;
        this.ellipse(ex, y - 8 - Math.sin(i / 4 * Math.PI) * height * .5, size, size * 1.4, active ? '#d2e0a699' : '#798b6c77');
      }
      if (active) for (let i = 0; i < 5; i++) {
        const arrival = clamp((p - i * .17) / .25, 0, 1);
        if (!arrival) continue;
        const drift = t * (.55 + i * .07) + i * 2.1;
        const lx = x + Math.sin(drift) * (33 + i * 12);
        const ly = y - 35 - i * 11 + Math.sin(drift * 1.4 + i) * 8;
        c.save(); c.globalAlpha = arrival * .78;
        this.habitatLarva(lx, ly, 7 + hash(i + 31) * 3, i);
        c.restore();
      }
    }
    if (active) for (let i = 0; i < 4; i++) {
      const age = (t * .27 + i * .25) % 1;
      c.globalAlpha = Math.sin(age * Math.PI) * p * .55;
      this.ellipse(x + Math.sin(i * 3 + age) * (25 + p * 25), y - 12 - age * 40, 1.2, 1.2, '#d1e6b4');
    }
    c.globalAlpha = 1;
    if (phase === 'recovering') {
      const rx = x + 77, ry = y - 43;
      this.ellipse(rx, ry, 15, 15, '#10353be6', '#91bca64d', 1);
      c.beginPath(); c.arc(rx, ry, 13, -Math.PI / 2, -Math.PI / 2 + TAU * p);
      c.strokeStyle = '#b9dec0'; c.lineWidth = 2; c.stroke();
      c.font = '9px "Microsoft YaHei", sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
      c.fillStyle = '#d5e5c5'; c.fillText(`${Math.floor(p * 100)}`, rx, ry + .5);
    } else if (!active) {
      c.save(); c.translate(x, y - 55 + Math.sin(t * 2) * 2); c.rotate(Math.PI / 4);
      c.fillStyle = '#e5c58b'; c.fillRect(-2.5, -2.5, 5, 5); c.restore();
    }
    if (near) {
      const text = restored ? `${habitat?.resident || '居民'}已回归` : active ? `${habitat?.name || '栖息地'}恢复中 · ${Math.floor(p * 100)}%` : o.label;
      if (text) this.label(text, x, y - (room === 'lung' && active ? 112 : 88), restored);
    }
    c.restore();
  }

  habitatShrimp(x, y, size, facing, seed) {
    if (this.art.sprite('baleen-shrimp-swarm', x, y, { units: 48 * size })) return;
    const c = this.ctx;
    c.save(); c.translate(x, y); c.scale(size * facing, size);
    c.beginPath(); c.moveTo(-9, 2); c.quadraticCurveTo(-3, -9, 6, -4); c.quadraticCurveTo(10, -1, 6, 2);
    c.strokeStyle = '#e0c49d'; c.lineWidth = 3; c.stroke();
    this.line([[-8, 2], [-12, -1], [-12, 4]], '#b69e7c', 1.5);
    for (let i = 0; i < 3; i++) {
      const kick = Math.sin(this.time * 7 + seed + i) * 1.7;
      this.line([[-2 + i * 3, 0], [-4 + i * 3 + kick, 6]], '#cab48a', .8);
    }
    this.line([[6, -3], [12, -8], [17, -7]], '#d1c9a0a0', .7);
    this.line([[6, -3], [13, -5], [18, -3]], '#d1c9a0a0', .7);
    this.ellipse(6, -4, 1, 1, '#1a4044');
    c.restore();
  }

  habitatShell(x, y, r, growth, seed) {
    const c = this.ctx, breath = .1 + (Math.sin(this.time * 1.4 + seed * 2) + 1) * .12 * growth;
    c.save(); c.translate(x, y); c.rotate((hash(seed + 51) - .5) * .35);
    c.beginPath(); c.moveTo(0, 0); c.bezierCurveTo(-r * 1.4, -r * .3, -r, -r * 1.8, 0, -r * 1.55);
    c.bezierCurveTo(r, -r * 1.8, r * 1.4, -r * .3, 0, 0);
    c.fillStyle = growth ? '#a6b69a' : '#718477'; c.fill(); c.strokeStyle = '#d4d4ad'; c.lineWidth = .9; c.stroke();
    for (let i = -2; i <= 2; i++) {
      c.beginPath(); c.moveTo(0, -.5); c.quadraticCurveTo(i * r * .35, -r * .7, i * r * .32, -r * (1.53 - Math.abs(i) * .1));
      c.strokeStyle = '#526e6588'; c.lineWidth = .7; c.stroke();
    }
    this.line([[-r * .85, -r * .55], [0, -r * breath], [r * .85, -r * .55]], '#263f3e', .8 + growth * 1.5);
    if (growth > .3) {
      const reach = Math.sin(this.time * 1.5 + seed) * 2;
      this.line([[0, -r * breath], [reach, -r * .35], [reach + 3, -r * .5]], '#c8d6a8', .8);
    }
    c.restore();
  }

  habitatLarva(x, y, r, seed) {
    const c = this.ctx, flutter = 1 + Math.sin(this.time * 3 + seed) * .15;
    c.save(); c.translate(x, y);
    for (const side of [-1, 1]) {
      c.beginPath(); c.moveTo(0, 2);
      c.bezierCurveTo(side * r * 1.4 * flutter, -r * .2, side * r * 1.1, -r * 1.5, 0, -r * .6);
      c.quadraticCurveTo(side * r * .25, -r * .1, 0, 2);
      c.fillStyle = '#a2d9cc3d'; c.fill(); c.strokeStyle = '#c1e3b6bb'; c.lineWidth = .8; c.stroke();
    }
    this.ellipse(0, 0, 2.5, 4.5, '#d4ddb0');
    for (const side of [-1, 1]) {
      c.beginPath(); c.moveTo(side, 3); c.quadraticCurveTo(side * 5, r * .8, side * 3 + Math.sin(this.time * 2 + seed) * 3, r * 1.5);
      c.strokeStyle = '#a4d9c99c'; c.lineWidth = .7; c.stroke();
    }
    c.restore();
  }

  label(text, x, y, done) {
    const c = this.ctx;
    c.font = '12px "Microsoft YaHei", sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle';
    const w = c.measureText(text).width + 22;
    c.fillStyle = '#0b2a31e8'; c.fillRect(x - w / 2, y - 12, w, 24);
    c.strokeStyle = done ? '#95bda14a' : '#c6b78460'; c.lineWidth = .7; c.strokeRect(x - w / 2, y - 12, w, 24);
    c.fillStyle = done ? '#b5d6bb' : '#e4d9b9'; c.fillText(text, x, y + .5);
  }

  lamp(x, y, scale = 1) {
    const c = this.ctx;
    this.glow(x, y, 38 * scale, '255,185,77', .4);
    this.ellipse(x, y, 5 * scale, 8 * scale, '#ffc768', '#795b32', 1.8);
    this.ellipse(x - scale, y - scale, 2 * scale, 5 * scale, '#fff0b8');
    this.line([[x, y - 10 * scale], [x, y + 8 * scale]], '#93682b', .8);
  }

  memory(m) {
    const c = this.ctx, y = m.y - 8 + Math.sin(this.time * 1.7 + m.x) * 4;
    this.glow(m.x, y, 65, '235,199,119', .25);
    if (this.art.sprite('migration-memory', m.x, y + 9)) return;
    c.save(); c.translate(m.x, y); c.rotate(.25 + Math.sin(this.time) * .1);
    c.beginPath(); c.moveTo(0, -14); c.quadraticCurveTo(16, -1, 4, 13); c.quadraticCurveTo(-11, 5, 0, -14); c.fillStyle = '#e6c483'; c.fill(); c.strokeStyle = '#f3e1b2'; c.lineWidth = 1; c.stroke();
    this.line([[0, -9], [1, 8]], '#a48046', 1); c.restore();
    for (let i = 0; i < 3; i++) this.ellipse(m.x + Math.cos(this.time + i * 2) * 23, y + Math.sin(this.time + i * 2) * 12, 1.4, 1.4, '#ecd49a');
  }

  exit(e) {
    const c = this.ctx, t = this.time;
    this.glow(e.x, e.y - 36, 75, '131,225,204', .13);
    c.save(); c.globalAlpha = .55 + Math.sin(t * 1.8) * .15;
    const dir = e.x < 180 ? -1 : 1;
    this.line([[e.x - dir * 5, e.y - 44], [e.x + dir * 5, e.y - 36], [e.x - dir * 5, e.y - 28]], '#c7dcc2', 1.5);
    c.restore();
  }

  pulse(p) {
    const c = this.ctx, age = p.age || 0, duration = p.long ? 1.3 : .85;
    const progress = clamp(age / duration, 0, 1), radius = 18 + progress * (p.long ? 250 : 150);
    c.save(); c.globalAlpha = Math.max(0, 1 - progress);
    const color = p.long ? '#f4cc85' : '#9edbd0';
    this.ellipse(p.x, p.y, radius, radius * .82, null, color, 1.7);
    if (p.long) { this.ellipse(p.x, p.y, radius * .8, radius * .66, null, '#d4c69b', 1); this.ellipse(p.x, p.y, radius * .6, radius * .49, null, '#d4c69b88', .8); }
    this.glow(p.x, p.y, radius, p.long ? '246,200,112' : '131,223,213', .07);
    c.restore();
  }

  hero(p, state) {
    if (!p) return;
    const c = this.ctx, t = this.time, f = p.facing || 1;
    const moving = Math.abs(p.vx || 0) > 5, stride = p.grounded && moving ? Math.sin(t * 14) * 5 : 0;
    const climbing = Boolean(p.climbing), swinging = Boolean(p.swinging);
    const climbStep = climbing && Math.abs(p.vy || 0) > 1 ? Math.sin(t * 9) * 5 : 0;
    const float = state.abilities.has('float') && p.floating;
    const x = p.x + p.w / 2, y = p.y;
    this.glow(x, y + 22, 100, '159,218,194', .09);
    if (p.grounded) this.ellipse(x, y + p.h + 1, 17, 3, '#001c2370');
    if (this.art.hero(p, state)) return;
    c.save(); c.translate(x, y); c.scale(f, 1);
    if (float) {
      const membrane = c.createRadialGradient(0, -10, 2, 0, -10, 42);
      membrane.addColorStop(0, '#cbebcd20'); membrane.addColorStop(1, '#a6e0d460');
      c.beginPath(); c.moveTo(-32, 4); c.bezierCurveTo(-42, -47, 33, -51, 36, 2); c.quadraticCurveTo(0, -7, -32, 4); c.fillStyle = membrane; c.fill(); c.strokeStyle = '#d3e8b5b0'; c.lineWidth = 1.2; c.stroke();
      for (let i = -2; i <= 2; i++) this.line([[i * 15, -3], [i * 7, 24]], '#d3e8b56b', .7);
      c.beginPath(); c.moveTo(-32, 4); c.quadraticCurveTo(-13, -43, 0, -38); c.quadraticCurveTo(19, -30, 36, 2); c.strokeStyle = '#e6e2ab70'; c.stroke();
    }
    // Boots, body and short torn cloak remain distinguishable against dark terrain.
    if (climbing) {
      this.line([[-5, 29], [-13, 34 - climbStep], [-10, 40 - climbStep], [-5, 40 - climbStep]], '#b9b89a', 4.6);
      this.line([[5, 29], [14, 32 + climbStep], [11, 40 + climbStep], [16, 40 + climbStep]], '#8b9b8b', 4.5);
    } else if (swinging) {
      const drift = clamp((p.vx || 0) * .025, -8, 8);
      this.line([[-5, 29], [-7 - drift, 41], [-3 - drift, 48], [3 - drift, 48]], '#b9b89a', 4.6);
      this.line([[5, 29], [13 - drift, 36], [15 - drift, 44], [20 - drift, 44]], '#8b9b8b', 4.5);
    } else {
      this.line([[-5, 29], [-7 - stride * .4, 39], [-10 - stride, 46], [-3 - stride, 46]], '#b9b89a', 4.6);
      this.line([[5, 29], [6 + stride * .4, 39], [8 + stride, 46], [14 + stride, 46]], '#8b9b8b', 4.5);
    }
    c.beginPath(); c.moveTo(-11, 14); c.lineTo(9, 16); c.lineTo(10, 35); c.lineTo(-10, 35); c.closePath(); c.fillStyle = '#7c8c75'; c.fill();
    const sway = Math.sin(t * 5) * 3 + (moving ? 6 : 0);
    c.beginPath(); c.moveTo(-11, 13); c.quadraticCurveTo(-19 - sway, 25, -24 - sway, 35); c.lineTo(-13 - sway, 31); c.lineTo(-16, 39); c.lineTo(-6, 34); c.lineTo(0, 38); c.lineTo(8, 20); c.closePath();
    c.fillStyle = '#326770'; c.fill(); c.strokeStyle = '#7ca39a'; c.lineWidth = 1; c.stroke();
    this.line([[-11, 18], [-17 - sway, 31]], '#4e8b8c', 1.7);
    this.line([[-7, 19], [7, 32]], '#a29670', 2.3);
    if (climbing || swinging) {
      const handY = swinging ? -8 : 3 + climbStep;
      this.line([[-8, 21], [-17, 10], [-12, swinging ? -5 : 1 - climbStep]], '#b4bda0', 3.4);
      this.line([[7, 20], [15, 6], [swinging ? 5 : 15, handY]], '#d3ceb0', 3.4);
      this.ellipse(swinging ? 5 : 15, handY, 3, 3, '#e8d0a0');
      // The resonance fork is strapped to the cloak while both hands grip.
      this.line([[-18, 33], [-24, 9]], '#c6b88c', 2);
      this.line([[-24, 9], [-28, 3]], '#c6b88c', 2);
      this.line([[-24, 9], [-21, 1]], '#c6b88c', 2);
    } else {
      this.line([[7, 20], [13, 29], [23, 23]], '#bdc2a2', 3.4);
      this.line([[18, 25], [20, 29]], '#c5674b', 2.7);
      this.line([[21, 34], [23, 11]], '#ddcca0', 2.2);
      c.beginPath(); c.moveTo(23, 17); c.quadraticCurveTo(15, 16, 19, 5); c.moveTo(23, 17); c.quadraticCurveTo(30, 16, 29, 5); c.strokeStyle = '#eee0b5'; c.lineWidth = 2; c.stroke();
      this.line([[21, 29], [17, 37]], '#b86d50', 1.2);
    }
    this.lamp(0, 30, .8);
    const head = c.createRadialGradient(-5, 4, 1, 0, 9, 17);
    head.addColorStop(0, '#fff2d0'); head.addColorStop(.6, '#d7d0ac'); head.addColorStop(1, '#9da28d');
    this.ellipse(0, 8, 14, 13, head, '#f0e2bd', .7);
    c.beginPath(); c.moveTo(-12, 9); c.lineTo(-20, 5); c.lineTo(-16, 13); c.lineTo(-10, 15); c.closePath(); c.fillStyle = '#52818a'; c.fill();
    this.ellipse(6.5, 8, 6.5, 8, '#0b2735', '#bca66e', 1.6);
    this.ellipse(7, 7, 4.4, 5.9, '#153e50');
    this.ellipse(8, 4.5, 1.8, 2, '#bfe4e8');
    this.line([[-10, 19], [1, 22], [11, 17]], '#3d737b', 4);
    if (state.charge > .02) {
      const charge = state.charge;
      this.glow(24, 9, 26 + charge * 30, '255,209,130', .2 + charge * .2);
      c.beginPath(); c.arc(24, 9, 14 + charge * 5, -Math.PI / 2, -Math.PI / 2 + TAU * charge); c.strokeStyle = '#f5d597'; c.lineWidth = 2; c.stroke();
    }
    c.restore();
  }

  waterParticles(state) {
    const c = this.ctx, t = this.time;
    for (let i = 0; i < 95; i++) {
      const depth = .2 + hash(i + 721) * .8;
      const x = ((hash(i + 100) * 1400 - this.camera * depth * .12 + Math.sin(t * .2 + i) * 18) % 1400 + 1400) % 1400 - 60;
      const y = ((hash(i + 400) * 800 - t * (2 + depth * 5)) % 800 + 800) % 800 - 40;
      c.globalAlpha = (.15 + depth * .35) * (.7 + Math.sin(t * .5 + i) * .3);
      this.ellipse(x, y, depth * 1.6, depth * 1.6, i % 7 === 0 ? '#f1d89b' : '#c1e8d5');
    }
    c.globalAlpha = 1;
  }

  foreground(room) {
    const c = this.ctx, cam = this.camera;
    this.art.foreground(room);
    for (let i = -1; i < 20; i++) {
      const x = i * 83 - (cam * 1.12 % 83), h = 18 + hash(i + 29) * 34;
      this.coral(x, 735, h, '#0a3039', i);
      if (i % 3 === 0) this.coral(x + 20, 735, h + 10, '#103f46', i + 2);
    }
    const g = c.createLinearGradient(0, 690, 0, 720); g.addColorStop(0, '#071c2500'); g.addColorStop(1, '#071c25a0');
    c.fillStyle = g; c.fillRect(0, 690, 1280, 30);
  }
}

export default Renderer;
