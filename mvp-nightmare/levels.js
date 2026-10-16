export const levels = [
  {
    id: 'threshold', name: '失声门庭', subtitle: 'THE SILENT THRESHOLD', beat: '探索 · 搬运 · 发现',
    width: 2300, floor: 574, spawn: { x: 150, y: 512, z: 0 },
    platforms: [], gaps: [], hides: [],
    crateStart: 540, rail: { min: 420, max: 970 }, plate: { x: 880, w: 110 },
    gate: { x: 1140, y: 274, w: 42, h: 300 }, crawl: { x: 1430, w: 250, clearance: 40 },
    exit: { x: 2180, y: 574 },
    objects: [
      { id: 'weight-clue', kind: 'mural', x: 300, y: 506, z: 0, label: '读刻痕' },
      { id: 'memory-0', kind: 'memory', x: 1880, y: 524, z: -.65, label: '听残留的声音' },
    ],
  },
  {
    id: 'listener', name: '听骨廊', subtitle: 'THE LISTENING HALL', beat: '观察 · 藏身 · 穿行',
    width: 2640, floor: 574, spawn: { x: 140, y: 512, z: 0 },
    platforms: [], gaps: [],
    hides: [{ x: 690, w: 180 }, { x: 1180, w: 200 }, { x: 1730, w: 190 }],
    gate: { x: 2470, y: 274, w: 42, h: 300 }, exit: { x: 2550, y: 574 },
    objects: [
      { id: 'hide-clue', kind: 'mural', x: 350, y: 506, z: 0, label: '读墙上的警告' },
      { id: 'fuse', kind: 'fuse', x: 1280, y: 534, z: -.65, label: '取走潮汐电芯' },
      { id: 'socket', kind: 'socket', x: 2320, y: 524, z: 0, label: '装入电芯' },
      { id: 'memory-1', kind: 'memory', x: 2080, y: 524, z: -.65, label: '听残留的声音' },
    ],
  },
  {
    id: 'heart', name: '最后一次心跳', subtitle: 'THE LAST HEARTBEAT', beat: '解码 · 唤醒 · 逃离',
    width: 3090, floor: 574, spawn: { x: 140, y: 512, z: 0 },
    platforms: [{ x: 1670, y: 534, w: 100, h: 40, kind: 'bone' }, { x: 2390, y: 534, w: 100, h: 40, kind: 'bone' }],
    gaps: [{ x: 1280, w: 130 }, { x: 1940, w: 135 }], hides: [],
    exit: { x: 2960, y: 574 },
    objects: [
      { id: 'order-clue', kind: 'mural', x: 300, y: 496, z: 0, label: '读泵上的刻痕' },
      { id: 'valve-1', kind: 'valve', number: 1, x: 490, y: 514, z: 0, label: '转动第一枚阀' },
      { id: 'valve-2', kind: 'valve', number: 2, x: 660, y: 514, z: 0, label: '转动第二枚阀' },
      { id: 'valve-3', kind: 'valve', number: 3, x: 830, y: 514, z: 0, label: '转动第三枚阀' },
      { id: 'memory-2', kind: 'memory', x: 1050, y: 524, z: -.65, label: '听残留的声音' },
    ],
  },
];

export const clues = {
  'weight-clue': '刻痕里画着一只箱子，压住秤盘，鲸须才肯抬起。靠近木箱，按住 E ＋ 方向键拖动。',
  'hide-clue': '它睁眼时，连脚步也会被听见。走进凹下的骨龛（W），蹲低（C），等它闭眼。',
  'order-clue': '三道刻痕从左往右，深浅却不同。铜管上的编号依次是 Ⅱ → Ⅰ → Ⅲ。',
  'memory-0': '“它曾载着一整个季节的光。如今，我只能借走一盏。”',
  'memory-1': '“这里的看守没有名字。它只记得，那些来不及屏住的呼吸。”',
  'memory-2': '“如果心脏再次跳动，别回头。替它去看看海面。”',
};
