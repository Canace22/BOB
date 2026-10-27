// Task progress is projected from gameplay IDs. Opening the journal never
// grants rewards or changes progression; existing saves need no quest migration.
export function campaignQuests(s) {
  const visited = id => s.visited.has(id);
  const flag = id => s.flags.has(id);
  const step = (id, text, done) => ({ id, text, done });
  const quest = (id, kind, title, unlocked, objectives, detail) => ({
    id, kind, title, unlocked, objectives, detail,
    done: objectives.every(objective => objective.done),
    completed: objectives.filter(objective => objective.done).length,
    total: objectives.length,
  });
  const boss = flag('BOSS_R1'), dash = s.abilities.has('A1'), finished = flag('BATCH_R1');
  const tasks = [
    quest('reach-baleen', 'main', '踏入须门', true, [
      step('reach', '穿过外伤坡，进入须筛', visited('R1-02')),
    ], '建议先在身旁贝壳营地按 E 登记。然后向右越过断口，靠近尽头的通路按 E。'),
    quest('reach-tongue', 'main', '穿过须筛', visited('R1-02'), [
      step('reach', '沿下层通路抵达舌台', visited('R1-03')),
    ], '沿须筛下层向右，避开尸蟹与虾流，到尽头按 E。高处支路暂不开放。'),
    quest('reach-gate', 'main', '前往蟹门', visited('R1-03'), [
      step('reach', '穿过舌台，抵达负壳蟹门庭', visited('R1-04')),
    ], '沿舌台向右穿过双蟹与承重膜，靠近右侧通路按 E。高台碎片可顺路拾取。'),
    quest('defeat-gate-crab', 'main', '击败负壳蟹', visited('R1-04'), [
      step('boss', '击败守门的负壳蟹', boss),
    ], '建议先登记门前营地。向右进入战场：跳过横扫、退开壳砸，等收招再按 Q 反击。'),
    quest('claim-dash', 'main', '承接贴流冲', boss, [
      step('ability', '在门庭右侧领取贴流冲', dash),
    ], '返回负壳蟹门庭右侧的发光处，靠近按 E 领取。击败首领不会自动获得能力。'),
    quest('cross-nursery', 'main', '穿越流膜育窝', dash, [
      step('enter', '进入流膜育窝', visited('R1-05')),
      step('practice', '用贴流冲跨沟并落稳', flag('DASH_PRACTICED')),
      step('finish', '越过三段沟，在尽头确认通路', finished),
    ], '从门庭右侧按 E 进入育窝。按住 D → 空格跳起 → 空中按 Shift → 落台刷新；到右端按 E 完成本章。'),
    quest('tongue-fragment', 'side', '舌台遗珍', visited('R1-03'), [
      step('fragment', '拾取舌台高台的生命碎片', s.collected.has('FRAGMENT_R1_03')),
    ], '舌台第二座丘上方有一块高台，跳上去靠近碎片按 E。四片碎片可增加一格生命，本章提供一片。'),
    quest('clearwater-nest', 'side', '安置清流窝', visited('R1-05'), [
      step('practice', '完成一次贴流冲跨沟并落稳', flag('DASH_PRACTICED')),
      step('habitat', '回到入口侧台，安置空壳', s.collected.has('H1')),
    ], '取得贴流冲并成功跨沟后，返回流膜育窝入口附近的小侧台，靠近空壳按 E。可稍后回访，不阻挡主线。'),
  ];
  return tasks;
}
