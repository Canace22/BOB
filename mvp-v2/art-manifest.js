// Runtime subset of assets/catalog.json (V5.2 static batches, 2026-10-27).
// Source IDs and pivots are preserved; V2 collision and interaction remain in levels.js.
// Backgrounds use their complete canvas projection, including transparent space.
// These are static poses/states, not animation frames. Left/right heroes are separate art.
export const ART_ASSETS = {
  "r1-water-base": {
    id: "r1-water-base", src: "../assets/runtime/sprites/r1-water-base/background.png",
    width: 1536, height: 864,
    bbox: [0,0,1536,864], pivot: [768,432],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":18,"canvasWidthU":32,"canvasHeightU":18},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/06_R1.png"]},
  },
  "r1-oral-far-layer": {
    id: "r1-oral-far-layer", src: "../assets/runtime/sprites/r1-oral-far-layer/background.png",
    width: 1671, height: 941,
    bbox: [0,0,1671,474], pivot: [835.5,470.5],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":9.0772,"canvasWidthU":32,"canvasHeightU":18.0203},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/06_R1.png"]},
  },
  "r2-water-base": {
    id: "r2-water-base", src: "../assets/runtime/sprites/r2-water-base/background.png",
    width: 1536, height: 864,
    bbox: [0,0,1536,864], pivot: [768,432],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":18,"canvasWidthU":32,"canvasHeightU":18},
    source: {"region":"R2","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/14_R2.png"]},
  },
  "r2-lung-far-layer": {
    id: "r2-lung-far-layer", src: "../assets/runtime/sprites/r2-lung-far-layer/background.png",
    width: 1672, height: 941,
    bbox: [0,0,1672,743], pivot: [836,470.5],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":14.2201,"canvasWidthU":32,"canvasHeightU":18.0096},
    source: {"region":"R2","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/14_R2.png"]},
  },
  "r3-water-base": {
    id: "r3-water-base", src: "../assets/runtime/sprites/r3-water-base/background.png",
    width: 1536, height: 864,
    bbox: [0,0,1536,864], pivot: [768,432],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":18,"canvasWidthU":32,"canvasHeightU":18},
    source: {"region":"R3","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/21_R3.png"]},
  },
  "r3-gastric-far-layer": {
    id: "r3-gastric-far-layer", src: "../assets/runtime/sprites/r3-gastric-far-layer/background.png",
    width: 1672, height: 941,
    bbox: [0,0,1672,941], pivot: [836,470.5],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":18.0096,"canvasWidthU":32,"canvasHeightU":18.0096},
    source: {"region":"R3","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/21_R3.png"]},
  },
  "r4-water-base": {
    id: "r4-water-base", src: "../assets/runtime/sprites/r4-water-base/background.png",
    width: 1536, height: 864,
    bbox: [0,0,1536,864], pivot: [768,432],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":18,"canvasWidthU":32,"canvasHeightU":18},
    source: {"region":"R4","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/30_R4.png"]},
  },
  "r4-vertebrae-far-layer": {
    id: "r4-vertebrae-far-layer", src: "../assets/runtime/sprites/r4-vertebrae-far-layer/background.png",
    width: 1672, height: 941,
    bbox: [0,0,1672,673], pivot: [836,470.5],
    world: {"axis":"width","units":32,"space":"canvas","visibleWidthU":32,"visibleHeightU":12.8804,"canvasWidthU":32,"canvasHeightU":18.0096},
    source: {"region":"R4","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/30_R4.png"]},
  },
  "tide-picker": {
    id: "tide-picker", src: "../assets/runtime/sprites/tide-picker/idle-right.png",
    width: 1290, height: 1219,
    bbox: [216,66,1166,1152], pivot: [691,1152],
    world: {"axis":"height","units":1,"visibleWidthU":0.8748,"visibleHeightU":1},
    source: {"region":"全局","batchId":"whalefall-v5-2-static-01","references":["assets/source/whalefall-v5-2-static-01/references/03_H01_拾潮者·三视图与挂点.png","assets/source/whalefall-v5-2-static-01/references/08_R1-02.png"]},
  },
  "tide-picker-left": {
    id: "tide-picker-left", src: "../assets/runtime/sprites/tide-picker-left/base.png",
    width: 1290, height: 1219,
    bbox: [192,59,888,1177], pivot: [540,1177],
    world: {"axis":"height","units":1,"visibleWidthU":0.6225,"visibleHeightU":1,"canvasWidthU":1.1538,"canvasHeightU":1.0903},
    source: {"region":"all","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/03_H01_拾潮者·三视图与挂点.png","assets/runtime/sprites/tide-picker/idle-right.png","assets/source/tide-picker-left/references/tide-picker-left_v01-wrong-attachments-ff5911920744.png","assets/source/tide-picker-left/references/tide-picker-left_v02-backward-tool-775c76cfe63a.png","assets/source/tide-picker-left/references/tide-picker-left_v03-long-cape-de4d89edadc6.png"]},
  },
  "shell-camp": {
    id: "shell-camp", src: "../assets/runtime/sprites/shell-camp/base.png",
    width: 1448, height: 1086,
    bbox: [91,117,1380,991], pivot: [735.5,991],
    world: {"axis":"width","units":3.4,"visibleWidthU":3.4,"visibleHeightU":2.3054},
    source: {"region":"共享","batchId":"whalefall-v5-2-static-01","references":["assets/source/whalefall-v5-2-static-01/references/52_P01_工具·共生模块·固定奖励.png","assets/source/whalefall-v5-2-static-01/references/07_R1-01.png"]},
  },
  "corpse-crab": {
    id: "corpse-crab", src: "../assets/runtime/sprites/corpse-crab/idle.png",
    width: 1536, height: 1024,
    bbox: [87,146,1468,916], pivot: [777.5,916],
    world: {"axis":"width","units":1.8,"visibleWidthU":1.8,"visibleHeightU":1.0036},
    source: {"region":"R1","batchId":"whalefall-v5-2-static-01","references":["assets/source/whalefall-v5-2-static-01/references/48_E01_敌人图鉴Ⅰ·距离与空战.png"]},
  },
  "migration-memory": {
    id: "migration-memory", src: "../assets/runtime/sprites/migration-memory/base.png",
    width: 1398, height: 1125,
    bbox: [119,139,1318,1046], pivot: [718.5,1046],
    world: {"axis":"height","units":0.3,"visibleWidthU":0.3966,"visibleHeightU":0.3,"canvasWidthU":0.4624,"canvasHeightU":0.3721},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/52_P01_工具·共生模块·固定奖励.png","assets/source/whalefall-v5-2-complete/references/13_R1-07.png"]},
  },
  "float-membrane": {
    id: "float-membrane", src: "../assets/runtime/sprites/float-membrane/base.png",
    width: 1536, height: 1024,
    bbox: [153,46,1446,985], pivot: [799.5,515.5],
    world: {"axis":"width","units":1.6,"visibleWidthU":1.6,"visibleHeightU":1.1619,"canvasWidthU":1.9007,"canvasHeightU":1.2671},
    source: {"region":"全局","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/05_C02_五能力与失败恢复.png"]},
  },
  "bone-anchor-ring": {
    id: "bone-anchor-ring", src: "../assets/runtime/sprites/bone-anchor-ring/base.png",
    width: 1287, height: 1222,
    bbox: [236,88,1064,1173], pivot: [700,453],
    world: {"axis":"width","units":0.55,"visibleWidthU":0.55,"visibleHeightU":0.7207},
    source: {"region":"共享","batchId":"whalefall-v5-2-static-01","references":["assets/source/whalefall-v5-2-static-01/references/52_P01_工具·共生模块·固定奖励.png","assets/source/whalefall-v5-2-static-01/references/07_R1-01.png"]},
  },
  "pressure-valve-base": {
    id: "pressure-valve-base", src: "../assets/runtime/sprites/pressure-valve-base/base.png",
    width: 1368, height: 1150,
    bbox: [386,164,1052,1010], pivot: [719,1010],
    world: {"axis":"height","units":1.2,"visibleWidthU":0.9447,"visibleHeightU":1.2,"canvasWidthU":1.9404,"canvasHeightU":1.6312},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/23_R3-02.png","assets/source/whalefall-v5-2-complete/references/18_R2-04.png","assets/source/whalefall-v5-2-complete/references/46_R5-07.png"]},
  },
  "pressure-valve-handle": {
    id: "pressure-valve-handle", src: "../assets/runtime/sprites/pressure-valve-handle/base.png",
    width: 1363, height: 1154,
    bbox: [151,162,1235,1012], pivot: [684,906],
    world: {"axis":"width","units":0.55,"visibleWidthU":0.55,"visibleHeightU":0.4313,"canvasWidthU":0.6916,"canvasHeightU":0.5855},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/23_R3-02.png","assets/source/whalefall-v5-2-complete/references/18_R2-04.png","assets/source/whalefall-v5-2-complete/references/46_R5-07.png"]},
  },
  "bypass-valve-base": {
    id: "bypass-valve-base", src: "../assets/runtime/sprites/bypass-valve-base/base.png",
    width: 1536, height: 1024,
    bbox: [310,211,1219,816], pivot: [764.5,816],
    world: {"axis":"height","units":1,"visibleWidthU":1.5025,"visibleHeightU":1,"canvasWidthU":2.5388,"canvasHeightU":1.6926},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/23_R3-02.png","assets/source/whalefall-v5-2-complete/references/18_R2-04.png","assets/source/whalefall-v5-2-complete/references/46_R5-07.png"]},
  },
  "bypass-valve-lever": {
    id: "bypass-valve-lever", src: "../assets/runtime/sprites/bypass-valve-lever/base.png",
    width: 1536, height: 1024,
    bbox: [346,259,1355,794], pivot: [760,766],
    world: {"axis":"height","units":0.45,"visibleWidthU":0.8487,"visibleHeightU":0.45,"canvasWidthU":1.292,"canvasHeightU":0.8613},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/23_R3-02.png","assets/source/whalefall-v5-2-complete/references/18_R2-04.png","assets/source/whalefall-v5-2-complete/references/46_R5-07.png"]},
  },
  "r1-tongue-ledge": {
    id: "r1-tongue-ledge", src: "../assets/runtime/sprites/r1-tongue-ledge/base.png",
    width: 2162, height: 727,
    bbox: [59,132,2102,665], pivot: [1081,194],
    world: {"axis":"width","units":10,"visibleWidthU":10,"visibleHeightU":2.6089},
    source: {"region":"R1","batchId":"whalefall-v5-2-static-01","references":["assets/source/whalefall-v5-2-static-01/references/08_R1-02.png"]},
  },
  "r1-weight-membrane": {
    id: "r1-weight-membrane", src: "../assets/runtime/sprites/r1-weight-membrane/base.png",
    width: 2162, height: 727,
    bbox: [54,169,2111,576], pivot: [1082.5,576],
    world: {"axis":"width","units":5,"visibleWidthU":5,"visibleHeightU":0.9893,"canvasWidthU":5.2552,"canvasHeightU":1.7671},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/09_R1-03.png"]},
  },
  "r1-weight-membrane-pressed": {
    id: "r1-weight-membrane-pressed", src: "../assets/runtime/sprites/r1-weight-membrane-pressed/base.png",
    width: 2162, height: 727,
    bbox: [53,165,2092,593], pivot: [1072.5,593],
    world: {"axis":"width","units":5,"visibleWidthU":5,"visibleHeightU":1.0495,"canvasWidthU":5.3016,"canvasHeightU":1.7827},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/09_R1-03.png"]},
  },
  "r2-membrane-platform": {
    id: "r2-membrane-platform", src: "../assets/runtime/sprites/r2-membrane-platform/base.png",
    width: 2162, height: 727,
    bbox: [60,192,2102,592], pivot: [1081,592],
    world: {"axis":"width","units":8,"visibleWidthU":8,"visibleHeightU":1.5671,"canvasWidthU":8.4701,"canvasHeightU":2.8482},
    source: {"region":"R2","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/15_R2-01.png","assets/source/whalefall-v5-2-complete/references/16_R2-02.png"]},
  },
  "r3-bank-platform": {
    id: "r3-bank-platform", src: "../assets/runtime/sprites/r3-bank-platform/base.png",
    width: 2162, height: 727,
    bbox: [84,191,2079,626], pivot: [1081.5,626],
    world: {"axis":"width","units":8,"visibleWidthU":8,"visibleHeightU":1.7444,"canvasWidthU":8.6697,"canvasHeightU":2.9153},
    source: {"region":"R3","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/23_R3-02.png","assets/source/whalefall-v5-2-complete/references/26_R3-05.png"]},
  },
  "r4-bone-platform": {
    id: "r4-bone-platform", src: "../assets/runtime/sprites/r4-bone-platform/base.png",
    width: 2098, height: 749,
    bbox: [63,239,2035,629], pivot: [1049,629],
    world: {"axis":"width","units":8,"visibleWidthU":8,"visibleHeightU":1.5822,"canvasWidthU":8.5112,"canvasHeightU":3.0385},
    source: {"region":"R4","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/30_R4.png","assets/source/whalefall-v5-2-complete/references/32_R4-02.png"]},
  },
  "r1-baleen-shadow": {
    id: "r1-baleen-shadow", src: "../assets/runtime/sprites/r1-baleen-shadow/base.png",
    width: 1916, height: 821,
    bbox: [12,90,1901,788], pivot: [956.5,788],
    world: {"axis":"width","units":14,"visibleWidthU":14,"visibleHeightU":5.1731,"canvasWidthU":14.2001,"canvasHeightU":6.0847},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/06_R1.png","assets/source/whalefall-v5-2-complete/references/08_R1-02.png"]},
  },
  "r2-foreground-membrane": {
    id: "r2-foreground-membrane", src: "../assets/runtime/sprites/r2-foreground-membrane/base.png",
    width: 2162, height: 727,
    bbox: [42,64,2120,675], pivot: [1081,675],
    world: {"axis":"width","units":14,"visibleWidthU":14,"visibleHeightU":4.1165,"canvasWidthU":14.5659,"canvasHeightU":4.898},
    source: {"region":"R2","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/14_R2.png"]},
  },
  "r3-foreground-fold": {
    id: "r3-foreground-fold", src: "../assets/runtime/sprites/r3-foreground-fold/base.png",
    width: 2032, height: 774,
    bbox: [22,414,2012,749], pivot: [1017,749],
    world: {"axis":"width","units":14,"visibleWidthU":14,"visibleHeightU":2.3568,"canvasWidthU":14.2955,"canvasHeightU":5.4452},
    source: {"region":"R3","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/21_R3.png"]},
  },
  "r4-foreground-bone": {
    id: "r4-foreground-bone", src: "../assets/runtime/sprites/r4-foreground-bone/base.png",
    width: 2162, height: 727,
    bbox: [56,169,2110,663], pivot: [1083,663],
    world: {"axis":"width","units":14,"visibleWidthU":14,"visibleHeightU":3.3671,"canvasWidthU":14.7361,"canvasHeightU":4.9552},
    source: {"region":"R4","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/30_R4.png"]},
  },
  "habitat-fungus-bed": {
    id: "habitat-fungus-bed", src: "../assets/runtime/sprites/habitat-fungus-bed/base.png",
    width: 1774, height: 887,
    bbox: [181,225,1591,748], pivot: [886,748],
    world: {"axis":"width","units":2,"visibleWidthU":2,"visibleHeightU":0.7418,"canvasWidthU":2.5163,"canvasHeightU":1.2582},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/22_R3-01.png"]},
  },
  "habitat-shell-nest": {
    id: "habitat-shell-nest", src: "../assets/runtime/sprites/habitat-shell-nest/base.png",
    width: 1774, height: 887,
    bbox: [56,198,1718,748], pivot: [887,748],
    world: {"axis":"width","units":2,"visibleWidthU":2,"visibleHeightU":0.6619,"canvasWidthU":2.1348,"canvasHeightU":1.0674},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/11_R1-05.png"]},
  },
  "habitat-larva-trough": {
    id: "habitat-larva-trough", src: "../assets/runtime/sprites/habitat-larva-trough/base.png",
    width: 1774, height: 887,
    bbox: [55,241,1725,773], pivot: [890,773],
    world: {"axis":"width","units":2.5,"visibleWidthU":2.5,"visibleHeightU":0.7964,"canvasWidthU":2.6557,"canvasHeightU":1.3278},
    source: {"region":"共享","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/46_R5-07.png"]},
  },
  "baleen-shrimp-swarm": {
    id: "baleen-shrimp-swarm", src: "../assets/runtime/sprites/baleen-shrimp-swarm/base.png",
    width: 1774, height: 887,
    bbox: [57,198,1721,674], pivot: [889,436],
    world: {"axis":"width","units":0.46,"visibleWidthU":0.46,"visibleHeightU":0.1316,"canvasWidthU":0.4904,"canvasHeightU":0.2452},
    source: {"region":"R1","batchId":"whalefall-v5-2-complete","references":["assets/source/whalefall-v5-2-complete/references/50_E03_敌人图鉴Ⅲ·群流与生态边界.png","assets/runtime/sprites/tide-picker/idle-right.png"]},
  }
};

// V2 room order differs from source region numbering.
export const REGION_ART = {
  "mouth": {
    "sourceRegion": "R1",
    "water": "r1-water-base",
    "organ": "r1-oral-far-layer",
    "foreground": "r1-baleen-shadow",
    "platform": "r1-tongue-ledge"
  },
  "stomach": {
    "sourceRegion": "R3",
    "water": "r3-water-base",
    "organ": "r3-gastric-far-layer",
    "foreground": "r3-foreground-fold",
    "platform": "r3-bank-platform"
  },
  "lung": {
    "sourceRegion": "R2",
    "water": "r2-water-base",
    "organ": "r2-lung-far-layer",
    "foreground": "r2-foreground-membrane",
    "platform": "r2-membrane-platform"
  },
  "ribs": {
    "sourceRegion": "R4",
    "water": "r4-water-base",
    "organ": "r4-vertebrae-far-layer",
    "foreground": "r4-foreground-bone",
    "platform": "r4-bone-platform"
  }
};
