"""Original, deterministic offline DSP masters. No external samples or paid service."""
from pathlib import Path
import numpy as np
import wave,json,hashlib,shutil
P=Path('G:/鲸落万物生/BOB/godot/WhalebellyRuins')
OUT=P/'assets/runtime/audio'; OLD=P/'assets/source/audio-v05-original'
OLD.mkdir(parents=True,exist_ok=True)
for f in OUT.glob('*.wav'):
    if f.stem in ['jump','dash','strike','hit','hurt','slam','collect','save','sweep','heavy','heal'] and not (OLD/f.name).exists():shutil.copy2(f,OLD/f.name)
rate=44100
def noise(n,rng,low=90,high=1200):
    f=np.fft.rfftfreq(n,1/rate)
    spectrum=np.fft.rfft(rng.normal(size=n))
    curve=(1-np.exp(-(f/low)**4))*np.exp(-(f/high)**4)
    out=np.fft.irfft(spectrum*curve,n=n)
    return out/(np.std(out)+1e-9)
def fade(x,attack=.012,release=.035):
    a=min(int(rate*attack),len(x)//3); b=min(int(rate*release),len(x)//3)
    x=x.copy();x[:a]*=np.sin(np.linspace(0,np.pi/2,a))**2;x[-b:]*=np.cos(np.linspace(0,np.pi/2,b))**2
    x[0]=x[-1]=0
    return x
def write(name,x,r=rate):
    pcm=np.round(np.clip(x,-.97,.97)*32767).astype('<i2')
    target=OUT/(name+'.wav')
    with wave.open(str(target),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(r);w.writeframes(pcm.tobytes())
    return {'name':name,'duration':len(x)/r,'rms':float(np.sqrt(np.mean(x*x))),'peak':float(max(abs(x))),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
spec={
 'jump':(.24,950,'flow'),'dash':(.30,1150,'flow'),'strike':(.22,1450,'flow'),
 'sweep':(.34,1200,'flow'),'hit':(.20,1050,'impact'),'hurt':(.36,750,'impact'),
 'heavy':(.48,800,'impact'),'slam':(.55,900,'impact'),
 'collect':(.65,1250,'drop'),'save':(.90,950,'drop'),'heal':(.80,1050,'drop')}
rows=[]
for sid,(duration,cutoff,kind) in spec.items():
    for variant in range(3):
        rng=np.random.default_rng(2700+list(spec).index(sid)*13+variant)
        n=int(rate*duration);t=np.arange(n)/rate
        rustle=noise(n,rng,110,cutoff*rng.uniform(.88,1.08))
        if kind=='flow':
            env=(1-np.exp(-t/.018))*np.exp(-t/(duration*.25))
            x=rustle*env
            x+=.22*np.sin(2*np.pi*(175*t-85*t*t))*env
        elif kind=='impact':
            env=(1-np.exp(-t/.006))*np.exp(-t/(duration*.20))
            body=np.sin(2*np.pi*(rng.uniform(85,115)*t+19*(1-np.exp(-t/.055))))
            x=(.65*rustle+.5*body)*env
        else:
            x=np.zeros(n)
            for j,start in enumerate([.02,.19,.36] if sid!='collect' else [.015,.18]):
                u=np.maximum(t-start,0);freq=235+rng.uniform(-28,28)+j*35
                env=(1-np.exp(-u/.015))*np.exp(-u/.105)*(t>=start)
                x+=(np.sin(2*np.pi*(freq*u+5*(1-np.exp(-u/.06))))*.6+rustle*.18)*env
        x=fade(x)
        x*=.115/(np.sqrt(np.mean(x*x))+1e-9)
        if max(abs(x))>.64:x*=.64/max(abs(x))
        rows.append(write(sid if variant==0 else f'{sid}_{variant+1}',x))
# A 24-second periodic stochastic bed replaces the obvious 4-second sine drone.
rate=22050;n=rate*24;t=np.arange(n)/rate;rng=np.random.default_rng(7831)
bed=noise(n,rng,55,670)*(.78+.12*np.cos(2*np.pi*t/12)+.10*np.sin(2*np.pi*t/8))
bed+=.06*np.sin(2*np.pi*43*t)*(.8+.2*np.sin(2*np.pi*t/24))
bed-=np.mean(bed);bed*=.105/np.sqrt(np.mean(bed*bed))
rows.append(write('water_bed',bed,rate))
report={'origin':'Original procedural audio generated locally with NumPy FFT/envelopes; no external samples','editable_master':'work/refine_audio_v05.py','preserved_originals':str(OLD),'design':'Soft filtered water/cloth noise and low-body impacts. 3 variants per event; short click-free fades; no bright pure-tone beeps. 24s periodic noise ambience.','files':rows,'requires_human_listening':True}
(P/'docs/audio-refinement-assets.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('Generated',len(rows),'audio assets; original masters preserved.')
