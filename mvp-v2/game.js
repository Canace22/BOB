import { Game, SAVE_KEY, validateSave } from './engine.js';
import { rooms, memories } from './levels.js';
import { Renderer } from './renderer.js';
import { Soundscape } from './audio.js';

const $ = id => document.getElementById(id);
const renderer = new Renderer($('game'));
const sound = new Soundscape();
const held = new Set();
let toastRemaining = 0, previousTime = 0, manual = false, muted = false, ready = false;
let storageAvailable = true;
let practice = false;
let stored = readSave();
const game = new Game(handleEvent);

function readSave() {
  try { return validateSave(JSON.parse(localStorage.getItem(SAVE_KEY))); }
  catch { return null; }
}
function persist() {
  if (practice) return;
  stored = game.serialize();
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(stored)); }
  catch { storageAvailable = false; }
}
function toast(message) {
  $('toast').textContent = message; $('toast').classList.remove('hidden'); toastRemaining = 4.5;
}
function handleEvent(type, data) {
  if (type === 'save') persist();
  if (type === 'toast') toast(data);
  if (type === 'sound') sound.cue(data);
  if (type === 'room') {
    toast(`${data} · ${rooms[game.state.room].subtitle}`);
    if (practice && game.state.room === 2) showOverlay('paused', '设施练习完成', '<p class="eyebrow">CLIMB · RIDE · SWING</p><p>你完成了攀网、升降台和骨环摆荡。主线存档保持原样。</p><div class="overlay-actions"><button class="primary" data-action="practice">再练一次</button><button class="secondary" data-action="main-menu">返回主菜单</button></div>');
  }
  if (type === 'memory') toast(`找回记忆「${memories[data].title}」 · 按 J 阅读`);
  if (type === 'ending') showEnding();
}
function input() {
  return { left: held.has('KeyA') || held.has('ArrowLeft') || held.has('left'),
    right: held.has('KeyD') || held.has('ArrowRight') || held.has('right'),
    up: held.has('KeyW') || held.has('ArrowUp') || held.has('up'),
    down: held.has('KeyS') || held.has('ArrowDown') || held.has('down'),
    jump: held.has('Space') || held.has('jump'),
    resonate: held.has('KeyE') || held.has('resonate'),
    interact: held.has('KeyF') || held.has('interact'),
    float: held.has('ShiftLeft') || held.has('ShiftRight') || held.has('float') };
}
function start(resume) {
  if (!ready) return;
  practice = false;
  held.clear(); sound.start();
  $('title-screen').classList.add('hidden'); $('overlay').classList.add('hidden');
  $('hud').classList.remove('hidden'); $('touch-controls').classList.remove('hidden');
  game.start(resume ? stored : null);
  if (!storageAvailable) toast('浏览器无法写入存档；当前旅程仍可正常游玩。');
  refresh();
}
function startPractice() {
  if (!ready) return;
  practice = true; held.clear(); sound.start();
  $('title-screen').classList.add('hidden'); $('overlay').classList.add('hidden');
  $('hud').classList.remove('hidden');
  game.start(); game.enter(3);
  toast('设施练习 · W / S 攀网 · F 抓骨环 · 空格跃出。不会覆盖主线存档。');
  refresh();
}
function mainMenu() {
  held.clear(); game.previous = {}; game.state.mode = 'title'; practice = false;
  $('title-screen').classList.remove('hidden'); $('hud').classList.add('hidden');
  $('overlay').classList.add('hidden'); $('touch-controls').classList.add('hidden');
  $('continue-btn').classList.toggle('hidden', !stored);
  $('start-btn').focus();
}
function refresh() {
  const s = game.state;
  $('room-name').textContent = rooms[s.room].name;
  $('objective').textContent = game.objective();
  $('memory-count').textContent = `${s.memories.size} / 4`;
  $('ability-status').textContent = s.abilities.has('float') ? '共生浮膜 · SHIFT 浮升' : '骨鸣器 · E 短鸣 / 长鸣';
  $('course-progress').classList.toggle('hidden', s.room !== 3);
  $('course-progress').textContent = `${practice ? '设施练习 · ' : ''}${[['course-climb','攀网'],['course-lift','升降台'],['course-swing','骨环']].map(([flag,name]) => `${s.flags.has(flag) ? '●' : '○'} ${name}`).join('  →  ')}`;
  $('pressure-bar').style.width = `${s.abilities.has('float') ? s.pressure * 100 : 0}%`;
  $('charge-bar').style.width = `${s.charge * 100}%`;
  $('context-hint').textContent = s.hint;
  $('context-hint').classList.toggle('hidden', !s.hint || s.mode !== 'playing');
  $('touch-controls').classList.toggle('hidden', s.mode !== 'playing');
}
function showOverlay(mode, title, html) {
  held.clear(); game.state.charge = 0; game.previous = {}; game.state.mode = mode;
  $('overlay-title').textContent = title;
  $('overlay-content').innerHTML = html;
  $('overlay').classList.remove('hidden');
  $('context-hint').classList.add('hidden');
  $('overlay-close').focus();
  refresh();
}
function closeOverlay() {
  held.clear(); game.previous = {}; game.state.mode = 'playing';
  $('overlay').classList.add('hidden'); refresh();
}
const habitatCount = () => [...game.state.flags].filter(f => f.startsWith('habitat-')).length;
function pause() {
  showOverlay('paused', '让菌灯陪你歇一会儿', `<p class="eyebrow">THE TIDE CAN WAIT</p><p>${practice ? '设施练习中，主线存档保持原样。' : '旅程已保存。海水静下来，回声仍在。'}</p><div class="cards"><div class="card"><b>移动与攀爬</b><p>A / D 移动，空格跳跃。W / S 或 ↑ / ↓ 攀网；空格脱离。</p></div><div class="card"><b>骨环与机关</b><p>F 交互、抓住骨环或放手，空格借摆速跃出。E 短鸣 / 蓄满长鸣。</p></div><div class="card"><b>共生浮膜</b><p>获得后按住 Shift 浮升。压力囊旁按 F 补压。</p></div></div><div class="overlay-actions"><button class="primary" data-action="resume">继续探索 →</button><button class="secondary" data-action="recover">回到安全点</button><button class="secondary" data-action="${practice ? 'main-menu' : 'restart-confirm'}">${practice ? '返回主菜单' : '重新开始'}</button></div>`);
  persist();
}
function showMap() {
  const s = game.state;
  showOverlay('map', '探索地图 · 沿旧伤前行', `<p class="eyebrow">FIELD MAP · 已探索 ${s.visited.size} / ${rooms.length}</p><p>鲸口 ⇄ 胃库 ⇄ 肋骨游廊 ⇄ 肺缘<br>${s.flags.has('shortcut') ? '已开放：肺缘高台 → 旧伤裂隙 → 鲸口高台' : '回程裂隙：从肺缘高处开启，通往鲸口上层。'}</p><div class="cards">${[0,1,3,2].map((i, order) => { const r = rooms[i]; return `<article class="card map-node ${s.room === i ? 'current' : ''}"><span class="eyebrow">0${order + 1} ${s.room === i ? '· 当前所在' : ''}</span><h3>${s.visited.has(i) ? r.name : '尚未抵达的轮廓'}</h3><p>${s.visited.has(i) ? r.subtitle : '沿水流继续探索'}</p><p>${s.visited.has(i) ? (i === 3 ? `设施 ${['course-climb','course-lift','course-swing'].filter(f => s.flags.has(f)).length} / 3` : `记忆 ${r.memories.filter(m => s.memories.has(m.id)).length} / ${r.memories.length}`) : '…'}</p></article>`; }).join('')}</div><p class="muted">贝壳营地与设施落脚点保存进度；跌落不丢失收集。</p>`);
}
function showJournal() {
  const s = game.state;
  showOverlay('journal', '拾潮手记', `<p class="eyebrow">MEMORIES ${s.memories.size} / 4 · 栖息地 ${habitatCount()} / 3</p><div class="cards">${Object.entries(memories).map(([id, m]) => `<article class="card"><span class="eyebrow">${s.memories.has(id) ? '◇ 已拾回' : '○ 尚未发现'}</span><h3>${s.memories.has(id) ? m.title : '一段未被听见的回声'}</h3><p>${s.memories.has(id) ? m.text : '观察高处、低槽与回程中的旧路。'}</p></article>`).join('')}</div><p class="muted">一鲸落，万物生。这里没有复活的鲸，只有逐渐接续的生命。</p>`);
}
function showEnding() {
  const s = game.state;
  showOverlay('ending', '旧路上，长出了新的生命', `<p class="eyebrow">A SMALL JOURNEY · A LIVING WORLD</p><p>你把第一道回声带回了营地。<br>鲸须之间，虾群仍在迁移；旧伤之上，菌灯亮起。</p><div class="cards"><div class="card"><b>${s.memories.size} / 4</b><p>记忆被重新听见</p></div><div class="card"><b>${habitatCount()} / 3</b><p>栖息地恢复生机</p></div><div class="card"><b>${Math.max(1, Math.round(s.elapsed / 60))} 分钟</b><p>这一次深海旅程</p></div></div><p>这是 V2 的四区域试玩切片。耳骨与尾椎，留待下一次远行。</p><div class="overlay-actions"><button class="primary" data-action="resume">继续回访与修复 →</button><button class="secondary" data-action="journal">阅读拾潮手记</button></div>`);
  persist();
}

