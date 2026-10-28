import { levels, memories } from './levels.js';
import { Renderer } from './renderer.js';
import { Soundscape } from './audio.js';

const $ = (id) => document.getElementById(id);
const renderer = new Renderer($('game'));
const audio = new Soundscape();
const SAVE_KEY = 'whalefall-mvp-v1';
const keys = new Set();
const clamp = (v, min, max) => Math.min(max, Math.max(min, v));
const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
let ready = false;
let manualTime = false;
let toastTimer = 0;
let introTimer = 0;
let previous = 0;
let checkpoint = { x: 120, y: 566 };
let save = readSave();
const state = {
  mode: 'title', time: 0, elapsed: 0, room: 0, unlocked: 0, camera: { x: 0 },
  player: { x:120,y:566,w:30,h:54,vx:0,vy:0,facing:1,grounded:false,invulnerable:0,jumps:0 },
  pulses:[],particles:[],collected:new Set(),activated:new Set(),cooldown:0,health:3,
  gateOpen:false,bridgeOpen:false,exitOpen:false,shake:0,deaths:0,
};

function readSave() {
  try {
    const value = JSON.parse(localStorage.getItem(SAVE_KEY));
    if (!value || value.version !== 1 || !Number.isInteger(value.room) || value.room < 0 || value.room > 2) return null;
    if (!Array.isArray(value.collected) || !Array.isArray(value.activated)) return null;
    return value;
  } catch { return null; }
}
function persist() {
  save = {version:1,room:state.room,unlocked:state.unlocked,collected:[...state.collected],activated:[...state.activated],elapsed:state.elapsed,deaths:state.deaths};
  try { localStorage.setItem(SAVE_KEY, JSON.stringify(save)); } catch { /* The game remains playable without storage. */ }
}
function center() { const p=state.player; return {x:p.x+p.w/2,y:p.y+p.h/2}; }
function activePlatforms() { return levels[state.room].platforms.filter(p => !p.requires || state.activated.has(p.requires)); }
function activeHazards() { return state.room===2 && state.exitOpen ? [] : levels[state.room].hazards; }
function solved() { return levels[state.room].nodes.every(n => state.activated.has(n.id)); }
function updateFlags() {
  state.gateOpen=state.activated.has('baleen');
  state.bridgeOpen=state.activated.has('bone-bridge');
  state.exitOpen=solved();
}
function showToast(message, duration = 3.6) {
  $('toast').textContent = message;
  $('toast').classList.remove('hidden');
  toastTimer = duration;
}
function burst(x,y,color,count=24) {
  for(let i=0;i<count;i++) {
    const angle=i/count*Math.PI*2;
    const speed=30+(i*37%91);
    state.particles.push({x,y,vx:Math.cos(angle)*speed,vy:Math.sin(angle)*speed-25,age:0,life:1.2+(i%5)*.12,color});
  }
}
function enterRoom(index) {
  state.room=index;
  state.unlocked=Math.max(state.unlocked,index);
  const level=levels[index];
  checkpoint={...level.spawn};
  Object.assign(state.player,{...checkpoint,vx:0,vy:0,grounded:false,jumps:0,invulnerable:1});
  state.camera.x=0;
  state.health=3;
  state.pulses=[];
  state.particles=[];
  state.cooldown=0;
  updateFlags();
  audio.setRoom(index);
  $('room-name').textContent=level.name;
  $('chapter-number').textContent=`0${index+1} / 03`;
  $('depth-value').textContent=level.depth;
  $('intro-number').textContent=`CHAPTER 0${index+1}`;
  $('intro-title').textContent=level.name;
  $('intro-subtitle').textContent=level.subtitle;
  $('room-intro').classList.remove('hidden');
  $('room-intro').style.animation='none';
  void $('room-intro').offsetWidth;
  $('room-intro').style.animation='';
  introTimer=4;
  showToast(index === 0 ? 'A / D 移动 · 空格浮跃，空中可再跃一次 · 靠近发光骨叉按 E' : level.description,5);
  persist();
  refreshHUD();
}
function startGame(resume = false) {
  if(!ready)return;
  audio.start();
  keys.clear();
  const data=resume?save:null;
  state.collected=new Set(data?.collected.filter(id=>memories.some(m=>m.id===id))||[]);
  state.activated=new Set(data?.activated.filter(id=>levels.some(l=>l.nodes.some(n=>n.id===id)))||[]);
  state.unlocked=data?.unlocked||0;
  state.elapsed=data?.elapsed||0;
  state.deaths=data?.deaths||0;
  state.time=0;
  state.mode='playing';
  $('title-screen').classList.add('hidden');
  $('overlay').classList.add('hidden');
  $('hud').classList.remove('hidden');
  $('touch-controls').classList.remove('hidden');
  enterRoom(data?.room||0);
}
function jump() {
  if(state.mode!=='playing')return;
  const p=state.player;
  if(p.jumps>=2)return;
  p.vy=p.jumps===0?-510:-450;
  p.grounded=false;
  p.jumps++;
  audio.play('jump');
  burst(p.x+15,p.y+p.h,'#a3d8d0',9);
}
function resonance() {
  if(state.mode!=='playing'||state.cooldown>0)return;
  const c=center();
  state.cooldown=.8;
  state.pulses.push({...c,age:0});
  audio.play('resonance');
  const level=levels[state.room];
  const nearby=level.nodes.filter(n=>distance(c,n)<145 && !state.activated.has(n.id));
  if(nearby.length) {
    const node=nearby.sort((a,b)=>distance(c,a)-distance(c,b))[0];
    state.activated.add(node.id);
    burst(node.x,node.y,'#e8d59f',35);
    audio.play('activate');
    state.shake=.3;
    const platform=activePlatforms().filter(p=>node.x>=p.x&&node.x<=p.x+p.w&&p.y>=node.y).sort((a,b)=>a.y-b.y)[0];
    if(platform)checkpoint={x:clamp(node.x-35,platform.x+8,platform.x+platform.w-40),y:platform.y-state.player.h};
    updateFlags();
    const messages={gate:'鲸须回应了你。门后的海水，正在缓缓流动。',bridge:'回声凝成骨桥。前往对岸，留意漂浮的水母。',valve:`凝血阀已疏通 · ${level.nodes.filter(n=>state.activated.has(n.id)).length} / 3`};
    showToast(solved() && state.room===2 ? '三枚阀门已疏通。潮水卷走清道夫，前往右侧出口。' : messages[node.kind]);
    persist();
  } else if (distance(c,level.exit)<130) {
    if(!solved()) showToast(state.room===2?'潮泵仍被堵塞。需要先疏通三枚凝血阀。':'前方仍未贯通。寻找尚未回应的机关。');
    else if(state.room<2) enterRoom(state.room+1);
    else finish();
  } else {
    const next=level.nodes.find(n=>!state.activated.has(n.id));
    if(next)showToast(`靠近「${next.label}」后，再按 E 共鸣。`,2.5);
  }
  refreshHUD();
}
function hurt(fall=false) {
  const p=state.player;
  if(!fall && p.invulnerable>0)return;
  state.health--;
  state.shake=.35;
  audio.play('hurt');
  burst(p.x+15,p.y+25,'#e4a084',15);
  if(fall||state.health<=0) {
    state.deaths++;
    if(state.health<=0)state.health=3;
    Object.assign(p,{...checkpoint,vx:0,vy:0,grounded:false,jumps:0,invulnerable:2});
    state.camera.x=clamp(p.x-380,0,levels[state.room].width-1280);
    showToast('提灯仍然亮着。你回到了最近的共鸣处。',3);
  } else {p.invulnerable=2;p.vy=-290;p.vx=-p.facing*180;}
  refreshHUD();
}
function movePlayer(dt) {
  const p=state.player;
  const level=levels[state.room];
  const direction=Number(keys.has('right'))-Number(keys.has('left'));
  p.vx=direction*270;
  if(direction)p.facing=direction;
  p.x=clamp(p.x+p.vx*dt,0,level.width-p.w);
  if(level.gate&&!state.activated.has(level.gate.nodeId)) {
    const g=level.gate;
    if(p.y+p.h>g.y&&p.y<g.y+g.h&&p.x+p.w>g.x&&p.x<g.x+g.w) {
      p.x=p.vx>=0?g.x-p.w:g.x+g.w;
    }
  }
  const oldBottom=p.y+p.h;
  p.vy+=1200*dt;
  p.y+=p.vy*dt;
  p.grounded=false;
  for(const platform of activePlatforms()) {
    if(p.vy>=0&&oldBottom<=platform.y+1&&p.y+p.h>=platform.y&&p.x+p.w>platform.x+2&&p.x<platform.x+platform.w-2) {
      p.y=platform.y-p.h;p.vy=0;p.grounded=true;p.jumps=0;
    }
  }
  // Walking off a ledge leaves exactly one midair jump.
  if(!p.grounded && p.vy>0 && p.jumps===0)p.jumps=1;
  p.invulnerable=Math.max(0,p.invulnerable-dt);
  if(p.y>790)hurt(true);
  for(const h of activeHazards()) {
    const c=center();
    const hx=h.x+Math.sin(state.time*h.speed)*h.range;
    if(Math.hypot(c.x-hx,c.y-h.y)<h.r+17)hurt();
  }
  for(const memory of level.memories) {
    if(!state.collected.has(memory.id)&&distance(center(),memory)<45) {
      state.collected.add(memory.id);
      audio.play('collect');
      burst(memory.x,memory.y,'#ead394',36);
      showToast(`拾回${memories.find(m=>m.id===memory.id).title} · 按 J 阅读`,4);
      persist();refreshHUD();
    }
  }
  const target=clamp(p.x-410,0,level.width-1280);
  state.camera.x+=(target-state.camera.x)*Math.min(1,dt*5);
}
function update(dt) {
  if(state.mode==='title'){state.time+=dt;return;}
  if(state.mode!=='playing')return;
  state.time+=dt;state.elapsed+=dt;
  state.cooldown=Math.max(0,state.cooldown-dt);
  state.shake=Math.max(0,state.shake-dt);
  movePlayer(dt);
  for(const pulse of state.pulses)pulse.age+=dt;
  state.pulses=state.pulses.filter(p=>p.age<1.2);
  for(const particle of state.particles){particle.age+=dt;particle.x+=particle.vx*dt;particle.y+=particle.vy*dt;particle.vy+=15*dt;}
  state.particles=state.particles.filter(p=>p.age<p.life);
  if(toastTimer>0){toastTimer-=dt;if(toastTimer<=0)$('toast').classList.add('hidden');}
  if(introTimer>0){introTimer-=dt;if(introTimer<=0)$('room-intro').classList.add('hidden');}
  refreshContext();
  $('cooldown-bar').style.width=`${(1-state.cooldown/.8)*100}%`;
  $('resonance-ready').textContent=state.cooldown>0?'回响中':'就绪';
}
function refreshHUD() {
  $('health').innerHTML=Array.from({length:3},(_,i)=>`<i class="health-pip ${i>=state.health?'empty':''}"></i>`).join('');
  $('health').setAttribute('aria-label',`生命 ${state.health} / 3`);
  $('memory-count').textContent=`${state.collected.size} / 3`;
  const goals=['共鸣鲸须，寻找进入鲸体的路','唤出骨桥，跨越沉默的穹顶','疏通凝血阀，让潮水重新流动'];
  $('objective').textContent=solved() ? (state.room===2?'潮泵已苏醒 · 前往右侧出口':'通路已开启 · 向右继续探索') : goals[state.room]+(state.room===2?` · ${levels[2].nodes.filter(n=>state.activated.has(n.id)).length} / 3`:'');
}
function refreshContext() {
  const level=levels[state.room];const c=center();
  const node=level.nodes.find(n=>distance(c,n)<145&&!state.activated.has(n.id));
  const hint=$('context-hint');
  let text=node?`<kbd>E</kbd> 共鸣 · ${node.label}`:'';
  if(!text&&distance(c,level.exit)<130)text=solved()?`<kbd>E</kbd> ${state.room===2?'随潮水离开':'进入'+levels[state.room+1].name}`:'尚有机关未被唤醒';
  hint.innerHTML=text;hint.classList.toggle('hidden',!text);
}
function openOverlay(kind) {
  if(state.mode!=='playing'&&state.mode!==kind)return;
  if(state.mode===kind){closeOverlay();return;}
  state.mode=kind;keys.clear();
  $('overlay-close').classList.remove('hidden');
  const container=$('overlay-content');
  if(kind==='paused')container.innerHTML=`<p class="eyebrow">A MOMENT IN THE DEEP</p><h2 id="overlay-title">在此歇息</h2><p class="overlay-sub">提灯为你守着这一小片海。</p><button class="primary" data-menu="resume">继续探索 <span>→</span></button><div class="pause-actions"><button data-menu="checkpoint">回到落脚点</button><button data-menu="fullscreen">全屏显示</button><button data-menu="title">返回标题</button></div><p>空格 · 浮跃与二段跳　 E · 共鸣　 J · 记忆　 F · 全屏</p>`;
  if(kind==='map')container.innerHTML=`<p class="eyebrow">ANATOMY OF A JOURNEY</p><h2 id="overlay-title">鲸体行迹</h2><p class="overlay-sub">跟随鲸歌，从入口走向心脏。</p><div class="route">${levels.map((l,i)=>`<article class="route-stop ${i===state.room?'current':''}"><img src="../${['01_鲸口门庭.png','08_肋骨穹顶.png','05_心室潮泵.png'][i]}" alt="${l.name}"><h3>0${i+1} · ${l.name}</h3><p>${l.description}</p><small>${i===state.room?'◆ 你在这里':i<=state.unlocked?'◇ 已探索':'○ 尚未抵达'}</small></article>`).join('')}</div><button class="primary" data-menu="resume">收起地图 <span>↗</span></button>`;
  if(kind==='journal')container.innerHTML=`<p class="eyebrow">MEMORIES HELD IN BONE</p><h2 id="overlay-title">骨中余音</h2><div class="journal-pages">${memories.map((m,i)=>`<article class="memory-page ${state.collected.has(m.id)?'':'locked'}"><span>0${i+1}</span><h3>${state.collected.has(m.id)?m.title:'尚未拾回的记忆'}</h3><p>${state.collected.has(m.id)?m.text:'微光散落在鲸体深处。触碰金色记忆泡，让过去再次浮现。'}</p></article>`).join('')}</div><button class="primary" data-menu="resume">合上手记 <span>↗</span></button>`;
  $('overlay').classList.remove('hidden');
  container.querySelector('button')?.focus();
}
function closeOverlay(){state.mode='playing';keys.clear();$('overlay').classList.add('hidden');}
function finish(){
  state.mode='ending';keys.clear();persist();audio.play('complete');
  $('overlay-close').classList.add('hidden');
  $('overlay-content').innerHTML=`<div class="ending"><div class="ending-symbol">◌</div><p class="eyebrow">THE END IS A BEGINNING</p><h2 id="overlay-title">一鲸落，万物生</h2><p class="ending-poem">潮水重新穿过沉睡的心室。<br>微小的生命循着回声，游向更深的蓝。<br>这座遗城，又开始呼吸了。</p><div class="ending-stats">记忆 ${state.collected.size} / 3　 ·　 探索 ${Math.floor(state.elapsed/60)} 分 ${Math.floor(state.elapsed%60)} 秒　 ·　 三处秘境已贯通</div><button class="primary" data-menu="restart">再次提灯入海 <span>↗</span></button><button class="text-button" data-menu="title">返回标题</button></div>`;
  $('overlay').classList.remove('hidden');
  $('overlay-content').querySelector('button')?.focus();
}
function returnTitle(){
  persist();state.mode='title';keys.clear();state.camera.x=0;
  $('overlay').classList.add('hidden');$('hud').classList.add('hidden');$('touch-controls').classList.add('hidden');$('title-screen').classList.remove('hidden');$('continue-btn').classList.remove('hidden');
}
function fullscreen(){
  if(document.fullscreenElement)document.exitFullscreen?.();
  else $('viewport').requestFullscreen?.().catch(()=>showToast('当前浏览器不支持全屏，可直接放大窗口。'));
}
$('start-btn').addEventListener('click',()=>startGame());
$('continue-btn').addEventListener('click',()=>startGame(true));
$('pause-btn').addEventListener('click',()=>openOverlay('paused'));
$('map-btn').addEventListener('click',()=>openOverlay('map'));
$('journal-btn').addEventListener('click',()=>openOverlay('journal'));
$('sound-btn').addEventListener('click',()=>{
  audio.start();audio.setMuted(!audio.muted);
  $('sound-btn').textContent=audio.muted?'♪':'♫';
  $('sound-btn').setAttribute('aria-label',audio.muted?'开启声音':'静音');
  showToast(audio.muted?'深海已静音':'深海声音已开启',2);
});
$('overlay').addEventListener('click',(event)=>{
  const action=event.target.closest('[data-menu]')?.dataset.menu;
  if(action==='resume')closeOverlay();
  if(action==='restart')startGame();
  if(action==='title')returnTitle();
  if(action==='fullscreen')fullscreen();
  if(action==='checkpoint'){Object.assign(state.player,{...checkpoint,vx:0,vy:0,invulnerable:2,jumps:0});closeOverlay();}
});
const directions={KeyA:'left',ArrowLeft:'left',KeyD:'right',ArrowRight:'right'};
window.addEventListener('keydown',(event)=>{
  if(['Space','ArrowUp','ArrowLeft','ArrowRight','ArrowDown','Tab'].includes(event.code)&&event.code!=='Tab')event.preventDefault();
  if(event.repeat){if(directions[event.code]&&state.mode==='playing')keys.add(directions[event.code]);return;}
  if(event.code==='KeyF'){fullscreen();return;}
  if(state.mode==='title'){if(event.code==='Enter')startGame();return;}
  if(event.code==='Escape'){
    if(state.mode==='playing')openOverlay('paused');
    else if(['paused','map','journal'].includes(state.mode))closeOverlay();
    return;
  }
  if(event.code==='KeyM'){openOverlay('map');return;}
  if(event.code==='KeyJ'){openOverlay('journal');return;}
  if(state.mode!=='playing')return;
  if(directions[event.code])keys.add(directions[event.code]);
  if(['Space','KeyW','ArrowUp'].includes(event.code))jump();
  if(event.code==='KeyE')resonance();
});
window.addEventListener('keyup',(event)=>{if(directions[event.code])keys.delete(directions[event.code]);});
window.addEventListener('blur',()=>{keys.clear();if(state.mode==='playing')openOverlay('paused');});
document.addEventListener('visibilitychange',()=>{if(document.hidden){keys.clear();if(state.mode==='playing')openOverlay('paused');}});
for(const button of document.querySelectorAll('[data-hold]')){
  button.addEventListener('pointerdown',(event)=>{event.preventDefault();button.setPointerCapture(event.pointerId);if(state.mode==='playing')keys.add(button.dataset.hold);});
  for(const event of ['pointerup','pointercancel','lostpointercapture'])button.addEventListener(event,()=>keys.delete(button.dataset.hold));
}
for(const button of document.querySelectorAll('[data-action]'))button.addEventListener('pointerdown',(event)=>{event.preventDefault();button.dataset.action==='jump'?jump():resonance();});

