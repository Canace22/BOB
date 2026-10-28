// Deterministic extraction only: no repainting, per-frame scaling, or alpha removal.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
let sharp;
try { sharp = require('sharp'); } catch { sharp = require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp'); }
const src = __dirname;
const root = path.resolve(src, '../../..');
const out = path.join(root,'assets/runtime/sprites/tide-picker-locomotion-v01');
const godot = path.join(root,'godot/WhalebellyRuins');
const game = path.join(godot,'assets/runtime/tide-picker-locomotion-v01');
const specs = {
  idle: {source:'idle-source.png',fps:6,roots:[210,200,195,196,205,200,195,195],ground:[428,406]},
  walk: {source:'walk-revision.png',fps:10,roots:[240,237,230,215,245,243,230,215],ground:[420,395]},
  run: {source:'run-revision.png',fps:14,roots:[233,244,238,240,235,253,245,245],ground:[430,390]}
};
const blank = (w,h,bg={r:0,g:0,b:0,alpha:0}) => sharp({create:{width:w,height:h,channels:4,background:bg}});
async function main(){
  [out,game,path.join(src,'review')].forEach(p=>fs.mkdirSync(p,{recursive:true}));
  const manifest={id:'tide-picker-locomotion-v01',status:'candidate',frameSize:[512,512],pivot:[256,460],pixelsPerUnit:1,globalScale:1,facing:'right',runtimeScale:94/365,loop:true,provenance:'Built-in imagegen redraw of user reference; Blender 4.2 sequence timing master',registration:'Hand-estimated pelvis X per cell; shared ground per row. Translations only, no per-frame resizing or bottom-bound snapping.',animations:{}};
  const qa={frames:[],knownIssues:['Walk/run near-far limb identity remains ambiguous at contact; candidate, not final art approval.','Idle gesture and helmet registration need playback review.','No main-level replacement or collision/stride validation.'],checks:{}};
  const thumbLayers=[];
  let row=0;
  for(const [state,s] of Object.entries(specs)){
    const p=path.join(src,s.source),meta=await sharp(p).metadata();
    const atlas=[]; const frameInfo=[];
    for(let i=0;i<8;i++){
      const c=i%4,r=Math.floor(i/4),left=Math.round(c*meta.width/4),top=Math.round(r*meta.height/2);
      const width=Math.round((c+1)*meta.width/4)-left,height=Math.round((r+1)*meta.height/2)-top;
      const dx=256-s.roots[i],dy=460-s.ground[r];
      const crop=await sharp(p).extract({left,top,width,height}).png().toBuffer();
      const image=await blank(512,512).composite([{input:crop,left:dx,top:dy}]).png().toBuffer();
      const name=`${state}_${String(i).padStart(2,'0')}.png`;
      fs.writeFileSync(path.join(out,name),image);
      fs.writeFileSync(path.join(game,name),image);
      const raw=await sharp(image).raw().toBuffer();
      const bounds={};
      for(const threshold of [1,8,32]){
        let b=[512,512,-1,-1];for(let y=0;y<512;y++)for(let x=0;x<512;x++)if(raw[(y*512+x)*4+3]>=threshold){b[0]=Math.min(b[0],x);b[1]=Math.min(b[1],y);b[2]=Math.max(b[2],x);b[3]=Math.max(b[3],y);}
        bounds[threshold]=b;
      }
      let transparent=0;for(let j=3;j<raw.length;j+=4)if(raw[j]===0)transparent++;
      qa.frames.push({state,index:i,file:name,sha256:crypto.createHash('sha256').update(image).digest('hex'),bounds,transparentFraction:transparent/(512*512)});
      frameInfo.push({file:name,duration:1/s.fps,crop:[left,top,width,height],translation:[dx,dy],phase:i});
      atlas.push({input:image,left:c*512,top:r*512});
      thumbLayers.push({input:await sharp(image).resize(192,192).toBuffer(),left:i*192,top:row*192});
    }
    await blank(2048,1024).composite(atlas).png().toFile(path.join(out,`${state}-atlas.png`));
    manifest.animations[state]={fps:s.fps,duration:8/s.fps,frames:frameInfo,source:s.source};
    row++;
  }
  qa.checks.decodedFrameCount=qa.frames.length;
  qa.checks.uniquePngCount=new Set(qa.frames.map(f=>f.sha256)).size;
  qa.checks.allHaveTransparentBackground=qa.frames.every(f=>f.transparentFraction>0.5);
  qa.checks.visibleEdgePadding=qa.frames.every(f=>{const b=f.bounds[32];return b[0]>5&&b[1]>5&&b[2]<506&&b[3]<506;});
  if(qa.checks.decodedFrameCount!==24||qa.checks.uniquePngCount!==24||!qa.checks.allHaveTransparentBackground||!qa.checks.visibleEdgePadding)throw Error(JSON.stringify(qa.checks));
  await blank(1536,576,{r:31,g:49,b:58,alpha:1}).composite(thumbLayers).png().toFile(path.join(src,'review/contact-sheet.png'));
  await blank(1536,576,{r:221,g:226,b:224,alpha:1}).composite(thumbLayers).png().toFile(path.join(src,'review/light-contact-sheet.png'));
  fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2));
  fs.writeFileSync(path.join(game,'manifest.json'),JSON.stringify(manifest,null,2));
  fs.writeFileSync(path.join(src,'review/technical.json'),JSON.stringify(qa,null,2));
  let tres='[gd_resource type="SpriteFrames" load_steps=25 format=3]\n\n';
  let n=1;const ids={};
  for(const [state,a]of Object.entries(manifest.animations)){ids[state]=[];for(const f of a.frames){tres+=`[ext_resource type="Texture2D" path="res://assets/runtime/tide-picker-locomotion-v01/${f.file}" id="${n}"]\n`;ids[state].push(n++);}}
  tres+='\n[resource]\nanimations = [\n'+Object.entries(manifest.animations).map(([state,a])=>`{\n"frames": [${ids[state].map(id=>`{ "duration": 1.0, "texture": ExtResource("${id}") }`).join(', ')}],\n"loop": true,\n"name": &"${state}",\n"speed": ${a.fps}.0\n}`).join(',\n')+'\n]\n';
  fs.writeFileSync(path.join(game,'locomotion.tres'),tres);
  console.log(JSON.stringify(qa.checks,null,2));
}
main().catch(e=>{console.error(e);process.exit(1);});
