$ErrorActionPreference='Stop'
$runtime=Join-Path $PSScriptRoot '../../../runtime/story-c01/characters'
$data=[ordered]@{manifest=(Get-Content -Raw (Join-Path $runtime 'animations.json') | ConvertFrom-Json);images=@{}}
foreach($key in @('forager','mender')) {
    $data.images[$key]='data:image/png;base64,'+[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $runtime "$key-atlas.png")))
}
$json=$data|ConvertTo-Json -Depth 15 -Compress
$html=@'
<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>须庭角色动作样板</title>
<style>body{margin:0;background:#081923;color:#ddd9c7;font:16px system-ui;padding:24px}h1{font-size:22px}button{padding:8px 18px;margin:0 10px 16px 0;background:#294b54;color:#fff;border:1px solid #72b6af;border-radius:5px}.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}article{border:1px solid #294b54;border-radius:6px;overflow:hidden}p{padding:0 12px}canvas{width:280px;max-width:100%;height:210px;display:block;margin:auto}small{color:#a4b4b7}</style>
<h1>第一章 · 食腐甲与补巢者</h1><p>新身份逐帧样板。上排食腐甲 70px，下排补巢者 90px；明暗底、翻面与暂停可检查。<br><small>技术预览，尚不代表用户审美认可或场景碰撞验收。一次性近扑播放后保留恢复姿态，再开始下一轮预览。</small></p>
<button id="pause">暂停</button><button id="mirror">翻面</button><button id="background">明暗底</button><div class="grid" id="grid"></div>
<script>const data=__DATA__;const canvases=[];const images={};let paused=false,mirrored=false,light=false,clock=0,last=performance.now();
for(const key of ['forager','mender']){images[key]=new Image();images[key].src=data.images[key];const names=key==='forager'?['feed','walk','attack','retreat']:['mend','talk','walk','idle'];for(const action of names){const article=document.createElement('article'),p=document.createElement('p'),canvas=document.createElement('canvas');canvas.width=280;canvas.height=210;p.textContent=key+' / '+action;article.append(p,canvas);grid.append(article);canvases.push({key,action,canvas});}}
pause.onclick=()=>{paused=!paused;pause.textContent=paused?'继续':'暂停';};mirror.onclick=()=>mirrored=!mirrored;background.onclick=()=>light=!light;
function draw(now){if(!paused)clock+=(now-last)/1000;last=now;for(const item of canvases){const {key,action,canvas}=item,actor=data.manifest.actors[key],spec=actor.actions[action],ctx=canvas.getContext('2d');let index=Math.floor(clock*spec.fps);if(spec.loop)index%=spec.frames.length;else index=Math.min(Math.floor((clock%(spec.frames.length/spec.fps+1))*spec.fps),spec.frames.length-1);const frame=spec.frames[index],s=actor.display_height/actor.reference_height;ctx.fillStyle=light?'#e8e4da':'#102b35';ctx.fillRect(0,0,280,210);ctx.save();ctx.translate(140,185);if(mirrored)ctx.scale(-1,1);ctx.drawImage(images[key],frame%4*336,Math.floor(frame/4)*336,336,336,-actor.root[0]*s,-actor.root[1]*s,336*s,336*s);ctx.restore();}window.previewState={clock,paused,mirrored,light,loaded:Object.values(images).every(i=>i.complete&&i.naturalWidth===1344)};requestAnimationFrame(draw)}requestAnimationFrame(draw);
</script></html>
'@
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'preview.html'),$html.Replace('__DATA__',$json),[Text.UTF8Encoding]::new($false))
