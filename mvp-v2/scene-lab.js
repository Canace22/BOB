import { rooms, memories } from './levels.js';
import { getLiftPosition, getSwingPosition } from './mechanics.js';
import { SCENES } from './scenes.js';

const NS = 'http://www.w3.org/2000/svg';
const order = ['mouth', 'stomach', 'ribs', 'lung'];
const intents = {
  mouth: '鲸须形成可辨识的入口节奏；低处初见、高处回访。共鸣门保留短 / 长两种交互。',
  stomach: '压低重心、形成盆地；投喂与排流改变低处路线，浮台与低层记忆对应水位变化。',
  ribs: '高耸肋骨形成纵向游廊；菌丝攀网 → 浮囊升降 → 骨环摆荡 → 上升流，底层设置安全回收网。',
  lung: '肺泡与薄膜形成轻盈上升空间；三层平台、压力补给与回程捷径串起能力回访。',
};
// Suggested design paths; this annotation is not a second simulation or a reachability proof.
const routes = {
  mouth: [[150, 556], [490, 556], [1080, 556], [1510, 556], [1910, 556], [2260, 556]],
  stomach: [[170, 556], [370, 556], [730, 556], [1080, 556], [1460, 606], [1840, 556], [2290, 556]],
  ribs: [[150, 596], [475, 636], [475, 356], [640, 356], [880, 466], [880, 166], [1100, 176], [1260, 220], [1470, 350], [1690, 250], [1810, 326], [1980, 326], [1980, 246], [2220, 246], [2330, 246]],
  lung: [[150, 556], [500, 556], [730, 556], [900, 356], [1130, 356], [1460, 255], [1770, 166], [1940, 166], [2220, 166]],
};
const palette = { solid: '#89afa9', safety: '#72d6a6', climb: '#cbb2ee', lift: '#e6c57b', swing: '#ffb889', current: '#72c9e5', hazard: '#df817a', object: '#ebce8c', memory: '#f8eaa9', checkpoint: '#78e0be', gate: '#d991bc' };
const map = document.querySelector('#map');
let selected = rooms.find(room => room.id === (location.hash.slice(1) || 'ribs')) || rooms[3];
let time = 0;
let playing = false;
let previous = 0;
const enabled = new Set(['terrain', 'traversal', 'interactions', 'route']);

