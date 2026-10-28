from pathlib import Path
import json,wave,numpy as np
root=Path(__file__).resolve().parents[1]; e=root/'evidence/fixed-run'
events=json.loads((e/'prototype.json').read_text('utf-8'))['events']
with wave.open(str(e/'actual-mix.wav')) as w:
    rate=w.getframerate(); v=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
checks=[]
for item in events:
    if item['event'] not in ['jump','attack','enemy_hit','dash']:continue
    t=item['frame']/60
    segment=v[max(0,int((t-.08)*rate)):min(len(v),int((t+.35)*rate))]
    peak=float(np.max(np.abs(segment))) if len(segment) else 0
    checks.append({'event':item['event'],'physics_seconds':round(t,3),'window_peak':peak,'nonzero':peak>0.001})
report={'source':'Godot movie audio decoded from the continuous engine capture','window':'event frame/60 -0.08 to +0.35 seconds','count':len(checks),'matched':sum(c['nonzero'] for c in checks),'checks':checks,'limitation':'Confirms non-silent game mix in action windows; overlapping cues are not perceptually separated. Subjective listening not run.'}
(e/'audio-timing.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k!='checks'}))
