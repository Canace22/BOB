const WIDTH = 1280;
const HEIGHT = 720;
const TAU = Math.PI * 2;
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const noise = (n) => { const v = Math.sin(n * 127.1 + 311.7) * 43758.5453; return v - Math.floor(v); };

export class Renderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d', { alpha: false });
    this.images = {};
    this.dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = WIDTH * this.dpr;
    canvas.height = HEIGHT * this.dpr;
  }

  async load() {
    const files = { title: '00_鲸落全景.png', mouth: '01_鲸口门庭.png', ribs: '08_肋骨穹顶.png', heart: '05_心室潮泵.png' };
    await Promise.all(Object.entries(files).map(async ([key, file]) => {
      const img = new Image();
      const loaded = new Promise((resolve) => { img.onload = resolve; img.onerror = resolve; });
      img.src = new URL(`../${file}`, import.meta.url).href;
      await loaded;
      if (img.complete && img.naturalWidth) this.images[key] = img;
    }));
  }

  draw(state, level) {
    const c = this.ctx;
    c.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    c.globalAlpha = 1;
    c.globalCompositeOperation = 'source-over';
    c.clearRect(0, 0, WIDTH, HEIGHT);
    if (state.mode === 'title' || !level) { this.title(state.time || 0); return; }
    const t = state.time || 0;
    const camera = state.camera?.x || 0;
    this.backdrop(state, level, camera, t);
    c.save();
    if (state.shake > 0) c.translate(Math.sin(t * 113) * state.shake * 4, Math.cos(t * 97) * state.shake * 3);
    c.translate(-camera, 0);
    this.farEcology(state, level, t);
    this.exit(state, level, t);
    for (const p of level.platforms) {
      if (p.x + p.w < camera - 100 || p.x > camera + WIDTH + 100) continue;
      this.platform(p, state, t);
    }
    if (level.gate) this.baleen(level.gate, state, t);
    for (const node of level.nodes || []) this.node(node, state, t);
    for (const memory of level.memories || []) if (!state.collected?.has(memory.id)) this.memory(memory, t);
    if (!(state.room === 2 && state.exitOpen)) {
      for (const hazard of level.hazards || []) this.hazard(hazard, t);
    }
    for (const p of state.pulses || []) this.pulse(p);
    this.player(state.player, t);
    this.particles(state.particles || []);
    c.restore();
    this.atmosphere(camera, t, state.room);
    this.foreground(camera, t, state.room);
  }

  glow(x, y, radius, color, alpha = 1) {
    const c = this.ctx;
    c.save(); c.globalAlpha *= alpha;
    const gradient = c.createRadialGradient(x, y, 0, x, y, radius);
    gradient.addColorStop(0, color); gradient.addColorStop(1, 'transparent');
    c.fillStyle = gradient; c.fillRect(x - radius, y - radius, radius * 2, radius * 2);
    c.restore();
  }

  ellipse(x, y, rx, ry, fill, stroke, width = 1) {
    const c = this.ctx;
    c.beginPath(); c.ellipse(x, y, Math.max(rx, .01), Math.max(ry, .01), 0, 0, TAU);
    if (fill) { c.fillStyle = fill; c.fill(); }
    if (stroke) { c.strokeStyle = stroke; c.lineWidth = width; c.stroke(); }
  }

  cover(image, x, y, w, h) {
    const scale = Math.max(w / image.width, h / image.height);
    this.ctx.drawImage(image, x + (w - image.width * scale) / 2, y + (h - image.height * scale) / 2, image.width * scale, image.height * scale);
  }

  title(t) {
    const c = this.ctx;
    c.fillStyle = '#06131d'; c.fillRect(0, 0, WIDTH, HEIGHT);
    if (this.images.title) this.cover(this.images.title, -8 + Math.sin(t * .1) * 5, -8, 1296, 736);
    const shade = c.createLinearGradient(0, 0, WIDTH, 100);
    shade.addColorStop(0, 'rgba(2,12,20,.83)'); shade.addColorStop(.6, 'rgba(2,12,20,.18)'); shade.addColorStop(1, 'rgba(2,12,20,.06)');
    c.fillStyle = shade; c.fillRect(0, 0, WIDTH, HEIGHT);
    const bottom = c.createLinearGradient(0, 500, 0, 720);
    bottom.addColorStop(0, 'transparent'); bottom.addColorStop(1, 'rgba(1,10,16,.8)');
    c.fillStyle = bottom; c.fillRect(0, 500, WIDTH, 220);
    this.atmosphere(0, t, 0);
  }

  backdrop(state, level, camera, t) {
    const c = this.ctx;
    const heart = state.room === 2;
    const key = ['mouth', 'ribs', 'heart'][state.room] || 'mouth';
    const base = c.createLinearGradient(0, 0, 0, HEIGHT);
    base.addColorStop(0, heart ? '#211a2c' : '#102e3b');
    base.addColorStop(.55, heart ? '#2c253e' : '#164153');
    base.addColorStop(1, '#071c27');
    c.fillStyle = base; c.fillRect(0, 0, WIDTH, HEIGHT);
    const img = this.images[key];
    if (img) {
      c.save(); c.globalAlpha = heart ? .63 : .61;
      // This upper-right environment crop deliberately excludes the painted hero.
      const sx = img.width * .59, sy = img.height * .02, sw = img.width * .41, sh = img.height * .73;
      const drift = camera * .085;
      c.drawImage(img, sx, sy, sw, sh, -120 - drift % 180, -30, 1570, 770);
      c.restore();
    }
    const veil = c.createLinearGradient(0, 0, 0, HEIGHT);
    veil.addColorStop(0, heart ? 'rgba(14,12,27,.28)' : 'rgba(5,25,36,.26)');
    veil.addColorStop(.58, heart ? 'rgba(27,20,42,.38)' : 'rgba(10,40,53,.22)');
    veil.addColorStop(1, '#061925');
    c.fillStyle = veil; c.fillRect(0, 0, WIDTH, HEIGHT);
    this.glow(850 - camera * .08, 250, 560, heart ? '#81546c55' : '#59c5d044', 1);
    c.save(); c.globalCompositeOperation = 'screen';
    for (let i = 0; i < 5; i++) {
      const x = i * 340 + 170 - camera * .13;
      const ray = c.createLinearGradient(x, 0, x - 90, 700);
      ray.addColorStop(0, heart ? '#d5b3bb16' : '#98eeeb1b'); ray.addColorStop(1, 'transparent');
      c.fillStyle = ray; c.beginPath(); c.moveTo(x, 0); c.lineTo(x + 65, 0); c.lineTo(x - 35, 700); c.lineTo(x - 270, 700); c.closePath(); c.fill();
    }
    c.restore();
    if (state.room !== 2) this.ribs(camera, state.room, t);
    else this.heartWalls(camera, t);
    this.fishSchool(260 - camera * .17, 312, 24, t, .32, '#9cc4c3');
    this.fishSchool(1100 - camera * .2, 440, 30, t + 8, .26, '#6d9baf');
  }

  ribs(camera, room, t) {
    const c = this.ctx;
    c.save();
    const spacing = room === 1 ? 340 : 460;
    for (let i = -1; i < 8; i++) {
      const x = i * spacing - camera * .31;
      c.globalAlpha = room === 1 ? .32 : .19;
      const bone = c.createLinearGradient(x - 140, 0, x + 140, 700);
      bone.addColorStop(0, '#a7b2a6'); bone.addColorStop(.45, '#638990'); bone.addColorStop(1, '#123342');
      c.strokeStyle = bone; c.lineWidth = 30 + noise(i + 3) * 20; c.lineCap = 'round';
      c.beginPath(); c.moveTo(x - 100, -100); c.bezierCurveTo(x + 240, 70, x + 150, 360, x - 60, 760); c.stroke();
      c.globalAlpha *= .6; c.strokeStyle = '#b8d7c7'; c.lineWidth = 2;
      c.beginPath(); c.moveTo(x - 96, -100); c.bezierCurveTo(x + 220, 70, x + 130, 360, x - 70, 760); c.stroke();
    }
    if (room === 0) {
      c.globalAlpha = .22;
      for (let i = 0; i < 90; i++) {
        const x = i * 28 - (camera * .22) % 28;
        const length = 120 + noise(i + 10) * 220;
        c.strokeStyle = i % 3 === 0 ? '#8db9b5' : '#4d7779'; c.lineWidth = 1 + noise(i) * 3;
        c.beginPath(); c.moveTo(x, -20); c.quadraticCurveTo(x + 15, length * .5, x + Math.sin(t * .5 + i) * 9, length); c.stroke();
      }
    }
    c.restore();
  }

  heartWalls(camera, t) {
    const c = this.ctx;
    c.save(); c.globalAlpha = .24;
    for (let i = 0; i < 9; i++) {
      const x = i * 350 - camera * .25;
      c.strokeStyle = '#b47b8b'; c.lineWidth = 11;
      c.beginPath(); c.moveTo(x - 80, -30); c.bezierCurveTo(x + 150, 80, x - 100, 220, x + 120, 400); c.bezierCurveTo(x + 260, 490, x + 130, 650, x + 200, 740); c.stroke();
      c.strokeStyle = '#3d263f'; c.lineWidth = 6; c.stroke();
    }
    c.restore();
    this.glow(650, 400, 420, '#b15c6c18', .85 + Math.sin(t * 2.1) * .15);
  }

  farEcology(state, level, t) {
    const c = this.ctx;
    for (let i = 0; i < 7; i++) {
      const x = 210 + i * 355 + Math.sin(t * .18 + i) * 35;
      const y = 140 + noise(i + 4) * 240 + Math.sin(t * .6 + i) * 12;
      this.jellyfish(x, y, 10 + noise(i) * 10, t + i, .36);
    }
    if (state.room === 2 && (state.exitOpen || (level.nodes || []).filter(n => n.kind === 'valve').every(n => state.activated?.has(n.id)))) {
      for (let i = 0; i < 4; i++) {
        const x = ((t * (90 + i * 12) + i * 470) % (level.width + 250)) - 100;
        const y = 310 + Math.sin(x * .003 + i) * 90;
        this.fishSchool(x, y, 24, t + i, .8, '#b6e1cb');
      }
    }
    c.globalAlpha = 1;
  }

  platform(p, state, t) {
    const c = this.ctx;
    const available = !p.requires || state.activated?.has(p.requires);
    const echo = p.kind === 'echo';
    if (echo && !available) {
      c.save(); c.strokeStyle = '#97e5d42c'; c.lineWidth = 1.5; c.setLineDash([5, 12]);
      c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x + p.w, p.y); c.stroke(); c.restore();
      return;
    }
    if (!available) return;
    const flesh = p.kind === 'flesh';
    const h = Math.max(p.h, 28);
    c.save();
    if (echo) {
      this.glow(p.x + p.w / 2, p.y + 5, p.w * .8, '#64e9cd21');
      const fill = c.createLinearGradient(0, p.y, 0, p.y + 35);
      fill.addColorStop(0, '#a5f9df9c'); fill.addColorStop(1, '#468d9222');
      c.fillStyle = fill; c.fillRect(p.x, p.y, p.w, 20);
      c.strokeStyle = '#b5ffe4'; c.lineWidth = 2;
      c.beginPath(); c.moveTo(p.x, p.y); c.lineTo(p.x + p.w, p.y); c.stroke();
      for (let x = p.x + 12; x < p.x + p.w; x += 25) {
        c.strokeStyle = '#c3fff046'; c.beginPath(); c.ellipse(x, p.y + 10, 4 + Math.sin(t * 3 + x) * 1.5, 17, 0, 0, TAU); c.stroke();
      }
      c.restore(); return;
    }
    const body = c.createLinearGradient(0, p.y, 0, p.y + h);
    body.addColorStop(0, flesh ? '#7d5a70' : '#939f95');
    body.addColorStop(.14, flesh ? '#493b54' : '#4f696c');
    body.addColorStop(.75, flesh ? '#272536' : '#233f48');
    body.addColorStop(1, '#0a212c');
    c.beginPath(); c.moveTo(p.x, p.y + 6); c.quadraticCurveTo(p.x + 10, p.y - 1, p.x + 24, p.y);
    c.lineTo(p.x + p.w - 18, p.y); c.quadraticCurveTo(p.x + p.w + 3, p.y + 1, p.x + p.w, p.y + 18);
    c.lineTo(p.x + p.w - 9, p.y + h * .65);
    for (let x = p.x + p.w - 15; x > p.x + 8; x -= 27) c.lineTo(x, p.y + h * (.5 + noise(x) * .5));
    c.lineTo(p.x, p.y + 12); c.closePath(); c.fillStyle = body; c.fill();
    c.save(); c.clip();
    for (let i = 0; i < Math.ceil(p.w / 22); i++) {
      const x = p.x + i * 22;
      c.strokeStyle = flesh ? '#bd89921c' : '#b3c9ba20'; c.lineWidth = 1;
      c.beginPath(); c.moveTo(x, p.y + 7); c.bezierCurveTo(x - 18, p.y + 25, x + 18, p.y + 46, x - 4, p.y + h); c.stroke();
      if (i % 3 === 0) { this.ellipse(x + 7, p.y + 20 + noise(i) * 14, 8, 3, '#061b244a'); }
    }
    c.restore();
    const rim = c.createLinearGradient(p.x, 0, p.x + p.w, 0);
    rim.addColorStop(0, flesh ? '#bb939a' : '#b7c8b5'); rim.addColorStop(.5, flesh ? '#f0c0b0' : '#e1e3c7'); rim.addColorStop(1, flesh ? '#9c7e88' : '#92b4a9');
    c.strokeStyle = rim; c.lineWidth = 3; c.lineCap = 'round';
    c.beginPath(); c.moveTo(p.x + 5, p.y + 2); c.quadraticCurveTo(p.x + 13, p.y, p.x + 25, p.y + 1); c.lineTo(p.x + p.w - 13, p.y + 1); c.stroke();
    for (let i = 0; i < Math.ceil(p.w / 27); i++) {
      const x = p.x + 10 + i * 27 + noise(i + p.x) * 10;
      if (x > p.x + p.w - 8) continue;
      const length = 6 + noise(x + 4) * 15;
      const sway = Math.sin(t * .9 + x) * 2;
      c.strokeStyle = flesh ? '#9bb8a161' : '#7fd1bb73'; c.lineWidth = 1;
      c.beginPath(); c.moveTo(x, p.y); c.quadraticCurveTo(x - 2, p.y - length / 2, x + sway, p.y - length); c.stroke();
      this.ellipse(x + sway, p.y - length, 2.2, 2.8, flesh ? '#dbbfbc' : '#a8e5c9');
      if (i % 4 === 0) this.glow(x, p.y - length, 17, '#88f3be2b');
    }
    for (let i = 0; i < p.w / 43; i++) {
      const x = p.x + 20 + i * 43;
      const y = p.y + h * .55;
      c.strokeStyle = '#091d24a8'; c.lineWidth = 2;
      c.beginPath(); c.moveTo(x, y); c.bezierCurveTo(x - 12, y + 28, x + Math.sin(t + i) * 5, y + 35, x - 7, y + 54 * noise(x)); c.stroke();
    }
    c.restore();
  }

  node(node, state, t) {
    const c = this.ctx;
    const active = state.activated?.has(node.id);
    const color = active ? '#9debc7' : '#edcda1';
    const pulse = .75 + Math.sin(t * 2.5 + node.x) * .25;
    this.glow(node.x, node.y, active ? 92 : 65, active ? '#8df3bc38' : '#f7c68b35', pulse);
    c.save(); c.translate(node.x, node.y);
    if (node.kind === 'valve') {
      this.ellipse(0, 0, 28, 34, '#473649', '#b99a9e', 3);
      for (let i = 0; i < 3; i++) {
        c.save(); c.rotate(i * TAU / 3 + (active ? .55 : 0));
        c.fillStyle = active ? '#628f84' : '#c2a8a0';
        c.beginPath(); c.moveTo(active ? 8 : 0, 1); c.bezierCurveTo(-23, -18, -11, -34, 7, -27); c.quadraticCurveTo(25, -12, active ? 8 : 0, 1); c.fill(); c.restore();
      }
      this.ellipse(0, 0, active ? 10 : 4, active ? 14 : 4, active ? '#72d3bb' : '#e9d4bd');
    } else {
      c.strokeStyle = '#a8b8a4'; c.lineWidth = 8; c.lineCap = 'round';
      c.beginPath(); c.moveTo(-17, 22); c.quadraticCurveTo(-35, -10, -10, -31); c.moveTo(17, 22); c.quadraticCurveTo(35, -10, 10, -31); c.stroke();
      c.lineWidth = 2; c.strokeStyle = color;
      for (let i = -1; i <= 1; i++) { c.beginPath(); c.moveTo(i * 9, -23); c.quadraticCurveTo(i * 9 + Math.sin(t * 3 + i) * (active ? 1 : 3), 0, i * 9, 24); c.stroke(); }
      this.ellipse(0, 0, 6, 6, color);
    }
    c.strokeStyle = active ? '#a8efd390' : '#e9cdab85'; c.lineWidth = 1;
    c.beginPath(); c.arc(0, 0, 39 + Math.sin(t * 1.8) * 2, -.2, Math.PI * 1.45); c.stroke();
    if (active) {
      c.strokeStyle = '#d2ffdc'; c.lineWidth = 2; c.beginPath(); c.moveTo(-5, 0); c.lineTo(-1, 4); c.lineTo(7, -5); c.stroke();
    }
    c.restore();
    const p = state.player;
    if (!active && p && Math.hypot(p.x + p.w / 2 - node.x, p.y + p.h / 2 - node.y) < 145) {
      c.save(); c.font = '11px "PingFang SC", sans-serif'; c.textAlign = 'center';
      const text = node.label || '共鸣'; const w = c.measureText(text).width + 22;
      c.fillStyle = '#09232fe8'; c.beginPath(); c.roundRect(node.x - w / 2, node.y - 67, w, 25, 12); c.fill();
      c.fillStyle = '#e0dec5'; c.fillText(text, node.x, node.y - 50); c.restore();
    }
  }

  memory(m, t) {
    const c = this.ctx;
    const y = m.y + Math.sin(t * 1.8 + m.x) * 5;
    this.glow(m.x, y, 53, '#efbf7753');
    this.glow(m.x, y, 20, '#ffe0a09a');
    this.ellipse(m.x, y, 10, 13, '#f4d4942b', '#ffe5b2c9');
    c.save(); c.translate(m.x, y); c.rotate(Math.sin(t) * .15);
    c.fillStyle = '#fff0cf'; c.beginPath(); c.moveTo(0, -7); c.lineTo(4, 0); c.lineTo(0, 7); c.lineTo(-4, 0); c.closePath(); c.fill();
    c.strokeStyle = '#f3d29b6e'; c.lineWidth = .8;
    c.beginPath(); c.ellipse(0, 0, 19, 5, t * .3, 0, TAU); c.stroke(); c.restore();
    for (let i = 0; i < 4; i++) { const angle = t * .5 + i * TAU / 4; this.ellipse(m.x + Math.cos(angle) * 22, y + Math.sin(angle) * 18, 1, 1, '#ffedc4'); }
  }

  baleen(gate, state, t) {
    const c = this.ctx;
    const open = state.activated?.has(gate.nodeId) || state.gateOpen;
    const length = open ? Math.min(50, gate.h * .18) : gate.h;
    this.glow(gate.x + gate.w / 2, gate.y + gate.h / 2, 160, open ? '#92ecc917' : '#ddcb9322');
    c.save();
    for (let i = 0; i < gate.w / 7; i++) {
      const x = gate.x + i * 7;
      const end = gate.y + length - noise(i + 23) * 24;
      const g = c.createLinearGradient(0, gate.y, 0, gate.y + length);
      g.addColorStop(0, '#78918a'); g.addColorStop(.65, '#b9c1a1'); g.addColorStop(1, '#f1dfb2');
      c.strokeStyle = g; c.lineWidth = i % 3 ? 2 : 4;
      c.beginPath(); c.moveTo(x, gate.y); c.bezierCurveTo(x + 7, gate.y + length * .33, x - 7, gate.y + length * .66, x + Math.sin(t * 1.2 + i * .5) * 3, end); c.stroke();
      if (i % 3 === 0) this.ellipse(x, end - 9, 2, 3, '#d6eeb9');
    }
    c.restore();
  }

  exit(state, level, t) {
    const c = this.ctx;
    const x = level.exit.x, y = level.exit.y;
    const ready = state.room !== 2 || state.exitOpen;
    this.glow(x, y - 32, 145, ready ? '#83e7d139' : '#aa809423');
    c.save(); c.translate(x, y - 40);
    this.ellipse(0, 0, 42, 85, '#082530bc', ready ? '#94cbb282' : '#b798a449', 9);
    c.strokeStyle = ready ? '#beead094' : '#a8a4aa38'; c.lineWidth = 2;
    c.beginPath(); c.ellipse(0, 0, 34, 76, 0, -Math.PI * .55, Math.PI * .56); c.stroke();
    if (ready) {
      for (let i = 0; i < 8; i++) {
        const py = 70 - ((t * 20 + i * 23) % 140);
        this.ellipse(Math.sin(i * 3 + t) * 20, py, 1.3, 1.3, '#c4ffe1a1');
      }
      c.strokeStyle = '#c8f4df'; c.lineWidth = 2; c.beginPath(); c.moveTo(-8, -6); c.lineTo(1, 0); c.lineTo(-8, 6); c.stroke();
    } else {
      c.strokeStyle = '#9c849c'; c.lineWidth = 4;
      for (let i = -2; i <= 2; i++) { c.beginPath(); c.moveTo(-25, i * 24); c.quadraticCurveTo(0, i * 16 + 9, 25, i * 24); c.stroke(); }
    }
    c.restore();
  }

  jellyfish(x, y, size, t, opacity = .55, dangerous = false) {
    const c = this.ctx;
    const color = dangerous ? '#e5a1bd' : '#a8e2e2';
    c.save(); c.globalAlpha = opacity;
    this.glow(x, y, size * 3.8, dangerous ? '#ee8fbf2d' : '#9adfe326');
    const r = size * (1 + Math.sin(t * 2) * .05);
    const g = c.createLinearGradient(x, y - r, x, y + r * .3);
    g.addColorStop(0, dangerous ? '#d9a6bd76' : '#c4ffff67'); g.addColorStop(1, dangerous ? '#824b8050' : '#5d9faf23');
    c.beginPath(); c.moveTo(x - r, y); c.bezierCurveTo(x - r, y - r * 1.4, x + r, y - r * 1.4, x + r, y); c.quadraticCurveTo(x, y + r * .35, x - r, y); c.fillStyle = g; c.fill();
    c.strokeStyle = color; c.lineWidth = 1; c.stroke();
    for (let i = 0; i < 6; i++) {
      const px = x - r * .75 + i * r * .3;
      const length = r * (1.6 + noise(i) * 1.8);
      c.strokeStyle = `${color}a8`; c.lineWidth = .7;
      c.beginPath(); c.moveTo(px, y); c.bezierCurveTo(px + Math.sin(t + i) * 10, y + length * .35, px + Math.cos(t + i) * 8, y + length * .7, px + Math.sin(t * .6 + i) * 12, y + length); c.stroke();
    }
    this.ellipse(x, y - r * .25, r * .2, r * .13, color);
    c.restore();
  }

  hazard(h, t) {
    const x = h.x + Math.sin(t * (h.speed || 1)) * (h.range || 0);
    this.jellyfish(x, h.y, h.r || 20, t, .95, true);
  }

  fishSchool(x, y, count, t, opacity, color) {
    const c = this.ctx;
    c.save(); c.globalAlpha = opacity; c.fillStyle = color;
    for (let i = 0; i < count; i++) {
      const fx = x + noise(i + 90) * 180 + Math.sin(t * .4 + i) * 5;
      const fy = y + (noise(i + 110) - .5) * 70 + Math.sin(t + i) * 3;
      const s = 2 + noise(i) * 3;
      c.beginPath(); c.moveTo(fx + s * 1.6, fy); c.quadraticCurveTo(fx, fy - s, fx - s, fy); c.lineTo(fx - s * 2, fy - s * .7); c.lineTo(fx - s * 2, fy + s * .7); c.lineTo(fx - s, fy); c.quadraticCurveTo(fx, fy + s, fx + s * 1.6, fy); c.fill();
    }
    c.restore();
  }

  pulse(p) {
    const c = this.ctx;
    const age = p.age || 0;
    const alpha = clamp(1 - age / .85, 0, 1);
    c.save(); c.globalAlpha = alpha; c.strokeStyle = '#ccffe6'; c.lineWidth = 2;
    for (let i = 0; i < 3; i++) {
      const r = Math.max(1, age * 210 - i * 18);
      c.globalAlpha = alpha * (1 - i * .2); c.beginPath(); c.arc(p.x, p.y, r, 0, TAU); c.stroke();
    }
    this.glow(p.x, p.y, 130, '#a8ffd82b', alpha);
    c.restore();
  }

  player(p, t) {
    if (!p) return;
    const c = this.ctx;
    const facing = p.facing || 1;
    const speed = Math.min(Math.abs(p.vx || 0) / 180, 1);
    const step = Math.sin(t * 13) * speed;
    const bob = p.grounded ? Math.abs(step) * 1.8 : -2;
    const cx = p.x + p.w / 2, cy = p.y + p.h / 2;
    this.glow(cx + facing * 19, cy + 9, 98, '#ffc77b25');
    this.glow(cx, cy - 10, 38, '#b2e4d51c');
    c.save(); c.translate(cx, p.y + bob); c.scale(facing, 1);
    if (p.invulnerable && Math.floor(t * 14) % 2) c.globalAlpha = .5;
    this.ellipse(0, p.h + 2, 18, 4, '#03151d50');
    c.lineCap = 'round'; c.lineJoin = 'round';
    c.strokeStyle = '#101e25'; c.lineWidth = 7;
    c.beginPath(); c.moveTo(-5, 35); c.lineTo(-6 - step * 5, 48); c.lineTo(-3 - step * 7, 53); c.moveTo(5, 35); c.lineTo(7 + step * 6, 48); c.lineTo(11 + step * 7, 52); c.stroke();
    c.strokeStyle = '#729389'; c.lineWidth = 1.2;
    c.beginPath(); c.moveTo(-6 - step * 5, 47); c.lineTo(-3 - step * 7, 51); c.moveTo(7 + step * 6, 47); c.lineTo(11 + step * 7, 50); c.stroke();
    const tail = -14 - speed * 12;
    const flutter = Math.sin(t * 5) * 3;
    const cloak = c.createLinearGradient(-30, 10, 15, 40);
    cloak.addColorStop(0, '#173d49'); cloak.addColorStop(.5, '#225865'); cloak.addColorStop(1, '#0c2935');
    c.fillStyle = cloak; c.beginPath(); c.moveTo(-8, 14); c.bezierCurveTo(-15, 25, tail + 3, 33 + flutter, tail - 7, 42 + flutter); c.lineTo(tail + 9, 40); c.lineTo(-9, 46); c.lineTo(-2, 39); c.lineTo(14, 39); c.lineTo(9, 16); c.closePath(); c.fill();
    c.strokeStyle = '#70a5a0'; c.lineWidth = 1; c.beginPath(); c.moveTo(-7, 17); c.quadraticCurveTo(-11, 31, tail - 2, 39 + flutter); c.moveTo(-3, 21); c.lineTo(-7, 38); c.stroke();
    c.strokeStyle = '#a49c7d'; c.lineWidth = 2; c.beginPath(); c.moveTo(7, 18); c.lineTo(-6, 36); c.stroke();
    c.fillStyle = '#163e49'; c.beginPath(); c.ellipse(0, 12, 13, 15, -.15, 0, TAU); c.fill();
    c.strokeStyle = '#739d98'; c.lineWidth = 1.2; c.beginPath(); c.arc(0, 12, 12, Math.PI * .85, Math.PI * 1.85); c.stroke();
    c.save(); c.translate(6, 12); c.rotate(-.08);
    this.ellipse(0, 0, 9, 11, '#e1d9b7', '#b4bda5', 1.5);
    this.ellipse(2, 0, 5.5, 7.5, '#17313b', '#8a9e94', 1);
    this.ellipse(3, -2, 2.2, 3.2, '#91c6c048'); c.restore();
    c.strokeStyle = '#22414c'; c.lineWidth = 6; c.beginPath(); c.moveTo(8, 23); c.lineTo(14, 30); c.lineTo(21, 26); c.stroke();
    c.strokeStyle = '#c7c7a7'; c.lineWidth = 2; c.beginPath(); c.moveTo(22, 29); c.lineTo(24, 10); c.moveTo(24, 16); c.quadraticCurveTo(17, 13, 20, 6); c.moveTo(24, 16); c.quadraticCurveTo(30, 14, 29, 6); c.stroke();
    const lampY = 34 + Math.sin(t * 6) * speed * 2;
    c.strokeStyle = '#a99a6b'; c.lineWidth = 1.1; c.beginPath(); c.moveTo(11, 28); c.lineTo(14, lampY + 3); c.stroke();
    this.glow(14, lampY + 6, 26, '#ffc56b9c');
    c.fillStyle = '#ca9d59'; c.fillRect(9, lampY, 10, 13); c.fillStyle = '#ffe3a2'; c.fillRect(11, lampY + 2, 6, 8);
    c.fillStyle = '#573f26'; c.fillRect(8, lampY - 1, 12, 2); c.fillRect(9, lampY + 12, 10, 2);
    c.restore();
  }

  particles(particles) {
    const c = this.ctx;
    c.save();
    for (const p of particles) {
      c.globalAlpha = clamp(1 - p.age / p.life, 0, 1);
      this.ellipse(p.x, p.y, 1.7, 1.7, p.color || '#d2ffdc');
    }
    c.restore();
  }

  atmosphere(camera, t, room) {
    const c = this.ctx;
    c.save();
    for (let i = 0; i < 65; i++) {
      const x = ((noise(i + 64) * 1400 - camera * (.04 + noise(i) * .09) + Math.sin(t * .3 + i) * 13) % 1400 + 1400) % 1400 - 60;
      const y = ((noise(i + 47) * 800 - t * (3 + noise(i) * 8)) % 800 + 800) % 800 - 40;
      const size = .7 + noise(i + 10) * 1.5;
      c.globalAlpha = .15 + noise(i) * .3;
      this.ellipse(x, y, size, size, room === 2 ? '#e3c4ce' : '#bce8e1');
    }
    c.globalAlpha = 1;
    const vignette = c.createRadialGradient(640, 340, 240, 640, 340, 820);
    vignette.addColorStop(0, 'transparent'); vignette.addColorStop(.72, 'rgba(0,12,22,.05)'); vignette.addColorStop(1, 'rgba(0,8,17,.54)');
    c.fillStyle = vignette; c.fillRect(0, 0, WIDTH, HEIGHT);
    c.restore();
  }

  foreground(camera, t, room) {
    const c = this.ctx;
    c.save();
    for (let i = 0; i < 30; i++) {
      const x = i * 74 - (camera * 1.15) % 74;
      const h = 23 + noise(i + 25) * 70;
      c.strokeStyle = room === 2 ? '#141c2be8' : '#08242ee8'; c.lineWidth = 3 + noise(i) * 4;
      c.lineCap = 'round'; c.beginPath(); c.moveTo(x, 735); c.quadraticCurveTo(x + 10, 710 - h / 2, x + Math.sin(t * .6 + i) * 7, 720 - h); c.stroke();
      if (i % 3 === 0) {
        c.strokeStyle = '#4a8e8144'; c.lineWidth = 1; c.stroke();
        this.ellipse(x + Math.sin(t * .6 + i) * 7, 720 - h, 3, 4, '#83c6ad55');
      }
    }
    const gradient = c.createLinearGradient(0, 665, 0, HEIGHT);
    gradient.addColorStop(0, 'transparent'); gradient.addColorStop(1, '#04141ed9');
    c.fillStyle = gradient; c.fillRect(0, 665, WIDTH, 55); c.restore();
  }
}
