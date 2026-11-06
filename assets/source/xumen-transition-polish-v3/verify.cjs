const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');const {pathToFileURL}=require('node:url');
(async()=>{
 const review=path.join(__dirname,'review');fs.mkdirSync(review,{recursive:true});
 const spec=JSON.parse(fs.readFileSync(path.join(__dirname,'specs.json'),'utf8'));
 const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'art-manifest.json'),'utf8'));
 assert.equal(manifest.paintings,4);assert.equal(manifest.reusedPaintings,2);
 for(const a of manifest.images){assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,a.file))).digest('hex'),a.sha256);assert.ok(Math.abs((a.width/a.height)/(a.context[2]/a.context[3])-1)<.002);}
 const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1600,height:1100}}),errors=[];page.on('pageerror',e=>errors.push(String(e)));
 const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
 await page.goto(url+'#real-scene');await page.addStyleTag({content:'html{scroll-behavior:auto!important}'});
 const root=page.locator('#real-scene');
 const loaded=await root.locator('svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(resolve=>{const im=new Image();im.onload=()=>resolve(true);im.onerror=()=>resolve(false);im.src=x.getAttribute('href')}))));
 assert.equal(loaded.length,25);assert.ok(loaded.every(Boolean));assert.equal(await root.locator('[data-polish-edge]').count(),6);
 const core=()=>root.locator('[data-reference-room]').evaluateAll(xs=>xs.map(x=>[x.id,...['x','y','width','height','href'].map(a=>x.getAttribute(a))]));const originalCore=await core();
 await root.locator('.reference-scroll').screenshot({path:path.join(review,'全景-本轮.png')});
 await root.locator('[data-polish-compare]').click();assert.equal(await root.locator('.polished-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await root.locator('.reference-scroll').screenshot({path:path.join(review,'全景-上一版.png')});
 await root.locator('[data-polish-compare]').click();assert.notEqual(await root.locator('.polished-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await root.locator('[data-seam-compare]').click();assert.equal(await root.locator('.painted-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');assert.equal(await root.locator('.polished-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await root.locator('.reference-scroll').screenshot({path:path.join(review,'全景-最初.png')});await root.locator('[data-seam-compare]').click();assert.deepEqual(await core(),originalCore);
 const bytes=n=>crypto.createHash('sha256').update(fs.readFileSync(path.join(review,n))).digest('hex');assert.equal(new Set(['全景-本轮.png','全景-上一版.png','全景-最初.png'].map(bytes)).size,3);
 const maskStyle=await root.locator('.polished-seam-layer mask path').evaluateAll(xs=>xs.map(x=>({fill:getComputedStyle(x).fill,stroke:getComputedStyle(x).stroke})));assert.ok(maskStyle.every(x=>x.fill==='rgb(255, 255, 255)'&&x.stroke==='none'));
 const focused=[];for(const s of spec){await root.locator(`[data-seam-focus="${s.id}"]`).click();await page.waitForFunction(id=>document.querySelector('#real-scene .reference-status').textContent.startsWith(id),s.id);focused.push(s.id);}
 await page.setViewportSize({width:390,height:844});await root.locator('[data-reference-action="fit"]').click();assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));await page.screenshot({path:path.join(review,'手机.png')});
 for(const s of spec){
 await page.setViewportSize({width:1600,height:1400});await page.goto(url+'?review='+s.id+'#real-scene');
 await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
 await page.evaluate(({context})=>{const [x,y,w,h]=context;const scale=Math.min(1500/w,1300/h);const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',context.join(' '));svg.style.cssText=`width:${Math.round(w*scale)}px;height:${Math.round(h*scale)}px;background:#071923;border:0;display:block;border-radius:0`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const c of [...document.body.children])if(c!==svg)c.style.display='none';document.body.style.cssText='margin:0;overflow:hidden;background:#071923'},s);
 await page.locator('body > svg').screenshot({path:path.join(review,s.id+'-本轮.png')});
 }
 assert.equal(errors.length,0);fs.writeFileSync(path.join(review,'checks.json'),JSON.stringify({passed:true,images:loaded.length,newPaintings:4,reusedContourPasses:2,threeDistinctVersions:true,roomSourceGeometryUnchanged:true,maskStyleCorrect:true,focused,mobileOverflow:false,errors,runtimeTested:false},null,2)+'\n');await browser.close();console.log('PASS: V3 composition, 25 images, hashes, contours, 3 versions, 7 rooms preserved, 6 focus and mobile.');
})().catch(e=>{console.error(e);process.exit(1)});
