"""Archive completed vendor videos and produce timestamped review frames.

No generation APIs are called here. Task submission/writeback uses Chaos CLI.
"""
from pathlib import Path
import hashlib, json, subprocess, urllib.request
import cv2
from PIL import Image, ImageDraw

BASE=Path(__file__).resolve().parent
FFMPEG=Path(r'C:\Users\Kingsoft\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe')

def main():
    brief=json.loads((BASE/'brief.json').read_text(encoding='utf-8'))
    (BASE/'review').mkdir(exist_ok=True)
    rows=[]
    for action in brief['actions']:
        key=action['id'];result=BASE/(key+'-result.json')
        if not result.exists() or not result.stat().st_size:continue
        data=json.loads(result.read_text(encoding='utf-8-sig'))['data']
        if data.get('status')!='completed':continue
        url=next(x['url'] for x in data['data'] if x['role']=='primary')
        source=BASE/(key+'-source.mp4');silent=BASE/(key+'.mp4')
        if not source.exists():urllib.request.urlretrieve(url,source)
        if not silent.exists():subprocess.run([str(FFMPEG),'-y','-i',str(source),'-c:v','copy','-an','-movflags','+faststart',str(silent),'-loglevel','error'],check=True)
        cap=cv2.VideoCapture(str(silent));fps=cap.get(cv2.CAP_PROP_FPS)
        frames=[]
        while True:
            ok,frame=cap.read()
            if not ok:break
            frames.append(frame)
        cap.release();assert frames and fps>0
        h,w=frames[0].shape[:2]
        # Include rapid attack phase and skill release/recovery; not full temporal QA.
        times=[0,.8,1.0,1.15,1.5,1.8,2.1,2.4,2.9,3.2,4.2,5.8]
        sheet=Image.new('RGB',(1200,720),'#dddddd')
        for k,t in enumerate(times):
            im=Image.fromarray(cv2.cvtColor(frames[min(len(frames)-1,round(t*fps))],cv2.COLOR_BGR2RGB))
            im.thumbnail((300,205));x=k%4*300;y=k//4*240
            sheet.paste(im,(x,y));ImageDraw.Draw(sheet).text((x+5,y+213),f'{t:.2f}s',fill='black')
        sheet.save(BASE/'review'/(key+'-contact.jpg'))
        Image.fromarray(cv2.cvtColor(frames[min(len(frames)-1,round(2.1*fps))],cv2.COLOR_BGR2RGB)).save(BASE/(key+'-poster.jpg'))
        rows.append({'id':key,'name':action['name'],'group':action['group'],'taskId':data['task_id'],'nodeId':data['node_id'],'url':url,'fps':fps,'frames':len(frames),'duration':len(frames)/fps,'size':[w,h],'file':silent.name,'source':source.name,'sha256':hashlib.sha256(silent.read_bytes()).hexdigest(),'status':'candidate','review':'decoded all frames; timestamped samples pending visual inspection','integrationStatus':'not-integrated'})
    (BASE/'technical-review.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(rows,ensure_ascii=False))

if __name__=='__main__':main()
