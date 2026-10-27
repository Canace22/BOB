const $ = id => document.getElementById(id);
const groupNames = {actors:'角色与生物', scenes:'场景与背景', props:'道具与机关', ui:'界面素材', fx:'特效素材'};
const stateNames = {missing:'尚缺素材', partial:'已有部分', ready:'静态文件齐备'};
let plan, catalog;
function el(tag, value, className) {
  const node = document.createElement(tag);
  if (value !== undefined) node.textContent = value;
  if (className) node.className = className;
  return node;
}
function coverage(row) {
  const expected = row.outputIds || [];
  const accepted = expected.filter(id => catalog.assets.some(a => a.id === id && a.status === 'accepted'));
  const present = expected.filter(id => catalog.assets.some(a => a.id === id && a.status !== 'archived'));
  return {expected, accepted, present, state:row.outputPlanComplete && expected.length && accepted.length === expected.length ? 'ready' : present.length ? 'partial' : 'missing'};
}
function matches(row, result) {
  const search = [row.name, row.id, ...(row.states || []), ...(row.rooms || [])].join(' ').toLocaleLowerCase();
  return search.includes($('plan-search').value.trim().toLocaleLowerCase())
    && (!$('plan-group').value || row.group === $('plan-group').value)
    && (!$('plan-status').value || result.state === $('plan-status').value);
}
function requirementCard(row, result) {
  const card = el('article', undefined, 'requirement-card');
  const heading = el('div', undefined, 'requirement-heading');
  const title = el('div');
  title.append(el('p', groupNames[row.group], 'eyebrow'), el('h2', row.name));
  heading.append(title, el('span', stateNames[result.state], `coverage-state ${result.state}`));
  card.append(heading, el('p', row.id, 'requirement-id'), el('p', row.states?.join(' / ') || '基础静态形象', 'requirement-states'));
  const count = row.outputPlanComplete ? `已验收 ${result.accepted.length} / ${result.expected.length} 个静态文件` : `已有 ${result.present.length} 个关联文件；拆分清单正在核对`;
  card.append(el('p', count, 'message'));
  if (row.note) card.append(el('p', row.note, 'requirement-note'));
  const details = el('details'); details.append(el('summary', '来源、文件与后续动作'));
  if (row.evidence) details.append(el('p', row.evidence));
  if (row.stateRules) details.append(el('p', '静态组合：' + row.stateRules));
  if (row.recipeFile) {const a=el('a','查看组件挂点与状态组合');a.href='/'+row.recipeFile;a.target='_blank';a.rel='noopener';details.append(a);}
  if (row.initialAuditNote) details.append(el('p', '初次盘点记录：' + row.initialAuditNote));
  const list = el('ul');
  for (const id of result.expected) {
    const asset = catalog.assets.find(a => a.id === id);
    const item = el('li');
    if (asset) {const a = el('a', `${asset.name} · ${asset.status === 'accepted' ? '静态验收通过' : '待验收或调整'}`); a.href = '/' + asset.file; a.target = '_blank'; a.rel = 'noopener'; item.append(a);}
    else item.textContent = `${id} · 尚未入库`;
    list.append(item);
  }
  details.append(list);
  if (row.animation?.length) details.append(el('p', `后续动画：${row.animation.join('、')}`));
  for (const url of row.sources || []) {const a = el('a', '查看设计依据');a.href = url;a.target = '_blank';a.rel = 'noopener';details.append(a);}
  card.append(details); return card;
}
function render() {
  const rows = plan.requirements.map(row => ({row, result:coverage(row)}));
  const ready = rows.filter(x => x.result.state === 'ready').length;
  $('overview').replaceChildren(...[
    ['需求家族', rows.length], ['已入库文件', catalog.assets.filter(a => a.status !== 'archived').length],
    ['静态文件齐备的家族', ready], ['尚未齐备的家族', rows.length - ready]
  ].map(([name, value]) => {const item = el('div'); item.append(el('strong', String(value)), el('span', name));return item;}));
  $('assembly-previews').replaceChildren(...(plan.previews || []).map(preview => {
    const link = el('a'); link.href = '/' + preview.file; link.target = '_blank'; link.rel = 'noopener';
    const image = document.createElement('img'); image.src = '/' + preview.file; image.alt = preview.name; image.loading = 'lazy';
    link.append(image, el('span', preview.name)); return link;
  }));
  const visible = rows.filter(x => matches(x.row, x.result));
  $('plan-count').textContent = `显示 ${visible.length} / ${rows.length} 个家族。静态文件齐备不代表用户美术确认或游戏内接入。`;
  $('requirements-list').replaceChildren(...visible.map(x => requirementCard(x.row, x.result)));
  $('rooms-list').replaceChildren(...plan.rooms.map(room => {
    const item = el('article', undefined, 'room-row');
    const linked = room.requirementIds.map(id => rows.find(x => x.row.id === id)).filter(Boolean);
    item.append(el('h3', `${room.id} ${room.name}`), el('p', `${linked.filter(x=>x.result.state === 'ready').length} / ${linked.length} 个相关家族静态文件齐备；拼装${room.assemblyVerified ? '已检查' : '待检查'}`), el('p', linked.map(x => x.row.name).join(' · ')));
    return item;
  }));
}
async function load() {
  $('reload').disabled = true;
  $('plan-note').textContent = '正在核对需求与项目文件…';
  try {
    const responses = await Promise.all([fetch('/assets/source/whalefall-v5-2-complete/coverage.json', {cache:'no-store'}), fetch('/api/catalog', {cache:'no-store'})]);
    if (responses.some(r => !r.ok)) throw new Error('读取失败，请确认管理服务与需求文件存在。');
    [plan, catalog] = await Promise.all(responses.map(r=>r.json()));
    render(); $('plan-note').textContent = plan.note;
    document.body.dataset.ready = 'true';
  } catch (error) { $('plan-note').textContent = error.message; }
  finally { $('reload').disabled = false; }
}
$('plan-filters').addEventListener('submit', e=>e.preventDefault());
for (const id of ['plan-search','plan-group','plan-status']) $(id).addEventListener('input', ()=>{if(plan && catalog) render();});
$('reload').addEventListener('click', load);
load();
