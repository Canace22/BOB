const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),{pathToFileURL}=require('node:url');
const crypto=require('node:crypto');
(async()=>{
 const review=path.join(__dirname,'review');fs.mkdirSync(review,{recursive:true});
 const design=JSON.parse(fs.readFileSync(path.join(__dirname,'design.json'),'utf8'));
 const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'art-manifest.json'),'utf8'));
 const inputs=JSON.parse(fs.readFileSync(path.join(__dirname,'input-manifest.json'),'utf8'));
 assert.equal(manifest.images.length,8);
 for(const a of [...manifest.images,...inputs])assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,a.file))).digest('hex'),a.sha256);
 const layout=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../xumen-reference-panorama-v2/assembly.json'),'utf8')).rooms;
 const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
 const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1800,height:1200}}),errors=[];page.on('pageerror',e=>errors.push(String(e)));
 async function load(){await page.goto(url+'?challenge-review='+Date.now()+'#real-scene');await page.addStyleTag({content:'html{scroll-behavior:auto!important}'});const loaded=await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(resolve=>{const im=new Image();im.onload=()=>resolve(true);im.onerror=()=>resolve(false);im.src=x.getAttribute('href')}))));assert.equal(loaded.length,35);assert.ok(loaded.every(Boolean));}
 await load();const root=page.locator('#real-scene');assert.equal(await root.locator('[data-reference-room]').count(),7);assert.equal(await root.locator('[data-reference-edge]').count(),6);assert.equal(await root.locator('[data-challenge-room]').count(),7);assert.equal(await root.locator('[data-planned-fly]').count(),8);
 await page.locator('nav').evaluate(x=>x.style.visibility='hidden');await root.locator('.reference-scroll').screenshot({path:path.join(review,'七房进阶-总览.png')});
 await root.locator('[data-challenge-toggle]').click();assert.equal(await root.locator('.challenge-layer').evaluate(x=>getComputedStyle(x).display),'none');await root.locator('.reference-scroll').screenshot({path:path.join(review,'原地形-对照.png')});await root.locator('[data-challenge-toggle]').click();assert.notEqual(await root.locator('.challenge-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await root.locator('[data-challenge-guide]').click();assert.notEqual(await root.locator('.challenge-route-guide').evaluate(x=>getComputedStyle(x).display),'none');
 await root.locator('.reference-focus-tools [data-reference-focus="R1-02"]').click();await page.waitForFunction(()=>document.querySelector('.reference-status').textContent.includes('R1-02'));
 await root.locator('.reference-scroll').screenshot({path:path.join(review,'须筛-候选路线.png')});
 await root.locator('[data-challenge-guide]').click();
 await root.locator('[data-polish-compare]').click();await page.waitForFunction(()=>document.querySelector('[data-challenge-toggle]').getAttribute('aria-pressed')==='false');
 await root.locator('[data-challenge-toggle]').click();assert.equal(await root.locator('[data-polish-compare]').getAttribute('aria-pressed'),'true');assert.equal(await root.locator('[data-challenge-toggle]').getAttribute('aria-pressed'),'true');
 for(const r of design.rooms){await root.locator(`.reference-focus-tools [data-reference-focus="${r.id}"]`).click();await page.waitForFunction(id=>document.querySelector('#real-scene .reference-status').textContent.includes(id),r.id);}
 const imgs=await page.locator('.challenge-details img').evaluateAll(xs=>Promise.all(xs.map(async im=>{im.loading='eager';try{await im.decode();return im.naturalWidth>0}catch{return false}})));assert.equal(imgs.length,8);assert.ok(imgs.every(Boolean));
 await page.setViewportSize({width:390,height:844});await page.reload();assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 for(const r of layout){await page.setViewportSize({width:r.intrinsicSize[0],height:r.intrinsicSize[1]});await load();await page.evaluate(r=>{const [x,y]=r.worldOrigin,[w,h]=r.intrinsicSize,svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',[x,y,w,h].join(' '));svg.style.cssText=`width:${w}px;height:${h}px;display:block;background:#071923;border:0;border-radius:0`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const c of [...document.body.children])if(c!==svg)c.style.display='none';document.body.style.cssText='margin:0;overflow:hidden;background:#071923'},r);await page.locator('body > svg').screenshot({path:path.join(review,r.id+'-组合.png')});}
 assert.equal(errors.length,0);const report={passed:true,rooms:7,edges:6,svgImagesLoaded:35,challengePaintings:7,enemyConcepts:1,plannedFlyInstances:8,versionToggle:true,routeGuideToggle:true,sevenRoomFocus:true,mobileOverflow:false,errors,runtimeTested:false};fs.writeFileSync(path.join(review,'checks.json'),JSON.stringify(report,null,2)+'\n');await browser.close();console.log(JSON.stringify(report));
})().catch(e=>{console.error(e);process.exit(1)});
