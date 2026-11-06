const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
const roomData=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../xumen-reference-panorama-v2/assembly.json'),'utf8')).rooms;
const browser=await chromium.launch({headless:true}),page=await browser.newPage();
const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
for(const r of roomData){const out=path.join(__dirname,'inputs',r.id+'-current.png');if(fs.existsSync(out))continue;const [x,y]=r.worldOrigin,[w,h]=r.intrinsicSize;await page.setViewportSize({width:w,height:h});await page.goto(url+'?challenge-input='+r.id+'#real-scene');await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(resolve=>{const im=new Image();im.onload=resolve;im.onerror=resolve;im.src=x.getAttribute('href')}))));await page.evaluate(({x,y,w,h})=>{const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',[x,y,w,h].join(' '));svg.style.cssText=`width:${w}px;height:${h}px;display:block;background:#071923;border:0;border-radius:0`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const c of [...document.body.children])if(c!==svg)c.style.display='none';document.body.style.cssText='margin:0;overflow:hidden;background:#071923'}, {x,y,w,h});await page.locator('body > svg').screenshot({path:out});}
await browser.close();console.log('Seven current room compositions captured without altering originals.');
})().catch(e=>{console.error(e);process.exit(1)});
