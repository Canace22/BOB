from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1];P=ROOT/'godot/WhalebellyRuins'
BASE=ROOT/'assets/source/baleen-wan22'
def write(p,s):p.write_text(s.rstrip()+'\n',encoding='utf-8',newline='\n')
def run():
    jobs=json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    for j in jobs:
        assert j['unique_frames']==j['frames'] and j['root_changed_pixels']==0
        write(P/f'scenes/environment/elements/{j["id"]}.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scenes/environment/elements/baleen_frames.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/baleen_wan22/{j['id']}.png" id="2"]
[node name="{j['id']}" type="Sprite2D"]
texture = ExtResource("2")
centered = false
hframes = {j['columns']}
vframes = {j['rows']}
script = ExtResource("1")
playback_fps = 12.0
frame_count = {j['frames']}
period = {j['duration']}
''')
    path=P/'scenes/environment/xumen_reference.tscn';t=path.read_text(encoding='utf-8').replace('metadata/motion = "blender_frames"','metadata/motion = "wan22_video_derived_frames"');write(path,t)
    path=ROOT/'assets/source/xumen-motion-elements/elements.json';items=json.loads(path.read_text(encoding='utf-8'))
    byid={j['id']:j for j in jobs}
    for item in items:
        if item['id'] in byid:
            j=byid[item['id']];item.update(asset=f'res://assets/baleen_wan22/{j["id"]}.png',motion='Wan2.2 video-derived 36 RGBA frames / 12 FPS / 3 seconds',source=f'baleen-wan22/krita/{j["id"]}.kra',parameters={k:j[k] for k in ['frames','fps','duration','rect','z']})
    write(path,json.dumps(items,ensure_ascii=False,indent=2))
    path=ROOT/'assets/source/xumen-motion-elements/master/scene-layout.json';items=json.loads(path.read_text(encoding='utf-8'))
    for item in items:
        if item['id'] in byid:item['kind']='wan22_video_derived_frames'
    write(path,json.dumps(items,ensure_ascii=False,indent=2))
    path=ROOT/'assets/source/xumen-motion-elements/master/editable-layout.svg';t=path.read_text(encoding='utf-8')
    for j in jobs:t=t.replace(f'../../baleen-blender/frames/{j["id"]}/000.png',f'../../baleen-wan22/frames/{j["id"]}/0000.png')
    write(path,t.replace('Blender frame 000;', 'Wan derived frame 0000;'))
    print('Integrated four Wan-derived groups, 144 frames total.')
if __name__=='__main__':run()
