const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true});const page=await browser.newPage({viewport:{width:1600,height:1000}});
 const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
 const specs=JSON.parse(fs.readFileSync(path.join(__dirname,'specs.json'),'utf8'));
 fs.mkdirSync(path.join(__dirname,'review'),{recursive:true});
 await page.goto(url+'#real-scene');
 await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
 await page.locator('#real-scene .reference-scroll').screenshot({path:path.join(__dirname,'review/全景-after.png')});
 for(const s of specs){
 await page.evaluate(({context})=>{const [x,y,w,h]=context;const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',[x,y,w,h].join(' '));svg.style.cssText=`width:${Math.round(w*.8)}px;height:${Math.round(h*.8)}px;display:block;border:0;border-radius:0;background:#071923`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const child of [...document.body.children])if(child!==svg)child.style.display='none';document.body.style.cssText='margin:0;background:#071923;overflow:hidden'},s);
 await page.locator('body > svg').screenshot({path:path.join(__dirname,'review',s.id+'-after.png')});
 await page.reload();await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
 }
 await browser.close();console.log('Six actual assembled crops and full view captured.');
})().catch(e=>{console.error(e);process.exit(1)});
