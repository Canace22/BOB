"""Decode/encode generated sequences and make sampled evidence; never invent missing frames."""
from pathlib import Path
import argparse,json,subprocess,hashlib
from PIL import Image,ImageDraw
import numpy as np
BASE=Path(__file__).resolve().parent
FFMPEG=Path('C:/Users/Kingsoft/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/Lib/site-packages/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe')
def run(state,revision):
    name=f'{state}_{revision}';source=BASE/'raw'/name;files=sorted(source.glob('*.png'))
    if not files:raise RuntimeError('No frames: '+name)
    out=BASE/'review';out.mkdir(exist_ok=True)
    subprocess.run([str(FFMPEG),'-hide_banner','-loglevel','error','-y','-framerate','24','-i',str(source/'%04d.png'),'-c:v','libx264','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',str(out/f'{name}.mp4')],check=True)
    sample=np.linspace(0,len(files)-1,12,dtype=int)
    sheet=Image.new('RGB',(4*352,3*380),'#142630');draw=ImageDraw.Draw(sheet)
    for k,i in enumerate(sample):
        im=Image.open(files[i]).convert('RGB').resize((352,352))
        x=k%4*352;y=k//4*380;sheet.paste(im,(x,y));draw.text((x+10,y+357),f'{state} / frame {i:03d} / {i/24:.3f}s',fill='white')
    sheet.save(out/f'{name}_contact.jpg',quality=92)
    frames=[np.asarray(Image.open(p).convert('RGB'),dtype=np.float32) for p in files]
    delta=[float(np.abs(frames[i]-frames[i-1]).mean()) for i in range(1,len(frames))]
    info={'state':state,'revision':revision,'frame_count':len(files),'fps':24,'duration':len(files)/24,'size':list(frames[0].shape[:2][::-1]),'unique_frame_hashes':len(set(hashlib.sha256(p.read_bytes()).hexdigest() for p in files)),'adjacent_mean_abs_difference':delta,'visual_review':'pending','main_game_replaced':False}
    (out/f'{name}_technical.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in info.items() if k!='adjacent_mean_abs_difference'}))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('state');p.add_argument('--revision',default='r1');a=p.parse_args();run(a.state,a.revision)
