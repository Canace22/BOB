// Browser checks only; no game launch or player storage changes.
const { chromium } = require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path = require('node:path');
const fs = require('node:fs');
const { pathToFileURL, fileURLToPath } = require('node:url');

(async () => {
  const root = path.resolve(__dirname, '../../..');
  const file = path.join(root, 'docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html');
  const review = path.join(__dirname, 'review');
  const browser = await chromium.launch({headless:true});
  const page = await browser.newPage({viewport:{width:1440,height:1000},deviceScaleFactor:1});
  const errors=[];
  page.on('pageerror', err=>errors.push(String(err)));
  await page.goto(pathToFileURL(file).href);
  // Exercise hidden references as well, then inspect each actual image load.
  await page.locator('details').evaluateAll(ds=>ds.forEach(d=>d.open=true));
  await page.locator('img').evaluateAll(async imgs=>{
    imgs.forEach(i=>i.loading='eager');
    await Promise.all(imgs.map(i=>i.decode().catch(()=>null)));
  });
  const images=await page.locator('img').evaluateAll(imgs=>imgs.map(i=>({src:i.getAttribute('src'),ok:i.complete&&i.naturalWidth>0,width:i.naturalWidth,height:i.naturalHeight})));
  const links=await page.locator('a').evaluateAll(as=>as.map(a=>({href:a.getAttribute('href'),resolved:a.href})));
  const broken=[];
  for(const a of links){
    if(a.href.startsWith('#')){
      if(!(await page.locator(`[id="${a.href.slice(1)}"]`).count()))broken.push(a.href);
    }else if(a.resolved.startsWith('file:')&&!fs.existsSync(fileURLToPath(new URL(a.resolved))))broken.push(a.href);
  }
  const nodes=await page.locator('.graph-node').count();
  const edges=await page.locator('.graph-edge').count();
  const connectorImages=await page.locator('.seam-board img').count();
  const connectorIds=await page.locator('[data-seam]').evaluateAll(xs=>xs.map(x=>x.dataset.seam));
  await page.locator('details').evaluateAll(ds=>ds.forEach(d=>d.open=false));
  await page.locator('#labels').click();
  await page.locator('#seam-notes').click();
  const seamNotesHidden=await page.locator('#connections').evaluate(el=>el.classList.contains('hide-seam-notes'));
  await page.locator('#seam-notes').click();
  const labelHidden=await page.locator('.hero').evaluate(el=>el.classList.contains('hide'));
  await page.locator('#labels').click();
  await page.locator('.graph-node[data-room="R1-04"]').click();
  const roomJump=await page.evaluate(()=>location.hash==='#R1-04');
  await page.locator('.graph-edge[data-edge="E33"] a').click();
  const edgeJump=await page.evaluate(()=>location.hash==='#E33');
  await page.goto(pathToFileURL(file).href+'#geography');
  await page.locator('#geography img').waitFor();
  await page.locator('.hero').screenshot({path:path.join(review,'atlas-desktop.png')});
  await page.goto(pathToFileURL(file).href+'#R1-04');
  await page.locator('#R1-04 > a').screenshot({path:path.join(review,'atlas-boss.png')});
  await page.locator('nav').evaluate(el=>el.style.visibility='hidden');
  await page.locator('#E01 .seam-board').screenshot({path:path.join(review,'atlas-E01.png')});
  await page.locator('#E33 .seam-board').screenshot({path:path.join(review,'atlas-E33.png')});
  await page.locator('nav').evaluate(el=>el.style.visibility='');
  await page.setViewportSize({width:390,height:844});
  await page.goto(pathToFileURL(file).href);
  const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
  await page.screenshot({path:path.join(review,'atlas-mobile.png')});
  await page.goto(pathToFileURL(file).href+'#E35');
  await page.locator('#E35 .seam-board').screenshot({path:path.join(review,'atlas-seam-mobile.png')});
  const seamOverflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);
  const result={images,broken,errors,nodes,edges,connectorImages,connectorIds,labelHidden,seamNotesHidden,roomJump,edgeJump,mobilePageOverflow:overflow,seamMobileOverflow:seamOverflow,
    passed:images.every(i=>i.ok)&&!broken.length&&!errors.length&&nodes===7&&edges===6&&connectorImages===6&&JSON.stringify(connectorIds)===JSON.stringify(['E01','E02','E03','E04','E33','E35'])&&labelHidden&&seamNotesHidden&&roomJump&&edgeJump&&!overflow&&!seamOverflow};
  fs.writeFileSync(path.join(review,'browser-results.json'),JSON.stringify(result,null,2)+'\n');
  console.log(JSON.stringify(result,null,2));
  await browser.close();
  if(!result.passed)process.exitCode=1;
})().catch(err=>{console.error(err);process.exitCode=1});
