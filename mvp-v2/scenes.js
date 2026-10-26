// Production scene assembly, separate from gameplay geometry in levels.js.
// V2 sheets are references, never level backgrounds. These modules describe only
// depth layers and reusable terrain art. Only levels.js defines collision.
const atmosphere = { src: './assets/abyss-backdrop-v2.png', parallax: 0.08 };
// Crop beneath the uneven skyline: the crop's first row is the walkable top.
// The original outer spikes are excluded; internal transparent holes remain.
const boneLedge = {
  src: './assets/bone-ledge-v2.png',
  crop: { x: 260, y: 246, w: 1480, h: 340 },
  scale: 0.23,
};
export const SCENES = {
  mouth: {
    reference: 'L02_鲸口门庭', palette: { top: '#153744', deep: '#071d27', tint: '#365862' },
    atmosphere, anatomy: { type: 'baleen', parallax: 0.22, spacing: 360 }, material: 'bone', terrain: { bone: boneLedge },
  },
  stomach: {
    reference: 'L04_胃库沼泽', palette: { top: '#283b35', deep: '#101f24', tint: '#5a5b3e' },
    atmosphere, anatomy: { type: 'chambers', parallax: 0.24, spacing: 430 }, material: 'tissue',
  },
  lung: {
    reference: 'L05_肺叶迷雾', palette: { top: '#17434a', deep: '#0a222d', tint: '#3d7474' },
    atmosphere, anatomy: { type: 'bronchi', parallax: 0.2, spacing: 460 }, material: 'membrane',
  },
  ribs: {
    reference: 'L09_肋骨穹顶', palette: { top: '#273a4a', deep: '#0d1e2c', tint: '#4d5a72' },
    atmosphere, anatomy: { type: 'ribs', parallax: 0.26, spacing: 340 }, material: 'bone', terrain: { bone: boneLedge },
  },
};
