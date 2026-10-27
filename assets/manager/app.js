const $ = id => document.getElementById(id);
const statusNames = {accepted:'静态验收通过', 'needs-review':'待验收', 'needs-work':'待调整', archived:'已归档'};
const kindNames = {character:'角色与生物', prop:'交互物', scenery:'场景件', background:'背景', ui:'界面素材', effect:'特效素材'};
const spriteNames = {background:'独立背景', ui:'界面静态组件', effect:'特效静态纹理', static:'静态精灵'};
let catalog, selectedId, original, pendingAction;
let dirty = false, saving = false, loading = false;
const images = new Map();

function element(tag, text, className) {
  const node = document.createElement(tag);
  if (text !== undefined) node.textContent = text;
  if (className) node.className = className;
  return node;
}

function localUrl(file) {
  return '/' + file.split('/').map(encodeURIComponent).join('/');
}

function setMessage(id, text, error = false) {
  $(id).textContent = text;
  $(id).classList.toggle('error', error);
}

function getImage(file) {
  if (!images.has(file)) images.set(file, new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => {images.delete(file); reject(new Error('图片未能载入'));};
    image.src = localUrl(file);
  }));
  return images.get(file);
}

function drawImage(canvas, image, asset) {
  const [left, top, right, bottom] = asset.bbox || [0, 0, asset.width, asset.height];
  const width = right - left, height = bottom - top;
  const scale = Math.min((canvas.width - 32) / width, (canvas.height - 32) / height);
  const context = canvas.getContext('2d');
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.drawImage(image, left, top, width, height, (canvas.width - width * scale) / 2, (canvas.height - height * scale) / 2, width * scale, height * scale);
}

function isVisible(asset) {
  const query = $('search').value.trim().toLocaleLowerCase();
  const haystack = [asset.name, asset.id, ...(asset.tags || [])].join(' ').toLocaleLowerCase();
  const status = $('status-filter').value;
  return (!query || haystack.includes(query))
    && (!$('kind').value || asset.kind === $('kind').value)
    && (!$('region').value || asset.region === $('region').value)
    && (status === 'all' || (status ? asset.status === status : asset.status !== 'archived'));
}

function createCard(asset) {
  const button = element('button', undefined, 'asset-card');
  button.type = 'button';
  button.dataset.assetId = asset.id;
  button.setAttribute('aria-label', `查看 ${asset.name}`);
  button.setAttribute('aria-pressed', String(asset.id === selectedId));
  button.classList.toggle('selected', asset.id === selectedId);
  const art = element('div', undefined, 'asset-image');
  const canvas = document.createElement('canvas');
  canvas.width = 480; canvas.height = 340;
  canvas.setAttribute('aria-hidden', 'true');
  art.append(canvas);
  getImage(asset.thumbnail || asset.file).then(image => {
    if (asset.thumbnail) canvas.getContext('2d').drawImage(image, 0, 0, canvas.width, canvas.height);
    else drawImage(canvas, image, asset);
  }).catch(() => {
    art.replaceChildren(element('span', '图片未载入', 'file-error'));
  });
  const info = element('div', undefined, 'asset-card-info');
  const meta = element('div', undefined, 'asset-card-meta');
  meta.append(element('span', `${asset.region} / ${spriteNames[asset.spriteType] || '静态精灵'}`), element('span', statusNames[asset.status] || asset.status, `status-dot ${asset.status}`));
  info.append(element('h3', asset.name), meta);
  button.append(art, info);
  button.addEventListener('click', () => requestAction(() => selectAsset(asset.id, true)));
  return button;
}

function renderGallery() {
  const visible = catalog.assets.filter(isVisible);
  $('gallery').replaceChildren(...visible.map(createCard));
  $('count').textContent = `${visible.length} / ${catalog.assets.length} 项`;
  $('empty').hidden = visible.length !== 0;
}

function renderAtlas() {
  const atlas = catalog.atlas;
  const ready = Boolean(atlas?.ready && (atlas.zip || atlas.image) && atlas.json);
  $('atlas-image').hidden = $('atlas-json').hidden = !ready;
  $('atlas-state').textContent = ready ? '静态图集已入库' : '静态图集整理中';
  if (ready) {
    $('atlas-image').href = localUrl(atlas.zip || atlas.image);
    $('atlas-image').textContent = atlas.zip ? '下载完整静态图集包' : '下载静态图集';
    $('atlas-json').href = localUrl(atlas.json);
  }
}

function addLinks(id, files) {
  $(id).replaceChildren(...(files || []).map(file => {
    const link = element('a', file.split('/').pop());
    link.href = localUrl(file); link.target = '_blank'; link.rel = 'noopener';
    return link;
  }));
  if (!files?.length) $(id).append(element('span', '尚未登记'));
}

