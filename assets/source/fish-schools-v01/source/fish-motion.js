/* Original bitmap masters + deterministic body-wave animation. No generated geometry substitutes. */
(function(){
const TAU=Math.PI*2;
const specs=[
 {id:'silverfin',name:'银鳍梭鱼',school:'流带巡游',count:28,rect:[61,312,1418,409],color:'#bfcbd0',cycles:12,amplitude:16,description:'细长梭形 · 象牙侧线 · 分叉尾鳍',motion:'28只 / 梭形长队 / 缓慢横穿 / 错拍摆尾'},
 {id:'tealback',name:'青背圆鳍鱼',school:'浮岛聚群',count:14,rect:[70,127,1387,802],color:'#7dada9',cycles:8,amplitude:11,description:'灰青圆身 · 短扇尾 · 低饱和鳞片',motion:'14只 / 松散团簇 / 起伏回游 / 缓收缓放'},
 {id:'lantern',name:'微光鳍鱼',school:'星弧回游',count:20,rect:[45,165,1681,521],color:'#d5b57c',cycles:16,amplitude:19,description:'细叶轮廓 · 薄膜鱼鳍 · 腹侧微光',motion:'20只 / 弧线跟随 / 连续转向 / 稀疏尾列'}
];
const images=[],frames=[];
const canvas=(w,h)=>Object.assign(document.createElement('canvas'),{width:w,height:h});
function load(url){return new Promise((resolve,reject)=>{let im=new Image();im.onload=()=>resolve(im);im.onerror=()=>reject(Error(url));im.src=url;});}
function makeFrame(k,phase){
 const s=specs[k],im=images[k],c=canvas(320,224),ctx=c.getContext('2d');
 const [sx,sy,sw,sh]=s.rect,w=272,h=w*sh/sw,x0=(320-w)/2,y0=(224-h)/2;
 // Adjacent strips share endpoints. Tail wave fades to zero at the head.
 for(let j=0;j<136;j++){
  let u=j/136,u1=(j+1)/136,tail=Math.pow(Math.max(0,(.8-u)/.8),1.8);
  let tail1=Math.pow(Math.max(0,(.8-u1)/.8),1.8);
  let dy=s.amplitude*tail*Math.sin(phase-u*5.2);
  let dy1=s.amplitude*tail1*Math.sin(phase-u1*5.2);
  let finScale=1+.08*tail*Math.sin(phase+.6);
  ctx.save();ctx.setTransform(1,(dy1-dy)/(w/136),0,finScale,x0+u*w,y0+dy+(h-h*finScale)/2);
  ctx.drawImage(im,sx+u*sw,sy,sw/136+.4,sh,0,0,w/136+.12,h);ctx.restore();
 }
 return c;
}
async function init(root='.'){
 for(const s of specs)images.push(await load(`${root}/source/${s.id}.png`));
 for(let k=0;k<3;k++){frames[k]=[];for(let f=0;f<32;f++)frames[k].push(makeFrame(k,f/32*TAU));}
}
function frac(x){return x-Math.floor(x);}
function member(k,i){
 const a=frac(i*.61803398875+.13),b=frac(i*.41421356237+.31);
 return {i,phase:frac(i*.381966),size:(k===1?48:36)*(0.72+.52*a),depth:.56+.4*b,
  ox:(a-.5)*(k===0?460:330),oy:(b-.5)*(k===0?115:156),cycles:specs[k].cycles+(i%3-1)*4};
}
const members=specs.map((s,k)=>Array.from({length:s.count},(_,i)=>member(k,i)));
function pose(k,m,t,mode='solo'){
 const q=t/16*TAU;
 let x,y,vx,vy;
 if(k===0){x=-390+2060*frac(t/16)+m.ox;y=360+m.oy+12*Math.sin(q*2+m.phase*TAU);vx=129;vy=9*Math.cos(q*2+m.phase*TAU);}
 else if(k===1){
  let pulse=1+.12*Math.sin(q*2);x=640+155*Math.sin(q)+m.ox*pulse;y=360+40*Math.sin(q*2)+m.oy*pulse;
  vx=61*Math.cos(q)+m.ox*.12*2*TAU/16*Math.cos(q*2);vy=31*Math.cos(q*2);
 }else{
  let a=q-m.i*.105, lane=(m.i%3-1)*17;
  x=640+(320+lane)*Math.sin(a);y=360+(110+lane*.45)*Math.cos(a);
  vx=(320+lane)*Math.cos(a);vy=-(110+lane*.45)*Math.sin(a);
 }
 if(mode==='all'){y=(k===0?175:k===1?370:575)+(y-360)*.65;}
 if(mode==='reference'){
  x=640+(x-640)*.58;
  y=(k===0?295:k===1?543:460)+(y-360)*.38;
 }
 const yaw=vx/Math.sqrt(vx*vx+vy*vy+1);
 return {x,y,flip:vx<0?-1:1,turn:.12+.88*Math.abs(yaw),angle:Math.atan2(vy,Math.abs(vx)+1)*.30,
  frame:Math.floor(frac(t*m.cycles/16+m.phase)*32),size:m.size*(mode==='reference'?.65:1),alpha:m.depth};
}
function fish(ctx,k,p,alpha=1){
 const img=frames[k][p.frame];let w=p.size/272*320;
 ctx.save();ctx.translate(p.x,p.y);ctx.rotate(p.angle);ctx.scale(p.flip*p.turn,1);ctx.globalAlpha=alpha;
 ctx.drawImage(img,-w/2,-w*224/640,w,w*224/320);ctx.restore();
}
function draw(ctx,t,selection=-1,mode='all',transparent=false,background=null){
 ctx.clearRect(0,0,1280,720);
 if(!transparent){
  if(mode==='reference'&&background)ctx.drawImage(background,0,0,1280,720);
  else {let g=ctx.createLinearGradient(0,0,0,720);g.addColorStop(0,'#142e3a');g.addColorStop(1,'#07151e');ctx.fillStyle=g;ctx.fillRect(0,0,1280,720);}
 }
 for(let k=0;k<3;k++)if(selection<0||selection===k){
  const drawMode=mode==='reference'?'reference':selection<0?'all':'solo';
  for(const m of members[k]){const p=pose(k,m,t,drawMode);fish(ctx,k,p,p.alpha*(mode==='reference'?.68:1));}
 }
}
window.FishMotion={specs,members,frames,images,init,makeFrame,draw,fish,pose,canvas};
})();
