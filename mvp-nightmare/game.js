import { Renderer } from './renderer.js';
import { levels, clues } from './levels.js';
import { Sound } from './audio.js';

const $ = (id) => document.getElementById(id);
const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const SAVE_KEY = 'bob-nightmare-25d-v1';
const keys = new Set();
const sound = new Sound();
const state = {
  mode: 'title', room: 0, time: 0, roomTime: 0, camera: 0, player: null,
  crate: null, plateDown: false, gateOpen: false, fuseTaken: false, powerOn: false,
  sequence: [], pumpOn: false, chaseX: -320, escapeTime: 0, alert: 0,
  watcher: { phase: 'sleep', beamX: 1250 }, memories: [], particles: [],
  deaths: 0, elapsed: 0, message: '', messageTime: 0, chapterTime: 0,
  checkpoint: null, grabbing: false, grabOffset: 0, coyote: 0, shake: 0,
};
let renderer;
let manualClock = false;
let lastTime = 0;
let heldJump = false;
let actionDown = false;
let lastStep = 0;
let checkpointGate = false;
const level = () => levels[state.room];
const center = () => state.player.x + state.player.w / 2;
const down = (...codes) => codes.some((code) => keys.has(code));
const inHide = () => level().hides.some((h) => center() > h.x + 12 && center() < h.x + h.w - 12);

