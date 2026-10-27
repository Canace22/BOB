import { CAMPAIGN_ROOMS, CAMPAIGN_ROOM_BY_ID, UNIT } from './campaign-levels.js';
import { followTerrain, terrainHeightAt, terrainLanding } from './terrain.js';

export const CAMPAIGN_SAVE_KEY = 'whalefall-v52-save';
// Source fixes ability ranges, life/resonance limits and telegraph/recovery times.
// Source walk speed is 3.2 U/s. Jump, damage, enemy HP, active durations and
// cooldowns below remain playtest tuning unless explicitly fixed by source.
export const CAMPAIGN_TUNING = Object.freeze({ speed: 3.2 * UNIT, jump: 380, gravity: 950, shortDamage: [8, 10], heavyDamage: 18, crabLife: 24, bossLife: 120, attackCooldown: .38, dashDuration: .16, dashCooldown: .55, restDuration: 1.4, hazardActive: .6 });
const clamp = (n, low, high) => Math.max(low, Math.min(high, n));
const overlaps = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
const objects = CAMPAIGN_ROOMS.flatMap(room => room.objects || []);
const objectIds = new Set(objects.map(object => object.id));
const flags = new Set(['BOSS_R1', 'BATCH_R1', 'DASH_PRACTICED', ...objects.map(object => object.grants || object.id)]);
const firstRoom = 'R1-01';
const dashTeachingPlatforms = new Set(['R1-05-entry', 'R1-05-middle-a', 'R1-05-middle-b', 'R1-05-exit']);
const permitted = (requirements, state) => (requirements || []).every(id => state.flags.has(id) || state.abilities.has(id));
const maxLife = collected => 4 + Math.min(2, Math.floor(objects.filter(object => object.type === 'fragment' && collected.has(object.id)).length / 4));

export function campaignHazardPhase(hazard, time) {
  if (hazard.type === 'soft' || hazard.damage === 0) return { phase: 'soft', progress: 0 };
  const warning = hazard.warning ?? .7, active = hazard.activeDuration ?? CAMPAIGN_TUNING.hazardActive;
  const cycle = time % (hazard.period || 4);
  if (cycle < warning) return { phase: 'warning', progress: cycle / warning };
  if (cycle < warning + active) return { phase: 'active', progress: (cycle - warning) / active };
  return { phase: 'safe', progress: 0 };
}

export function validateCampaignSave(save) {
  if (!save || save.version !== 1 || save.campaign !== 'v5.2-r1' || !CAMPAIGN_ROOM_BY_ID[save.checkpoint?.room]) return null;
  if (![save.flags, save.abilities, save.collected, save.visited].every(Array.isArray)) return null;
  if (save.flags.some(id => !flags.has(id)) || save.abilities.some(id => id !== 'A1') || save.collected.some(id => !objectIds.has(id)) || save.visited.some(id => !CAMPAIGN_ROOM_BY_ID[id])) return null;
  if (save.abilities.includes('A1') && !save.flags.includes('BOSS_R1')) return null;
  const room = CAMPAIGN_ROOM_BY_ID[save.checkpoint.room], point = save.checkpoint;
  const safe = [...(room.camps || []).map(camp => ({ x: camp.x - 15, y: camp.y - 48 })), ...(room.id === firstRoom ? [room.spawn] : [])];
  if (!safe.some(candidate => candidate.x === point.x && candidate.y === point.y)) return null;
  if (![save.deaths, save.elapsed].every(number => Number.isFinite(number) && number >= 0)) return null;
  return save;
}

