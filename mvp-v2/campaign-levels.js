// V5.2 R1 first playable batch. World topology and room sizes come from the
// saved full design; collision shapes are explicit gameplay adaptations.
// The authoritative layout SVG/JSON is currently unavailable, so these shapes
// must not be described as an exact reconstruction of its geometry.
export const UNIT = 48;
const u = value => value * UNIT;
const spawn = (x, floor) => ({ x: u(x) - 15, y: u(floor) - UNIT });
const platform = (id, x, y, w, h = .6, kind = 'tissue') => ({ id, x: u(x), y: u(y), w: u(w), h: u(h), kind });
const fold = (id, points, bottom, source) => ({ id, kind: 'tissue', points: points.map(([x, y]) => ({ x: u(x), y: u(y) })), bottom: u(bottom), source });
// Sample each smooth rise into the same polyline used by drawing and collision.
// Source anchors remain exact; intermediate curvature is gameplay adaptation.
const rounded = anchors => anchors.flatMap(([x, y], index) => {
  if (index === anchors.length - 1) return [[x, y]];
  const [nextX, nextY] = anchors[index + 1];
  const steps = Math.max(1, Math.ceil((nextX - x) / .35));
  return Array.from({ length: steps }, (_, step) => {
    const t = step / steps;
    return [x + (nextX - x) * t, y + (nextY - y) * t * t * (3 - 2 * t)];
  });
});
const at = (id, type, x, y, label, extra = {}) => ({ id, type, x: u(x), y: u(y), label, ...extra });
const exit = (room, edgeId, x, y, to, targetX, targetFloor, requires = [], extra = {}) => ({
  id: `${room}-${edgeId}`, edgeId, x: u(x), y: u(y), to,
  spawn: spawn(targetX, targetFloor), requires, label: `前往 ${to}`, ...extra,
});
const crab = (id, x, floor) => ({ id, type: 'corpse-crab', x: u(x), y: u(floor), patrolMin: u(x - 1.25), patrolMax: u(x + 1.25), sourceAtU: [x, floor] });
const hazard = (id, type, x, y, w, h, extra = {}) => ({ id, type, x: u(x), y: u(y), w: u(w), h: u(h), ...extra });
const reference = id => ({
  page: `http://10.11.140.20:8765/full/#room-${id}`,
  layout: `http://10.11.140.20:8765/full/maps/rooms/${id}.svg`,
  snapshot: 'assets/source/whalefall-v5-2-complete/inventory/full-source.html',
});
const room = (id, name, width, height, fields) => ({
  id, name, region: 'R1', width: u(width), height: u(height), sizeU: [width, height],
  platforms: [], terrain: [], camps: [], enemies: [], hazards: [], objects: [], exits: [],
  references: reference(id), layoutStatus: 'adapted-from-source',
  coordinateNotes: 'World pixels at 48 px/U; entity x/y are ground or source anchor positions; spawn is player top-left. Geometry not specified in source text is provisional playtest tuning.',
  ...fields,
});