function notify(message, duration = 4.8) {
  state.message = message; state.messageTime = duration;
}
function readSave() {
  try {
    const s = JSON.parse(localStorage.getItem(SAVE_KEY));
    if (s?.version !== 1 || !Number.isInteger(s.room) || s.room < 0 || s.room > 2) return null;
    return { room: s.room, stage: ['entry', 'gate', 'fuse', 'pump'].includes(s.stage) ? s.stage : 'entry', memories: Array.isArray(s.memories) ? s.memories.filter((id) => /^memory-[012]$/.test(id)) : [] };
  } catch { return null; }
}
function saveCheckpoint(stage = 'entry') {
  state.checkpoint = { room: state.room, stage, memories: [...state.memories] };
  try { localStorage.setItem(SAVE_KEY, JSON.stringify({ version: 1, ...state.checkpoint })); } catch { /* Playing still works without storage. */ }
}
function enterRoom(room, stage = 'entry', announce = true) {
  state.room = room;
  const l = level();
  state.player = { ...l.spawn, w: 26, h: 62, vx: 0, vy: 0, grounded: true, crouching: false, facing: 1, hidden: false };
  state.crate = { x: l.crateStart || 540, y: 512, w: 70, h: 62 };
  Object.assign(state, { mode: 'playing', roomTime: 0, plateDown: false, gateOpen: false, fuseTaken: false, powerOn: false, sequence: [], pumpOn: false, chaseX: -320, escapeTime: 0, alert: 0, grabbing: false, coyote: .12, shake: 0 });
  state.watcher = { phase: 'sleep', beamX: 1250 };
  if (room === 0 && stage === 'gate') { state.crate.x = 900; state.plateDown = true; state.gateOpen = true; state.player.x = 1020; }
  if (room === 1 && stage === 'fuse') { state.fuseTaken = true; state.player.x = 1260; state.player.z = -.65; }
  if (room === 2 && stage === 'pump') { state.pumpOn = true; state.sequence = [2, 1, 3]; state.player.x = 920; state.chaseX = state.player.x - 520; }
  checkpointGate = stage === 'gate';
  keys.clear(); heldJump = false; actionDown = false;
  state.camera = clamp(state.player.x - 420, 0, l.width - 1280);
  state.chapterTime = announce ? 3.5 : 0;
  state.messageTime = 0;
  saveCheckpoint(stage);
  syncUI();
}
function start(continuing = false) {
  const saved = continuing ? readSave() : null;
  state.memories = saved?.memories || []; state.elapsed = 0; state.deaths = 0;
  sound.start();
  enterRoom(saved?.room || 0, saved?.stage || 'entry');
}
function retry() {
  const cp = state.checkpoint || { room: state.room, stage: 'entry' };
  enterRoom(cp.room, cp.stage, false);
  notify(cp.stage === 'pump' ? '潮水来了。按住 Shift，向右跑，空格跨过断口。' : '灯还亮着。再试一次。', 3);
}
function die(reason) {
  if (state.mode !== 'playing') return;
  state.mode = 'dead'; state.deaths++; state.grabbing = false; keys.clear();
  $('death-reason').textContent = reason;
  sound.note(55, .9, 'sawtooth', .18); syncUI();
}
function pause() {
  if (state.mode !== 'playing' && state.mode !== 'paused') return;
  state.mode = state.mode === 'paused' ? 'playing' : 'paused';
  keys.clear(); state.grabbing = false; heldJump = false; actionDown = false; syncUI();
}
function title() {
  state.mode = 'title'; keys.clear(); $('continue-btn').hidden = !readSave(); syncUI();
}
function finish() {
  state.mode = 'ending'; keys.clear(); state.grabbing = false;
  $('ending-stats').textContent = `找回 ${state.memories.length} / 3 段回声 · ${state.deaths} 次重试 · ${Math.floor(state.elapsed / 60)} 分 ${Math.floor(state.elapsed % 60)} 秒`;
  sound.note(440, 2, 'sine', .35); syncUI();
}
function nearbyObject() {
  const p = state.player;
  return level().objects.find((o) => {
    if (o.id === 'fuse' && state.fuseTaken) return false;
    if (o.kind === 'memory' && state.memories.includes(o.id)) return false;
    if (o.kind === 'valve' && state.pumpOn) return false;
    return Math.abs(center() - o.x) < 62 && Math.abs(p.y + p.h / 2 - o.y) < 90 && Math.abs(p.z - (o.z || 0)) < .6;
  });
}
function nearCrate() {
  const p = state.player, c = state.crate;
  return state.room === 0 && p.grounded && Math.abs(p.z) < .7 && p.y + p.h > c.y + 15 && Math.min(Math.abs(p.x + p.w - c.x), Math.abs(p.x - c.x - c.w)) < 20;
}
function interact() {
  const p = state.player, l = level();
  if (Math.abs(center() - l.exit.x) < 76 && p.grounded) {
    if (state.room < 2) {
      if (!state.gateOpen) { notify('通路还没有打开。'); return; }
      sound.note(330, .7); enterRoom(state.room + 1); return;
    }
    if (state.pumpOn) finish(); else notify('升降井没有潮压。先唤醒心脏。');
    return;
  }
  if (nearCrate()) { state.grabbing = true; state.grabOffset = state.crate.x - p.x; return; }
  const o = nearbyObject();
  if (!o) return;
  if (o.kind === 'mural' || o.kind === 'memory') {
    notify(clues[o.id], o.kind === 'mural' ? 7 : 6);
    sound.note(o.kind === 'memory' ? 440 : 165, .7, 'sine', .3);
    if (o.kind === 'memory') { state.memories.push(o.id); saveCheckpoint(state.checkpoint.stage); }
  }
  if (o.kind === 'fuse') {
    state.fuseTaken = true; saveCheckpoint('fuse'); sound.note(330, .6);
    notify('电芯还温着。前方的升降门在等它。这里已留下一个落脚点。', 5);
  }
  if (o.kind === 'socket') {
    if (!state.fuseTaken) { notify('一个空的电芯槽。骨龛里似乎有微光。'); return; }
    state.powerOn = true; state.gateOpen = true; sound.note(220, .8);
    notify('升降门醒了。继续向右。', 3.5);
  }
  if (o.kind === 'valve') turnValve(o.number);
}
function turnValve(number) {
  const order = [2, 1, 3];
  if (number !== order[state.sequence.length]) {
    state.sequence = []; state.shake = .4; sound.note(73, .4, 'sawtooth', .15);
    notify('铜管发出闷响，阀门弹回了原位。再看看左侧的刻痕。'); return;
  }
  state.sequence.push(number); sound.note(140 + state.sequence.length * 65, .5);
  if (state.sequence.length === 3) {
    state.pumpOn = true; state.chaseX = state.player.x - 520; state.escapeTime = 0; state.shake = .8;
    saveCheckpoint('pump'); notify('它醒了。向右跑！Shift 奔跑 · 空格跨过断口', 5);
  } else notify(`第 ${state.sequence.length} 道潮压接通了。`, 2);
}
function hint() {
  if (state.mode !== 'playing') return;
  const hints = [
    state.gateOpen ? '前方的低矮骨缝需要蹲下通过（C）。走进后侧的微光（W），也许能听到什么。' : '靠近箱子，按住 E 和 D，把箱子拖到发光秤盘上。松开 E，再跳过去。',
    state.fuseTaken ? '等看守闭眼再穿行。躲避时走进骨龛（W）并按住 C。电芯槽在最右侧。' : '中间的骨龛里有电芯。看守睁眼前，W 走进骨龛并按住 C；等它闭眼再动。',
    state.pumpOn ? '按住 Shift 向右跑。接近断口边缘时按空格；抵达右侧升降井后按 E。' : '读左侧刻痕（E）。铜管的接通顺序是第二枚、第一枚、第三枚。',
  ];
  notify(hints[state.room], 7);
}
function updateCrouch() {
  const p = state.player, crawl = level().crawl;
  const under = crawl && p.x + p.w > crawl.x && p.x < crawl.x + crawl.w;
  const crouching = down('KeyC', 'ControlLeft', 'ControlRight') || (under && p.crouching);
  const h = crouching ? 34 : 62;
  p.y += p.h - h; p.h = h; p.crouching = crouching;
}
function solidRects() {
  const l = level(), solids = [...l.platforms];
  if (l.gate && !state.gateOpen) solids.push(l.gate);
  if (state.room === 0 && Math.abs(state.player.z) < .85) solids.push(state.crate);
  if (l.crawl) solids.push({ x: l.crawl.x, y: 250, w: l.crawl.w, h: l.floor - l.crawl.clearance - 250 });
  return solids;
}
function overlap(a, b) { return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y; }
function movePlayer(dt) {
  const p = state.player, l = level();
  updateCrouch();
  const dx = Number(down('KeyD', 'ArrowRight')) - Number(down('KeyA', 'ArrowLeft'));
  const dz = Number(down('KeyS', 'ArrowDown')) - Number(down('KeyW', 'ArrowUp'));
  const speed = state.grabbing ? 110 : p.crouching ? 80 : down('ShiftLeft', 'ShiftRight') ? 265 : 168;
  p.vx = dx * speed; if (dx) p.facing = dx;
  const oldZ = p.z;
  p.z = clamp(p.z + dz * dt * (p.crouching ? .85 : 1.45), -1, 1);
  // Entering the crate's depth band must not place the player inside it.
  if (state.room === 0 && Math.abs(p.z) < .85 && overlap(p, state.crate)) p.z = oldZ;
  if (!keys.has('KeyE') || !p.grounded || Math.abs(p.z) > .7) state.grabbing = false;
  if (state.grabbing) {
    const old = state.crate.x;
    state.crate.x = clamp(old + p.vx * dt, l.rail.min, l.rail.max);
    p.x = state.crate.x - state.grabOffset;
    p.vx = (state.crate.x - old) / dt;
  } else {
    p.x += p.vx * dt;
    for (const s of solidRects()) if (overlap(p, s)) {
      p.x = p.vx > 0 ? s.x - p.w : p.vx < 0 ? s.x + s.w : p.x;
    }
  }
  p.x = clamp(p.x, 12, l.width - p.w - 12);
  const jump = down('Space');
  if (jump && !heldJump && state.coyote > 0 && !p.crouching && !state.grabbing) {
    p.vy = -465; p.grounded = false; state.coyote = 0; sound.note(170, .12, 'sine', .13);
  }
  heldJump = jump;
  const beforeY = p.y;
  p.vy += 1200 * dt; p.y += p.vy * dt; p.grounded = false;
  const surfaces = solidRects();
  let start = 0;
  for (const gap of l.gaps) { surfaces.push({ x: start, y: l.floor, w: gap.x - start, h: 500 }); start = gap.x + gap.w; }
  surfaces.push({ x: start, y: l.floor, w: l.width - start, h: 500 });
  for (const s of surfaces) {
    if (!overlap(p, s)) continue;
    if (p.vy >= 0 && beforeY + p.h <= s.y + 4) { p.y = s.y - p.h; p.vy = 0; p.grounded = true; }
    else if (p.vy < 0 && beforeY >= s.y + s.h - 4) { p.y = s.y + s.h; p.vy = 0; }
  }
  state.coyote = p.grounded ? .1 : Math.max(0, state.coyote - dt);
  p.hidden = state.room === 1 && p.crouching && p.z < -.28 && inHide();
  if (p.y > 820) die('断口下面没有落脚点。接近边缘时跳跃，按住 Shift 能跳得更远。');
  if (p.grounded && dx && state.time - lastStep > (p.crouching ? .55 : .33)) {
    lastStep = state.time; sound.note(75 + Math.sin(state.time) * 10, .07, 'sine', p.crouching ? .045 : .12);
  }
}
function updateWatcher(dt) {
  const oldPhase = state.watcher.phase;
  const cycle = state.roomTime % 11.4;
  state.watcher.phase = cycle < 5.5 ? 'sleep' : cycle < 6.8 ? 'warning' : 'watch';
  state.watcher.beamX = 1280 + Math.sin((cycle - 6.8) / 4.6 * Math.PI * 2) * 530;
  const p = state.player, x = center();
  const active = x > 555 && x < 2080;
  const visible = active && !p.hidden && Math.abs(x - state.watcher.beamX) < 510;
  if (state.watcher.phase === 'watch' && visible) state.alert = Math.min(1, state.alert + dt * (p.crouching ? .61 : 1));
  else state.alert = Math.max(0, state.alert - dt * .9);
  if (oldPhase !== state.watcher.phase && state.watcher.phase === 'warning') sound.note(90, .8, 'triangle', .35);
  if (state.alert >= 1) die('它听到了你的呼吸。走进骨龛（W）并蹲下（C），等它闭眼再走。');
}
function update(dt) {
  state.time += dt;
  if (state.mode !== 'playing') return;
  state.elapsed += dt; state.roomTime += dt;
  state.messageTime = Math.max(0, state.messageTime - dt);
  state.chapterTime = Math.max(0, state.chapterTime - dt); state.shake = Math.max(0, state.shake - dt);
  const action = keys.has('KeyE');
  if (action && !actionDown) interact();
  actionDown = action;
  if (state.mode !== 'playing') return;
  movePlayer(dt);
  if (state.room === 0) {
    const plate = level().plate, middle = state.crate.x + state.crate.w / 2;
    const wasOpen = state.gateOpen;
    state.plateDown = middle > plate.x + 12 && middle < plate.x + plate.w - 12;
    // A door does not close on someone crossing its threshold.
    const atGate = Math.abs(center() - level().gate.x) < 55;
    state.gateOpen = state.plateDown || (wasOpen && atGate);
    if (state.gateOpen && !wasOpen) { sound.note(110, .8, 'triangle', .4); notify('秤盘沉了下去，鲸须缓缓抬起。', 3); }
    if (state.gateOpen && !checkpointGate && center() > 1020) { checkpointGate = true; saveCheckpoint('gate'); }
  }
  if (state.room === 1) updateWatcher(dt);
  if (state.room === 2 && state.pumpOn) {
    state.escapeTime += dt;
    // Keep the tide close enough to see; sprinting gains room, stopping is dangerous.
    const distance = state.player.x - state.chaseX;
    state.chaseX += clamp(210 + Math.max(0, distance - 230) * .35, 210, 330) * dt;
    if (state.player.x < state.chaseX + 20) die('回潮追上了你。阀门已经接通，起身就跑。');
    if (Math.floor(state.time * 1.6) !== Math.floor((state.time - dt) * 1.6)) sound.note(46, .22, 'sine', .22);
  }
  state.camera += (clamp(state.player.x - 420, 0, level().width - 1280) - state.camera) * Math.min(1, dt * 6);
}
function promptText() {
  if (state.grabbing) return '<kbd>E ＋ A / D</kbd> 搬动木箱 · 松开 E 放手';
  if (nearCrate()) return '<kbd>按住 E</kbd> 搬动木箱';
  const o = nearbyObject();
  if (o) return `<kbd>E</kbd> ${o.label}`;
  if (Math.abs(center() - level().exit.x) < 76) return '<kbd>E</kbd> 进入升降井';
  if (state.room === 0 && center() > 1310 && center() < 1700) return '<kbd>按住 C</kbd> 蹲下穿过骨缝';
  if (state.room === 1 && inHide()) return state.player.hidden ? '已经藏好 · 等它闭眼' : '<kbd>W ＋ C</kbd> 走进骨龛并蹲下';
  return '';
}
function syncUI() {
  const playing = state.mode === 'playing';
  $('title-screen').hidden = state.mode !== 'title';
  $('pause-screen').hidden = state.mode !== 'paused';
  $('death-screen').hidden = state.mode !== 'dead';
  $('ending-screen').hidden = state.mode !== 'ending';
  $('hud').hidden = !playing;
  $('prompt').hidden = !playing;
  $('message').hidden = !playing || state.messageTime <= 0;
  $('chapter-card').hidden = !playing || state.chapterTime <= 0;
  if (!playing) return;
  const l = level();
  $('chapter-number').textContent = `CHAPTER 0${state.room + 1} / 03`;
  $('chapter-name').textContent = l.name;
  $('objective').textContent = state.room === 0 ? (state.gateOpen ? '穿过鲸须后的通道' : '寻找打开鲸须门的办法') : state.room === 1 ? (state.powerOn ? '进入前方升降井' : state.fuseTaken ? '把电芯送到升降门' : '在骨龛中寻找电芯') : (state.pumpOn ? '回潮正在靠近 · 奔向右侧升降井' : '让三道潮压依次接通');
  $('threat').hidden = state.room !== 1 || state.alert === 0;
  $('threat').firstElementChild.style.width = `${state.alert * 100}%`;
  $('status').textContent = state.room === 1 ? (state.player.hidden ? '已藏好' : { sleep: '它闭上了眼睛', warning: '它就要醒了…', watch: '它正在寻找你' }[state.watcher.phase]) : state.room === 2 ? (state.pumpOn ? `潮水距你 ${Math.max(0, Math.round((state.player.x - state.chaseX) / 100))} 米` : `潮压 ${state.sequence.length} / 3`) : '';
  $('prompt').innerHTML = promptText(); $('prompt').hidden = !$('prompt').innerHTML;
  $('message').textContent = state.message;
  const card = $('chapter-card'); card.style.opacity = Math.min(1, state.chapterTime);
  card.querySelector('span').textContent = l.subtitle; card.querySelector('h2').textContent = l.name; card.querySelector('p').textContent = l.beat;
}
function render() { if (renderer) renderer.draw(state, level()); syncUI(); }
function frame(time) {
  const dt = Math.min((time - lastTime) / 1000 || 0, .04); lastTime = time;
  if (!manualClock) { update(dt); render(); }
  requestAnimationFrame(frame);
}
window.advanceTime = (ms) => {
  manualClock = true;
  const steps = Math.max(1, Math.ceil(ms / (1000 / 60)));
  for (let i = 0; i < steps; i++) update(ms / steps / 1000);
  render();
};
window.render_game_to_text = () => JSON.stringify({
  mode: state.mode, room: state.room, roomName: level().name,
  coordinates: 'x right, y down in logical pixels; z in meters, negative is deeper; floor y=574',
  player: state.player, camera: state.camera, crate: state.crate, plateDown: state.plateDown, gateOpen: state.gateOpen,
  fuseTaken: state.fuseTaken, powerOn: state.powerOn, sequence: state.sequence, pumpOn: state.pumpOn,
  watcher: state.room === 1 ? state.watcher : null, alert: state.alert,
  chaseX: state.pumpOn ? state.chaseX : null, escapeTime: state.escapeTime,
  memories: state.memories, deaths: state.deaths, elapsed: state.elapsed, roomTime: state.roomTime,
  checkpoint: state.checkpoint, grabbing: state.grabbing, message: state.messageTime > 0 ? state.message : '',
  prompt: state.mode === 'playing' ? $('prompt').textContent : '',
  level: { width: level().width, gate: level().gate, plate: level().plate, crawl: level().crawl, hides: level().hides, objects: level().objects, gaps: level().gaps, platforms: level().platforms, exit: level().exit },
});
async function fullscreen() {
  try { if (document.fullscreenElement) await document.exitFullscreen(); else await $('stage').requestFullscreen(); } catch { notify('当前浏览器暂不支持全屏。'); }
}
window.addEventListener('keydown', (e) => {
  const controlled = ['Space', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'KeyA', 'KeyD', 'KeyW', 'KeyS', 'KeyC', 'KeyE', 'ShiftLeft', 'ShiftRight', 'ControlLeft', 'ControlRight'];
  if (controlled.includes(e.code)) e.preventDefault();
  if (!e.repeat) {
    if (e.code === 'Escape') { pause(); return; }
    if (e.code === 'KeyF') { fullscreen(); return; }
    if (e.code === 'KeyH') { hint(); return; }
    if ((e.code === 'KeyR' && ['dead', 'playing'].includes(state.mode)) || (e.code === 'Enter' && state.mode === 'dead')) { retry(); return; }
  }
  if (state.mode === 'playing') keys.add(e.code);
});
window.addEventListener('keyup', (e) => { keys.delete(e.code); if (e.code === 'KeyE') { state.grabbing = false; actionDown = false; } if (e.code === 'Space') heldJump = false; });
window.addEventListener('blur', () => { keys.clear(); if (state.mode === 'playing') pause(); });
document.addEventListener('visibilitychange', () => { if (document.hidden && state.mode === 'playing') pause(); });
$('start-btn').onclick = () => start(); $('continue-btn').onclick = () => start(true);
$('resume-btn').onclick = pause; $('pause-btn').onclick = pause;
$('retry-btn').onclick = retry; $('retry-room-btn').onclick = retry;
$('menu-btn').onclick = title; $('ending-menu-btn').onclick = title;
$('replay-btn').onclick = () => start(); $('hint-btn').onclick = hint;
$('sound-btn').onclick = () => { const on = sound.toggle(); $('sound-btn').textContent = on ? '声音 开' : '声音 关'; $('sound-btn').setAttribute('aria-label', on ? '关闭声音' : '开启声音'); };
try {
  renderer = new Renderer($('game')); await renderer.load();
  $('start-btn').disabled = false; $('start-btn').innerHTML = '走进深处 <span>→</span>';
  $('continue-btn').hidden = !readSave(); render(); requestAnimationFrame(frame);
} catch (error) { $('load-error').hidden = false; console.error(error); }