function fillFacts(asset) {
  const unit = asset.world;
  const scale = unit ? `${unit.axis === 'height' ? '高' : '宽'} ${unit.units}U${unit.space === 'canvas' ? '，按完整画布' : ''}（1U = 0.30m）` : asset.kind === 'ui' ? '界面原生像素；按组件规格缩放' : '尚未登记';
  const facts = [['资源 ID', asset.id], ['原始尺寸', `${asset.width} × ${asset.height}px`], ['建议尺度', scale], ['锚点', asset.pivot ? `${asset.pivot.join(', ')}px，原图坐标` : '尚未登记'], ['用途', `${kindNames[asset.kind] || asset.kind} / ${asset.region}`], ['游戏接入', asset.integrationStatus === 'not-integrated' ? '尚未接入游戏' : asset.integrationStatus || '尚未登记']];
  $('facts').replaceChildren(...facts.flatMap(([key, value]) => [element('dt', key), element('dd', value)]));
  $('qa-summary').textContent = `${asset.qa?.passed ? '已通过：' : '待检查：'}${asset.qa?.scope || '尚未登记验收范围'}`;
  $('limitations').replaceChildren(...(asset.qa?.limitations || []).map(note => element('li', note)));
  addLinks('prompt-links', asset.source?.prompts);
  addLinks('reference-links', asset.source?.references);
  addLinks('editable-links', asset.source?.sourceFiles);
  $('editable-heading').hidden = $('editable-links').hidden = !asset.source?.sourceFiles?.length;
}

async function drawPreview() {
  const asset = catalog?.assets.find(item => item.id === selectedId);
  if (!asset) return;
  const canvas = $('preview'), zoom = Number($('zoom').value) / 100;
  const width = Math.max(200, $('preview-stage').clientWidth), height = $('preview-stage').clientHeight;
  canvas.width = Math.round(width * zoom * devicePixelRatio);
  canvas.height = Math.round(height * zoom * devicePixelRatio);
  canvas.style.width = `${width * zoom}px`; canvas.style.height = `${height * zoom}px`;
  $('zoom-value').textContent = `${Math.round(zoom * 100)}%`;
  canvas.classList.remove('image-error');
  try {
    const image = await getImage(asset.file);
    if (asset.id === selectedId) drawImage(canvas, image, asset);
  } catch {
    canvas.classList.add('image-error');
    setMessage('save-message', '预览图片未载入。请确认项目中的文件存在，然后刷新。', true);
  }
}

function formValue() {
  return {name:$('edit-name').value.trim(), tags:[...new Set($('edit-tags').value.split(/[,，]/).map(tag => tag.trim()).filter(Boolean))], notes:$('edit-notes').value, status:$('edit-status').value};
}

function updateDirty() {
  dirty = Boolean(original && JSON.stringify(formValue()) !== JSON.stringify(original));
  for (const id of ['edit-name', 'edit-tags', 'edit-notes', 'edit-status']) $(id).disabled = saving || loading;
  $('save').disabled = saving || loading || !dirty;
  $('reset').disabled = saving || loading || !dirty;
  $('save-state').textContent = saving ? '正在保存…' : loading ? '正在读取…' : dirty ? '有未保存的更改' : '已保存';
  $('save-state').classList.toggle('dirty', dirty);
}

function selectAsset(id, scroll = false) {
  const asset = catalog.assets.find(item => item.id === id);
  if (!asset) return;
  selectedId = id;
  $('detail').hidden = false; $('no-selection').hidden = true;
  $('detail-title').textContent = asset.name;
  $('detail-kind').textContent = `${kindNames[asset.kind] || asset.kind} / ${spriteNames[asset.spriteType] || '静态精灵，单张姿态'}`;
  $('detail-status').textContent = statusNames[asset.status] || asset.status;
  $('download').href = localUrl(asset.file); $('download').download = asset.file.split('/').pop();
  $('file-path').textContent = asset.file;
  fillFacts(asset);
  original = {name:asset.name, tags:asset.tags || [], notes:asset.notes || '', status:asset.status};
  $('edit-name').value = original.name; $('edit-tags').value = original.tags.join('，');
  $('edit-notes').value = original.notes; $('edit-status').value = original.status;
  $('conflict').hidden = true; setMessage('save-message', '');
  $('zoom').value = '100'; $('preview-stage').scrollTo(0, 0);
  updateDirty(); renderGallery(); drawPreview();
  if (scroll && matchMedia('(max-width:780px)').matches) $('inspector').scrollIntoView({block:'start', behavior:'instant'});
}

function requestAction(action) {
  if (saving || loading) return;
  if (!dirty) {action(); return;}
  pendingAction = action;
  $('unsaved-dialog').showModal();
}

