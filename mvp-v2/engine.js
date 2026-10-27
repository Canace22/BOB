import { rooms } from './levels.js';
import { getLiftPosition, getSwingPosition } from './mechanics.js';
import { HABITATS, getHabitatStatus } from './ecology.js';
import { followTerrain, terrainLanding } from './terrain.js';

export const SAVE_KEY = 'whalefall-v2-2d-save';
const clamp = (n, a, b) => Math.min(b, Math.max(a, n));
const overlap = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
const flagNames = new Set(['short-gate', 'long-gate', 'food', 'fed', 'drain', 'float', 'shortcut', 'finished', 'course-climb', 'course-lift', 'course-swing', ...rooms.flatMap(r => r.objects.map(o => o.id))]);
const memoryNames = new Set(rooms.flatMap(r => r.memories.map(m => m.id)));
export function validateSave(value) {
  if (!value || value.version !== 2 || !Number.isInteger(value.room) || !rooms[value.room]) return null;
  if (![value.flags, value.memories, value.abilities, value.visited].every(Array.isArray)) return null;
  if (value.flags.some(f => !flagNames.has(f)) || value.memories.some(m => !memoryNames.has(m)) || value.abilities.some(a => a !== 'float')) return null;
  if (value.visited.some(r => !Number.isInteger(r) || !rooms[r])) return null;
  if (value.habitats !== undefined) {
    if (!value.habitats || typeof value.habitats !== 'object' || Object.getPrototypeOf(value.habitats) !== Object.prototype) return null;
    if (Object.entries(value.habitats).some(([id, seconds]) => {
      const habitat = HABITATS.find(h => h.id === id);
      return !habitat || !Number.isFinite(seconds) || seconds < 0 || seconds > habitat.duration;
    })) return null;
  }
  if (value.checkpoint) {
    const r = rooms[value.room], cp = value.checkpoint;
    const safe = [r.spawn, ...(r.checkpoints || []), ...r.objects.filter(o => o.type === 'camp').map(o => ({ x: o.x - 15, y: o.y - 48 })),
      ...rooms.flatMap(room => room.exits.filter(e => e.to === value.room && e.spawn).map(e => e.spawn)), { x: r.width - 220, y: 532 }];
    if (cp.room !== value.room || !safe.some(p => p.x === cp.x && p.y === cp.y)) return null;
  }
  return value;
}

