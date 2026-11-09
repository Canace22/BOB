// Frozen actual V2 composition inputs. Existing files are never recaptured.
const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
const specs=[
 {id:'E33',name:'上层骨壁与须筛洞顶',context:[1640,-1530,2304,2304],kind:'new-paint',paths:['M 2305 -510 Q 3000 -535 3750 -510 L 3790 -20 Q 3070 40 2270 15 Z']},
 {id:'E35',name:'记忆袋下壁与舌台穹顶',context:[3300,-1530,2560,2560],kind:'new-paint',paths:['M 4030 -585 Q 4850 -580 5630 -545 L 5650 175 Q 4830 90 4010 175 Z']},
 {id:'E01',name:'外伤坡与上行壁根部',context:[1159,-220,1536,1280],kind:'new-paint',paths:['M 1460 -90 Q 1900 -160 2390 -80 L 2400 940 Q 1950 1050 1460 960 Z']},
 {id:'E02',name:'须筛高低双层接口',context:[3343,-220,1536,1280],kind:'new-paint',paths:['M 3640 -90 Q 4090 -160 4570 -80 L 4580 1010 Q 4090 1110 3640 990 Z']},
 {id:'E03',name:'蟹场前骨拱轮廓',context:[5527,-180,1536,1280],kind:'reuse-paint',file:'../xumen-seam-repaint-v2/images/E03.png',paths:['M 5850 110 Q 6220 80 6580 90 Q 6670 180 6710 250 L 6750 1000 Q 6280 1110 5850 1010 Z']},
 {id:'E04',name:'育窝膜拱与前景轮廓',context:[7630,-100,1536,1408],kind:'reuse-paint',file:'../xumen-seam-repaint-v2/images/E04.png',paths:['M 7950 125 Q 8380 90 8820 260 L 8840 1120 Q 8370 1170 7940 1040 Z']}
];
(async()=>{
for(const dir of ['inputs','images','review'])fs.mkdirSync(path.join(__dirname,dir),{recursive:true});
fs.writeFileSync(path.join(__dirname,'specs.json'),JSON.stringify(specs,null,2)+'\n');
const browser=await chromium.launch({headless:true}),page=await browser.newPage();
const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
for(const s of specs.filter(s=>s.kind==='new-paint')){
const out=path.join(__dirname,'inputs',s.id+'-v2.png');if(fs.existsSync(out))continue;
const [x,y,w,h]=s.context;await page.setViewportSize({width:w,height:h});await page.goto(url+'?capture='+s.id+'#real-scene');await page.locator('#real-scene svg').waitFor();
await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
await page.evaluate(({x,y,w,h})=>{const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',[x,y,w,h].join(' '));svg.style.cssText=`width:${w}px;height:${h}px;display:block;border:0;border-radius:0;background:#071923`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const child of [...document.body.children])if(child!==svg)child.style.display='none';document.body.style.cssText='margin:0;background:#071923;overflow:hidden';},{x,y,w,h});
await page.locator('body > svg').screenshot({path:out});
}
await browser.close();console.log('Four frozen V2 edit targets captured.');
})().catch(e=>{console.error(e);process.exit(1)});