$('start-btn').addEventListener('click', () => {
  if (stored) {
    showOverlay('title', '开始一段新的旅程？', '<p>新的旅程会替换当前 V2 存档。</p><div class="overlay-actions"><button class="primary" data-action="new">开始新旅程</button><button class="secondary" data-action="title">保留存档并返回</button></div>');
  } else start(false);
});
$('continue-btn').addEventListener('click', () => start(true));
$('practice-btn').addEventListener('click', startPractice);
$('update-btn').addEventListener('click', () => {
  if (game.state.mode !== 'title') persist();
  location.assign('/');
});
const releaseId = /^\/build\/([^/]+)\//.exec(location.pathname)?.[1];
if (releaseId) setInterval(async () => {
  try {
    const response = await fetch('/__preview/status', { cache: 'no-store' });
    if (!response.ok) return;
    const active = await response.json();
    $('update-btn').classList.toggle('hidden', active.release === releaseId);
  } catch { /* An offline server never stops an already loaded game. */ }
}, 5000);
$('map-btn').addEventListener('click', showMap);
$('journal-btn').addEventListener('click', showJournal);
$('pause-btn').addEventListener('click', pause);
$('sound-btn').addEventListener('click', () => {
  muted = !muted; sound.setMuted(muted); $('sound-btn').textContent = muted ? '静音' : '声音';
  $('sound-btn').setAttribute('aria-pressed', String(muted));
});
function dismiss() {
  if (game.state.mode === 'title') { $('overlay').classList.add('hidden'); $('start-btn').focus(); }
  else closeOverlay();
}
$('overlay-close').addEventListener('click', dismiss);
$('overlay-content').addEventListener('click', e => {
  const action = e.target.closest('[data-action]')?.dataset.action;
  if (action === 'resume') closeOverlay();
  if (action === 'recover') { closeOverlay(); game.respawn(); }
  if (action === 'new') start(false);
  if (action === 'title') dismiss();
  if (action === 'journal') showJournal();
  if (action === 'practice') startPractice();
  if (action === 'main-menu') mainMenu();
  if (action === 'restart-confirm') showOverlay('paused', '重新开始这段旅程？', '<p>当前 V2 存档会被替换。</p><div class="overlay-actions"><button class="primary" data-action="new">确认重新开始</button><button class="secondary" data-action="resume">返回旅程</button></div>');
});

