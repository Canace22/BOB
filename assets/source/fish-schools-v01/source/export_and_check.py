"""Bake the authored browser animation, render previews, and inspect real outputs."""
from pathlib import Path
import base64, json, subprocess, hashlib, sys
from playwright.sync_api import sync_playwright
import imageio_ffmpeg
ROOT=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
def save_data(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(base64.b64decode(data.split(',',1)[1]))
def run():
    ffmpeg=imageio_ffmpeg.get_ffmpeg_exe()
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,args=['--allow-file-access-from-files'])
        page=browser.new_page(viewport={'width':1440,'height':1050},device_scale_factor=1)
        errors=[]
        page.on('pageerror',lambda e:errors.append(str(e)))
        page.goto((ROOT/'预览.html').as_uri())
        page.wait_for_function('window.fishReady === true')
        page.evaluate('previewControl.set(8)')
        page.screenshot(path=str(ROOT/'evidence/gallery.png'),full_page=True)
        manifest=page.evaluate('({species:FishMotion.specs,members:FishMotion.members})')
        manifest.update({'frameCount':32,'frameSize':[320,224],'atlasGrid':[8,4],'cycleSeconds':16,'singleCycleSeconds':16/12,'pivot':[160,112],'facing':'right','method':'bitmap strip-deformation baked to frames; group curves','userArtApproval':False})
        for k,s in enumerate(manifest['species']):
            name=s['id']; folder=ROOT/'runtime'/name
            for f in range(32):
                data=page.evaluate('([k,f])=>FishMotion.frames[k][f].toDataURL()',[k,f])
                save_data(folder/f'swim_{f:02d}.png',data)
            atlas=page.evaluate('k=>{let c=FishMotion.canvas(2560,896),x=c.getContext("2d");FishMotion.frames[k].forEach((im,f)=>x.drawImage(im,(f%8)*320,Math.floor(f/8)*224));return c.toDataURL();}',k)
            save_data(folder/'swim_atlas.png',atlas)
            data=page.evaluate('k=>{let c=FishMotion.canvas(1280,720);FishMotion.draw(c.getContext("2d"),k===0?8:2,k,"solo",true);return c.toDataURL();}',k)
            save_data(ROOT/'runtime'/f'{name}_school.png',data)
            subprocess.run([ffmpeg,'-y','-framerate','24','-i',str(folder/'swim_%02d.png'),'-c:v','libwebp_anim','-lossless','1','-loop','0',str(ROOT/'previews'/f'{name}_single.webp')],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,check=True)
        (ROOT/'runtime/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
        # Exercise visible pause, seek, selection and playback controls.
        page.locator('#play').click();page.wait_for_timeout(150)
        moving=page.evaluate('previewControl.state()')
        page.locator('#play').click(); held=page.evaluate('previewControl.state().t');page.wait_for_timeout(150)
        paused=page.evaluate('previewControl.state().t')
        page.locator('#selection').select_option('1')
        selected=page.evaluate('previewControl.state().group')
        checks={'pageErrors':errors,'playAdvances':moving['t']>8,'pauseHolds':held==paused,'selectionWorks':selected==1}
        # Loop endpoints and seam step compare decoded canvas values, including transparency.
        checks['seams']=page.evaluate('''()=>{let result=[];for(let k=0;k<3;k++){let c=FishMotion.canvas(1280,720),ctx=c.getContext('2d');function read(t){FishMotion.draw(ctx,t,k,'solo',true);return new Uint8Array(ctx.getImageData(0,0,1280,720).data);}let a=read(0),b=read(16),pre=read(16-1/24),post=read(1/24);function diff(a,b){let sum=0;for(let i=0;i<a.length;i++)sum+=Math.abs(a[i]-b[i]);return sum/a.length;}result.push({id:FishMotion.specs[k].id,endpoints:diff(a,b),lastToFirst:diff(pre,a),firstStep:diff(a,post)});}return result;}''')
        for k in [-1,0,1,2]:
            title='三组鱼群总览' if k<0 else manifest['species'][k]['id']+'_school'
            target=ROOT/'previews'/f'{title}.mp4'
            cmd=[ffmpeg,'-y','-f','image2pipe','-vcodec','png','-framerate','24','-i','-','-an','-c:v','libx264','-crf','19','-preset','fast','-pix_fmt','yuv420p','-movflags','+faststart',str(target)]
            with (ROOT/'evidence'/f'encode_{k}.log').open('wb') as log:
                proc=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=log)
                for f in range(384):
                    data=page.evaluate('([t,k])=>{let c=window.exportCanvas||(window.exportCanvas=FishMotion.canvas(1280,720));FishMotion.draw(c.getContext("2d"),t,k,"all");return c.toDataURL();}',[f/24,k])
                    proc.stdin.write(base64.b64decode(data.split(',',1)[1]))
                    if f in [48,192,336]:save_data(ROOT/'evidence'/f'{title}_{f:03d}.png',data)
                proc.stdin.close(); code=proc.wait();assert code==0
            print('Rendered',target.name,flush=True)
        page.evaluate('previewControl.set(8,-1,"reference")')
        page.locator('#stage').screenshot(path=str(ROOT/'evidence/reference-scale.png'))
        page.set_viewport_size({'width':390,'height':844});page.screenshot(path=str(ROOT/'evidence/mobile.png'),full_page=True)
        checks['mobileOverflow']=page.evaluate('document.documentElement.scrollWidth>innerWidth')
        (ROOT/'evidence/browser-checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
        browser.close()
        print(json.dumps(checks),flush=True)
if __name__=='__main__':run()
