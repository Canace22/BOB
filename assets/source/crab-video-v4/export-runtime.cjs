// Deterministic crop/registration/packing only. Requires sharp; source art stays unchanged.
const fs=require('node:fs'), path=require('node:path'), sharp=require('sharp');
const root=__dirname, spec=JSON.parse(fs.readFileSync(path.join(root,'registration.json'),'utf8'));
const out=path.resolve(root,'../../runtime/sprites/crab-video-v4');
const [W,H]=spec.frameSize, [PX,PY]=spec.pivot;
(async()=>{
 fs.mkdirSync(out,{recursive:true});
 const report={frames:[],method:'one scale per sequence, shell-template root registration; raw RGBA atlas packing'};
 for(const [id,a] of Object.entries(spec.actions)){
  const atlas=Buffer.alloc(W*4*H*3*4);
  for(const [i,f] of a.frames.entries()){
   const [left,top,width,height]=f.rect;
   const art=await sharp(path.join(root,'raw',id+'.png')).extract({left,top,width,height}).resize(Math.round(width*a.scale),Math.round(height*a.scale)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   const x=Math.round(PX-f.root[0]*a.scale),y=Math.round(PY-f.root[1]*a.scale);
   if(x<8||y<8||x+art.info.width>W-8||y+art.info.height>H-8)throw Error('Clipped '+id+' '+i);
   const frame=Buffer.alloc(W*H*4);
   for(let row=0;row<art.info.height;row++) art.data.copy(frame,((y+row)*W+x)*4,row*art.info.width*4,(row+1)*art.info.width*4);
   for(let row=0;row<H;row++) frame.copy(atlas,((Math.floor(i/4)*H+row)*W*4+(i%4)*W)*4,row*W*4,(row+1)*W*4);
   report.frames.push({id,index:i,placement:[x,y,art.info.width,art.info.height],shell_match:f.shell_match});
  }
  const file=path.join(out,id+'.png');
  await sharp(atlas,{raw:{width:W*4,height:H*3,channels:4}}).png().toFile(file);
  const decoded=await sharp(file).raw().toBuffer();
  if(!decoded.equals(atlas))throw Error('Atlas RGBA mismatch: '+id);
 }
 report.count=report.frames.length;
 fs.writeFileSync(path.join(root,'validation.json'),JSON.stringify(report,null,2)+'\n');
 console.log('Exported and verified '+report.count+' registered frames');
})().catch(e=>{console.error(e);process.exitCode=1});