export class CampaignGame {
  constructor(onEvent = () => {}) { this.onEvent = onEvent; this.previous = {}; this.state = this.fresh(); }
  fresh() {
    const spawn = CAMPAIGN_ROOM_BY_ID[firstRoom].spawn;
    return { mode: 'title', room: firstRoom, time: 0, elapsed: 0, camera: { x: 0, y: 0 },
      player: { ...spawn, w: 30, h: 48, vx: 0, vy: 0, facing: 1, grounded: false },
      flags: new Set(), abilities: new Set(), collected: new Set(), visited: new Set(),
      life: 4, maxLife: 4, resonance: 4, checkpoint: { room: firstRoom, ...spawn }, stable: { ...spawn },
      enemies: [], attack: null, particles: [], pulses: [], deaths: 0, respawnFlash: 0, invulnerable: 0,
      dash: { remaining: 0, available: true, cooldown: 0 }, rest: 0, lamp: true, attackCooldown: 0, combo: 0, comboTimer: 0,
      arenaActive: false, hazardTime: 0, hint: '', charge: 0, pressure: 0 };
  }
  event(type, payload) { this.onEvent(type, payload); }
  get room() { return CAMPAIGN_ROOM_BY_ID[this.state.room]; }
  start(save = null) {
    this.state = this.fresh(); this.previous = {};
    const valid = validateCampaignSave(save), s = this.state;
    if (valid) {
      for (const key of ['flags', 'abilities', 'collected', 'visited']) s[key] = new Set(valid[key]);
      s.checkpoint = { ...valid.checkpoint }; s.elapsed = valid.elapsed; s.deaths = valid.deaths;
      s.maxLife = maxLife(s.collected); s.life = s.maxLife;
    }
    s.mode = 'playing'; this.enter(s.checkpoint.room, s.checkpoint);
  }
  serialize() {
    const s = this.state;
    return { version: 1, campaign: 'v5.2-r1', checkpoint: { ...s.checkpoint }, flags: [...s.flags], abilities: [...s.abilities], collected: [...s.collected], visited: [...s.visited], deaths: s.deaths, elapsed: s.elapsed };
  }
  enter(id, spawn) {
    const room = CAMPAIGN_ROOM_BY_ID[id]; if (!room) return false;
    const s = this.state; s.room = id; s.visited.add(id);
    const point = spawn || room.spawn;
    Object.assign(s.player, { x: point.x, y: point.y, vx: 0, vy: 0, grounded: false });
    s.stable = { x: s.player.x, y: s.player.y }; s.attack = null; s.rest = 0;
    s.dash = { remaining: 0, available: true, cooldown: 0 }; s.arenaActive = false; s.hazardTime = 0;
    s.enemies = (room.enemies || []).filter(enemy => !enemy.victoryFlag || !s.flags.has(enemy.victoryFlag)).map(enemy => {
      // Exclude decorative leg tips but retain the painted shell/body footprint.
      const boss = enemy.type === 'gate-shell-crab', w = boss ? 4.2 * UNIT : 68, h = boss ? 2.7 * UNIT : 43;
      return { ...enemy, x: enemy.x - w / 2, y: enemy.y - h, w, h, foot: enemy.y,
        hp: boss ? CAMPAIGN_TUNING.bossLife : CAMPAIGN_TUNING.crabLife, maxHp: boss ? CAMPAIGN_TUNING.bossLife : CAMPAIGN_TUNING.crabLife,
        boss, spawnX: enemy.x, phase: 'idle', timer: .65, facing: -1, attack: null, preview: null, cycle: 0, move: 'sweep', hitPlayer: false };
    });
    s.camera.x = clamp(s.player.x - 400, 0, Math.max(0, room.width - 1280));
    s.camera.y = clamp(s.player.y - 400, 0, Math.max(0, room.height - 720));
    this.event('room', room.name); this.event('save'); return true;
  }
  near(point, radius = 92) {
    const p = this.state.player;
    return Math.abs(p.x + p.w / 2 - point.x) <= radius && Math.abs(p.y + p.h - point.y) <= 78;
  }
  objective() {
    const s = this.state;
    if (s.flags.has('BATCH_R1')) return '须门主线已完成；胃枢将在后续批次开放，可继续回访';
    if (s.room === 'R1-04') return s.flags.has('BOSS_R1') ? '战后在流膜授予点按 E，取得贴流冲 A1' : '登记门前营地；跳横扫、退壳砸，在恢复时短击侧腹';
    if (s.room === 'R1-05') return 'Shift 贴流冲跨过三段宽沟；每次落稳后才刷新冲刺';
    return s.room === 'R1-01' ? '在贝壳营地按 E 登记，沿外伤坡找到须筛入口' : '沿亮边台面前进；Q 短击，R 重鸣，E 交互';
  }
  interactionTarget() {
    const s = this.state, p = s.player, room = this.room;
    const candidates = [
      ...(room.camps || []).map(data => ({ type: 'camp', data, radius: 92 })),
      ...(room.objects || []).filter(data => !s.collected.has(data.id)).map(data => ({ type: 'object', data, radius: 92 })),
      ...(room.exits || []).map(data => ({ type: 'exit', data, radius: 82 })),
    ];
    return candidates.filter(candidate => this.near(candidate.data, candidate.radius))
      .sort((a, b) => Math.hypot(a.data.x - p.x - p.w / 2, a.data.y - p.y - p.h) - Math.hypot(b.data.x - p.x - p.w / 2, b.data.y - p.y - p.h))[0] || null;
  }
  context() {
    const s = this.state, target = this.interactionTarget();
    const camp = target?.type === 'camp' ? target.data : null;
    if (camp) return '[ E ] 登记营地 · 恢复生命与蓄振';
    const object = target?.type === 'object' ? target.data : null;
    if (object) return permitted(object.requires, s) ? `[ E ] ${object.label || object.id}` : `尚缺：${object.requires.filter(id => !s.flags.has(id) && !s.abilities.has(id)).join(' + ')}`;
    const exit = target?.type === 'exit' ? target.data : null;
    if (exit) return !permitted(exit.requires, s) ? `通路尚缺：${exit.requires.filter(id => !s.flags.has(id) && !s.abilities.has(id)).join(' + ')}`
      : exit.unavailable ? '[ E ] 须门阶段终点 · 胃枢后续开放' : `[ E ] ${exit.label || exit.to}`;
    return s.arenaActive ? 'Q 短击 · R 重鸣 · H 调息；观察预告再退步或跳跃' : '';
  }
  interact() {
    const s = this.state, room = this.room;
    if (s.arenaActive) { this.event('toast', '战斗仍在继续，先避开预告并击败负壳蟹。'); return; }
    const target = this.interactionTarget();
    const camp = target?.type === 'camp' ? target.data : null;
    if (camp) {
      s.checkpoint = { room: room.id, x: camp.x - 15, y: camp.y - 48 };
      s.life = s.maxLife; s.resonance = 4; s.rest = 0;
      this.event('save'); this.event('toast', '营地已登记，生命与蓄振已恢复。'); return;
    }
    const object = target?.type === 'object' ? target.data : null;
    if (object) {
      if (!permitted(object.requires, s)) { this.event('toast', `尚缺：${object.requires.join(' + ')}`); return; }
      if (object.requireDashPractice && !s.flags.has('DASH_PRACTICED')) { this.event('toast', '先完成一次贴流冲并落稳，再整理清流窝。'); return; }
      s.collected.add(object.id);
      if (object.type === 'ability') s.abilities.add(object.grants);
      else if (object.grants) s.flags.add(object.grants);
      const previousMax = s.maxLife; s.maxLife = maxLife(s.collected); s.life += s.maxLife - previousMax;
      this.event('save'); this.event('sound', 'success'); this.event('toast', object.type === 'ability' ? '获得贴流冲 A1：Shift 冲刺；每次离地一次，落稳刷新。' : `已完成：${object.label || object.id}`); return;
    }
    const exit = target?.type === 'exit' ? target.data : null;
    if (!exit) return;
    if (!permitted(exit.requires, s)) { this.event('toast', `这条通路需要 ${exit.requires.join(' + ')}。`); return; }
    if (exit.unavailable || !CAMPAIGN_ROOM_BY_ID[exit.to]) {
      if (room.id === 'R1-05' && s.abilities.has('A1')) {
        s.flags.add('BATCH_R1'); this.event('save'); this.event('batch-complete', '须门遗港主线已完成；胃枢将在下一批开放，当前可继续回访。');
      } else this.event('toast', '此区域尚未开放。');
      return;
    }
    this.enter(exit.to, exit.spawn);
  }
  respawn() {
    const s = this.state; s.deaths++; s.life = s.maxLife; s.resonance = 4;
    this.enter(s.checkpoint.room, s.checkpoint); s.invulnerable = 1; s.respawnFlash = .8;
    this.event('save'); this.event('toast', '回到登记营地。能力、奖励、Boss 胜利和开闩进度保留。');
  }
  hurt(amount = 1, recover = false) {
    const s = this.state; if (s.invulnerable > 0) return false;
    s.life = Math.max(0, s.life - amount); s.invulnerable = 1; s.respawnFlash = .35; s.rest = 0; s.attack = null;
    this.event('sound', 'recover');
    if (s.life <= 0) { this.respawn(); return true; }
    if (recover) { Object.assign(s.player, s.stable, { vx: 0, vy: 0, grounded: false }); s.dash.remaining = 0; }
    return true;
  }
  attack(heavy = false) {
    const s = this.state, p = s.player;
    if (s.attackCooldown > 0 || s.rest > 0 || s.dash.remaining > 0 || heavy && s.resonance < 2) return;
    if (heavy) s.resonance -= 2;
    else { s.combo = s.comboTimer > 0 ? 1 - s.combo : 0; s.comboTimer = .9; }
    const range = (heavy ? 1.8 : 1.3) * UNIT, center = p.x + p.w / 2;
    s.attack = { kind: heavy ? 'heavy' : 'short', x: p.facing > 0 ? center : center - range, y: p.y + 7, w: range, h: p.h - 5,
      time: heavy ? .28 : .18, damage: heavy ? CAMPAIGN_TUNING.heavyDamage : CAMPAIGN_TUNING.shortDamage[s.combo], hits: new Set() };
    s.attackCooldown = heavy ? .68 : CAMPAIGN_TUNING.attackCooldown;
    this.event('sound', heavy ? 'long' : 'short');
  }
  enemyVolume(enemy) {
    const range = (enemy.boss ? 2.6 : 1.6) * UNIT, center = enemy.x + enemy.w / 2;
    return enemy.move === 'smash'
      ? { x: enemy.targetX - 58, y: enemy.foot - 115, w: 116, h: 115 }
      : { x: enemy.facing > 0 ? center : center - range, y: enemy.foot - 30, w: range, h: 30 };
  }
  updateCombat(dt) {
    const s = this.state, p = s.player, room = this.room;
    for (const enemy of s.enemies) {
      if (enemy.hp <= 0) continue;
      const boss = enemy.boss;
      if (boss && !s.arenaActive) {
        if (p.x + p.w / 2 < (enemy.triggerX ?? room.arena?.left ?? 6 * UNIT)) continue;
        s.arenaActive = true;
      }
      if (s.attack && !s.attack.hits.has(enemy.id) && overlaps(s.attack, enemy)) {
        s.attack.hits.add(enemy.id); enemy.hp = Math.max(0, enemy.hp - s.attack.damage);
        if (s.attack.kind === 'short') s.resonance = Math.min(4, s.resonance + 1);
        if (!enemy.hp) {
          enemy.phase = 'defeated'; enemy.attack = null; enemy.preview = null;
          if (enemy.victoryFlag) { s.flags.add(enemy.victoryFlag); s.arenaActive = false; this.event('save'); this.event('toast', '负壳蟹已退去。到右侧流膜授予点按 E 取得 A1。'); }
          continue;
        }
      }
      enemy.timer -= dt;
      if (enemy.phase === 'idle') {
        const distance = p.x + p.w / 2 - (enemy.x + enemy.w / 2);
        const visible = enemy.x + enemy.w > s.camera.x && enemy.x < s.camera.x + 1280 && enemy.y + enemy.h > s.camera.y && enemy.y < s.camera.y + 720;
        if (Math.abs(distance) < (boss ? 215 : 145) && Math.abs(p.y + p.h - enemy.foot) < 150 && enemy.timer <= 0 && visible) {
          enemy.facing = Math.sign(distance) || 1; enemy.phase = 'telegraph'; enemy.hitPlayer = false;
          enemy.move = boss && enemy.cycle % 2 ? 'smash' : 'sweep';
          enemy.timer = boss ? (enemy.move === 'smash' ? 1.1 : .8) : .65;
          enemy.targetX = p.x + p.w / 2;
          enemy.preview = this.enemyVolume(enemy);
        } else if (enemy.timer <= 0) {
          const minimum = (enemy.patrolMin ?? enemy.spawnX - 60) - enemy.w / 2;
          const maximum = (enemy.patrolMax ?? enemy.spawnX + 60) - enemy.w / 2;
          if (enemy.x <= minimum) enemy.facing = 1;
          if (enemy.x >= maximum) enemy.facing = -1;
          enemy.x = clamp(enemy.x + enemy.facing * (boss ? 62 : 34) * dt, minimum, maximum);
        }
      } else if (enemy.phase === 'telegraph' && enemy.timer <= 0) {
        enemy.phase = 'active'; enemy.timer = enemy.move === 'smash' ? .25 : .18;
        enemy.attack = this.enemyVolume(enemy); enemy.preview = null;
      } else if (enemy.phase === 'active') {
        if (!enemy.hitPlayer && enemy.attack && overlaps(p, enemy.attack)) { enemy.hitPlayer = true; this.hurt(1); if (s.room !== room.id) return; }
        if (enemy.timer <= 0) {
          enemy.attack = null;
          if (boss && enemy.move === 'sweep' && enemy.hp <= enemy.maxHp / 2 && !enemy.secondSweep) {
            enemy.phase = 'telegraph'; enemy.timer = .55; enemy.secondSweep = true; enemy.hitPlayer = false;
            enemy.preview = this.enemyVolume(enemy);
          } else { enemy.phase = 'recovery'; enemy.timer = boss ? (enemy.move === 'smash' ? 1 : .75) : .7; enemy.secondSweep = false; }
        }
      } else if (enemy.phase === 'recovery' && enemy.timer <= 0) { enemy.phase = 'idle'; enemy.timer = .5; enemy.cycle++; }
    }
  }
  move(dt, input) {
    const s = this.state, p = s.player, room = this.room, before = { x: p.x, y: p.y };
    const direction = (input.right ? 1 : 0) - (input.left ? 1 : 0);
    if (direction) p.facing = direction;
    if (input.jump && !this.previous.jump && p.grounded && s.rest <= 0) { p.vy = -CAMPAIGN_TUNING.jump; p.grounded = false; this.event('sound', 'jump'); }
    if (input.dash && !this.previous.dash && s.abilities.has('A1') && s.dash.available && s.dash.cooldown <= 0 && s.rest <= 0) {
      s.dash.remaining = CAMPAIGN_TUNING.dashDuration; s.dash.cooldown = CAMPAIGN_TUNING.dashCooldown; s.dash.available = false; s.dash.used = true; s.attack = null;
      s.dash.fromPlatform = (room.platforms || []).find(platform => s.stable.x + p.w / 2 >= platform.x && s.stable.x + p.w / 2 <= platform.x + platform.w && Math.abs(s.stable.y + p.h - platform.y) < 2)?.id;
    }
    const dashing = s.dash.remaining > 0;
    const dashTime = Math.min(dt, s.dash.remaining);
    p.vx = s.rest > 0 ? 0 : dashing ? p.facing * (2.6 * UNIT / CAMPAIGN_TUNING.dashDuration) : direction * CAMPAIGN_TUNING.speed;
    if (dashing) p.vy = 0; else p.vy = Math.min(650, p.vy + CAMPAIGN_TUNING.gravity * dt);
    const follow = p.grounded && p.vy >= 0 && !dashing;
    p.x = clamp(p.x + p.vx * (dashing ? dashTime : dt), 0, room.width - p.w);
    for (const wall of room.barriers || []) {
      if (wall.requires && permitted(wall.requires, s)) continue;
      const vertical = p.y < wall.y + wall.h && p.y + p.h > wall.y;
      const crossed = vertical && (p.vx >= 0 ? before.x + p.w <= wall.x && p.x + p.w >= wall.x : before.x >= wall.x + wall.w && p.x <= wall.x + wall.w);
      if (crossed || overlaps(p, wall)) { p.x = p.vx >= 0 ? wall.x - p.w : wall.x + wall.w; s.dash.remaining = 0; }
    }
    if (s.arenaActive && room.arena) p.x = clamp(p.x, room.arena.left, room.arena.right - p.w);
    p.y += p.vy * dt; p.grounded = false;
    const platforms = (room.platforms || []).filter(platform => permitted(platform.requires, s));
    for (const platform of platforms) if (p.vy >= 0 && p.x + p.w > platform.x && p.x < platform.x + platform.w && before.y + p.h <= platform.y + 2 && p.y + p.h >= platform.y) {
      p.y = platform.y - p.h; p.vy = 0; p.grounded = true;
    }
    const landing = terrainLanding(room.terrain, s.flags, before, p);
    const following = follow ? followTerrain(room.terrain, platforms, s.flags, { x: before.x + p.w / 2, y: before.y }, p.x + p.w / 2, p.h) : null;
    const top = following ?? landing;
    if (top !== null && (following !== null || !p.grounded || top <= p.y + p.h + 2)) { p.y = top - p.h; p.vy = 0; p.grounded = true; }
    if (p.y < 0) { p.y = 0; p.vy = Math.max(0, p.vy); }
    s.dash.remaining = Math.max(0, s.dash.remaining - dt);
    if (p.grounded && !dashing) {
      s.dash.available = true;
      if (s.dash.used) {
        const landed = platforms.find(platform => p.x + p.w / 2 >= platform.x && p.x + p.w / 2 <= platform.x + platform.w && Math.abs(p.y + p.h - platform.y) < 2);
        const origin = platforms.find(platform => platform.id === s.dash.fromPlatform);
        const gap = origin && landed ? Math.max(landed.x - origin.x - origin.w, origin.x - landed.x - landed.w) : 0;
        if (room.id === 'R1-05' && dashTeachingPlatforms.has(origin?.id) && dashTeachingPlatforms.has(landed?.id) && gap >= 4 * UNIT - .001) { s.flags.add('DASH_PRACTICED'); this.event('save'); }
        s.dash.used = false;
      }
      const center = p.x + p.w / 2;
      const stablePlatform = platforms.some(platform => center > platform.x + 20 && center < platform.x + platform.w - 20 && Math.abs(platform.y - p.y - p.h) < 2);
      const stableTerrain = (room.terrain || []).some(terrain => terrainHeightAt(terrain, center) !== null && Math.abs(terrainHeightAt(terrain, center) - p.y - p.h) < 2);
      if ((stablePlatform || stableTerrain) && !(room.hazards || []).some(hazard => overlaps({ ...p, y: p.y + 8 }, hazard))) s.stable = { x: p.x, y: p.y };
    }
    if (p.y > room.height + 100) {
      if (room.softRecovery) { Object.assign(p, s.stable, { vx: 0, vy: 0, grounded: false }); s.dash.remaining = 0; }
      else this.hurt(1, true);
    }
    for (const hazard of room.hazards || []) if (overlaps(p, hazard)) {
      if (hazard.type === 'soft' || hazard.damage === 0) { Object.assign(p, s.stable, { vx: 0, vy: 0, grounded: false }); s.dash.remaining = 0; }
      else if (campaignHazardPhase(hazard, s.hazardTime).phase === 'active') this.hurt(hazard.damage || 1, true);
    }
  }
  step(dt, input = {}) {
    const s = this.state;
    if (s.mode !== 'playing') { this.previous = { ...input }; return; }
    s.time += dt; s.elapsed += dt; s.hazardTime += dt;
    for (const key of ['attackCooldown', 'comboTimer', 'invulnerable', 'respawnFlash']) s[key] = Math.max(0, s[key] - dt);
    s.dash.cooldown = Math.max(0, s.dash.cooldown - dt);
    if (s.attack) { s.attack.time -= dt; if (s.attack.time <= 0) s.attack = null; }
    if (input.lamp && !this.previous.lamp) s.lamp = !s.lamp;
    const roomBefore = s.room;
    if (input.interact && !this.previous.interact) this.interact();
    if (s.room !== roomBefore || s.mode !== 'playing') { this.previous = { ...input }; return; }
    if (input.rest && !this.previous.rest && s.player.grounded && s.resonance >= 2 && s.life < s.maxLife) { s.rest = CAMPAIGN_TUNING.restDuration; s.resonance -= 2; s.attack = null; }
    if (s.rest > 0) { s.rest = Math.max(0, s.rest - dt); if (!s.rest) s.life = Math.min(s.maxLife, s.life + 1); }
    if (input.attack && !this.previous.attack) this.attack();
    if (input.heavy && !this.previous.heavy) this.attack(true);
    this.move(dt, input);
    if (s.room !== roomBefore) { this.previous = { ...input }; return; }
    this.updateCombat(dt);
    s.camera.x += (clamp(s.player.x + s.player.facing * 4 * UNIT - 640, 0, Math.max(0, this.room.width - 1280)) - s.camera.x) * Math.min(1, dt * 5);
    s.camera.y += (clamp(s.player.y - 350, 0, Math.max(0, this.room.height - 720)) - s.camera.y) * Math.min(1, dt * 5);
    s.hint = this.context(); this.previous = { ...input };
  }
}
