// A compressed, connected slice. V5.2 source silhouettes are adapted to this
// route; they are not a literal reconstruction of its 36 rooms.
const terrain = (id, kind, points, source) => ({ id, kind, points: points.map(([x, y]) => ({ x, y })), bottom: 740, source });
export const rooms = [
  {
    id: 'mouth', name: '鲸口门庭', subtitle: '循着虾群，听见第一道回声', depth: '1,240', width: 2400,
    spawn: { x: 150, y: 532 },
    terrain: [
      terrain('mouth-entry-ridge', 'tissue', [[0,580],[240,580],[420,530],[570,530],[650,550],[730,580]], 'R1-02 须筛：宽丘与鞍部'),
      terrain('mouth-return-bank', 'tissue', [[880,580],[960,550],[1140,550],[1340,540],[1480,580],[1640,580],[1790,540],[2000,540],[2160,580],[2400,580]], 'R1-02 须筛：低路返坡'),
    ],
    platforms: [
      { id: 'tongue', x: 730, y: 580, w: 150, h: 160, kind: 'soft' },
      { x: 430, y: 300, w: 530, h: 45, kind: 'bone' },
      { x: 1200, y: 450, w: 190, h: 32, kind: 'bone' },
    ],
    gates: [
      { id: 'short-gate', x: 550, y: 290, w: 45, h: 290, kind: 'short' },
      { id: 'long-gate', x: 1550, y: 240, w: 50, h: 340, kind: 'long' },
    ],
    objects: [
      { id: 'camp-mouth', type: 'camp', x: 170, y: 580, label: '贝壳营地' },
      { id: 'refill-mouth', type: 'refill', x: 1010, y: 550, label: '再充压力囊' },
      { id: 'habitat-mouth', type: 'habitat', x: 1910, y: 540, label: '修复菌席' },
    ],
    memories: [{ id: 'song', x: 1080, y: 535 }, { id: 'return', x: 620, y: 255 }],
    exits: [{ x: 2260, y: 580, to: 1, label: '沿食道 → 胃库', requires: 'long-gate' }], hazards: [],
  },
  {
    id: 'stomach', name: '胃库沼泽', subtitle: '让出一条路，也留下一处栖息地', depth: '1,268', width: 2400,
    spawn: { x: 170, y: 532 },
    terrain: [
      terrain('gastric-fold-bank', 'tissue', [[0,580],[440,580],[600,530],[850,530],[1010,580],[1200,580]], 'R3-02 漂台阀：厚褶岸台'),
      { ...terrain('gastric-drained-bed', 'tissue', [[1200,630],[1330,650],[1460,630],[1580,650],[1680,630]], 'R3-02 漂台阀：下陷危险沟'), requires: 'drain' },
      terrain('gastric-restoration-bank', 'tissue', [[1680,580],[1880,580],[1970,540],[2090,540],[2160,580],[2400,580]], 'R3-02 漂台阀：对岸高低褶面'),
    ],
    platforms: [
      { x: 1300, y: 520, w: 130, h: 30, kind: 'raft' },
      { x: 1510, y: 490, w: 130, h: 30, kind: 'raft' },
    ], gates: [],
    objects: [
      { id: 'food', type: 'food', x: 370, y: 580, label: '拾取可再生腐屑' },
      { id: 'fed', type: 'crab', x: 730, y: 530, label: '投喂尸蟹' },
      { id: 'drain', type: 'valve', x: 1080, y: 580, label: '转动胃瓣 · 排流' },
      { id: 'camp-stomach', type: 'camp', x: 1840, y: 580, label: '贝壳营地' },
      { id: 'habitat-stomach', type: 'habitat', x: 2010, y: 540, label: '修复营养坡' },
    ],
    memories: [{ id: 'drift', x: 1460, y: 591 }],
    exits: [{ x: 80, y: 580, to: 0, label: '返回鲸口' }, { x: 2290, y: 580, to: 3, label: '组织裂隙 → 肋骨游廊', requires: 'drain' }],
    hazards: [{ x: 1200, y: 600, w: 480, h: 120 }],
  },
  {
    id: 'lung', name: '肺缘浮庭', subtitle: '借一口压差，回到曾经仰望的地方', depth: '1,251', width: 2400,
    spawn: { x: 150, y: 532 },
    terrain: [terrain('lung-soft-basin', 'membrane', [[0,580],[800,580],[980,635],[1360,645],[1630,600],[1850,580],[2400,580]], 'R2-01 育床：下凹软床与独立分层膜岸')],
    platforms: [
      { x: 820, y: 380, w: 500, h: 42, kind: 'membrane' },
      { x: 1600, y: 190, w: 800, h: 45, kind: 'bone' },
    ], gates: [],
    objects: [
      { id: 'camp-lung', type: 'camp', x: 260, y: 580, label: '贝壳营地' },
      { id: 'float', type: 'float', x: 500, y: 580, label: '接纳共生浮膜' },
      { id: 'refill-low', type: 'refill', x: 730, y: 580, label: '补充浮膜压力' },
      { id: 'refill-mid', type: 'refill', x: 1130, y: 380, label: '补充浮膜压力' },
      { id: 'refill-high', type: 'refill', x: 1770, y: 190, label: '补充浮膜压力' },
      { id: 'habitat-lung', type: 'habitat', x: 1940, y: 190, label: '修复浮膜巢' },
      { id: 'shortcut', type: 'shortcut', x: 2220, y: 190, label: '打开旧伤裂隙' },
    ],
    memories: [{ id: 'surface', x: 1460, y: 255 }],
    exits: [{ x: 80, y: 580, to: 3, label: '返回肋骨游廊', spawn: { x: 2260, y: 222 } }, { x: 2300, y: 190, to: 0, label: '捷径 → 鲸口高台', requires: 'shortcut', spawn: { x: 850, y: 252 } }], hazards: [],
  },
  {
    id: 'ribs', name: '肋骨游廊', subtitle: '攀上菌丝网，搭乘浮囊，借骨环荡向远处', depth: '1,259', width: 2400,
    spawn: { x: 150, y: 572 },
    platforms: [
      { x: 0, y: 620, w: 390, h: 100, kind: 'bone' },
      { x: 390, y: 660, w: 2010, h: 60, kind: 'safety' },
      { x: 370, y: 380, w: 350, h: 28, kind: 'bone' },
      { x: 1000, y: 200, w: 320, h: 28, kind: 'bone' },
      { x: 1710, y: 350, w: 280, h: 28, kind: 'bone' },
      { x: 1980, y: 300, w: 130, h: 28, kind: 'bone' },
      { x: 2090, y: 270, w: 310, h: 32, kind: 'bone' },
    ],
    climbs: [{ id: 'mycelium-net', x: 405, y: 380, w: 140, h: 280 }],
    lifts: [{ id: 'bladder-lift', x: 790, w: 180, h: 26, minY: 190, maxY: 490, period: 6, requires: 'course-powered' }],
    swings: [{ id: 'bone-ring', x: 1470, y: 70, length: 280, amplitude: 0.92, period: 4.6 }],
    currents: [{ x: 1930, y: 360, w: 100, h: 300 }],
    checkpoints: [{ x: 1100, y: 152 }, { x: 1770, y: 302 }],
    gates: [], hazards: [], memories: [],
    objects: [
      { id: 'camp-ribs', type: 'camp', x: 220, y: 620, label: '攀爬营地 · 保存进度' },
      { id: 'course-powered', type: 'course-power', x: 640, y: 380, label: '开启浮囊升降台' },
      { id: 'course-reset', type: 'course-reset', x: 1670, y: 660, label: '回到最近攀爬检查点' },
      { id: 'course-clear', type: 'course-finish', x: 2220, y: 270, label: '拉下通路拉杆' },
    ],
    exits: [
      { x: 75, y: 620, to: 1, label: '返回胃库', spawn: { x: 2180, y: 532 } },
      { x: 2330, y: 270, to: 2, label: '肋间通路 → 肺缘', requires: 'course-clear' },
    ],
  },
];

export const memories = {
  song: { title: '第一道歌纹', text: '鲸须间留下三个音。虾群沿着它们曾经指向的水流，找到新的食物。' },
  drift: { title: '漂来的细线', text: '一缕网线沉在低处。拾潮者把它卷起，为路过的幼体留出空隙。' },
  surface: { title: '海面之光', text: '薄膜里的一线金色，像很久以前的海面。这不是呼吸，是水流经过留下的回声。' },
  return: { title: '仰望过的地方', text: '第一次经过时，这里遥不可及。如今，一片小小的共生浮膜带你回到旧路上方。' },
};
