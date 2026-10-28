from pathlib import Path
import subprocess,json,wave,struct,hashlib
from PIL import Image,ImageDraw
import imageio_ffmpeg
root=Path(__file__).resolve().parents[1]
e=root/'evidence/fixed-run';ff=imageio_ffmpeg.get_ffmpeg_exe();movie=e/'playthrough.mp4'
for t in [3,16,28,42,55,70,76]:
    subprocess.run([ff,'-y','-ss',str(t),'-i',str(movie),'-frames:v','1',str(e/f'view-{t:02}.png')],capture_output=True,check=True)
subprocess.run([ff,'-y','-ss','45','-t','2','-i',str(movie),'-vf','fps=6,scale=640:360',str(e/'motion-%02d.png')],capture_output=True,check=True)
frames=sorted(e.glob('motion-*.png'))
sheet=Image.new('RGB',(1920,1440),'#16313b')
for n,path in enumerate(frames[:12]):
    im=Image.open(path);sheet.paste(im,((n%3)*640,(n//3)*360))
sheet.save(e/'motion-contact.jpg')
subprocess.run([ff,'-y','-i',str(movie),'-vn','-ac','1','-ar','44100',str(e/'actual-mix.wav')],capture_output=True,check=True)
with wave.open(str(e/'actual-mix.wav')) as w:
    data=w.readframes(w.getnframes());rate=w.getframerate()
v=struct.unpack('<'+'h'*(len(data)//2),data)
report={'source':'actual Godot MovieWriter captured game audio','seconds':len(v)/rate,'peak':max(abs(x) for x in v)/32768,'rms':(sum(x*x for x in v)/len(v))**.5/32768,'nonzero_samples':sum(x!=0 for x in v),'clipped_samples':sum(abs(x)>=32767 for x in v),'subjective_listening':'not_run: model audio input unsupported; no fabricated listening verdict'}
(e/'audio-check.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report))