function svg(tag, attrs = {}, parent = map) {
  const node = document.createElementNS(NS, tag);
  for (const [key, value] of Object.entries(attrs)) node.setAttribute(key, String(value));
  parent.append(node);
  return node;
}
function text(x, y, value, attrs = {}, parent = map) {
  const node = svg('text', { x, y, fill: '#dbe9e5', 'font-size': 23, ...attrs }, parent);
  node.textContent = value;
  return node;
}
function inspect(node, kind, data) {
  node.classList.add('object');
  const title = svg('title', {}, node);
  title.textContent = `${kind} · ${data.label || data.id || ''}`;
  node.addEventListener('click', () => {
    document.querySelector('#selection').textContent = `${kind}\n${JSON.stringify(data, null, 2)}`;
  });
}
function rect(data, attrs = {}, parent = map) {
  return svg('rect', { x: data.x, y: data.y, width: data.w, height: data.h, ...attrs }, parent);
}
function marker(x, y, color, label, kind, data, shape = 'circle') {
  const group = svg('g');
  if (shape === 'diamond') svg('path', { d: `M ${x} ${y - 13} l 13 13 -13 13 -13 -13 Z`, fill: '#102c34', stroke: color, 'stroke-width': 4 }, group);
  else svg('circle', { cx: x, cy: y, r: 12, fill: '#102c34', stroke: color, 'stroke-width': 4 }, group);
  text(x, y - 23, label, { fill: color, 'text-anchor': 'middle', 'font-size': 21 }, group);
  inspect(group, kind, data);
  return group;
}
function drawMap() {
  map.replaceChildren();
  map.setAttribute('viewBox', `0 0 ${selected.width} 740`);
  map.setAttribute('aria-label', `${selected.name}实际地图，宽 ${selected.width}，高 740`);
  const defs = svg('defs');
  const hatch = svg('pattern', { id: 'net-pattern', width: 20, height: 20, patternUnits: 'userSpaceOnUse' }, defs);
  svg('path', { d: 'M0 0L20 20M20 0L0 20', stroke: palette.climb, 'stroke-width': 1, opacity: 0.4 }, hatch);
  for (let x = 0; x <= selected.width; x += 200) {
    svg('line', { x1: x, y1: 0, x2: x, y2: 740, stroke: '#19343c', 'stroke-width': 1 });
    text(x + 7, 25, String(x), { fill: '#607c83', 'font-size': 18 });
  }
  for (let y = 100; y < 740; y += 100) {
    svg('line', { x1: 0, y1: y, x2: selected.width, y2: y, stroke: '#19343c', 'stroke-width': 1 });
    text(7, y - 7, String(y), { fill: '#607c83', 'font-size': 18 });
  }
  if (enabled.has('terrain')) {
    for (const platform of selected.platforms) {
      const color = platform.kind === 'safety' ? palette.safety : palette.solid;
      const node = rect(platform, { fill: color, 'fill-opacity': platform.kind === 'safety' ? 0.13 : 0.2, stroke: color, 'stroke-width': 3, 'stroke-dasharray': platform.requires ? '12 8' : platform.kind === 'safety' ? '5 6' : 'none' });
      inspect(node, platform.kind === 'safety' ? '安全网 / 实体碰撞区' : '平台 / 实体碰撞区', platform);
      if (platform.requires) text(platform.x + 8, platform.y + 30, `条件：${platform.requires}`, { fill: color, 'font-size': 19 });
    }
    for (const hazard of selected.hazards || []) {
      inspect(rect(hazard, { fill: palette.hazard, 'fill-opacity': 0.15, stroke: palette.hazard, 'stroke-width': 2, 'stroke-dasharray': '9 9' }), '危险区（排流前）', hazard);
    }
    for (const gate of selected.gates || []) inspect(rect(gate, { fill: palette.gate, 'fill-opacity': 0.25, stroke: palette.gate, 'stroke-width': 3 }), '共鸣门（打开前）', gate);
  }
  if (enabled.has('route')) {
    svg('polyline', { points: routes[selected.id].map(point => point.join(',')).join(' '), fill: 'none', stroke: '#e8ce8e', 'stroke-opacity': 0.55, 'stroke-width': 3, 'stroke-dasharray': '12 10' });
    const spawn = selected.spawn;
    const player = rect({ ...spawn, w: 30, h: 48 }, { fill: '#e9d69a', 'fill-opacity': 0.5, stroke: '#e9d69a', 'stroke-width': 2 });
    inspect(player, '出生点 / 主角 30 × 48 比例', spawn);
    text(spawn.x + 15, spawn.y - 12, '起点', { fill: '#e9d69a', 'text-anchor': 'middle' });
    for (const [i, cp] of (selected.checkpoints || []).entries()) marker(cp.x + 15, cp.y + 24, palette.checkpoint, `检查点 ${i + 1}`, '检查点（主角左上坐标）', cp, 'diamond');
  }
  if (enabled.has('traversal')) {
    for (const climb of selected.climbs || []) {
      inspect(rect(climb, { fill: 'url(#net-pattern)', stroke: palette.climb, 'stroke-width': 3 }), '攀爬网 / 可攀范围', climb);
      text(climb.x + climb.w / 2, climb.y - 15, '菌丝攀网', { fill: palette.climb, 'text-anchor': 'middle' });
    }
    for (const lift of selected.lifts || []) {
      rect({ x: lift.x, y: lift.minY, w: lift.w, h: lift.maxY - lift.minY + lift.h }, { fill: palette.lift, 'fill-opacity': 0.04, stroke: palette.lift, 'stroke-width': 2, 'stroke-dasharray': '10 9' });
      for (const y of [lift.minY, lift.maxY]) text(lift.x + lift.w + 12, y + 10, `y=${y}`, { fill: palette.lift, 'font-size': 18 });
      const current = getLiftPosition(lift, time, new Set([lift.requires]));
      inspect(rect(current, { fill: palette.lift, 'fill-opacity': 0.5, stroke: palette.lift, 'stroke-width': 3 }), '浮囊升降台 / 当前位置', { ...lift, previewPosition: current });
      text(lift.x + lift.w / 2, lift.minY - 16, `升降 · ${lift.period}s`, { fill: palette.lift, 'text-anchor': 'middle' });
    }
    for (const ring of selected.swings || []) {
      const points = Array.from({ length: 81 }, (_, i) => getSwingPosition(ring, ring.period * i / 80));
      svg('polyline', { points: points.map(point => `${point.x},${point.y}`).join(' '), fill: 'none', stroke: palette.swing, 'stroke-width': 3, 'stroke-dasharray': '9 7', opacity: 0.65 });
      const p = getSwingPosition(ring, time);
      svg('line', { x1: ring.x, y1: ring.y, x2: p.x, y2: p.y, stroke: palette.swing, 'stroke-width': 4 });
      svg('circle', { cx: ring.x, cy: ring.y, r: 7, fill: palette.swing });
      const handle = svg('circle', { cx: p.x, cy: p.y, r: 21, fill: '#102c34', stroke: palette.swing, 'stroke-width': 5 });
      inspect(handle, '骨环 / 摆荡端点（共享物理公式）', { ...ring, previewPosition: p });
      text(ring.x + 20, ring.y + 5, `骨环 · ${ring.period}s`, { fill: palette.swing });
    }
    for (const current of selected.currents || []) {
      inspect(rect(current, { fill: palette.current, 'fill-opacity': 0.13, stroke: palette.current, 'stroke-width': 2, 'stroke-dasharray': '8 7' }), '上升流 / 作用范围', current);
      for (let y = current.y + 40; y < current.y + current.h; y += 60) text(current.x + current.w / 2, y, '↑', { fill: palette.current, 'text-anchor': 'middle', 'font-size': 38 });
    }
  }
  if (enabled.has('interactions')) {
    for (const object of selected.objects) marker(object.x, object.y - 10, palette.object, object.label.split(' · ')[0], '交互物', object);
    for (const memory of selected.memories) marker(memory.x, memory.y, palette.memory, memories[memory.id]?.title || memory.id, '记忆', memory, 'diamond');
    for (const exit of selected.exits) {
      const group = marker(exit.x, exit.y - 14, palette.current, rooms[exit.to]?.name || '出口', '出口 / 连接关系', { ...exit, targetRoom: rooms[exit.to]?.id }, 'diamond');
      text(exit.x, exit.y + 30, '↗', { fill: palette.current, 'text-anchor': 'middle', 'font-size': 28 }, group);
    }
  }
  document.querySelector('#time-value').value = `${time.toFixed(1)}s`;
}
function updateRoom(room) {
  selected = room;
  history.replaceState(null, '', `#${room.id}`);
  for (const button of document.querySelectorAll('[data-room]')) button.setAttribute('aria-pressed', String(button.dataset.room === room.id));
  document.querySelector('#room-title').textContent = `${room.name} · 地图图例`;
  document.querySelector('#coordinates').textContent = `游戏坐标 ${room.width} × 740 · 主角 30 × 48 · x 向右 / y 向下 · 等比显示`;
  document.querySelector('#selection').textContent = '请选择地图实体。';
  document.querySelector('#room-json').textContent = JSON.stringify(room, null, 2);
  document.querySelector('#scene-json').textContent = JSON.stringify(SCENES[room.id], null, 2);
  const legend = [['实体平台', palette.solid], ['交互点', palette.object], ['出口', palette.current]];
  if (room.gates?.length) legend.push(['共鸣门', palette.gate]);
  if (room.hazards?.length) legend.push(['危险区', palette.hazard]);
  if (room.memories?.length) legend.push(['记忆', palette.memory]);
  if (room.platforms.some(p => p.kind === 'safety')) legend.push(['安全网', palette.safety]);
  if (room.climbs?.length) legend.push(['攀爬范围', palette.climb]);
  if (room.lifts?.length) legend.push(['升降行程', palette.lift]);
  if (room.swings?.length) legend.push(['摆荡轨迹', palette.swing]);
  if (room.checkpoints?.length) legend.push(['检查点', palette.checkpoint]);
  document.querySelector('#legend').replaceChildren(...legend.map(([label, color]) => {
    const span = document.createElement('span'); span.className = 'key';
    const icon = document.createElement('i'); icon.style.color = color; icon.style.background = `${color}33`;
    span.append(icon, document.createTextNode(label)); return span;
  }));
  const facts = document.querySelector('#facts'); facts.replaceChildren();
  const entries = [
    ['空间提炼', intents[room.id]],
    ['地图结构', `${room.platforms.length} 个平台 · ${(room.climbs || []).length} 处攀爬 · ${(room.lifts || []).length} 台升降 · ${(room.swings || []).length} 处摆荡 · ${room.exits.length} 个出口`],
    ['原画依据', `docs/鲸腹遗城原画集/V2/images/${SCENES[room.id].reference}.png`],
    ['场景模块', `${SCENES[room.id].anatomy.type} · 材质 ${SCENES[room.id].material} · 中景视差 ${SCENES[room.id].anatomy.parallax}`],
    ['连接关系', room.exits.map(exit => `${room.name} → ${rooms[exit.to].name}${exit.requires ? `（${exit.requires}）` : ''}`).join('；')],
  ];
  for (const [label, value] of entries) {
    const div = document.createElement('div'); const strong = document.createElement('strong'); strong.textContent = `${label}：`;
    div.append(strong, document.createTextNode(value)); if (label === '原画依据') div.className = 'source'; facts.append(div);
  }
  drawMap();
}
for (const [index, id] of order.entries()) {
  const room = rooms.find(candidate => candidate.id === id);
  const button = document.createElement('button'); button.dataset.room = id; button.type = 'button';
  const title = document.createElement('strong'); title.textContent = `${String(index + 1).padStart(2, '0')}　${room.name}`;
  const meta = document.createElement('small'); meta.textContent = `${room.width} × 740 · ${room.id}`;
  button.append(title, meta); button.addEventListener('click', () => updateRoom(room)); document.querySelector('#rooms').append(button);
}
for (const input of document.querySelectorAll('[data-layer]')) input.addEventListener('change', () => {
  input.checked ? enabled.add(input.dataset.layer) : enabled.delete(input.dataset.layer); drawMap();
});
document.querySelector('#time').addEventListener('input', event => { time = Number(event.target.value); drawMap(); });
document.querySelector('#play').addEventListener('click', event => {
  playing = !playing; event.currentTarget.textContent = playing ? '暂停设施' : '播放设施'; event.currentTarget.setAttribute('aria-pressed', String(playing));
});
function frame(now) {
  if (playing) {
    time = (time + Math.min((now - previous) / 1000, 0.1)) % 12;
    document.querySelector('#time').value = String(time); drawMap();
  }
  previous = now; requestAnimationFrame(frame);
}
updateRoom(selected);
requestAnimationFrame(frame);
