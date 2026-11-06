const {chromium}=require('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),{pathToFileURL}=require('node:url');
(async()=>{
 const rootGlow=process.argv.includes('--e01');
 const review=path.resolve(__dirname,rootGlow?'../xumen-root-glow-v1/review':'review');fs.mkdirSync(review,{recursive:true});
 const originX=rootGlow?1159:3343;
 const allowed=rootGlow?[[2070,330,2360,680]]:[[3605,305,3935,675],[4235,295,4575,660]];
 const browser=await chromium.launch({headless:true}),page=await browser.newPage({viewport:{width:1600,height:1100}}),errors=[];page.on('pageerror',e=>errors.push(String(e)));
 const url=pathToFileURL(path.resolve(__dirname,'../../../docs/鲸腹遗城原画集/须门遗港精修设计/原画册.html')).href;
 const load=async mode=>{await page.goto(url+'?niche-review='+mode+'#real-scene');await page.locator('#real-scene svg image').evaluateAll(xs=>Promise.all(xs.map(x=>new Promise((resolve,reject)=>{const im=new Image();im.onload=resolve;im.onerror=()=>reject(new Error(x.getAttribute('href')));im.src=x.getAttribute('href')}))));};
 await load('full');assert.equal(await page.locator('[data-ecology-detail]').count(),3);assert.equal(await page.locator('#real-scene svg image').count(),28);
 await page.locator('#real-scene .reference-scroll').screenshot({path:path.join(review,'总览.png')});
 const buffers={};for(const mode of ['after','before']){
 await load(mode);if(mode==='before')await page.locator('[data-niche-compare]').click();
 await page.setViewportSize({width:1536,height:1280});
 await page.evaluate(originX=>{const root=document.querySelector('#real-scene'),svg=root.querySelector('svg');svg.classList.toggle('hide-niches',root.classList.contains('hide-niches'));svg.setAttribute('viewBox',originX+' -220 1536 1280');svg.style.cssText='width:1536px;height:1280px;display:block;background:#071923;border:0;border-radius:0';svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const c of [...document.body.children])if(c!==svg)c.style.display='none';document.body.style.cssText='margin:0;overflow:hidden;background:#071923';},originX);
 buffers[mode]=await page.locator('body > svg').screenshot({path:path.join(review,(rootGlow?'发光珊瑚':'两处浅窝')+(mode==='after'?'-修改后.png':'-修改前.png'))});
 }
 const difference=await page.evaluate(async({a,b,originX,allowed})=>{
 const pixels=async src=>{const im=new Image();im.src=src;await im.decode();const c=document.createElement('canvas');c.width=im.width;c.height=im.height;const ctx=c.getContext('2d');ctx.drawImage(im,0,0);return ctx.getImageData(0,0,c.width,c.height).data;};
 const p=await pixels(a),q=await pixels(b);let changed=0,outside=0;const bbox=[1536,1280,0,0];
 for(let y=0;y<1280;y++)for(let x=0;x<1536;x++){const n=(y*1536+x)*4;if(Math.max(Math.abs(p[n]-q[n]),Math.abs(p[n+1]-q[n+1]),Math.abs(p[n+2]-q[n+2]))>2){changed++;bbox[0]=Math.min(bbox[0],x);bbox[1]=Math.min(bbox[1],y);bbox[2]=Math.max(bbox[2],x);bbox[3]=Math.max(bbox[3],y);const wx=x+originX,wy=y-220;const inside=allowed.some(([l,t,r,b])=>wx>=l&&wx<=r&&wy>=t&&wy<=b);if(!inside)outside++;}}
 return{changed,outside,bbox};
 },{a:'data:image/png;base64,'+buffers.after.toString('base64'),b:'data:image/png;base64,'+buffers.before.toString('base64'),originX,allowed});
 assert.ok(difference.changed>1000);assert.equal(difference.outside,0,'Pixels changed outside the two local regions');
 await load('controls');await page.locator('[data-polish-compare]').click();assert.equal(await page.locator('.polished-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await page.locator('[data-polish-compare]').click();await page.locator('[data-seam-compare]').click();assert.equal(await page.locator('.polished-seam-layer').evaluate(x=>getComputedStyle(x).display),'none');
 await page.locator('[data-niche-compare]').click();await page.locator('[data-niche-compare]').click();assert.equal(await page.locator('[data-niche-compare]').getAttribute('aria-pressed'),'true');
 await page.setViewportSize({width:390,height:844});await page.locator('[data-reference-action="fit"]').click();assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));assert.equal(errors.length,0);
 const closeup=rootGlow?[2050,330,450,390]:[3540,300,1120,430];await load('close-up');await page.setViewportSize({width:closeup[2],height:closeup[3]});
 await page.evaluate(box=>{const svg=document.querySelector('#real-scene svg');svg.setAttribute('viewBox',box.join(' '));svg.style.cssText=`width:${box[2]}px;height:${box[3]}px;display:block;background:#071923;border:0;border-radius:0`;svg.querySelector('.reference-room-notes').style.display='none';document.body.append(svg);for(const c of [...document.body.children])if(c!==svg)c.style.display='none';document.body.style.cssText='margin:0;overflow:hidden;background:#071923';},closeup);
 await page.locator('body > svg').screenshot({path:path.join(review,rootGlow?'发光珊瑚近景.png':'浅窝近景.png')});
 fs.writeFileSync(path.join(review,'checks.json'),JSON.stringify({passed:true,scope:rootGlow?'E01-glow':'E02-niches',localOverlays:rootGlow?1:2,uniqueNewPainting:1,imageReferences:28,difference,versionControls:true,mobileOverflow:false,errors,runtimeTested:false},null,2)+'\n');
 await browser.close();console.log(JSON.stringify({passed:true,difference}));
})().catch(e=>{console.error(e);process.exit(1)});
