import { rooms, memories } from './levels.js';
import { HABITATS, getHabitatStatus } from './ecology.js';

export function ecologySummary(state) {
  const phases = HABITATS.map(h => getHabitatStatus(state, h.id).phase);
  return { restored: phases.filter(p => p === 'restored').length, recovering: phases.filter(p => p === 'recovering').length };
}

function habitatNote(state, habitat) {
  if (!state.visited.has(habitat.room)) return '<p class="muted">抵达后记录这里的生命。</p>';
  const { phase, progress } = getHabitatStatus(state, habitat.id);
  const label = { dormant: '○ 待修复', recovering: '◒ 恢复中', restored: '● 已恢复' }[phase];
  const detail = phase === 'restored' ? habitat.restoredText
    : phase === 'recovering' ? '营养流已接通，生命正在回来。可以先去探索，再回来看看。'
      : state.flags.has(habitat.requires) ? `靠近${habitat.name}按 F，留下一处新的栖息地。` : habitat.hint;
  return `<div class="habitat-note" data-habitat="${habitat.id}" data-phase="${phase}"><span class="habitat-state ${phase}">${label}</span><p>${detail}</p>${phase === 'recovering' ? `<div class="habitat-meter" role="progressbar" aria-label="${habitat.name}恢复进度" aria-valuenow="${Math.floor(progress * 100)}" aria-valuemin="0" aria-valuemax="100"><span style="width:${progress * 100}%"></span></div><small>继续探索时生长 · 面板中暂停</small>` : ''}</div>`;
}

export function renderEcology(state) {
  return `<div class="cards ecology-cards">${HABITATS.map(h => {
    const known = state.visited.has(h.room), phase = getHabitatStatus(state, h.id).phase;
    return `<article class="card ecology-card ${known ? phase : 'undiscovered'}"><span class="eyebrow">${known ? rooms[h.room].name : '未探索区域'}</span><h3>${known ? h.name : '尚未记录的栖息地'}</h3>${known ? `<p class="resident">${h.resident}</p>` : ''}${habitatNote(state, h)}</article>`;
  }).join('')}</div>`;
}

function routeDiagram(state) {
  const order = [0, 1, 3, 2], positions = [80, 270, 460, 650];
  const links = order.slice(0, -1).map((room, i) => {
    const exit = rooms[room].exits.find(e => e.to === order[i + 1]);
    const known = state.visited.has(room), open = known && (!exit.requires || state.flags.has(exit.requires));
    return `<path class="map-link ${open ? 'open' : 'closed'}" d="M${positions[i] + 25} 104 H${positions[i + 1] - 25}"/><text class="map-link-label" x="${(positions[i] + positions[i + 1]) / 2}" y="92">${known ? open ? '已通行' : '待开通' : '···'}</text>`;
  }).join('');
  const nodes = order.map((room, i) => {
    const known = state.visited.has(room), current = state.room === room;
    return `<g class="map-station ${known ? 'visited' : 'undiscovered'} ${current ? 'current' : ''}"><circle cx="${positions[i]}" cy="104" r="${current ? 21 : 16}"/><text class="map-station-number" x="${positions[i]}" y="109">${known ? `0${i + 1}` : '?'}</text><text class="map-station-name" x="${positions[i]}" y="153">${known ? rooms[room].name : '未知区域'}</text>${current ? `<text class="map-current-label" x="${positions[i]}" y="176">你在这里</text>` : ''}</g>`;
  }).join('');
  const shortcut = state.visited.has(2) ? `<path class="map-link shortcut ${state.flags.has('shortcut') ? 'open' : 'closed'}" d="M650 79 V46 Q650 28 632 28 H98 Q80 28 80 46 V79"/><text class="map-link-label" x="365" y="20">${state.flags.has('shortcut') ? '旧伤裂隙 → 鲸口高台 · 已开放' : '高位裂隙 · 待开启'}</text>` : '';
  return `<svg class="field-map" viewBox="0 0 730 192" role="img" aria-label="四区域路线示意，实线为已开通，虚线为待开通。当前位于${rooms[state.room].name}">${links}${shortcut}${nodes}</svg>`;
}

export function renderFieldMap(state, objective) {
  const summary = ecologySummary(state);
  return `<p class="eyebrow">FIELD MAP · 已探索 ${state.visited.size} / ${rooms.length}</p>${routeDiagram(state)}<div class="field-objective"><span class="small-label">接下来的旅程</span><p>${objective}</p></div><div class="cards room-cards">${[0, 1, 3, 2].map((i, order) => {
    const room = rooms[i], known = state.visited.has(i), habitat = HABITATS.find(h => h.room === i);
    const collected = room.memories.filter(m => state.memories.has(m.id)).length;
    return `<article class="card map-node ${state.room === i ? 'current' : ''}"><span class="eyebrow">0${order + 1} ${state.room === i ? '· 当前所在' : ''}</span><h3>${known ? room.name : '尚未抵达的轮廓'}</h3><p>${known ? i === 3 ? `设施 ${['course-climb', 'course-lift', 'course-swing'].filter(f => state.flags.has(f)).length} / 3` : `记忆 ${collected} / ${room.memories.length}` : '沿水流继续探索'}</p>${known && habitat ? habitatNote(state, habitat) : ''}${known && i === 3 ? '<p class="muted">经过设施检查点时自动保存。</p>' : ''}</article>`;
  }).join('')}</div><p class="map-legend">实线：已开通 · 虚线：待开通 · 金色圆环：当前位置</p><p class="muted">栖息地 ${summary.restored} / ${HABITATS.length} 已恢复${summary.recovering ? ` · ${summary.recovering} 处恢复中` : ''}。营地与设施落脚点保存进度；跌落保留修复与收集。</p>`;
}

export function renderJournal(state) {
  const summary = ecologySummary(state);
  return `<p class="eyebrow">LIVING FIELD NOTES · 栖息地 ${summary.restored} / ${HABITATS.length}</p><p>留下一处栖息地，再回来看生命怎样接续。修复在探索中逐渐完成，无需守在原地。</p>${renderEcology(state)}<h3 class="journal-section">拾回的歌纹 <span>${state.memories.size} / ${Object.keys(memories).length}</span></h3><div class="cards">${Object.entries(memories).map(([id, m]) => `<article class="card"><span class="eyebrow">${state.memories.has(id) ? '◇ 已拾回' : '○ 尚未发现'}</span><h3>${state.memories.has(id) ? m.title : '一段未被听见的回声'}</h3><p>${state.memories.has(id) ? m.text : '观察高处、低槽与回程中的旧路。'}</p></article>`).join('')}</div><p class="muted">一鲸落，万物生。这里没有复活的鲸，只有逐渐接续的生命。</p>`;
}
