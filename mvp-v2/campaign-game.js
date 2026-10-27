import { CampaignGame, CAMPAIGN_SAVE_KEY, validateCampaignSave } from './campaign-engine.js';
import { CAMPAIGN_ROOMS } from './campaign-levels.js';
import { CampaignRenderer } from './campaign-renderer.js';
import { Soundscape } from './audio.js';

const $ = id => document.getElementById(id);
const canvas=$('game'), renderer=new CampaignRenderer(canvas), audio=new Soundscape();
const defaults={left:'KeyA',right:'KeyD',jump:'Space',attack:'KeyQ',heavy:'KeyR',interact:'KeyE',dash:'ShiftLeft',rest:'KeyH',lamp:'KeyL'};
const labels={left:'向左',right:'向右',jump:'跳跃',attack:'短击',heavy:'重鸣',interact:'交互',dash:'贴流冲',rest:'调息',lamp:'提灯'};
const bindingKey='whalefall-v52-controls';
let bindings={...defaults}, saved=null, paused=false, manual=false, capture=null, toastUntil=0, ready=false;
const held=new Set(), touch=new Set();
try {
  saved=validateCampaignSave(JSON.parse(localStorage.getItem(CAMPAIGN_SAVE_KEY)));
  const stored=JSON.parse(localStorage.getItem(bindingKey));
  if (stored && Object.keys(defaults).every(k=>typeof stored[k]==='string') && new Set(Object.values(stored)).size===9) bindings={...defaults,...stored};
} catch { /* Invalid storage starts a fresh campaign; legacy saves remain intact. */ }
function persist() {
  saved=game.serialize();
  try { localStorage.setItem(CAMPAIGN_SAVE_KEY,JSON.stringify(saved)); }
  catch { toast('浏览器无法保存进度，请保持此页面打开。'); }
}
function toast(text) { $('toast').textContent=hint(text); $('toast').classList.remove('hidden'); toastUntil=performance.now()+4200; }
const game=new CampaignGame((type,payload)=>{
  if(type==='save') persist();
  if(type==='toast') toast(payload);
  if(type==='sound') audio.cue(payload);
  if(type==='batch-complete') showPanel('须门遗港 · 主线完成',`<p>${payload}</p><p>已取得贴流冲 A1。可继续探索育窝、返回旧营地，或在地图查看尚待开放的通路。</p>`);
});
function keyName(code) { return code.replace(/^Key/,'').replace('Space','空格').replace('ShiftLeft','Shift').replace('ShiftRight','右 Shift').replace('Arrow',''); }
function hint(text='') {
  return text.replace(/\b(Q|R|E|L|H|Shift)\b/g, key=>keyName(bindings[({Q:'attack',R:'heavy',E:'interact',L:'lamp',H:'rest',Shift:'dash'})[key]]));
}
function setText(id,text) { if($(id).textContent!==text) $(id).textContent=text; }
function guide() { $('controls-guide').replaceChildren(...Object.entries(labels).filter(([k])=>!['rest','lamp'].includes(k)).map(([key,label])=>{ const el=document.createElement('span'), k=document.createElement('kbd');k.textContent=keyName(bindings[key]);el.append(k,` ${label}`);return el; })); }
function updateHUD() {
  const s=game.state;
  setText('room-id',`${s.room} / 须门遗港`);setText('room-name',game.room.name);
  setText('objective',hint(game.objective())); setText('context-hint',hint(game.context()));
  setText('life-status','● '.repeat(s.life)+'○ '.repeat(s.maxLife-s.life));
  setText('resonance-status',`蓄振 ${s.resonance} / 4`);
  setText('ability-status',s.abilities.has('A1')?`贴流冲 A1 · ${s.dash.available?'就绪':'落稳刷新'}`:'贴流冲 · 尚未取得');
  setText('rest-status',s.rest>0?'调息中…':`${keyName(bindings.rest)} 调息 · 消耗 2 蓄振`);
  if(performance.now()>toastUntil) $('toast').classList.add('hidden');
}
function clearInput() { held.clear();touch.clear(); }
function start(continuing=false) {
  if(!ready)return;
  closePanel(); game.start(continuing?saved:null);$('title-screen').classList.add('hidden');$('hud').classList.remove('hidden');
  audio.start();canvas.focus();updateHUD();
}
function showPanel(title,html) { paused=true;clearInput();$('overlay-title').textContent=title;$('overlay-content').innerHTML=html;$('overlay').classList.remove('hidden');$('overlay-close').focus(); }
function closePanel() { paused=false;capture=null;clearInput();$('overlay').classList.add('hidden');canvas.focus(); }
function map() {
  const s=game.state;
  const r=game.room;
  const terrain=(r.terrain||[]).map(t=>`<polyline points="${t.points.map(p=>`${p.x},${p.y}`).join(' ')}" fill="none" stroke="#b7c9b5" stroke-width="7"/>`).join('');
  const platforms=(r.platforms||[]).map(p=>`<rect x="${p.x}" y="${p.y}" width="${p.w}" height="8" fill="#b7c9b5"/>`).join('');
  const exits=(r.exits||[]).map(e=>`<circle cx="${e.x}" cy="${e.y-25}" r="15" fill="${e.unavailable?'#bb9673':'#92d2bb'}"/>`).join('');
  const minimap=`<svg class="room-minimap" viewBox="0 0 ${r.width} ${r.height}" role="img" aria-label="当前房间地形和所在位置">${terrain}${platforms}${exits}<circle cx="${s.player.x+15}" cy="${s.player.y+24}" r="18" fill="#f6d085"/></svg><p>金点：你的位置 · 青点：通路 · 棕点：后续能力通路</p>`;
  showPanel('须门遗港 · 路线图',`${minimap}<p>沿须门主线前进，记住高处暂时无法抵达的通路。</p><ol class="route-list">${CAMPAIGN_ROOMS.map(r=>`<li class="${r.id===s.room?'current':''}"><strong>${s.visited.has(r.id) ? r.name : "未探索房间"}</strong><small>${r.id===s.room?'所在房间':s.visited.has(r.id)?'已到访':s.visited.has('R1-02')&&r.id==='R1-06'?'高处通路 · 需要 A2':s.visited.has('R1-02')&&r.id==='R1-07'?'高处通路 · 需要 A3':'未知'}</small></li>`).join('')}</ol><p>当前开放五间主线房。R1 两条能力支路与胃枢在后续批次接续；全设计共 36 房。</p>`);
}
function settings() {
  showPanel('操作按键', '<p>点击一项后按新键。方向键也可移动；M 地图、Esc 暂停固定保留。</p><div class="binding-grid"></div><div class="panel-actions"><button id="reset-bindings">恢复默认</button></div>');
  for(const [action,label] of Object.entries(labels)) {
    const button=document.createElement('button');button.textContent=`${label} · ${keyName(bindings[action])}`;
    button.onclick=()=>{capture={action,button};button.textContent=`${label} · 请按新键…`;};
    document.querySelector('.binding-grid').append(button);
  }
  $('reset-bindings').onclick=()=>{bindings={...defaults};saveBindings();settings();};
}
function saveBindings() { try {localStorage.setItem(bindingKey,JSON.stringify(bindings));} catch {} guide(); }
function pause() {
  showPanel('潮声暂歇','<p>当前进度已保存至最近登记的营地；取得的能力、奖励和 Boss 胜利会保留。</p><div class="panel-actions"><button id="resume-btn">继续探索</button><button id="restart-btn">重新开始</button></div>');
  persist();$('resume-btn').onclick=closePanel;
  $('restart-btn').onclick=()=>{
    showPanel('重新开始本轮主线','<p>将重置须门主线进度。旧四区的存档仍保留。</p><div class="panel-actions"><button id="confirm-restart">重新开始</button></div>');
    $('confirm-restart').onclick=()=>start(false);
  };
}
$('start-btn').onclick=()=>saved? (showPanel('开始新旅程','<p>将替换当前须门主线存档。</p><div class="panel-actions"><button id="confirm-start">开始新旅程</button></div>'),$('confirm-start').onclick=()=>start(false)):start(false);
$('continue-btn').onclick=()=>start(true);$('overlay-close').onclick=closePanel;
$('map-btn').onclick=map;$('settings-btn').onclick=settings;$('pause-btn').onclick=pause;
$('sound-btn').onclick=()=>{audio.start();audio.setMuted(!audio.muted);setText('sound-btn',audio.muted?'声音 关':'声音 开');};
window.addEventListener('keydown',event=>{
  if(capture) {
    event.preventDefault();if(event.repeat)return;
    if(['Escape','KeyM','Tab','ArrowLeft','ArrowRight','MetaLeft','ControlLeft','AltLeft'].includes(event.code)) {capture.button.textContent='此键保留，请换一个';return;}
    const duplicate=Object.keys(bindings).find(key=>bindings[key]===event.code);
    if(duplicate) bindings[duplicate]=bindings[capture.action];
    bindings[capture.action]=event.code;capture=null;saveBindings();settings();return;
  }
  if(Object.values(bindings).includes(event.code)||['ArrowLeft','ArrowRight','Space','Escape','KeyM'].includes(event.code)) event.preventDefault();
  if(event.repeat)return;
  if(game.state.mode==='playing' && event.code==='Escape') { paused?closePanel():pause();return; }
  if(game.state.mode==='playing' && event.code==='KeyM') { paused?closePanel():map();return; }
  held.add(event.code);
});
window.addEventListener('keyup',e=>held.delete(e.code));
window.addEventListener('blur',()=>{clearInput();if(game.state.mode==='playing'&&!paused)pause();});
for(const button of document.querySelectorAll('[data-action]')) {
  button.addEventListener('pointerdown',e=>{e.preventDefault();button.setPointerCapture(e.pointerId);touch.add(button.dataset.action);});
  for(const event of ['pointerup','pointercancel','lostpointercapture']) button.addEventListener(event,()=>touch.delete(button.dataset.action));
}
function input() { return Object.fromEntries(Object.keys(defaults).map(action=>[action,touch.has(action)||held.has(bindings[action])||(action==='left'&&held.has('ArrowLeft'))||(action==='right'&&held.has('ArrowRight'))])); }
function step(dt) { if(!paused)game.step(dt,input()); }
let previous=performance.now(),accumulator=0,hudTimer=0;
function frame(now) {
  const dt=Math.min(.1,(now-previous)/1000);previous=now;
  if(!manual){accumulator+=dt;while(accumulator>=1/120){step(1/120);accumulator-=1/120;}}
  renderer.draw(game.state,game.room);hudTimer+=dt;if(hudTimer>.1){updateHUD();hudTimer=0;}
  requestAnimationFrame(frame);
}
window.render_campaign_to_text=()=>JSON.stringify({...game.state,paused,context:hint(game.context()),objective:hint(game.objective())},(_key,value)=>value instanceof Set?[...value]:value);
window.advanceTime=async ms=>{manual=true;for(let remaining=Math.max(0,ms);remaining>0;remaining-=1000/120)step(Math.min(remaining/1000,1/120));renderer.draw(game.state,game.room);updateHUD();};
guide();requestAnimationFrame(frame);
await renderer.load();ready=true;
$('start-btn').disabled=false;$('start-btn').textContent='开始探索 ↗';
if(saved)$('continue-btn').classList.remove('hidden');
const missing=[...renderer.images.values()].filter(image=>!image).length;
if(missing)$('load-status').textContent=`${missing} 项图片暂未载入，已使用基础外观，可继续探索。`;
