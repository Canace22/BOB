// Reproducible additions to the accepted 19-room layout. No exits or footing are moved.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..');
const dir = path.join(repo, 'game/content/whalebelly/world/recipes');
const edit = (id, fn) => {const file=path.join(dir,id+'.json'); const r=JSON.parse(fs.readFileSync(file,'utf8')); fn(r); fs.writeFileSync(file,JSON.stringify(r,null,2)+'\n');};
const prop = (art,at,units) => ({art,at,units});
const landmark = (art,at,units,opacity=0.55,parallax=0.7) => ({art,at,units,opacity,parallax});
// Regional door pairs retain the same graph conditions and destination spawn.
for (const id of ['R2-01','R2-03','R2-04','R3-01','R5-01','R5-02','R5-04','R5-08']) edit(id,r=>{
  const pair = r.kit==='R2'?'blowhole-latch':r.kit==='R3'?'gut-latch':'ear-latch';
  for (const d of r.doors) if (!d.art || /^(blowhole|gut|ear)-latch-/.test(d.art)) {d.art=pair+'-closed';d.art_open=pair+'-open';}
});
edit('R3-01',r=>{
  r.props=[prop('shell-camp',[14,26],3.4),prop('habitat-fungus-bed',[23,26],3.2)];
  r.landmarks=[landmark('r3-liver-edge',[30,25],17,0.35),landmark('r3-shell-nest-before',[20,26],4,0.7)];
  r.interactables=[
    {id:'hub-yusuo',name:'余索',title:'余索 · 旧索与通路',art:'yusuo',at:[17.4,26],units:1.3,lines:['上面的肺口还通着，先去那边看看。','右侧强流门需要潮压，红索上的固定环会带你过去。'],progress_flag:'pressure',progressed_lines:['潮压稳住了。沿右侧固定环上去，过门就是断脊。','回来时认准这处壳营，旧路还在。']},
    {id:'hub-beituo',name:'贝驮',art:'beituo',at:[21,26],units:1.35,lines:['空壳是住处，壳口要留给水流。','别急着搬，先在安全岸边放稳。']}
  ];
  Object.assign(r.drift[1],{progress_flag:'pressure',unlocked_velocity:[0,-35],unlocked_opacity:0.22,transition_seconds:1.2});
});
edit('R2-01',r=>{
  r.props=[prop('nursery-shell-support',[5.6,19.25],3.3),prop('nursery-sac',[5.6,19],2.2)];
  r.landmarks=[landmark('r2-membrane-patch',[19,18.5],7,0.5),landmark('r2-trachea-wall',[4,12],11,0.3)];
  r.state_props=[{before:'nursery-valve-leaf',after:'nursery-valve-leaf',at:[6.75,18.2],units:1.5,flags:['float'],after_rotation:-0.4,layer:2}];
  r.interactables=[{id:'nursery-memory',name:'育床旧刻痕',title:'育床 · 留给上行者的刻痕',at:[4,19],lines:['先跃离膜床，再张开浮膜。','往右上逐台攀升，门后是心室观察台。']}];
});
edit('R2-03',r=>{r.landmarks=[landmark('r2-heart-rupture',[20,16],21,0.55,0.65),landmark('r2-membrane-patch',[7,12],5,0.4)];});
edit('R2-04',r=>{
  r.landmarks=[landmark('r2-heart-rupture',[20,20],23,0.35)];
  r.enemies[0].sprites.core={art:'blood-nest-core',units:1.1,max:256};
  r.enemies[0].tint='ffffff';
});
edit('R4-01',r=>{r.landmarks=[landmark('r4-training-groove',[20,18],10,0.6)];r.props=[prop('anchor-bone-mount',[20,13],1.4)];});
edit('R4-03',r=>{
  r.landmarks=[landmark('r4-training-groove',[19,18],12,0.48)];
  r.props=[prop('anchor-bone-mount',[5.5,18],1.2)];
});
for (const id of ['R4-03','R4-05']) edit(id,r=>{
  const b=r.enemies.find(e=>e.kind==='clam').sprites.body;
  r.enemies.find(e=>e.kind==='clam').sprites.body={art:'clam-spit-cycle-v1',units:id==='R4-05'?4.2:2.15,max:0,visible_width:340,columns:4,rows:2,pivot:[192,393],fallback:b.fallback??b.art,fallback_max:id==='R4-05'?512:256};
});
edit('R4-05',r=>{r.landmarks=[landmark('r4-tapering-vertebrae',[31,20],15,0.3)];});
edit('R4-06',r=>{
  r.props=[prop('shell-camp',[5,18],3.4),prop('tail-flow-shutter',[13.5,16.5],1.6)];
  r.landmarks=[landmark('r4-tapering-vertebrae',[26,21],14,0.45)];
  r.interactables=[{id:'transit-bone-node',name:'骨音节点',title:'骨音节点 · 交通椎',art:'bone-sound-node',at:[8,18],units:1.9,required_flags:['bone'],locked_lines:['骨面安静，尚未取得骨音。'],lines:['骨音沿椎列传来回应。','右门通向耳海。潮压、骨音与静默齐备后，从中段下行口前往归海释放槽。']}];
  const ear=r.doors.find(d=>d.to_id==='R5-01');ear.art='ear-latch-closed';ear.art_open='ear-latch-open';
});
edit('R5-01',r=>{
  r.state_props=[{before:'r5-echo-wall-covered',after:'r5-echo-wall-revealed',before_max:1280,at:[19,15],units:6,flags:['silence'],scan_reveal:true}];
  r.progress_slots=[{flag:'pressure',art:'ui-progress-pressure',at:[19,12.94],pixels:32},{flag:'bone',art:'ui-progress-bone',at:[19,13.75],pixels:32},{flag:'silence',art:'ui-progress-silence',at:[19,14.5],pixels:32}];
  r.interactables=[{id:'ear-three-marks',name:'三槽与声壁',title:'三槽记忆 · 骨面回声',at:[19,15],lines:['三槽分别对应潮压、骨音与静默。','取得的标记会在骨槽中亮起。先沿右门去安全池，再向覆膜深处。'],progress_flag:'silence',progressed_lines:['覆膜后的声槽已显露，静默也回到三槽。','回到交通椎，从中段下行口去释放槽。']}];
});
edit('R5-02',r=>{
  r.props=[prop('habitat-shade',[20,17],3.0),prop('shell-camp',[5,17],3.4)];
  r.landmarks=[landmark('r5-echo-wall-covered',[25,16.5],8,0.2)];
  r.interactables=[{id:'safe-pool-echo',name:'安全池旧刻痕',title:'安全池 · 暂歇',at:[8,17],lines:['先在壳营歇息，右门之后是缄声覆膜。','空心回声圈会记住你先前的位置，等它收拢后再移步。']}];
});
edit('R5-04',r=>{
  r.state_props=[{before:'r5-echo-wall-covered',after:'r5-echo-wall-revealed',before_max:1280,at:[30,18],units:8.5,flags:['silence']}];
});
edit('R5-08',r=>{
  r.landmarks=[landmark('r4-tapering-vertebrae',[22,20],14,0.3)];
  r.ecology=[{art:'sea-larva-swim-v1',rect:[24,10,15,5],count:6,width:90}];
  r.interactables=[{id:'release-record',name:'导流闸记录',title:'归海释放槽 · 导流闸',at:[24,16],lines:['导流闸需要潮压、骨音与静默齐备。','标记不会被消耗。三样齐备后，到右侧导流闸前按交互键。'],progress_flag:'ending',progressed_lines:['导流闸已经打开，流向外海的路仍在。','可以沿左门返回，继续探索鲸体中的旧路。']}];
});
console.log('Updated the existing twelve kit rooms; topology and collisions preserved.');