window.render_game_to_text=()=>JSON.stringify({
  mode:state.mode,room:levels[state.room].name,roomIndex:state.room,coordinates:'origin top-left; x right, y down; units logical pixels',
  player:{...state.player,x:Math.round(state.player.x),y:Math.round(state.player.y)},cameraX:Math.round(state.camera.x),health:state.health,
  collected:[...state.collected],activated:[...state.activated],cooldown:+state.cooldown.toFixed(2),elapsed:+state.elapsed.toFixed(2),deaths:state.deaths,
  gateOpen:state.gateOpen,bridgeOpen:state.bridgeOpen,exitOpen:state.exitOpen,checkpoint,
  platforms:activePlatforms(),nodes:levels[state.room].nodes.map(n=>({...n,active:state.activated.has(n.id),distance:Math.round(distance(center(),n))})),
  memories:levels[state.room].memories.filter(m=>!state.collected.has(m.id)),hazards:activeHazards().map(h=>({...h,x:h.x+Math.sin(state.time*h.speed)*h.range})),exit:levels[state.room].exit,
});
window.advanceTime=(ms)=>{manualTime=true;const steps=Math.max(1,Math.round(ms/(1000/60)));for(let i=0;i<steps;i++)update(1/60);renderer.draw(state,levels[state.room]);};
function frame(now){
  const dt=previous?Math.min((now-previous)/1000,.04):0;
  previous=now;
  if(!manualTime)update(dt);
  renderer.draw(state,levels[state.room]);
  requestAnimationFrame(frame);
}
async function boot(){
  try{
    await renderer.load();ready=true;
    $('start-btn').disabled=false;
    $('start-btn').innerHTML='<span>提灯入海</span><span>↗</span>';
    if(save)$('continue-btn').classList.remove('hidden');
    requestAnimationFrame(frame);
  }catch(error){$('loading-error').classList.remove('hidden');$('loading-error').textContent='场景加载失败，请刷新重试。'+error.message;console.error(error);}
}
boot();