const controls = new Set(['KeyA','KeyD','ArrowLeft','ArrowRight','Space','KeyW','KeyS','ArrowUp','ArrowDown','KeyE','KeyF','ShiftLeft','ShiftRight']);
window.addEventListener('keydown', e => {
  const mode = game.state.mode;
  if (e.code === 'Tab' && !$('overlay').classList.contains('hidden')) {
    const focusable = [...$('overlay').querySelectorAll('button:not([disabled])')];
    const first = focusable[0], last = focusable.at(-1);
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus(); }
    return;
  }
  if (controls.has(e.code) && mode === 'playing') { e.preventDefault(); held.add(e.code); }
  if (e.repeat) return;
  if (e.code === 'Escape' && (mode !== 'title' || !$('overlay').classList.contains('hidden'))) {
    e.preventDefault(); mode === 'playing' ? pause() : dismiss();
  }
  if (e.code === 'KeyM' && mode !== 'title') mode === 'map' ? closeOverlay() : showMap();
  if (e.code === 'KeyJ' && mode !== 'title') mode === 'journal' ? closeOverlay() : showJournal();
});
window.addEventListener('keyup', e => held.delete(e.code));
window.addEventListener('blur', () => { held.clear(); if (game.state.mode === 'playing') pause(); });
document.addEventListener('visibilitychange', () => { if (document.hidden && game.state.mode === 'playing') pause(); });
window.addEventListener('pagehide', () => { if (game.state.mode !== 'title') persist(); });
document.querySelectorAll('[data-hold]').forEach(button => {
  const key = button.dataset.hold;
  button.addEventListener('pointerdown', e => { e.preventDefault(); button.setPointerCapture(e.pointerId); held.add(key); });
  for (const event of ['pointerup','pointercancel','lostpointercapture']) button.addEventListener(event, () => held.delete(key));
});
document.querySelectorAll('#touch-controls [data-action="interact"]').forEach(button => button.addEventListener('pointerdown', e => {
  e.preventDefault(); if (game.state.mode === 'playing') game.interact();
}));
function update(dt) {
  game.step(dt, input());
  if (toastRemaining > 0) { toastRemaining -= dt; if (toastRemaining <= 0) $('toast').classList.add('hidden'); }
}
function paint() { renderer.draw(game.state, rooms[game.state.room]); refresh(); }
function frame(now) {
  if (!manual) {
    let dt = Math.min(0.05, (now - (previousTime || now)) / 1000);
    while (dt > 0) { const step = Math.min(dt, 1 / 120); update(step); dt -= step; }
  }
  previousTime = now; paint(); requestAnimationFrame(frame);
}
// Read-only diagnostics and a deterministic clock for input-driven playthroughs.
window.render_game_to_text = () => JSON.stringify({ ...game.state,
  practice,
  flags: [...game.state.flags], memories: [...game.state.memories], abilities: [...game.state.abilities], visited: [...game.state.visited],
  objective: game.objective(), coordinateSystem: 'pixels, origin top-left; x right, y down; player x/y top-left',
});
window.advanceTime = ms => {
  manual = true;
  let remaining = Math.max(0, Math.min(60000, Number(ms) || 0)) / 1000;
  while (remaining > 0) { const dt = Math.min(remaining, 1 / 120); update(dt); remaining -= dt; }
  paint(); return window.render_game_to_text();
};
try {
  await renderer.load(); ready = true;
  $('start-btn').disabled = false;
  $('practice-btn').disabled = false;
  $('continue-btn').classList.toggle('hidden', !stored);
  requestAnimationFrame(frame);
} catch (error) {
  $('start-btn').textContent = '画面加载失败，请刷新重试';
  console.error(error);
}