async function loadCatalog() {
  loading = true; updateDirty();
  setMessage('load-message', '正在读取项目资源…');
  $('refresh').disabled = true;
  try {
    const response = await fetch('/api/catalog', {cache:'no-store'});
    if (!response.ok) throw new Error('无法读取资源清单，请确认服务已启动后重试。');
    const data = await response.json();
    if (!Array.isArray(data.assets)) throw new Error('资源清单格式不正确，请检查 catalog.json。');
    catalog = data;
    const currentRegion = $('region').value;
    $('region').replaceChildren(new Option('全部区域', ''), ...[...new Set(catalog.assets.map(asset => asset.region))].map(region => new Option(region, region)));
    $('region').value = currentRegion;
    renderAtlas(); renderGallery();
    const id = catalog.assets.some(asset => asset.id === selectedId) ? selectedId : catalog.assets.find(asset => asset.status !== 'archived')?.id;
    if (id) selectAsset(id);
    else {selectedId = original = null; dirty = false; $('detail').hidden = true; $('no-selection').hidden = false;}
    setMessage('load-message', '');
    document.body.dataset.ready = 'true';
  } catch (error) {
    setMessage('load-message', error.message || '加载失败，请点击刷新重试。', true);
  } finally { loading = false; $('refresh').disabled = false; updateDirty(); }
}

async function saveAsset(event) {
  event.preventDefault();
  if (!dirty || saving || !$('edit-form').reportValidity()) return;
  saving = true; updateDirty(); setMessage('save-message', '正在写入项目资源清单…');
  try {
    const response = await fetch(`/api/assets/${encodeURIComponent(selectedId)}`, {method:'PATCH', headers:{'Content-Type':'application/json'}, body:JSON.stringify({revision:catalog.revision, ...formValue()})});
    const data = await response.json();
    if (response.status === 409) {
      $('conflict').hidden = false;
      throw new Error('保存冲突，当前草稿已保留。');
    }
    if (!response.ok) throw new Error(data.error || data.message || '保存未完成，请检查服务后重试。');
    catalog = data; selectAsset(selectedId);
    setMessage('save-message', '已保存到项目资源清单。');
  } catch (error) {
    setMessage('save-message', error instanceof TypeError ? '网络连接中断，当前草稿已保留，可以重试。' : error.message || '保存未完成，当前草稿已保留，可以重试。', true);
  } finally {saving = false; updateDirty();}
}

async function copyText(text, success) {
  try {await navigator.clipboard.writeText(text); setMessage('save-message', success);}
  catch {setMessage('save-message', '浏览器未允许复制。可选中对应文字手动复制。', true);}
}

$('filters').addEventListener('submit', event => event.preventDefault());
for (const id of ['search', 'kind', 'region', 'status-filter']) $(id).addEventListener('input', () => catalog && renderGallery());
$('clear-filters').addEventListener('click', () => {for (const id of ['search', 'kind', 'region', 'status-filter']) $(id).value = ''; renderGallery();});
for (const button of document.querySelectorAll('[data-backdrop] button, button[data-backdrop]')) button.addEventListener('click', () => {
  const backdrop = button.dataset.backdrop;
  if (!backdrop) return;
  document.querySelectorAll('button[data-backdrop]').forEach(item => item.setAttribute('aria-pressed', String(item === button)));
  $('gallery').dataset.backdrop = $('preview-stage').dataset.backdrop = backdrop;
});
$('zoom').addEventListener('input', drawPreview);
$('edit-form').addEventListener('input', updateDirty);
$('edit-form').addEventListener('submit', saveAsset);
$('reset').addEventListener('click', () => selectAsset(selectedId));
$('refresh').addEventListener('click', () => requestAction(loadCatalog));
$('reload-conflict').addEventListener('click', () => requestAction(loadCatalog));
$('copy-path').addEventListener('click', () => copyText($('file-path').textContent, '项目路径已复制。'));
$('copy-draft').addEventListener('click', () => copyText(JSON.stringify(formValue(), null, 2), '当前草稿已复制，可在重新载入后恢复。'));
$('keep-editing').addEventListener('click', () => {pendingAction = null; $('unsaved-dialog').close();});
$('unsaved-dialog').addEventListener('cancel', () => {pendingAction = null;});
$('discard').addEventListener('click', () => {
  const action = pendingAction; pendingAction = null;
  $('unsaved-dialog').close();
  if (selectedId) selectAsset(selectedId);
  action?.();
});
window.addEventListener('beforeunload', event => {if (dirty) {event.preventDefault(); event.returnValue = '';}});
window.addEventListener('resize', drawPreview);
loadCatalog();
