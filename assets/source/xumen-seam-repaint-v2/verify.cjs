const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url');
(async()=>{
const review=path.join(__dirname,'review');fs.mkdirSync(review,{recursive:true});
const specs=JSON.parse(fs.readFileSync(path.join(__dirname,'specs.json'),'utf8'));
const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'art-manifest.json'),'utf8')).images;
assert.equal(manifest.length,6);
for(const a of manifest){const f=fs.readFileSync(path.join(__dirname,a.file));assert.equal(crypto.createHash('sha256').update(f).digest('hex'),a.sha256);assert.ok(Math.abs((a.width/a.height)/(a.context[2]/a.context[3])-1)<.002,'framing aspect changed: '+a.id);}
const browser=await chromium.launch({headless:true});const page=await browser.newPage({viewport:{width:1500,height:1100}});const errors=[];page.on('pageerror',e=>errors.push(String(e)));
await page.goto(pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href+'#real-scene');
await page.addStyleTag({content:'html{scroll-behavior:auto!important}'});
const scope=page.locator('#real-scene');
await scope.locator('svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise(r=>{const im=new Image();im.onload=r;im.onerror=r;im.src=x.getAttribute('href')}))));
assert.equal(await scope.locator('[data-reference-room]').count(),7);assert.equal(await scope.locator('[data-reference-edge]').count(),6);assert.equal(await scope.locator('[data-repaint-edge]').count(),6);
const gradientFills=await scope.locator('mask rect').evaluateAll(xs=>xs.map(x=>getComputedStyle(x).fill));assert.ok(gradientFills.length===12&&gradientFills.every(f=>f.startsWith('url(')),'page CSS overrides masks');
const roomGeometry=()=>scope.locator('[data-reference-room]').evaluateAll(xs=>xs.map(x=>[x.id,...['x','y','width','height','href'].map(a=>x.getAttribute(a))]));
const before=await roomGeometry();
await scope.locator('.reference-scroll').screenshot({path:path.join(review,'全景-精修.png')});
await scope.locator('[data-seam-compare]').click();assert.ok(await scope.evaluate(el=>el.classList.contains('hide-painted-seams')));
assert.equal(await scope.locator('.painted-seam-layer').evaluate(el=>getComputedStyle(el).display),'none');
await scope.locator('.reference-scroll').screenshot({path:path.join(review,'全景-原拼接.png')});
await scope.locator('[data-seam-compare]').click();assert.ok(!(await scope.evaluate(el=>el.classList.contains('hide-painted-seams'))));assert.deepEqual(await roomGeometry(),before);
assert.notEqual(crypto.createHash('sha256').update(fs.readFileSync(path.join(review,'全景-精修.png'))).digest('hex'),crypto.createHash('sha256').update(fs.readFileSync(path.join(review,'全景-原拼接.png'))).digest('hex'));
const focus=[];for(const s of specs){await scope.locator(`[data-seam-focus="${s.id}"]`).click();await page.waitForFunction(id=>document.querySelector('#real-scene .reference-status').textContent.startsWith(id),s.id);focus.push(await scope.locator('.reference-status').innerText());}
await page.setViewportSize({width:390,height:844});await scope.locator('[data-reference-action="fit"]').click();assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
await scope.locator('[data-seam-focus="E35"]').click();await page.waitForFunction(()=>document.querySelector('#real-scene .reference-status').textContent.startsWith('E35'));await page.screenshot({path:path.join(review,'手机-E35.png')});
assert.equal(errors.length,0);
fs.writeFileSync(path.join(review,'checks.json'),JSON.stringify({passed:true,paintings:manifest.length,originalRooms:7,originalEdges:6,gradientMasks:gradientFills.length,focus,sourceRoomTransformsUnchanged:true,paintingsHashed:true,aspectRatioPreserved:true,compareChangesActualImage:true,mobileOverflow:false,errors,runtimeTested:false},null,2)+'\n');
console.log('PASS: 6 repaints, 7 locked rooms, masks, hashes, aspect, real before/after, 6 focus controls, mobile and JS.');await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
