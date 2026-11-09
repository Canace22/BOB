// Capture the actual atlas composition as image-edit inputs, without repainting room pixels.
const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
const specs=[
 {id:'E01',name:'外伤坡到须筛',context:[1159,-220,1536,1280],patch:[1451,-120,952,1150],pair:['R1-01','R1-02']},
 {id:'E02',name:'须筛到舌台',context:[3343,-220,1536,1280],patch:[3635,-120,952,1280],pair:['R1-02','R1-03']},
 {id:'E03',name:'舌台到蟹场',context:[5527,-180,1536,1280],patch:[5819,-60,952,1200],pair:['R1-03','R1-04']},
 {id:'E04',name:'蟹场到育窝',context:[7630,-100,1536,1408],patch:[7922,0,952,1250],pair:['R1-04','R1-05']},
 {id:'E33',name:'须筛到喷气孔上层',context:[1600,-1420,1152,2112],patch:[1760,-1280,740,1830],pair:['R1-02','R1-06']},
 {id:'E35',name:'须筛到记忆袋',context:[3380,-1420,1152,2112],patch:[3540,-1420,970,2000],pair:['R1-02','R1-07']}
];
(async()=>{
fs.mkdirSync(path.join(__dirname,'inputs'),{recursive:true});fs.mkdirSync(path.join(__dirname,'images'),{recursive:true});fs.mkdirSync(path.join(__dirname,'review'),{recursive:true});
fs.writeFileSync(path.join(__dirname,'specs.json'),JSON.stringify(specs,null,2)+'\n');
const browser=await chromium.launch({headless:true});
const page=await browser.newPage();await page.goto(pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href);
await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
for(const s of specs){
if(fs.existsSync(path.join(__dirname,'inputs',s.id+'-before.png')))continue;
const [x,y,w,h]=s.context;await page.setViewportSize({width:w,height:h});
await page.evaluate(({x,y,w,h})=>{const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',[x,y,w,h].join(' '));svg.style.cssText=`width:${w}px;height:${h}px;display:block;border:0;border-radius:0;background:#071923`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const child of [...document.body.children])if(child!==svg)child.style.display='none';document.body.style.cssText='margin:0;background:#071923;overflow:hidden';},{x,y,w,h});
await page.locator('body > svg').screenshot({path:path.join(__dirname,'inputs',s.id+'-before.png')});
// Put the SVG back under the section before reading it for the next capture.
await page.reload();await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
}
await browser.close();console.log('Captured six contextual edit targets.');
})().catch(e=>{console.error(e);process.exit(1)});
