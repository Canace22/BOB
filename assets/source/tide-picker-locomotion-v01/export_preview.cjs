const fs=require('fs'),path=require('path');
let sharp;try{sharp=require('sharp')}catch{sharp=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp')}
async function main(){
  const dir=path.resolve(__dirname,'../../runtime/sprites/tide-picker-locomotion-v01');
  const specs=[['idle',6],['walk',10],['run',14]],images={};
  for(const [name]of specs)images[name]=await Promise.all(Array.from({length:8},(_,i)=>sharp(path.join(dir,`${name}_${String(i).padStart(2,'0')}.png`)).resize(300,300).png().toBuffer()));
  const header=Buffer.from('<svg width="900" height="360"><g font-family="Arial" font-size="18" fill="#e1c28b"><text x="30" y="30">IDLE / 6 FPS</text><text x="330" y="30">WALK / 10 FPS</text><text x="630" y="30">RUN / 14 FPS</text></g><g stroke="#547079"><path d="M20 320 H280 M320 320 H580 M620 320 H880"/></g><text x="30" y="350" font-family="Arial" font-size="12" fill="#a1b7be">FIRST PASS / in-place preview / gait refinement pending</text></svg>');
  const pages=[];
  for(let f=0;f<120;f++){
    pages.push(await sharp({create:{width:900,height:360,channels:4,background:'#172b35'}}).composite([{input:header},...specs.map(([name,fps],i)=>({input:images[name][Math.floor(f*fps/30)%8],left:i*300,top:50}))]).raw().toBuffer());
  }
  const raw=Buffer.concat(pages),options={raw:{width:900,height:360*120,channels:4,pageHeight:360}};
  await sharp(raw,options).webp({quality:82,loop:0,delay:Array(120).fill(33)}).toFile(path.join(__dirname,'review/loops.webp'));
  console.log(JSON.stringify(await sharp(path.join(__dirname,'review/loops.webp'),{animated:true}).metadata()));
}
main().catch(e=>{console.error(e);process.exit(1)});
