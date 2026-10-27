// Local recovery is compressed into a short, playable interval for this slice.
export const HABITATS = [
  {
    id: 'habitat-mouth', room: 0, name: '鲸须菌席', resident: '食腐虾群', requires: 'long-gate',
    hint: '先用长鸣打开第二道鲸须，让营养流抵达菌席。',
    restoredText: '菌丝在鲸须旁舒展开来。食腐虾群循着营养流，在这里停留。', duration: 12,
  },
  {
    id: 'habitat-stomach', room: 1, name: '营养坡', resident: '骨礁双壳', requires: 'drain',
    hint: '先转动胃瓣排流，让营养坡露出安全的附着面。',
    restoredText: '排流后的坡面接住了细小的沉积。骨礁双壳张开外壳，滤取经过的营养。', duration: 12,
  },
  {
    id: 'habitat-lung', room: 2, name: '浮膜巢', resident: '浮膜幼体', requires: 'float',
    hint: '先接纳共生浮膜，再帮助高处的浮膜巢重新舒展。',
    restoredText: '薄膜托住了一处安静的水流。浮膜幼体在巢边轻轻漂动。', duration: 12,
  },
];

export function getHabitatStatus(state, id) {
  const habitat = HABITATS.find(h => h.id === id);
  if (!habitat) return { phase: 'dormant', progress: 0 };
  // Existing V2 saves already used these flags for completed repairs.
  if (state.flags?.has(id)) return { phase: 'restored', progress: 1 };
  if (!Object.prototype.hasOwnProperty.call(state.habitats || {}, id)) return { phase: 'dormant', progress: 0 };
  const seconds = state.habitats[id];
  return { phase: 'recovering', progress: Number.isFinite(seconds) ? Math.min(1, Math.max(0, seconds / habitat.duration)) : 0 };
}
