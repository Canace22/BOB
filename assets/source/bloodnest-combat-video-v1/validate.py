"""Decode both reference videos and verify lossless removal of provider audio."""
import hashlib, json, subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
SOURCE=Path(__file__).resolve().parent
QA=ROOT/'game/build/qa/bloodnest-combat-video-v1'
FFMPEG=Path('C:/Program Files/EVCapture/ffmpeg.exe')
FFPROBE=FFMPEG.with_name('ffprobe.exe')
def run(args):
    return subprocess.run([str(x) for x in args],capture_output=True,text=True,encoding='utf-8',errors='replace',check=True)
def stream_hash(path):
    return run([FFMPEG,'-v','error','-i',path,'-map','0:v:0','-c','copy','-f','hash','-hash','sha256','-']).stdout.strip()

execution=json.loads((SOURCE/'execution.json').read_text(encoding='utf-8'))
report=[]
for clip in execution['clips']:
    key=clip['id']
    original=SOURCE/f'videos/{key}-wan-v1-original.mp4'
    silent=SOURCE/f'videos/{key}-wan-v1.mp4'
    probe=json.loads(run([FFPROBE,'-v','error','-show_entries','format=duration:stream=codec_type,width,height,r_frame_rate,nb_frames','-of','json',silent]).stdout)
    assert len(probe['streams'])==1 and probe['streams'][0]['codec_type']=='video'
    video=probe['streams'][0]
    assert (video['width'],video['height'])==(1280,720)
    assert video['r_frame_rate']=='30/1' and int(video['nb_frames'])==300
    assert abs(float(probe['format']['duration'])-10)<0.01
    decoded=run([FFMPEG,'-v','error','-i',silent,'-f','null','-'])
    assert not decoded.stderr.strip(),decoded.stderr
    original_hash=stream_hash(original)
    silent_hash=stream_hash(silent)
    assert original_hash==silent_hash,'Video bitstream changed while removing audio'
    result=json.loads((QA/f'{key}-wan-result.json').read_text(encoding='utf-8-sig'))['data']
    assert result['status']=='completed'
    primary=next(item for item in result['data'] if item.get('role')=='primary')
    clip.update(status='completed',review='candidate_with_deviations',
        original_file=str(original.relative_to(ROOT)).replace('\\','/'),
        silent_file=str(silent.relative_to(ROOT)).replace('\\','/'),
        output_url=primary['url'],sha256=hashlib.sha256(silent.read_bytes()).hexdigest())
    report.append({'clip':key,'duration':10,'size':[1280,720],'fps':30,'frames':300,
      'audio_streams':0,'full_decode':'pass','video_bitstream_preserved':True,'video_stream_hash':silent_hash,
      'visual_review':clip['review']})
execution['clips'][0]['review_notes']='原画风格、双向群游与水丝可作参考；未精确还原既有AI的每段时间，不能直接作游戏动作。'
execution['clips'][1]['review_notes']='原画人物仍出现；约5秒后镜头跟随／场景变化；受击波纹偏大，局部破群／补位不够清楚。未通过固定镜头与局部反馈验收。'
(SOURCE/'execution.json').write_text(json.dumps(execution,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
(SOURCE/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
