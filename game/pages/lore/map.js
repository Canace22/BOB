const positions = [[100,350],[340,330],[460,430],[630,465],[780,395],[620,160],[450,215],[760,235],[900,135],[105,130],[190,235],[1010,360]];
const tones = {'主要对抗':'major','短遭遇':'short','可选遭遇':'optional','休整与判断':'quiet'};
const point = (x,y) => `${x},${y}`;
const stopBefore = (from,to) => {const length=Math.hypot(to[0]-from[0],to[1]-from[1]);return to.map((v,i)=>v-(to[i]-from[i])*34/length)};
const link = (n, mode, emphasis='') => '#'+new URLSearchParams({c:'路线地图',node:String(n),layout:mode,k:emphasis});

function spatial(chapters, selected, state, escape) {
  const route = chapters.slice(0,-1).map((chapter,i) => {
    const from=positions[i],to=positions[i+1];
    if(i===10) return '';
    const line=i===8 ? `M${point(...from)} V60 H${to[0]} V${to[1]-34}` : `M${point(...from)} L${point(...stopBefore(from,to))}`;
    return `<path class="route-edge ${selected===i+1 || selected===i+2?'active-edge':''}" d="${line}" marker-end="url(#arrow)"/>`;
  }).join('');
  return `<div class="map-canvas"><svg viewBox="0 0 1100 570" role="group" aria-label="十二章叙事空间示意图。十一章后沿回流长腔折返，再到尾根主闸。">
    <defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L6,3 L0,6" fill="none" stroke="#96c9ec" stroke-width="1.2"/></marker></defs>
    <rect class="map-zone" x="30" y="85" width="230" height="425" rx="22"/><text class="zone-label" x="50" y="482">头部相关腔室</text>
    <rect class="map-zone" x="285" y="95" width="545" height="415" rx="22"/><text class="zone-label" x="310" y="125">组织与体腔</text>
    <rect class="map-zone" x="850" y="85" width="220" height="425" rx="22"/><text class="zone-label" x="875" y="482">脊椎与尾根</text>
    <g>${route}<path class="route-edge return-edge ${selected===11 || selected===12?'active-edge':''}" d="M190,235 V35 H900 V135 L${point(...stopBefore(positions[8],positions[11]))}" marker-end="url(#arrow)"/><text class="edge-label" x="510" y="24">11 → 经回流长腔折返 → 12</text></g>
    ${chapters.map((c,i)=>{const [x,y]=positions[i];return `<a href="${escape(link(c.number,'space',state.k))}" aria-label="选择第${c.number}章 ${escape(c.place)}，${c.encounterKind}" class="map-node ${tones[c.encounterKind]} ${selected===c.number?'selected-node':''} ${state.k && state.k!==c.encounterKind?'dim-node':''}"><circle class="node-halo" cx="${x}" cy="${y}" r="29"/><circle class="node-circle" cx="${x}" cy="${y}" r="21"/><text class="node-number" x="${x}" y="${y+5}" text-anchor="middle">${String(c.number).padStart(2,'0')}</text><text class="node-label" x="${x}" y="${y+43}" text-anchor="middle">${escape(c.place)}</text>${c.encounterKind==='主要对抗'?`<path class="combat-marker" d="M${x+17},${y-30} l6,10 h-12z"/>`:''}</a>`}).join('')}
  </svg></div>`;
}

function timeline(chapters, selected, state, escape) {
  return `<ol class="chapter-timeline">${chapters.map(c=>`<li class="${selected===c.number?'current-chapter':''} ${state.k && state.k!==c.encounterKind?'dim-node':''}"><a href="${escape(link(c.number,'route',state.k))}" class="timeline-item"><span class="timeline-number">${String(c.number).padStart(2,'0')}</span><span class="timeline-content"><span class="timeline-heading"><strong>${escape(c.place)}</strong><span class="encounter-tag ${tones[c.encounterKind]}">${c.encounterKind}</span></span><span class="timeline-plot">${escape(c.plot)}</span><span class="timeline-after">${escape(c.encounter)}</span></span></a></li>`).join('')}</ol>`;
}