export class Game {
  constructor(onEvent = () => {}) {
    this.onEvent = onEvent;
    this.state = this.fresh();
    this.previous = {};
  }
  fresh() {
    return { mode: 'title', time: 0, elapsed: 0, room: 0, camera: { x: 0 },
      player: { x: 150, y: 532, w: 30, h: 48, vx: 0, vy: 0, facing: 1, grounded: true, climbing: null, riding: null, swinging: null, swingLock: 0, launchVx: 0 },
      course: { climb: false, lift: false, swing: false, clear: false },
      flags: new Set(), memories: new Set(), abilities: new Set(), visited: new Set([0]), habitats: {},
      pressure: 1, charge: 0, pulses: [], particles: [], hint: '', respawnFlash: 0,
      checkpoint: { room: 0, x: 150, y: 532 }, deaths: 0, softTime: 0, softDown: 0, cooldown: 0,
    };
  }
  event(type, message) { this.onEvent(type, message); }
  start(save = null) {
    this.state = this.fresh();
    const valid = validateSave(save);
    if (valid) {
      for (const key of ['flags', 'memories', 'abilities', 'visited']) this.state[key] = new Set(valid[key]);
      this.state.habitats = { ...valid.habitats };
      for (const key of ['climb', 'lift', 'swing', 'clear']) this.state.course[key] = this.state.flags.has(`course-${key}`);
      this.state.elapsed = Number.isFinite(valid.elapsed) ? Math.max(0, valid.elapsed) : 0;
      this.state.deaths = Number.isFinite(valid.deaths) ? Math.max(0, valid.deaths) : 0;
    }
    this.state.mode = 'playing';
    this.enter(valid?.room || 0, valid?.checkpoint);
    this.previous = {};
    this.event('toast', valid ? '营地已点亮。继续这段旅程。' : 'A / D 移动 · 空格跳跃 · 靠近鲸须，轻按并松开 E。');
  }
  serialize() {
    const s = this.state;
    return { version: 2, room: s.checkpoint.room, checkpoint: { ...s.checkpoint }, flags: [...s.flags], memories: [...s.memories], abilities: [...s.abilities], visited: [...s.visited], habitats: { ...s.habitats }, elapsed: s.elapsed, deaths: s.deaths };
  }
  enter(index, spawn) {
    const s = this.state, r = rooms[index];
    s.room = index; s.visited.add(index);
    Object.assign(s.player, spawn || r.spawn, { vx: 0, vy: 0, grounded: false, climbing: null, riding: null, swinging: null, swingLock: 0, launchVx: 0, climbDistance: 0, liftDistance: 0 });
    s.checkpoint = { room: index, ...(spawn || r.spawn) };
    s.camera.x = clamp(s.player.x - 400, 0, r.width - 1280);
    s.charge = 0; s.pressure = 1; s.softTime = 0; s.softDown = 0; s.pulses = [];
    this.event('save'); this.event('room', r.name);
  }
  near(object, radius = 105) {
    const p = this.state.player;
    return Math.abs(p.x + p.w / 2 - object.x) < radius && Math.abs(p.y + p.h - object.y) < 90;
  }
  objective() {
    const s = this.state, f = s.flags;
    if (s.room === 3 && !f.has('course-clear')) {
      if (!f.has('course-climb')) return '第一段：靠近菌丝网按 W / S 攀爬，登上启动台';
      if (!f.has('course-powered')) return '在上层转动阀门，启动浮囊升降台';
      if (!f.has('course-lift')) return '第二段：跳上浮囊升降台，搭乘它升向高处';
      if (!f.has('course-swing')) return '第三段：靠近骨环按 F 抓握，向右荡起时按空格跃出';
      return '抵达右侧高台，按 F 拉下通路拉杆';
    }
    if (f.has('finished')) {
      const current = HABITATS.find(h => h.room === s.room && getHabitatStatus(s, h.id).phase !== 'restored');
      const next = current || HABITATS.find(h => getHabitatStatus(s, h.id).phase !== 'restored');
      if (next) return getHabitatStatus(s, next.id).phase === 'recovering'
        ? `${next.name}正在恢复，可以先探索，再回访${rooms[next.room].name}`
        : `回访${rooms[next.room].name}，修复${next.name} · M 查看地图`;
      if (s.memories.size < memoryNames.size) return `栖息地已全部恢复，再寻找 ${memoryNames.size - s.memories.size} 枚记忆 · M 查看地图`;
      return '四枚记忆与三处栖息地已全部完成，沿旧路看看新生的居民';
    }
    if (s.memories.has('return') && f.has('shortcut')) return '回到鲸口起点的贝壳营地，完成旅程';
    if (f.has('shortcut')) return '沿裂隙返回鲸口高台，找回仰望过的记忆';
    if (s.abilities.has('float')) return '补充压力，分两段浮升，打开肺缘高处裂隙';
    if (f.has('drain')) return '穿过肋骨游廊的攀爬设施，在肺缘寻找共生浮膜';
    if (f.has('fed')) return '转动胃瓣排流，打开通往肺缘的路';
    if (f.has('long-gate')) return '前往胃库，拾取腐屑并投喂占道尸蟹';
    if (f.has('short-gate')) return '继续向右；按住 E 蓄满，松开长鸣开启第二道鲸须';
    return '靠近第一道鲸须，轻按并松开 E 发出短鸣';
  }
  context() {
    const s = this.state, r = rooms[s.room];
    if (s.room === 3 && s.player.y > 590 && s.player.x > 720 && s.flags.has('course-lift')) return '[ F ] 从安全网返回最近攀爬检查点';
    if (s.player.swinging) return '随骨环向右摆荡 · 空格借力跃出 · F 松手';
    if (s.player.climbing) return 'W / S 上下攀爬 · 空格蹬离菌丝网';
    if ((r.swings || []).some(ring => this.nearRing(ring))) return '[ F ] 抓住摆荡骨环 · 空格借力跳出';
    if ((r.climbs || []).some(net => overlap(s.player, { ...net, x: net.x - 25, w: net.w + 50 }))) return '[ W / S ] 抓住菌丝网攀爬';
    if (s.player.riding) return '站稳搭乘浮囊 · 到达高处后向右跳上肋骨台';
    for (const g of r.gates) {
      if (!s.flags.has(g.id) && this.near({ x: g.x, y: g.y + g.h }, 190)) return g.kind === 'short' ? '轻按 E 再松开 · 短鸣分开鲸须' : '按住 E 至环纹蓄满，松开 · 长鸣';
    }
    const object = r.objects.find(o => this.near(o) && (!s.flags.has(o.id) || ['camp', 'refill', 'valve', 'course-reset', 'habitat'].includes(o.type)));
    if (object) {
      if (object.type === 'habitat') {
        const habitat = HABITATS.find(h => h.id === object.id), status = getHabitatStatus(s, object.id);
        if (status.phase === 'restored') return `${habitat.name}已恢复 · ${habitat.resident}已经安居`;
        if (status.phase === 'recovering') return `${habitat.name}恢复中 · ${Math.round(status.progress * 100)}% · 可以先去探索，稍后回访`;
        return s.flags.has(habitat.requires) ? `[ F ] 修复${habitat.name} · 等待${habitat.resident}归来` : habitat.hint;
      }
      if (object.type === 'refill' && !s.abilities.has('float')) return '这处压力囊能为浮膜充压。记住它的位置。';
      if (object.type === 'camp' && s.room === 0 && s.memories.has('return') && s.flags.has('shortcut') && !s.flags.has('finished')) return '[ F ] 在贝壳营地休息 · 完成旅程';
      if (object.type === 'crab' && !s.flags.has('food')) return '尸蟹正在进食。先在左侧拾取腐屑。';
      return `[ F ] ${object.label}`;
    }
    const exit = r.exits.find(e => this.near(e, 90));
    if (exit) return exit.requires && !s.flags.has(exit.requires) ? '先完成本区域机关，通路才会开放' : `[ F ] ${exit.label}`;
    if (s.room === 0 && s.player.x > 690 && s.player.x < 900) return '舌面正在下陷 · 空格浮跃，或快速通过';
    if (s.abilities.has('float') && s.room === 2) return '在压力囊旁按 F 充压 · 按住 Shift 浮升 · 松开落脚';
    return '';
  }
  resonate() {
    const s = this.state;
    if (s.cooldown > 0) { s.charge = 0; return; }
    const long = s.charge >= 0.95;
    s.pulses.push({ x: s.player.x + 15, y: s.player.y + 20, age: 0, long });
    s.cooldown = 0.45;
    this.event('sound', long ? 'long' : 'short');
    const g = rooms[s.room].gates.find(g => !s.flags.has(g.id) && this.near({ x: g.x, y: g.y + g.h }, 200));
    if (g) {
      if ((g.kind === 'long') === long) {
        s.flags.add(g.id); this.event('save');
        this.event('toast', long ? '长鸣让第二道鲸须展开。沿着水流继续。' : '鲸须回应了短鸣。那处高台，等找到浮膜再回来。');
      } else this.event('toast', g.kind === 'long' ? '环纹尚未重合。按住 E 至蓄满，再松开。' : '这道纹路很短。轻按并松开 E 即可。');
    }
    s.charge = 0;
  }
  interact() {
    const s = this.state, r = rooms[s.room];
    if (s.room === 3 && s.player.y > 590 && s.player.x > 720 && s.flags.has('course-lift')) { this.respawn(); return; }
    if (s.player.swinging) { this.releaseSwing(false); return; }
    const ring = (r.swings || []).find(ring => this.nearRing(ring));
    if (ring && s.player.swingLock <= 0) {
      Object.assign(s.player, { swinging: ring.id, climbing: null, riding: null, grounded: false, swingTime: 0, launchVx: 0 });
      this.event('sound', 'interact'); return;
    }
    const o = r.objects.find(o => this.near(o) && (!s.flags.has(o.id) || ['camp', 'refill', 'valve', 'course-reset', 'habitat'].includes(o.type)));
    if (o) {
      switch (o.type) {
        case 'course-power': s.flags.add(o.id); this.event('toast', '浮囊开始往复升降。等它靠近，跳上去一起升高。'); break;
        case 'course-reset': this.respawn(); return;
        case 'course-finish':
          if (!['climb', 'lift', 'swing'].every(key => s.flags.has(`course-${key}`))) {
            this.event('toast', '通路需要三处设施的回声：攀爬菌丝网、搭乘浮囊、摆荡骨环。'); return;
          }
          this.courseMark('clear'); this.event('toast', '攀爬通路已打通！右侧通往肺缘浮庭。'); break;
        case 'camp':
          s.checkpoint = { room: s.room, x: o.x - 15, y: o.y - 48 }; s.pressure = 1;
          if (s.room === 0 && s.memories.has('return') && s.flags.has('shortcut') && !s.flags.has('finished')) {
            s.flags.add('finished'); s.mode = 'ending'; this.event('ending');
          } else this.event('toast', '已在贝壳营地休息，旅程已保存。');
          break;
        case 'food': s.flags.add('food'); this.event('toast', '带上少量腐屑。靠近尸蟹按 F 放下食物。'); break;
        case 'crab':
          if (!s.flags.has('food')) { this.event('toast', '先去左侧的腐屑堆拾取食物。'); return; }
          s.flags.add('fed'); this.event('toast', '尸蟹挪向食物，清出了软组织通路。'); break;
        case 'valve':
          if (!s.flags.has('fed')) { this.event('toast', '先帮助尸蟹清出通路。'); return; }
          if (s.flags.has('drain')) { s.flags.delete('drain'); this.event('toast', '胃瓣回转，液位升高。可再次按 F 排流。'); }
          else { s.flags.add('drain'); this.event('toast', '胃瓣排流，低槽显露。可以从低处安全通过。'); }
          break;
        case 'float': s.flags.add('float'); s.abilities.add('float'); s.pressure = 1; this.event('toast', '获得共生浮膜！按住 Shift 浮升；压力囊旁按 F 再充。'); break;
        case 'refill':
          if (!s.abilities.has('float')) { this.event('toast', '压力囊轻轻鼓动。找到共生浮膜后再来。'); return; }
          s.pressure = 1; this.event('toast', '浮膜已充压。分段浮升，在侧台松开 Shift 落脚。'); break;
        case 'habitat': {
          const habitat = HABITATS.find(h => h.id === o.id), status = getHabitatStatus(s, o.id);
          if (status.phase === 'restored') { this.event('toast', habitat.restoredText); return; }
          if (status.phase === 'recovering') { this.event('toast', `${habitat.name}正在恢复。可以先去探索，稍后回来看看${habitat.resident}。`); return; }
          if (!s.flags.has(habitat.requires)) { this.event('toast', habitat.hint); return; }
          s.habitats[o.id] = 0;
          this.event('toast', `${habitat.name}开始恢复。继续探索，稍后回访这里的新居民。`);
          break;
        }
        case 'shortcut':
          s.flags.add('shortcut'); this.event('toast', '旧伤裂隙已开放。再向右，按 F 回到鲸口的高台。'); break;
      }
      this.event('sound', 'interact'); this.event('save'); return;
    }
    const exit = r.exits.find(e => this.near(e, 90));
    if (exit) {
      if (exit.requires && !s.flags.has(exit.requires)) { this.event('toast', '这条路仍被阻住。观察本区域的机关。'); return; }
      const backward = exit.to < s.room && !exit.spawn && s.room !== 3;
      this.enter(exit.to, exit.spawn || (backward ? { x: rooms[exit.to].width - 220, y: 532 } : undefined));
    }
  }
  respawn() {
    const s = this.state;
    Object.assign(s.player, { x: s.checkpoint.x, y: s.checkpoint.y, vx: 0, vy: 0, grounded: false, climbing: null, riding: null, swinging: null, swingLock: 0.4, launchVx: 0 });
    s.pressure = 1; s.respawnFlash = 1; s.deaths++; s.charge = 0;
    this.event('toast', '水流把你送回安全处。能力、记忆与已开的通路都还在。');
    this.event('sound', 'recover');
  }
  courseMark(key) {
    const s = this.state;
    if (s.flags.has(`course-${key}`)) return;
    s.flags.add(`course-${key}`); s.course[key] = true;
    this.event('save');
  }
  nearRing(ring) {
    const p = this.state.player, anchor = getSwingPosition(ring, this.state.time);
    return Math.hypot(p.x + p.w / 2 - anchor.x, p.y + 12 - anchor.y) < 100;
  }
  releaseSwing(jump) {
    const s = this.state, p = s.player, ring = (rooms[s.room].swings || []).find(ring => ring.id === p.swinging);
    if (!ring) return;
    const anchor = getSwingPosition(ring, s.time);
    p.launchVx = clamp(anchor.vx, -420, 420); p.vx = p.launchVx;
    p.vy = jump ? clamp(anchor.vy - 400, -560, -300) : anchor.vy;
    p.swinging = null; p.swingLock = 0.45; p.grounded = false;
    if (jump) this.event('sound', 'jump');
  }
  attachedMotion(dt, input) {
    const s = this.state, p = s.player, r = rooms[s.room];
    p.swingLock = Math.max(0, p.swingLock - dt);
    if (p.swinging) {
      if (input.jump && !this.previous.jump) { this.releaseSwing(true); return false; }
      const ring = r.swings.find(ring => ring.id === p.swinging), a = getSwingPosition(ring, s.time);
      p.x = a.x - p.w / 2; p.y = a.y + 8; p.vx = a.vx; p.vy = a.vy; p.floating = false;
      p.swingTime += dt;
      if (p.swingTime >= 0.65) this.courseMark('swing');
      return true;
    }
    if (!p.climbing && (input.up || input.down)) {
      const net = (r.climbs || []).find(net => overlap(p, { x: net.x - 20, y: net.y - 50, w: net.w + 40, h: net.h + 50 }));
      if (net) { p.climbing = net.id; p.climbDistance = 0; p.riding = null; p.launchVx = 0; }
    }
    if (!p.climbing) return false;
    if (input.jump && !this.previous.jump) {
      p.climbing = null; p.vy = -460; p.grounded = false;
      this.event('sound', 'jump'); return false;
    }
    const net = r.climbs.find(net => net.id === p.climbing), oldY = p.y;
    p.x = clamp(p.x + ((input.right ? 1 : 0) - (input.left ? 1 : 0)) * 150 * dt, net.x - 10, net.x + net.w - p.w + 10);
    p.y = clamp(p.y + ((input.down ? 1 : 0) - (input.up ? 1 : 0)) * 170 * dt, net.y - p.h, net.y + net.h - p.h);
    p.climbDistance += Math.max(0, oldY - p.y);
    if (p.climbDistance > 100) this.courseMark('climb');
    p.vx = 0; p.vy = 0; p.floating = false; p.grounded = false;
    if (p.y <= net.y - p.h && !input.down) { p.climbing = null; p.grounded = true; }
    if (p.y >= net.y + net.h - p.h && input.down) { p.climbing = null; p.grounded = true; }
    return true;
  }
  step(dt, input = {}) {
    const s = this.state;
    if (s.mode === 'title' || s.mode === 'playing') s.time += dt;
    if (s.mode !== 'playing') { this.previous = { ...input }; return; }
    s.elapsed += dt; s.cooldown = Math.max(0, s.cooldown - dt); s.respawnFlash = Math.max(0, s.respawnFlash - dt);
    for (const habitat of HABITATS) {
      if (getHabitatStatus(s, habitat.id).phase !== 'recovering') continue;
      s.habitats[habitat.id] = Math.min(habitat.duration, s.habitats[habitat.id] + dt);
      if (s.habitats[habitat.id] >= habitat.duration) {
        s.flags.add(habitat.id);
        this.event('save'); this.event('sound', 'success');
        this.event('toast', `${habitat.name}已恢复，${habitat.resident}已经归来。回访${rooms[habitat.room].name}看看吧。`);
      }
    }
    const p = s.player, r = rooms[s.room];
    if (input.interact && !this.previous.interact) this.interact();
    if (r !== rooms[s.room] || s.mode !== 'playing') { this.previous = { ...input }; return; }
    if (input.resonate) s.charge = Math.min(1, s.charge + dt / 0.9);
    if (!input.resonate && this.previous.resonate) this.resonate();
    if (!this.attachedMotion(dt, input)) {
    const ridingLift = (r.lifts || []).find(lift => lift.id === p.riding);
    if (ridingLift && p.grounded) {
      const current = getLiftPosition(ridingLift, s.time, s.flags), prior = getLiftPosition(ridingLift, s.time - dt, s.flags);
      p.y += current.y - prior.y;
      p.liftDistance = (p.liftDistance || 0) + Math.max(0, prior.y - current.y);
      if (p.liftDistance > 100) this.courseMark('lift');
    }
    p.vx = ((input.right ? 1 : 0) - (input.left ? 1 : 0)) * 240 + (p.launchVx || 0);
    p.launchVx *= Math.exp(-1.2 * dt);
    if (p.vx) p.facing = Math.sign(p.vx);
    if (input.jump && !this.previous.jump && p.grounded) { p.vy = -460; p.grounded = false; p.riding = null; this.event('sound', 'jump'); }
    const floating = input.float && s.abilities.has('float') && s.pressure > 0;
    p.floating = Boolean(floating);
    if (floating) { p.vy = Math.max(-210, p.vy - 1050 * dt); s.pressure = Math.max(0, s.pressure - dt / 2.8); }
    else p.vy = Math.min(650, p.vy + 900 * dt);
    if ((r.currents || []).some(current => overlap(p, current))) p.vy = Math.max(-240, p.vy - 1500 * dt);
    const oldY = p.y, oldX = p.x, canFollowTerrain = p.grounded && p.vy >= 0;
    p.x = clamp(p.x + p.vx * dt, 0, r.width - p.w);
    const barriers = r.gates.filter(g => !s.flags.has(g.id));
    if (s.room === 1 && !s.flags.has('fed')) barriers.push({ x: 755, y: 440, w: 90, h: 140 });
    for (const b of barriers) {
      if (overlap(p, b)) { p.x = p.vx >= 0 ? b.x - p.w : b.x + b.w; p.vx = 0; }
    }
    p.y += p.vy * dt; p.grounded = false;
    if (p.y < 45) { p.y = 45; p.vy = Math.max(0, p.vy); }
    s.softDown = Math.max(0, s.softDown - dt);
    let onSoft = false;
    const moving = (r.lifts || []).map(lift => ({ ...getLiftPosition(lift, s.time, s.flags), kind: 'lift', id: lift.id, previousY: getLiftPosition(lift, s.time - dt, s.flags).y }));
    const previousRide = p.riding; p.riding = null;
    for (const platform of [...r.platforms, ...moving]) {
      if (platform.requires && !s.flags.has(platform.requires)) continue;
      if (platform.kind === 'soft' && s.softDown > 0) continue;
      const collisionTop = previousRide === platform.id ? platform.y : (platform.previousY ?? platform.y);
      if (p.x + p.w > platform.x && p.x < platform.x + platform.w && p.vy >= 0 && oldY + p.h <= collisionTop + 2 && p.y + p.h >= platform.y) {
        p.y = platform.y - p.h; p.vy = 0; p.grounded = true;
        p.launchVx = 0;
        if (platform.kind === 'lift') { p.riding = platform.id; if (previousRide !== platform.id) p.liftDistance = 0; }
        if (platform.kind === 'soft') onSoft = true;
      }
    }
    const previous = { x: oldX, y: oldY };
    const landing = terrainLanding(r.terrain, s.flags, previous, p);
    const following = canFollowTerrain ? followTerrain(r.terrain,
      r.platforms.filter(platform => platform.kind !== 'soft' || s.softDown <= 0), s.flags,
      { x: oldX + p.w / 2, y: oldY }, p.x + p.w / 2, p.h) : null;
    const terrainTop = following ?? landing;
    if (terrainTop !== null && (following !== null || !p.grounded || terrainTop <= p.y + p.h + 2)) {
      p.y = terrainTop - p.h; p.vy = 0; p.grounded = true; p.riding = null; p.launchVx = 0;
    }
    s.softTime = onSoft ? s.softTime + dt : 0;
    if (s.softTime > 0.7) { s.softDown = 2; s.softTime = 0; this.event('toast', '舌面下陷了！浮跃或继续向前；片刻后会恢复。'); }
    }
    if (s.room === 3 && p.grounded && !p.riding) {
      const cp = p.x > 1690 && p.y < 400 && s.flags.has('course-swing') ? r.checkpoints[1]
        : p.x >= 1000 && p.x < 1320 && p.y < 220 && s.flags.has('course-lift') ? r.checkpoints[0] : null;
      if (cp && (cp.x !== s.checkpoint.x || cp.y !== s.checkpoint.y)) {
        s.checkpoint = { room: s.room, ...cp }; this.event('save'); this.event('toast', '已点亮攀爬检查点。跌落后，在安全网上按 F 返回。');
      }
    }
    if (p.y > 770 || (s.respawnFlash <= 0 && !s.flags.has('drain') && r.hazards.some(h => overlap(p, h)))) this.respawn();
    for (const m of r.memories) {
      if (!s.memories.has(m.id) && Math.hypot(p.x + 15 - m.x, p.y + 24 - m.y) < 55) {
        s.memories.add(m.id); this.event('memory', m.id); this.event('save'); this.event('sound', 'memory');
      }
    }
    s.pulses = s.pulses.filter(p => (p.age += dt) < 1.2);
    s.camera.x += (clamp(p.x - 440, 0, r.width - 1280) - s.camera.x) * Math.min(1, dt * 6);
    s.hint = this.context();
    this.previous = { ...input };
  }
}