export const CAMPAIGN_ROOMS = [
  room('R1-01', '外伤坡', 30, 18, {
    subtitle: '沿受光坡入鲸，学会走跳与辨认可站顶边。',
    spawn: spawn(1.5, 16),
    geometryNotes: ['按中文通关流程向右推进，只有一条 E01；旧英文绘图提示词写左侧出口，与中文方向冲突，待源布局核对。', '保留第一条1U教学缝；后续高差适配成圆润隆起与下坡，曲率不是源结构图坐标。'],
    terrain: [
      fold('R1-01-entry-slope', rounded([[0,16],[2.5,16],[4.2,16.15],[7,15.5],[8,15.5]]), 18, 'R1-01 浅亮入鲸坡；曲面适配'),
      fold('R1-01-shade-ridges', rounded([[9,15.5],[11,15.5],[13.5,14.9],[16,14.2],[18,14.35],[21,13.3],[23,13.6],[26.5,15.5],[30,15.5]]), 18, 'R1-01 须影低岸、圆润隆起与返坡；曲面适配'),
      fold('R1-01-soft-recovery', [[8,17],[9,17]], 18, 'R1-01 缝底无伤恢复台'),
    ],
    camps: [{ id: 'CAMP_R1_ENTRY', name: '入鲸营地', x: u(2), y: u(16) }],
    exits: [exit('R1-01', 'E01', 28.5, 15.5, 'R1-02', 1.5, 18, [], { label: '沿口角创口 → 须筛' })],
  }),
  room('R1-02', '须筛', 38, 21, {
    subtitle: '观察尸蟹举钳，步退后短击；记住高处两条旧路。',
    spawn: spawn(1.5, 18),
    geometryNotes: ['尸蟹(11,16)U、虾流(23,16)U及三个骨环位置来自源文；低路丘面为适配。', '左井相邻层差4U，右侧高门无斜坡绕行；A2/A3支路等待对应批次开放。'],
    terrain: [fold('R1-02-low-return-route', rounded([[0,18],[2.5,18],[4.5,17.8],[6,18.1],[9.75,16],[12.25,16],[16.8,17.6],[19,17.15],[22,16],[24,16],[27,17.3],[30,18.15],[32.5,17.6],[35.5,18],[38,18]]), 21, 'R1-02 宽丘低路、凹部与返坡；圆润曲面为适配')],
    platforms: [
      platform('R1-02-shaft-low', 2, 14.5, 5),
      platform('R1-02-shaft-mid', 2, 10.5, 5),
      platform('R1-02-shaft-high', 2, 6.5, 5),
      platform('R1-02-anchor-high', 32.5, 10, 5.5),
    ],
    anchors: [[26,13],[29,10],[32,7]].map(([x,y], i) => ({ id: `R1-02-anchor-${i+1}`, x: u(x), y: u(y), requires: ['A3'], unavailable: true })),
    enemies: [crab('R1-02-corpse-crab', 11, 16)],
    hazards: [hazard('R1-02-shrimp-lane', 'damage', 22, 15.6, 2, .45, { mechanism: 'shrimp-migration', sourceAtU: [23,16], warning: .7, period: 4, damage: 1 })],
    exits: [
      exit('R1-02', 'E01', 1, 18, 'R1-01', 28, 15.5, [], { label: '返回外伤坡' }),
      exit('R1-02', 'E02', 36.5, 18, 'R1-03', 1.5, 15, [], { label: '沿须筛下缘 → 舌台' }),
      exit('R1-02', 'E33', 5, 6.5, 'R1-06', 2, 21, ['A2'], { unavailable: true, label: '旧创伤竖井 · 需要浮膜 A2，后续批次开放' }),
      exit('R1-02', 'E35', 33, 10, 'R1-07', 2, 15, ['A3'], { unavailable: true, label: '须根侧袋 · 需要锚定 A3，后续批次开放' }),
    ],
  }),
  room('R1-03', '舌台', 36, 18, {
    subtitle: '错开两蟹的举钳节拍，越过承重膜，取固定生命碎片。',
    spawn: spawn(1.5, 15),
    geometryNotes: ['两蟹(11,13)/(24,12.8)U、承重膜(16,14)U、碎片(24.5,10.5)U来自源表。', '奖励台比第二丘高1.5U；低路丘面与平台宽度为适配。'],
    terrain: [fold('R1-03-tongue-ridges', rounded([[0,15],[2.5,15],[4,14.8],[7.5,13.2],[9.75,13],[12.25,13],[15,13.8],[16,14],[18,14],[20,13.65],[22,12.8],[25.25,12.8],[27,13],[30.5,14.7],[32,15.15],[33.5,15],[36,15]]), 18, 'R1-03 两丘与中央下陷舌膜；圆润曲面为适配')],
    platforms: [platform('R1-03-reward-ledge', 23, 11.3, 4)],
    enemies: [crab('R1-03-corpse-crab-left', 11, 13), crab('R1-03-corpse-crab-right', 24, 12.8)],
    hazards: [hazard('R1-03-weight-membrane', 'damage', 16, 13.65, 2, .4, { mechanism: 'weight-membrane', sourceAtU: [16,14], warning: .7, period: 4.5, damage: 1 })],
    objects: [at('FRAGMENT_R1_03', 'fragment', 24.5, 10.5, '取生命碎片', { sourceAtU: [24.5,10.5] })],
    exits: [
      exit('R1-03', 'E02', 1, 15, 'R1-02', 36, 18, [], { label: '返回须筛' }),
      exit('R1-03', 'E03', 34.5, 15, 'R1-04', 2, 14, [], { label: '舌根 → 负壳蟹门庭' }),
    ],
  }),
  room('R1-04', '负壳蟹', 36, 18, {
    subtitle: '先在门庭登记；走跳短击击败负壳蟹，再承接贴流冲。',
    spawn: spawn(2, 14),
    geometryNotes: ['营地x2、战斗线x6、首领(22,14)、两侧低台x10–14/x25–29及高差1.5U来自源文。', '首领空间保持宽平；回营地无需重穿杂兵。'],
    terrain: [fold('R1-04-arena-floor', [[0,14],[36,14]], 18, 'R1-04 宽平战场与独立前室')],
    platforms: [platform('R1-04-left-ledge', 10, 12.5, 4), platform('R1-04-right-ledge', 25, 12.5, 4)],
    camps: [{ id: 'CAMP_R1_BOSS', name: '蟹前营地', x: u(2), y: u(14) }],
    arena: { left: u(6), right: u(34), triggerX: u(6), victoryFlag: 'BOSS_R1' },
    enemies: [{ id: 'BOSS_R1', type: 'gate-shell-crab', x: u(22), y: u(14), patrolMin: u(10), patrolMax: u(30), triggerX: u(6), victoryFlag: 'BOSS_R1', sourceAtU: [22,14] }],
    objects: [at('GRANT_A1', 'ability', 32, 13.2, '承接贴流冲 A1', { grants: 'A1', requires: ['BOSS_R1'], sourceAtU: [32,13.2] })],
    exits: [
      exit('R1-04', 'E03', 1, 14, 'R1-03', 34, 15, [], { label: '返回舌台' }),
      exit('R1-04', 'E04', 35, 14, 'R1-05', 2, 14, ['BOSS_R1'], { label: '咽后纵裂 → 流膜育窝' }),
    ],
  }),
  room('R1-05', '流膜育窝', 38, 18, {
    subtitle: '三段4U沟：跳起、贴流冲、落台；每次离地只有一次冲刺。',
    spawn: spawn(2, 14),
    anatomy: 'esophagus',
    geometryNotes: ['三沟宽4U、独立5U落台、沟底(6/15/24,16)U与H1(4,13.2)U来自源流程。', '无伤恢复床不能形成平走绕过冲刺训练的通路；R3门只展示后续目标。'],
    platforms: [
      platform('R1-05-entry', 0, 14, 6, 2), platform('R1-05-middle-a', 10, 14, 5, 2),
      platform('R1-05-middle-b', 19, 14, 5, 2), platform('R1-05-exit', 28, 14, 10, 2),
      platform('R1-05-habitat-side-ledge', 3.2, 13.2, 1.6, .8),
    ],
    recoveryY: u(16), softRecovery: true,
    hazards: [6,15,24].map((x, i) => hazard(`R1-05-teaching-gap-${i+1}`, 'soft', x, 16, 4, 2, { mechanism: 'teaching', damage: 0, recovery: 'stable', sourceAtU: [x,16] })),
    objects: [at('H1', 'habitat', 4, 13.2, '安置空壳 · 清流窝', { grants: 'H1', requires: ['A1'], requireDashPractice: true, sourceAtU: [4,13.2], sourceAction: '冲刺教学后将一只空壳安置在侧台，清流窝显露' })],
    exits: [
      exit('R1-05', 'E04', 1, 14, 'R1-04', 34, 14, ['BOSS_R1'], { label: '返回负壳蟹门庭' }),
      exit('R1-05', 'E05', 36.5, 14, 'R3-01', 2, 26, ['A1'], { unavailable: true, label: '前胃枢纽 · 本批到此，下一批开放' }),
    ],
  }),
  room('R1-06', '喷气孔上层', 24, 24, {
    subtitle: '浮膜回访支路；本批展示设计，暂不开放。',
    available: false, requires: ['A2'], anatomy: 'nasal-trauma',
    spawn: spawn(2, 21),
    geometryNotes: ['四级膜岸为源意图适配，需后续浮膜能力和补压验证；本批不可进入。'],
    platforms: [platform('R1-06-low', 0, 21, 7), platform('R1-06-mid-a', 7, 17, 4), platform('R1-06-mid-b', 12, 13, 4), platform('R1-06-high', 17, 11, 7)],
    objects: [at('MODULE_QUIET_FUNGUS', 'module', 18, 10.2, '静菌模块', { grants: 'quiet-fungus', sourceAtU: [18,10.2] })],
    exits: [
      exit('R1-06', 'E33', 1, 21, 'R1-02', 5, 6.5, ['A2']),
      exit('R1-06', 'E34', 22, 11, 'R2-05', 2, 17, ['A2','SC_BLOWHOLE'], { unavailable: true, openFrom: 'R2-05', label: '肺侧远端闩 · 须从回流出口开启' }),
    ],
  }),
  room('R1-07', '鲸须记忆袋', 28, 19, {
    subtitle: '固定环回访支路；本批展示设计，暂不开放。',
    available: false, requires: ['A3'],
    spawn: spawn(2, 15),
    geometryNotes: ['三台x0–6/11–16/21–28、等高y15、四环x7.5/10.5/17.5/20.5与y12来自源文。', '只有左侧E35；右侧封闭，不凭原画装饰添加出口。'],
    platforms: [platform('R1-07-left', 0, 15, 6), platform('R1-07-middle', 11, 15, 5), platform('R1-07-right', 21, 15, 7)],
    anchors: [7.5,10.5,17.5,20.5].map((x,i) => ({ id: `R1-07-anchor-${i+1}`, x: u(x), y: u(12), requires: ['A3'], unavailable: true })),
    recoveryY: u(18), softRecovery: true,
    objects: [
      at('FRAGMENT_R1_07', 'fragment', 24.5, 14.2, '取生命碎片', { sourceAtU: [24.5,14.2] }),
      at('MEMORY_BALEEN', 'memory', 27, 14.2, '听取鲸须记忆', { sourceAtU: [27,14.2] }),
    ],
    exits: [exit('R1-07', 'E35', 1, 15, 'R1-02', 33, 10, ['A3'])],
  }),
];

