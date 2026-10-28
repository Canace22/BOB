"""Archive native sources losslessly and export a short combined motion review."""
from pathlib import Path
import json,hashlib,subprocess
from PIL import Image,ImageDraw
import imageio_ffmpeg
BASE=Path(__file__).resolve().parent
RUNTIME=BASE.parents[2]/'assets/runtime/sprites/tide-picker-locomotion-v02-video'
def main():
    m=json.loads((RUNTIME/'manifest.json').read_text());sources=BASE/'native-sources';sources.mkdir(exist_ok=True)
    provenance={}
    for state,a in m['animations'].items():
        files=sorted((BASE/'raw'/a['source']).glob('*.png'));ims=[Image.open(p).convert('RGB') for p in files]
        dest=sources/f'{a["source"]}.webp'
        ims[0].save(dest,save_all=True,append_images=ims[1:],lossless=True,duration=[42 if i%3!=2 else 41 for i in range(len(ims))],loop=0,method=4)
        probe=Image.open(dest);assert probe.n_frames==81
        provenance[state]={'source':a['source'],'frames':81,'source_sha256':[hashlib.sha256(p.read_bytes()).hexdigest() for p in files],
          'lossless_archive':str(dest.relative_to(BASE)),'archive_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
          'original_preview_fps':16 if state=='run' else 24,'current_review_fps':24,'reused_historical_source':state=='run'}
        print('ARCHIVED',state,flush=True)
    (BASE/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2),encoding='utf8')
    clip=[];loaded={state:[Image.open(RUNTIME/f['file']).convert('RGBA') for f in a['frames']] for state,a in m['animations'].items()}
    for i in range(240):
        frame=Image.new('RGB',(960,400),'#10222c');draw=ImageDraw.Draw(frame)
        for j,(state,a) in enumerate(m['animations'].items()):
            n=int(i/30*a['fps'])%a['frame_count'];im=loaded[state][n].resize((320,320));frame.paste(im,(j*320,26),im)
            draw.text((j*320+20,12),f'{state.upper()}  /  {a["frame_count"]} frames',fill='#dabb7e')
            draw.line((j*320+12,312,j*320+308,312),fill='#607a80')
            draw.text((j*320+20,354),f'{n+1:03d}/{a["frame_count"]}  {a["fps"]} FPS / REVIEW CANDIDATE',fill='#adc4c9')
        clip.append(frame)
    clip[0].save(BASE/'review/combined-preview.webp',save_all=True,append_images=clip[1:],duration=[33,33,34]*80,loop=0,quality=85,method=4)
    pipe=subprocess.Popen([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-hide_banner','-loglevel','error','-f','rawvideo','-vcodec','rawvideo','-pix_fmt','rgb24','-s','960x400','-r','30','-i','-','-an','-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(BASE/'review/combined-preview.mp4')],stdin=subprocess.PIPE)
    for im in clip:pipe.stdin.write(im.tobytes())
    pipe.stdin.close();assert pipe.wait()==0
    print('REVIEW_EXPORTED')
if __name__=='__main__':main()
