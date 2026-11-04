const $ = selector => document.querySelector(selector);
const workspace = $('#workspace');
const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[c]));
const categories = ['人物', '组织', '世界规则', '地点', '章节', '战斗', '叙事说明', '待定事项', '原始文稿', '总览'];
const icons = {
  '人物':'<circle cx="12" cy="7" r="3.5"/><path d="M5 21v-3a7 7 0 0 1 14 0v3"/>',
  '组织':'<path d="m12 3 8 4v6c0 4-8 8-8 8s-8-4-8-8V7z"/>',
  '世界规则':'<circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12h18"/>',
  '地点':'<path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 0 1 14 0z"/><circle cx="12" cy="10" r="2.5"/>',
  '章节':'<path d="M12 5c-4-3-9-1-9-1v16s5-2 9 1c4-3 9-1 9-1V4s-5-2-9 1v16"/>',
  '战斗':'<path d="m4 3 15 15M20 3 5 18M3 15l6 6m6-6 6 6M3 3l1 5 4-4zM21 3l-5 1 4 4z"/>',
  '叙事说明':'<path d="M5 3h14v18H5zM8 8h8M8 12h8M8 16h5"/>',
  '待定事项':'<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 5 2c-2 1-2 2-2 3M12 17v.1"/>',
  '原始文稿':'<path d="M7 3h9l4 4v14H7zM16 3v5h4M4 7v13M10 12h7M10 16h7"/>',
  '总览':'<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
};
const icon = category => `<span class="nav-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${icons[category]}</svg></span>`;
let data, state;
const readState = () => ({c:'人物', ...Object.fromEntries(new URLSearchParams(location.hash.slice(1)))});
const tag = record => `<span class="tag ${record.status === '叙事提案' ? 'proposal' : ''}">${escape(record.status)}</span>`;
function highlight(text) {
  if (!state.q) return escape(text);
  const needle = state.q.toLocaleLowerCase();
  const lower = text.toLocaleLowerCase();
  let result = '', cursor = 0, found;
  while ((found = lower.indexOf(needle, cursor)) !== -1) {
    result += escape(text.slice(cursor, found)) + '<mark>' + escape(text.slice(found, found + needle.length)) + '</mark>';
    cursor = found + needle.length;
  }
  return result + escape(text.slice(cursor));
}
function inline(text) {
  // Source links are labels here; the exact original is available as a download.
  return text.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').split(/(\*\*[^*]+\*\*)/).map(part => part.startsWith('**') ? `<strong>${highlight(part.slice(2, -2))}</strong>` : highlight(part)).join('');
}
function markdown(raw) {
  const lines = raw.replace(/\r/g, '').split('\n');
  let html = '', paragraph = [];
  const flush = () => { if (paragraph.length) html += `<p>${inline(paragraph.join('\n'))}</p>`; paragraph = []; };
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith('|')) {
      flush();
      const rows = [];
      while (i < lines.length && lines[i].startsWith('|')) rows.push(lines[i++]);
      i--;
      html += '<div class="table-scroll"><table>' + rows.filter(r => !/^\|[\s:|\-]+\|$/.test(r)).map((row, j) => '<tr>' + row.slice(1, -1).split('|').map(cell => `<${j ? 'td' : 'th'}>${inline(cell.trim())}</${j ? 'td' : 'th'}>`).join('') + '</tr>').join('') + '</table></div>';
    } else if (/^#{1,3} /.test(line)) {
      flush(); const level = Math.min(3, line.match(/^#+/)[0].length + 1);
      html += `<h${level} id="line-${i + 1}">${inline(line.replace(/^#+ /, ''))}</h${level}>`;
    } else if (!line.trim()) flush();
    else paragraph.push(line);
  }
  flush(); return html;
}
function navigate(patch, replace = false) {
  if (!data) return;
  state = {...state, ...patch};
  for (const key of Object.keys(state)) if (!state[key]) delete state[key];
  const hash = new URLSearchParams(state).toString();
  history[replace ? 'replaceState' : 'pushState'](null, '', '#' + hash);
  render();
}
function goRecord(id) {
  const record = data.records.find(r => r.id === id);
  if (!record) return;
  navigate({id, c: record.category, q: '', s: '', src:'', doc: '', line: ''});
  if (innerWidth < 761) $('#reader')?.scrollIntoView({behavior: 'smooth', block: 'start'});
}
const recordButton = (record, css = 'feature') => `<button class="${css}" data-record="${escape(record.id)}">${tag(record)}<h3>${escape(record.title)}</h3><p>${escape(record.summary.slice(0, 86))}…</p></button>`;
function overview() {
  const chapters = data.records.filter(r => r.category === '章节');
  const synopsis = data.records.find(r => r.title === '故事梗概');
  return `<section class="hero" id="reader" tabindex="-1"><div class="eyebrow">WHALEFALL · WORLD ARCHIVE</div><h1>在鲸落之后，万物生长。</h1><p>${escape(synopsis.body.split('\n\n')[0])}</p><div class="note">${data.documents.map(d => escape(d.name + " · " + d.version)).join(" / ")}<br>两份文稿尚未整稿审定；十二章为叙事提案，设定收录不代表已接入游戏。</div></section>
  <div class="stats">${[['世界规则','基础设定'],['人物','人物档案'],['地点','叙事腔室'],['章节','主线章节']].map(([c,label]) => `<button class="stat" data-category="${c}"><strong>${String(data.records.filter(r => r.category === c).length).padStart(2,'0')}</strong><span>${label} ↗</span></button>`).join('')}</div>
  <div class="section-head"><h2>从这里认识遗城</h2><span>世界、人物与旧秩序</span></div><div class="feature-grid">${['巨鲸与遗城','主角：拾潮者','守护组织与旧秩序'].map(title => recordButton(data.records.find(r => r.title === title))).join('')}</div>
  <div class="section-head"><h2>十二章 · 一条新的循环</h2><span>按叙事阅读顺序排列 · 地点与事件待审定</span></div><div class="routes">${chapters.map(r => `<button class="route" data-record="${escape(r.id)}"><span class="number">${String(r.number).padStart(2,'0')}</span><span><strong>${escape(r.place)}</strong><small>${escape(r.title.replace(/^第.+?章\s*/,''))}</small></span></button>`).join('')}</div>
  <div class="notice">设定中的空白仍然保留：人物姓名与族群、组织正式名称、共鸣残像规则等。<button class="reset" data-category="待定事项">查看待定事项 →</button></div>
  <footer>来源：${data.documents.map(d => escape(d.name + " · " + d.version)).join(" / ")}　/　资料随原稿构建同步</footer>`;
}
function related(record) {
  const candidates = data.records.filter(r => r.id !== record.id && (
    record.chapter === r.id || r.chapter === record.id || record.mentions?.includes(r.id) || r.mentions?.includes(record.id) ||
    (r.category === '人物' && record.body.includes(r.title.replace(/^主角：/, '').replace(/：可选配角$/, ''))) ||
    (record.category === '人物' && r.category === '章节' && r.body.includes(record.title.replace(/^主角：/, '').replace(/：可选配角$/, '')))
  ));
  return `<section class="related"><h2>相关条目 · 按原文提及关联</h2><div>${candidates.length ? candidates.map(r => `<button data-record="${escape(r.id)}">${escape(r.title)}</button>`).join('') : '<span class="toast">暂无关联条目</span>'}</div></section>`;
}
function detail(record) {
  if (!record) return '<article class="reading" id="reader"><div class="empty"><p>未找到相关设定。<br>试试更换关键词，或清除筛选条件。</p><button class="reset" data-reset>清除筛选</button></div></article>';
  const doc = data.documents.find(d => d.id === record.doc);
  return `<article class="reading" id="reader" tabindex="-1"><button class="back-grid" data-grid>← 返回卡片列表</button><div class="eyebrow">${escape(record.category)} / ARCHIVE</div><h1>${highlight(record.title)}</h1><div class="meta">${tag(record)}　${escape(doc.version)}<br>来源：${escape(doc.name)} · ${escape(record.parent || record.title)} · 第 ${record.line} 行<div class="read-actions"><button data-source="${doc.id}" data-line="${record.line}">查看原文位置 ↗</button><button data-copy>复制条目链接</button><span class="toast" role="status" id="copy-status"></span></div></div><div class="prose">${markdown(record.body)}</div>${related(record)}</article>`;
}
function catalog() {
  const term = (state.q || '').toLocaleLowerCase();
  const rows = data.records.filter(r => (!state.c || state.c === '总览' || r.category === state.c) && (!state.s || r.status === state.s) && (!state.src || r.doc === state.src) && (!term || `${r.title} ${r.body} ${r.category}`.toLocaleLowerCase().includes(term)));
  const selected = rows.find(r => r.id === state.id);
  if (!selected) return `<div class="grid-head" role="status"><span>${term ? `“${escape(state.q)}” · ` : ''}共 ${rows.length} 个条目 · 点击卡片查看详情</span><button class="reset" data-reset>重置筛选</button></div><section class="entity-grid" id="reader" tabindex="-1" aria-label="设定条目">${rows.map((r,i) => `<button class="entity-card" data-select="${escape(r.id)}"><span class="card-badge">${String(i+1).padStart(2,'0')}</span><h2>${highlight(r.title)}</h2><span class="card-kind">${escape(r.category)} / ${r.doc === 'world' ? 'WORLD SETTING' : 'STORY DRAFT'}</span><p>${highlight(r.summary.slice(0,180))}</p><span class="card-footer">${tag(r)}<span class="source-tag">${r.doc === 'world' ? '世界观原稿' : '主线叙事原稿'}</span></span></button>`).join('')}</section>${rows.length ? '' : '<div class="empty"><p>未找到相关设定，请更换关键词或清除筛选。</p><button data-reset>清除筛选</button></div>'}`;
  return `<div class="catalog"><section class="list-pane" aria-label="条目列表"><div class="list-head"><span role="status">${escape(state.c || '全部条目')} · ${rows.length} 条</span><button class="reset" data-reset>重置</button></div><div class="record-list">${rows.length ? rows.map(r => `<button class="record" data-select="${escape(r.id)}" aria-current="${r.id === selected?.id}"><span class="tag">${escape(r.category)}</span> ${tag(r)}<strong>${highlight(r.title)}</strong><small>${highlight(r.summary.slice(0, 130))}</small></button>`).join('') : '<div class="empty">没有匹配条目</div>'}</div></section>${detail(selected)}</div>`;
}
function sources() {
  const doc = data.documents.find(d => d.id === state.doc) || data.documents[0];
  return `<div class="catalog"><section class="list-pane" aria-label="原始文稿"><div class="list-head">完整原文 · 2 份</div>${data.documents.map(d => `<button class="record" data-source="${d.id}" aria-current="${d.id === doc.id}"><strong>${escape(d.name)}</strong><small>${escape(d.version)}</small></button>`).join('')}</section><article class="reading" id="reader" tabindex="-1"><div class="eyebrow">SOURCE DOCUMENT / 原始文稿</div><h1>${escape(doc.name)}</h1><div class="meta">${escape(doc.version)}<div class="read-actions"><a href="${doc.id}.md" download>下载 Markdown 原稿 ↓</a><button data-back>返回上一页</button></div></div><div class="prose">${markdown(doc.raw)}</div></article></div>`;
}
function render() {
  $('#categories').innerHTML = categories.map(c => `<button data-category="${c}" aria-current="${state.c === c}" aria-label="${c}">${icon(c)}<span>${c}</span></button>`).join('');
  $('#breadcrumb').textContent = state.c || '总览';
  $('#category-count').textContent = state.c === '原始文稿' ? '2 份原稿' : state.c === '总览' ? `${data.records.length} 个设定条目` : `${data.records.filter(r=>r.category===state.c).length} 个条目`;
  $('#search').value = state.q || '';
  $('#status-filters').innerHTML = [['','全部'],['基础初稿','基础初稿'],['叙事提案','叙事提案']].map(([value,label])=>`<button data-status="${value}" aria-pressed="${(state.s||'')===value}">${label}</button>`).join('');
  $('#source-filters').innerHTML = [['','全部'],['world','世界观原稿'],['story','主线叙事原稿']].map(([value,label])=>`<button data-origin="${value}" aria-pressed="${(state.src||'')===value}">${label}</button>`).join('');
  $('.toolbar').hidden = state.c === '原始文稿';
  workspace.innerHTML = state.c === '原始文稿' ? sources() : (!state.c || state.c === '总览') && !state.q && !state.s && !state.src ? overview() : catalog();
  if (state.line && state.c === '原始文稿') requestAnimationFrame(() => $(`#line-${Number(state.line)}`)?.scrollIntoView({block:'start'}));
}
document.addEventListener('click', async event => {
  if (event.target.closest('.skip')) { event.preventDefault(); $('#reader')?.focus(); return; }
  const button = event.target.closest('button');
  if (!button || !data) return;
  if (button.dataset.category) navigate({c: button.dataset.category, id:'', doc:'', line:''});
  if (button.hasAttribute('data-status')) navigate({s:button.dataset.status, id:''});
  if (button.hasAttribute('data-origin')) navigate({src:button.dataset.origin, id:''});
  if (button.hasAttribute('data-grid')) navigate({id:''});
  if (button.dataset.record) goRecord(button.dataset.record);
  if (button.dataset.select) {
    const scroll = $('.record-list')?.scrollTop || 0;
    navigate({id: button.dataset.select});
    if ($('.record-list')) $('.record-list').scrollTop = scroll;
    $('#reader').focus({preventScroll: true});
    if (innerWidth < 761) $('#reader').scrollIntoView({behavior:'smooth'});
  }
  if (button.dataset.source) navigate({c:'原始文稿', doc:button.dataset.source, line:button.dataset.line || '', q:'', s:''});
  if (button.hasAttribute('data-reset')) navigate({q:'', s:'', src:'', id:'', doc:'', line:''});
  if (button.hasAttribute('data-back')) history.back();
  if (button.hasAttribute('data-copy')) {
    const feedback = $('#copy-status');
    feedback.textContent = '正在复制…';
    try { await navigator.clipboard.writeText(location.href); feedback.textContent = '链接已复制'; }
    catch { feedback.textContent = '请复制浏览器地址栏中的链接'; }
  }
});
$('#search').addEventListener('input', event => navigate({q:event.target.value, id:'', c:'总览', doc:'', line:''}, true));
document.addEventListener('keydown', event => {
  if (event.key === '/' && !['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName)) { event.preventDefault(); $('#search').focus(); }
  if (event.key === 'Escape' && document.activeElement === $('#search')) { navigate({q:'', id:''}, true); $('#search').blur(); }
  if (['ArrowDown','ArrowUp'].includes(event.key) && event.target.matches('.record[data-select]')) {
    event.preventDefault(); const next = event.key === 'ArrowDown' ? event.target.nextElementSibling : event.target.previousElementSibling; next?.focus();
  }
});
window.addEventListener('hashchange', () => { if (data) { state = readState(); render(); } });
try {
  const response = await fetch('data.json');
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  data = await response.json(); state = readState(); render();
} catch {
  workspace.innerHTML = '<div class="empty"><h1>资料暂时未能加载</h1><p>请检查网络后重试。原稿仍可单独下载。</p><button onclick="location.reload()">重新加载</button> · <a href="world.md">世界观原稿</a> · <a href="story.md">叙事原稿</a></div>';
}