export function renderMap(data,state,escape) {
  const chapters=data.records.filter(r=>r.category==='章节');
  const chapter=chapters.find(c=>c.number===Number(state.node)) || chapters[0];
  const mode=state.layout==='route'?'route':'space';
  const characters=data.records.filter(r=>r.category==='人物' && chapter.body.includes(r.title.replace(/^主角：/,'').replace(/：可选配角$/,'')));
  return `<section class="map-intro"><div><h1>主线编排与空间关系</h1><p>把章节连接、人物动机和战后结果放在一起，检查这条主线如何向前推进。</p></div><div class="map-tabs" aria-label="可视化方式"><a href="${escape(link(chapter.number,'space',state.k))}" aria-current="${mode==='space'}">空间示意</a><a href="${escape(link(chapter.number,'route',state.k))}" aria-current="${mode==='route'}">章节路线</a></div></section>
  <div class="map-boundary">叙事提案 · 布局仅作开发编排示意，连线表示故事行进顺序；尚未建立与当前游戏房间的对应关系。</div>
  <div class="map-layout"><section class="map-board" aria-label="章节地图"><div class="map-board-top"><span>${mode==='space'?'腔室索引 / 点击节点查看开发信息':'章节顺序 / 点击章节查看开发信息'}</span><span>12 章 · 4 次主要对抗</span></div>
  <div class="map-legend" aria-label="突出战斗类型">${['','主要对抗','可选遭遇','休整与判断'].map(kind=>`<a href="${escape(link(chapter.number,mode,kind))}" aria-current="${(state.k||'')===kind}"><i class="${tones[kind]||'all'}"></i>${kind||'全部节点'}</a>`).join('')}</div>
  ${mode==='space'?spatial(chapters,chapter.number,state,escape):timeline(chapters,chapter.number,state,escape)}
  <div class="map-caption">${mode==='space'?'实线：首次推进　虚线：决战前折返　▲：主要对抗。示意位置不代表精确解剖、距离或关卡坐标。':'第十、十一章不安排强制战斗；第四、六章的可选遭遇不影响关键证据。章节不预设相同游玩时长。'}</div></section>
  <article class="map-detail" id="reader" tabindex="-1" aria-label="章节开发信息"><div class="eyebrow">CHAPTER ${String(chapter.number).padStart(2,'0')} / 叙事提案</div><h2>${escape(chapter.place)}</h2><p class="map-chapter-title">${escape(chapter.title)}</p><span class="encounter-tag ${tones[chapter.encounterKind]}">${chapter.encounterKind}</span>
  <dl><dt>叙事推进</dt><dd>${escape(chapter.plot)}</dd><dt>交战位置</dt><dd>${escape(chapter.encounter)}</dd><dt>战前动机</dt><dd>${escape(chapter.motive)}</dd><dt>战后承接 / 离开时带走什么</dt><dd>${escape(chapter.aftermath)}</dd></dl>
  <div class="map-people"><span>本章涉及</span><div>${characters.map(r=>`<button data-record="${escape(r.id)}">${escape(r.title.replace(/^主角：/,''))}</button>`).join('')}</div></div>
  <div class="map-links"><button data-record="${escape(chapter.id)}">章节正文 ↗</button><button data-record="combat-${chapter.number}">战斗安排 ↗</button></div>
  <nav class="chapter-step" aria-label="前后章节">${chapter.number>1?`<a href="${escape(link(chapter.number-1,mode,state.k))}">← 上一章</a>`:'<span>故事起点</span>'}${chapter.number<chapters.length?`<a href="${escape(link(chapter.number+1,mode,state.k))}">下一章 →</a>`:'<span>恢复期与新生活</span>'}</nav>
  <p class="map-source">来源：主线叙事初稿「章节路线」「战斗顺序与剧情承接」及本章正文。章名、事件、人物与战斗均待审定。</p></article></div>`;
}
