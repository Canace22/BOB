const platform = (x, y, w, kind = 'bone', requires) => ({ x, y, w, h: 55, kind, requires });
export const memories = [
  { id: 'song', title: '第一枚记忆 · 呼唤', text: '很久以前，海水还是明亮的。母亲的歌从远处传来，它跟着那道声音，游过了第一个冬天。' },
  { id: 'journey', title: '第二枚记忆 · 远行', text: '冰层下的海没有路标。它把每一次回声藏进骨骼，在漫长的迁徙里，记住了回家的方向。' },
  { id: 'fall', title: '第三枚记忆 · 归处', text: '最后一次下潜，它没有再浮上海面。而此刻，千万个微小的生命，正在替它继续呼吸。' },
];
export const levels = [
  {
    id: 'mouth', name: '鲸口门庭', subtitle: 'THE BALEEN GATE', depth: '1,240', width: 2360, height: 720,
    description: '鲸须如弦。用骨叉唤醒沉默的入口。', spawn: { x: 120, y: 566 },
    platforms: [platform(0,620,550,'flesh'),platform(480,558,300,'flesh'),platform(750,510,270,'flesh'),platform(1060,565,300,'flesh'),platform(1430,520,280,'flesh'),platform(1750,570,610,'flesh')],
    nodes: [{ id:'baleen',x:865,y:475,kind:'gate',label:'鲸须琴弦' }],
    gate: { x: 965, y: 0, w: 35, h: 510, nodeId: 'baleen' },
    memories: [{id:'song', x:1520, y:475}], hazards: [], exit: {x:2260,y:525},
  },
  {
    id: 'ribs', name: '肋骨穹顶', subtitle: 'THE RESONANT VAULT', depth: '1,380', width: 2520, height:720,
    description: '敲响骨骼，让回声成为脚下的路。', spawn: {x:120,y:536},
    platforms:[platform(0,590,500),platform(430,530,250),platform(680,530,640,'echo','bone-bridge'),platform(1320,530,300),platform(1680,460,200),platform(1950,530,250),platform(2240,590,280)],
    nodes:[{id:'bone-bridge',x:600,y:490,kind:'bridge',label:'回声骨桥'}],
    memories:[{id:'journey',x:1780,y:414}],
    hazards:[{x:1480,y:480,r:24,range:65,speed:1.2}],exit:{x:2420,y:545},
  },
  {
    id:'heart',name:'心室潮泵',subtitle:'THE TIDAL HEART',depth:'1,460',width:2460,height:720,
    description:'疏通三枚凝血阀，让鲸体里的潮水重新流动。',spawn:{x:120,y:556},
    platforms:[platform(0,610,600,'flesh'),platform(420,540,320,'flesh'),platform(790,470,260,'flesh'),platform(1100,540,310,'flesh'),platform(1460,460,300,'flesh'),platform(1800,540,280,'flesh'),platform(2120,610,340,'flesh')],
    nodes:[{id:'valve-1',x:590,y:500,kind:'valve',label:'凝血阀 · 一'},{id:'valve-2',x:930,y:430,kind:'valve',label:'凝血阀 · 二'},{id:'valve-3',x:1610,y:420,kind:'valve',label:'凝血阀 · 三'}],
    memories:[{id:'fall',x:1940,y:494}],hazards:[{x:1240,y:493,r:25,range:55,speed:1.4}],exit:{x:2340,y:565},
  },
];