export const CAMPAIGN_ROOM_BY_ID = Object.fromEntries(CAMPAIGN_ROOMS.map(room => [room.id, room]));

// Source-extracted world metadata, not a claim that later rooms are playable.
// Derived from the saved full-source.html tables and scene inventory.
export const WORLD_ROOMS = [
  {"id":"R1-01","name":"外伤坡","region":"R1","sizeU":[30,18],"available":true,"source":"http://10.11.140.20:8765/full/#room-R1-01"},
  {"id":"R1-02","name":"须筛","region":"R1","sizeU":[38,21],"available":true,"source":"http://10.11.140.20:8765/full/#room-R1-02"},
  {"id":"R1-03","name":"舌台","region":"R1","sizeU":[36,18],"available":true,"source":"http://10.11.140.20:8765/full/#room-R1-03"},
  {"id":"R1-04","name":"负壳蟹","region":"R1","sizeU":[36,18],"available":true,"source":"http://10.11.140.20:8765/full/#room-R1-04"},
  {"id":"R1-05","name":"流膜育窝","region":"R1","sizeU":[38,18],"available":true,"source":"http://10.11.140.20:8765/full/#room-R1-05"},
  {"id":"R1-06","name":"喷气孔上层","region":"R1","sizeU":[24,24],"available":false,"source":"http://10.11.140.20:8765/full/#room-R1-06"},
  {"id":"R1-07","name":"鲸须记忆袋","region":"R1","sizeU":[28,19],"available":false,"source":"http://10.11.140.20:8765/full/#room-R1-07"},
  {"id":"R2-01","name":"育床","region":"R2","sizeU":[28,23],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-01"},
  {"id":"R2-02","name":"双层肺膜","region":"R2","sizeU":[34,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-02"},
  {"id":"R2-03","name":"心室观察台","region":"R2","sizeU":[30,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-03"},
  {"id":"R2-04","name":"血巢潮群","region":"R2","sizeU":[36,23],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-04"},
  {"id":"R2-05","name":"回流出口","region":"R2","sizeU":[32,21],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-05"},
  {"id":"R2-06","name":"最后呼吸囊","region":"R2","sizeU":[25,27],"available":false,"source":"http://10.11.140.20:8765/full/#room-R2-06"},
  {"id":"R3-01","name":"胃枢","region":"R3","sizeU":[48,30],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-01"},
  {"id":"R3-02","name":"漂台阀","region":"R3","sizeU":[34,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-02"},
  {"id":"R3-03","name":"肝叶灯罩","region":"R3","sizeU":[38,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-03"},
  {"id":"R3-04","name":"脂槽刹车","region":"R3","sizeU":[40,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-04"},
  {"id":"R3-05","name":"肠入口","region":"R3","sizeU":[32,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-05"},
  {"id":"R3-06","name":"迁居搬盘","region":"R3","sizeU":[40,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-06"},
  {"id":"R3-07","name":"搬壳母蟹","region":"R3","sizeU":[40,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-07"},
  {"id":"R3-08","name":"胃顶沉积袋","region":"R3","sizeU":[30,25],"available":false,"source":"http://10.11.140.20:8765/full/#room-R3-08"},
  {"id":"R4-01","name":"组合门","region":"R4","sizeU":[30,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-01"},
  {"id":"R4-02","name":"低骨训练","region":"R4","sizeU":[36,24],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-02"},
  {"id":"R4-03","name":"上锚路线","region":"R4","sizeU":[36,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-03"},
  {"id":"R4-04","name":"下菌毯路线","region":"R4","sizeU":[40,21],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-04"},
  {"id":"R4-05","name":"悬脊鸣贝","region":"R4","sizeU":[40,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-05"},
  {"id":"R4-06","name":"稳定交通椎","region":"R4","sizeU":[34,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-06"},
  {"id":"R4-07","name":"修索小室","region":"R4","sizeU":[32,25],"available":false,"source":"http://10.11.140.20:8765/full/#room-R4-07"},
  {"id":"R5-01","name":"三槽记忆","region":"R5","sizeU":[30,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-01"},
  {"id":"R5-02","name":"安全池","region":"R5","sizeU":[32,21],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-02"},
  {"id":"R5-03","name":"薄缝训练","region":"R5","sizeU":[38,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-03"},
  {"id":"R5-04","name":"缄声覆膜","region":"R5","sizeU":[40,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-04"},
  {"id":"R5-05","name":"最后静默","region":"R5","sizeU":[28,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-05"},
  {"id":"R5-06","name":"记忆侧囊","region":"R5","sizeU":[28,22],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-06"},
  {"id":"R5-07","name":"尾根观察","region":"R5","sizeU":[34,21],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-07"},
  {"id":"R5-08","name":"归海释放槽","region":"R5","sizeU":[40,20],"available":false,"source":"http://10.11.140.20:8765/full/#room-R5-08"}
];
export const WORLD_EDGES = [
  {"id":"E01","from":"R1-01","to":"R1-02","routeType":"创伤腔连续","anatomyRoute":"口角创口→口腔侧壁","scaleType":"局部","requires":[]},
  {"id":"E02","from":"R1-02","to":"R1-03","routeType":"天然邻接","anatomyRoute":"须筛下缘→舌背","scaleType":"局部","requires":[]},
  {"id":"E03","from":"R1-03","to":"R1-04","routeType":"天然邻接","anatomyRoute":"舌背→舌根→口咽前庭","scaleType":"局部","requires":[]},
  {"id":"E04","from":"R1-04","to":"R1-05","routeType":"天然腔道＋分解损伤","anatomyRoute":"咽前台→咽后→塌陷食管纵裂边","scaleType":"局部","requires":["BOSS_R1"]},
  {"id":"E05","from":"R1-05","to":"R3-01","routeType":"天然消化道走向＋纵裂边通行","anatomyRoute":"咽后食管→胸腔内食管走向→横膈食管裂孔附近→前胃","scaleType":"长廊","requires":["A1"]},
  {"id":"E06","from":"R2-01","to":"R2-02","routeType":"同器官外表面邻接","anatomyRoute":"肺后缘胸膜面→肺叶外侧剥离层","scaleType":"局部","requires":["A2"]},
  {"id":"E07","from":"R2-02","to":"R2-03","routeType":"胸腔内损伤过渡","anatomyRoute":"肺外表面→胸膜破口→纵隔→心包外缘","scaleType":"跨器官","requires":[]},
  {"id":"E08","from":"R2-03","to":"R2-04","routeType":"破口进入","anatomyRoute":"心包外缘→心包旧破口→心室断壁旁","scaleType":"局部","requires":[]},
  {"id":"E09","from":"R2-04","to":"R2-05","routeType":"破口离开＋胸腔转向","anatomyRoute":"心室断壁旁→心包侧破口→前纵隔→气管旁","scaleType":"跨器官","requires":["BOSS_R2"]},
  {"id":"E10","from":"R3-01","to":"R2-01","routeType":"横膈/胃壁死后破口＋修补通道","anatomyRoute":"前胃外侧→横膈后面→横膈旧撕裂→肺后缘","scaleType":"跨器官","requires":["A1"]},
  {"id":"E11","from":"R3-01","to":"R3-02","routeType":"同器官褶层","anatomyRoute":"前胃裂缘→大胃褶","scaleType":"局部","requires":[]},
  {"id":"E12","from":"R3-02","to":"R3-03","routeType":"胃壁破口＋腹腔表面","anatomyRoute":"胃壁旧破口→腹腔→肝叶外缘","scaleType":"跨器官","requires":[]},
  {"id":"E13","from":"R3-03","to":"R3-04","routeType":"腹膜表面邻接","anatomyRoute":"肝叶外表面邻隙→系膜脂质沉积槽","scaleType":"局部","requires":[]},
  {"id":"E14","from":"R3-04","to":"R3-05","routeType":"腹腔邻接＋肠管破口","anatomyRoute":"系膜→胃出口附近→肠管纵裂入口","scaleType":"跨器官","requires":[]},
  {"id":"E15","from":"R3-05","to":"R3-06","routeType":"肠袢纵裂／系膜表面","anatomyRoute":"肠纵裂边→同一肠袢的系膜搬盘台","scaleType":"局部","requires":["A3"]},
  {"id":"E16","from":"R3-06","to":"R3-07","routeType":"肠袢连续","anatomyRoute":"回折肠袢→母蟹侧巢","scaleType":"局部","requires":[]},
  {"id":"E17","from":"R3-07","to":"R3-01","routeType":"分解破口＋聚落改造捷径","anatomyRoute":"回折肠袢侧腔→系膜维护坡→前胃外壁旧破口→胃枢","scaleType":"局部","requires":["SC_ESOPHAGUS"],"openFrom":"R3-07","firstOpenRequires":["BOSS_R3"]},
  {"id":"E18","from":"R3-01","to":"R4-01","routeType":"腹腔背外侧创伤＋修补闸","anatomyRoute":"胃外缘→腹腔背壁/横膈背外侧创伤→椎旁外廊","scaleType":"跨器官","requires":["P","A3"]},
  {"id":"E19","from":"R4-01","to":"R4-02","routeType":"椎旁外侧连续","anatomyRoute":"胸腰椎外侧→外露训练台","scaleType":"局部","requires":[]},
  {"id":"E20","from":"R4-02","to":"R4-03","routeType":"同椎旁区域分层","anatomyRoute":"训练台→椎体侧上缘","scaleType":"局部","requires":["A4"]},
  {"id":"E21","from":"R4-02","to":"R4-04","routeType":"同椎旁区域分层","anatomyRoute":"训练台→椎体下外侧肌膜沟","scaleType":"局部","requires":["A3"]},
  {"id":"E22","from":"R4-03","to":"R4-05","routeType":"外侧上路汇合","anatomyRoute":"椎旁上路→双贝宽骨台","scaleType":"局部","requires":[]},
  {"id":"E23","from":"R4-04","to":"R4-05","routeType":"外侧下路汇合","anatomyRoute":"椎旁下路→双贝宽骨台","scaleType":"局部","requires":[]},
  {"id":"E24","from":"R4-05","to":"R4-06","routeType":"椎旁纵向连续","anatomyRoute":"后腰椎外缘→腰尾交界分流台","scaleType":"局部","requires":["B"]},
  {"id":"E25","from":"R4-06","to":"R5-01","routeType":"长距离椎旁维护回廊","anatomyRoute":"腰尾分流→向头椎旁维护长廊→胸椎外缘→颈后外侧→枕骨侧面→耳区创伤口","scaleType":"长廊","requires":["B","A4","A2"]},
  {"id":"E26","from":"R5-01","to":"R5-02","routeType":"后颅底外侧损伤腔邻接","anatomyRoute":"枕骨外侧→耳骨外周积水凹部","scaleType":"局部","requires":[]},
  {"id":"E27","from":"R5-02","to":"R5-03","routeType":"外周软膜连续","anatomyRoute":"耳骨外周凹部→软膜褶","scaleType":"局部","requires":["A5"]},
  {"id":"E28","from":"R5-03","to":"R5-04","routeType":"创伤腔中的邻接平台","anatomyRoute":"软膜褶→暴露颅底骨面","scaleType":"局部","requires":[]},
  {"id":"E29","from":"R5-04","to":"R5-05","routeType":"同一耳周腔绕行","anatomyRoute":"覆膜后骨面→耳周腔后侧声槽台","scaleType":"局部","requires":["BOSS_R5"]},
  {"id":"E30","from":"R5-03","to":"R5-05","routeType":"聚落闩＋短柔膜支路","anatomyRoute":"后侧声槽→回折软膜短缝→薄缝训练台","scaleType":"局部","requires":["A5","SC_EAR"],"openFrom":"R5-05","firstOpenRequires":["A5","BOSS_R5"]},
  {"id":"E31","from":"R4-06","to":"R5-07","routeType":"尾椎外侧长廊","anatomyRoute":"腰尾分流→渐细尾椎外缘→尾柄幼体窝","scaleType":"长廊","requires":["B"]},
  {"id":"E32","from":"R5-07","to":"R5-08","routeType":"尾柄裂缘至海水","anatomyRoute":"尾柄外侧→尾鳍基部纤维裂谷→外海","scaleType":"局部","requires":["P","B","S"]},
  {"id":"E33","from":"R1-02","to":"R1-06","routeType":"非天然连通：头侧创伤路线","anatomyRoute":"口腔上侧→上颚衬层剥离→颅侧旧创伤坡→鼻道破口→喷气孔内缘","scaleType":"跨器官","requires":["A2"]},
  {"id":"E34","from":"R2-05","to":"R1-06","routeType":"呼吸道走向＋死后破口/修补","anatomyRoute":"前胸气管旁→喉/鼻道遗迹→鼻道纵裂修补台→喷气孔内缘","scaleType":"长廊","requires":["A2","SC_BLOWHOLE"],"openFrom":"R2-05","firstOpenRequires":["A2","BOSS_R2"]},
  {"id":"E35","from":"R1-02","to":"R1-07","routeType":"须根衬层侧袋","anatomyRoute":"须筛→上颚须根附着面脱层袋","scaleType":"局部","requires":["A3"]},
  {"id":"E36","from":"R2-02","to":"R2-06","routeType":"肺缘剥离侧袋","anatomyRoute":"肺表面→肺缘剥离褶袋","scaleType":"局部","requires":["A2"]},
  {"id":"E37","from":"R3-01","to":"R3-08","routeType":"胃壁高褶袋","anatomyRoute":"胃枢→同一胃壁穹顶高褶","scaleType":"局部","requires":["A2"]},
  {"id":"E38","from":"R4-02","to":"R4-07","routeType":"椎旁外侧膜袋","anatomyRoute":"椎旁训练台→肌腱剥离侧袋","scaleType":"局部","requires":["A3","A4"]},
  {"id":"E39","from":"R5-02","to":"R5-06","routeType":"耳周软膜盲袋","anatomyRoute":"耳区安全池→共生短膜缝→耳周侧袋","scaleType":"局部","requires":["A5"]}
];
export const CAMPAIGN_EDGES = WORLD_EDGES.filter(edge => edge.from.startsWith('R1-') || edge.to.startsWith('R1-'));
