"""把已认可白盒文字/事件映射到现有19房；不生成地形、不改正式房间。"""
from pathlib import Path
import copy
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game/content/narrative/campaign_story.json'
SOURCE = ROOT / 'game/content/prototypes/chapters'


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))


def rooms():
    raw = read('game/art/whalebelly/rooms.json')
    base = raw if isinstance(raw, list) else raw['rooms']
    replacements = {r['id']: r for r in read('game/content/whalebelly/layout/rooms.json')['rooms']}
    return {r['id']: r for r in [replacements.get(r['id'], r) for r in base] + read('game/content/whalebelly/world/rooms.json')['rooms']}


ROOMS = rooms()


def spot(room, surface, x):
    """只沿已存在的surface线段插值，数据保留支撑索引供真实碰撞复核。"""
    points = ROOMS[room]['surfaces'][surface]
    assert points[0][0] <= x <= points[-1][0], (room, surface, x)
    for left, right in zip(points, points[1:]):
        if left[0] <= x <= right[0]:
            t = (x-left[0]) / max(.00001, right[0]-left[0])
            return [round(x, 3), round(left[1]+(right[1]-left[1])*t, 3)]
    raise AssertionError((room, surface, x))


def position(room, surface, x):
    return {'room_id': room, 'at': spot(room, surface, x), 'support': {'room_id': room, 'surface': surface, 'x': x}}


# stage/task ID是唯一绑定键，不能依靠对白中的文字、任务排序或白盒坐标判定进度。
BIND = {}

def bind(room, surface, entries):
    for key, x in entries.items(): BIND[key] = position(room, surface, x)


bind('R2-01', 1, {'ch04_01_arrival':350,'ch04_02_survey':450,'ch04_supply_rubbing':370,'ch04_safe_flow':480})
bind('R2-01', 2, {'ch04_exposed_flow':950,'ch04_03_agreement':1050,'ch04_04_limited_flow':960,'ch04_lift_homes':880,'ch04_open_slit':1030})
bind('R2-01', 3, {'ch04_05_tides':1350,'ch04_06_keep_limit':1450,'ch04_reduce_opening':1400,'ch04_take_record':1530})
bind('R2-01', 4, {'ch04_07_exit':2160})
bind('R2-03', 1, {'ch05_01_find_family':430,'ch05_02_prepare_refuge':500,'ch05_inspect_attached':400,'ch05_move_residents':570})
bind('R2-03', 4, {'ch05_03_eel':1790,'ch05_04_after_battle':2220,'ch05_05_carry_base':2180,'ch05_lift_whole_base':2220,'ch05_keep_mooring':1880,'ch05_handover_base':2310,'ch05_06_exit':2320})
bind('R2-04', 0, {'ch06_01_patrol':380,'ch06_02_outside':700,'ch06_sheltered_view':720,'ch06_compare_marks':1100,'ch06_03_place_samples':1400,'ch06_place_fast':1300,'ch06_place_shelter':1560,'ch06_place_control':1820,'ch06_04_tides':2050,'ch06_05_mark_limits':2150,'ch06_compare_samples':2150,'ch06_protect_membrane_a':2400,'ch06_protect_membrane_b':2630,'ch06_clear_slow_inlet':2790,'ch06_06_echo':2500,'ch06_07_exit':80})
bind('R2-04', 2, {'ch06_exposed_view':1480})
bind('R4-01', 1, {'ch07_evidence':460,'ch07_compare_samples':400})
bind('R4-01', 2, {'ch07_read_decline':950})
bind('R4-01', 0, {'ch07_dispute':1200,'ch07_make_copy':1450,'ch07_copy_records':1450,'ch07_blocked':1710,'ch07_leave_pump':1730,'ch07_called_off':950})
bind('R4-01', 4, {'ch07_exit':2320})
bind('R4-03', 1, {'ch08_arrival':410})
bind('R4-03', 2, {'ch08_check_support':850,'ch08_show_base':850,'ch08_show_water':1100})
bind('R4-03', 0, {'ch08_refusal':1240,'ch08_beam_fight':1500,'ch08_no_reply':1900})
bind('R4-03', 4, {'ch08_receive_nests':2390,'ch08_restore_rope':2350,'ch08_bring_nests':2650,'ch08_note_name':2490,'ch08_exit':2800})
bind('R4-05', 0, {'ch09_find_routes':450,'ch09_read_map':400,'ch09_ask_carriers':680,'ch09_clear_outer':950,'ch09_clear_rope':1460,'ch09_check_outcomes':1980,'ch09_stable_bed':1980,'ch09_failed_nest':2290,'ch09_seal_opening':2500,'ch09_move_inside':2700,'ch09_record_old_loss':2160,'ch09_compare_return':2890,'ch09_trace_return':2890,'ch09_receive_name_shell':3000,'ch09_exit':3120})
bind('R4-06', 1, {'ch10_find_archive':500,'ch10_read_archive':500})
bind('R4-06', 2, {'ch10_place_shell':1030,'ch10_set_shell':1030,'ch10_take_shell':1030})
bind('R4-06', 3, {'ch10_whale_memory':1700,'ch10_leave_record':1850,'ch10_copy_names':1850})
bind('R4-06', 4, {'ch10_departure':2440,'ch10_exit':2640})
bind('R5-01', 2, {'ch11_check_contacts':960,'ch11_contact_lung':960})
bind('R5-02', 2, {'ch11_contact_pump':1040})
bind('R5-04', 0, {'ch11_contact_tail':1000,'ch11_listen_pause':1000})
bind('R5-04', 0, {'ch11_match_return':1600,'ch11_compare_return':1500,'ch11_compare_supply':1740})
bind('R5-04', 0, {'ch11_mark_plan':2300,'ch11_protect_nests':2200,'ch11_mark_narrow_outlet':2400,'ch11_reply_and_pack':2700})
bind('R5-04', 0, {'ch11_exit':80})
bind('R5-08', 0, {'ch12_return_name':480,'ch12_dispute_patch':950,'ch12_elder_duel':1280,'ch12_rescue_and_brace':2210,'ch12_move_elder_safe':2210,'ch12_shift_narrow_cover':2410,'ch12_set_old_anchor':2600,'ch12_limited_outflow':2410,'ch12_recovery_life':2850,'ch12_exit':3070})

ENEMIES = {
    'ch04_02_survey': ('R2-01',0,1100,[850,1664,650]),
    'ch05_03_eel': ('R2-03',4,2090,[1720,1160,620]),
    'ch06_02_outside': ('R2-04',2,1540,[1300,960,340]),
    'ch07_leave_pump': ('R4-01',0,2060,[900,1424,1350]),
    'ch08_beam_fight': ('R4-03',0,1850,[1190,1584,1020]),
    'ch09_clear_outer': ('R4-05',0,1210,[850,1440,650]),
    'ch09_clear_rope': ('R4-05',0,1730,[1370,1440,650]),
    'ch12_elder_duel': ('R5-08',0,1650,[1020,1280,1180]),
}

ROUTES = {
 1:['R1-01','R1-02','R1-03','R1-04'],2:['R1-04','R1-05','R3-01'],3:['R3-01','R2-01'],
 4:['R2-01','R2-03'],5:['R2-03','R2-04'],6:['R2-04','R2-03','R2-01','R3-01','R4-01'],
 7:['R4-01','R4-03'],8:['R4-03','R4-05'],9:['R4-05','R4-06'],10:['R4-06','R5-01'],
 11:['R5-04','R5-02','R5-01','R4-06','R5-08'],12:['R5-08']}
IDS = {1:'ch01_xuting',2:'ch02_zhejing',3:'ch03_weishi',4:'ch04_zhiku',5:'ch05_huanju',6:'ch06_feiyuan',7:'ch07_bengting',8:'ch08_gongqiong',9:'ch09_huiliu',10:'ch10_jiuge',11:'ch11_huisheng',12:'ch12_zhazha'}
ACTORS = {'补巢者':('nest_mender',104),'脂库看守':('fat_store_keeper',120),'环居看守':('ring_keeper',74),'肺缘看守':('lung_keeper',120),'负壳守卫':('shell_guard',100),'负壳守卫（上层）':('shell_guard',100),'老守护者':('elder_guardian',135),'泵庭执卫':('pump_warden',108),'封梁卫':('beam_guard',102),'住户':('resident_settled',88),'住巢居民':('resident_settled',88),'迁居居民':('resident_migrant',102),'留居居民':('resident_settled',88),'搬运居民':('resident_carrier',65)}


def annotate(stage):
    source = copy.deepcopy(stage)
    stage.update(copy.deepcopy(BIND[stage['id']]))
    stage['source_at'] = source.get('at',[])
    stage['checkpoint'] = stage['at'][:]
    stage['radius'] = 155 if stage['kind']=='dialogue' else 115
    for task in stage.get('tasks',[]):
        task['source_at'] = task['at'][:]
        task.update(copy.deepcopy(BIND[task['id']]))
        task['radius'] = 100
    if 'actor_at' in stage: stage['source_actor_at']=stage.pop('actor_at')
    if stage['id'] in ENEMIES:
        room,surface,x,arena=ENEMIES[stage['id']]
        enemy=stage['enemy'];enemy['source_at']=enemy['at'];enemy['source_lane']=enemy.get('lane',[])
        enemy.update(position(room,surface,x));enemy['lane']=[arena[0],arena[0]+arena[2]];enemy['arena']=[arena[0],arena[1]-520,arena[2],520]
        enemy['floor_y']=enemy['at'][1]
        if enemy['profile']==3:
            enemy['shelter']=[480,1520];enemy['shelter_radius']=170
    if 'goal' in stage:
        stage['source_goal']=stage['goal'];stage['goal']=spot('R4-01',0,950);stage['goal_radius']=110
    add_actors(stage)
    return stage


def add_actors(stage):
    speakers=[]
    for line in stage.get('lines',[]):speakers.append(line[0])
    for task in stage.get('tasks',[]):
        for line in task.get('lines',[]):speakers.append(line[0])
    identities=[]
    for speaker in speakers:
        if speaker in ACTORS and ACTORS[speaker][0] not in [i[0] for i in identities]:identities.append(ACTORS[speaker])
    actors=[]
    room=stage['room_id'];surface=stage['support']['surface'];points=ROOMS[room]['surfaces'][surface]
    for index,(identity,height) in enumerate(identities):
        x=max(points[0][0]+40,min(points[-1][0]-40,stage['at'][0]+(-1 if index%2==0 else 1)*(90+int(index/2)*125)))
        actors.append({'id':identity,'key':identity,'height':height,**position(room,surface,x)})
    stage['actors']=actors
    extras = {
      'ch02_arrival':[('shell_guard',100,position('R1-04',3,1750))],
      'loop.arrival':[('nest_mender',104,position('R1-01',0,320))],
      'ch02_rescue':[('resident_settled',88,position('R1-05',0,150)),('resident_migrant',90,position('R1-05',0,260))],
      'ch03_flood':[('nest_mender',104,position('R3-01',2,1350)),('resident_settled',88,position('R3-01',2,1500))],
      'ch08_no_reply':[('shell_guard',100,position('R4-03',0,2040)),('nest_mender',104,position('R4-03',0,1700))],
      'ch12_recovery_life':[('nest_mender',104,position('R5-08',0,2740)),('shell_guard',100,position('R5-08',0,2510)),('elder_guardian',135,position('R5-08',0,2960)),('resident_settled',88,position('R5-08',0,3100))],
      'ch12_exit':[('nest_mender',104,position('R5-08',0,2740)),('shell_guard',100,position('R5-08',0,2510)),('elder_guardian',135,position('R5-08',0,2960))],
    }
    for identity,height,anchor in extras.get(stage['id'],[]):
        if identity not in [a['id'] for a in actors]:actors.append({'id':identity,'key':identity,'height':height,**anchor})
    # 折井下层平台狭小，住户与守卫分居实际相邻台面，不能把三名演员挤在同一脚点。
    if stage['id']=='ch02_permit':
        stage['actors']=[
          {'id':'elder_guardian','key':'elder_guardian','height':135,**position('R1-05',1,600)},
          {'id':'resident_settled','key':'resident_settled','height':88,**position('R1-05',0,230)},
          {'id':'shell_guard','key':'shell_guard','height':100,**position('R1-05',2,965)},
        ]


def lines_dictionary(path):
    text=(ROOT/path).read_text(encoding='utf-8')
    result={}
    for match in re.finditer(r'^\s*"([^"\n]+)":\s*\[',text,re.M):
        start=match.end()-1;depth=0;quoted=False;escaped=False
        for index in range(start,len(text)):
            char=text[index]
            if quoted:
                if escaped:escaped=False
                elif char=='\\':escaped=True
                elif char=='"':quoted=False
            elif char=='"':quoted=True
            elif char=='[':depth+=1
            elif char==']':
                depth-=1
                if depth==0:
                    result[match[1]]=json.loads(text[start:index+1]);break
    return result


def simple_stage(key, kind, room, surface, x, objective, lines=None, **kwargs):
    item={'id':key,'kind':kind,'objective':objective,'radius':155 if kind=='dialogue' else 115,'checkpoint':spot(room,surface,x),**position(room,surface,x)}
    if lines:item['lines']=lines
    item.update(kwargs);add_actors(item);return item


def first_chapters():
    scene=(ROOT/'game/content/whalebelly/narrative/chapter_loop.tscn').read_text(encoding='utf-8')
    first={}
    for block in re.split(r'(?=\[node )',scene):
        idm=re.search(r'dialogue_id = "([^"]+)"',block)
        if not idm:continue
        speakers=json.loads('['+re.search(r'speakers = PackedStringArray\(([^\n]*)\)',block)[1]+']')
        lines=json.loads('['+re.search(r'lines = PackedStringArray\(([^\n]*)\)',block)[1]+']')
        first[idm[1]]=list(map(list,zip(speakers,lines)))
    # 正式下台仅容纳单体护食甲，精确修正本句数量与扑击方向，其他对白复用。
    first['loop.warning'][0][1] = first['loop.warning'][0][1].replace('前面两只食腐甲', '前面那只食腐甲').replace('它们会以为你来抢食，从两边一起扑过来', '它会以为你来抢食，迎面扑过来')
    first['loop.warning'][2][1] = first['loop.warning'][2][1].replace('它们', '它')
    first['loop.aftermath'][0][1] = first['loop.aftermath'][0][1].replace('它们', '它')
    two=lines_dictionary('game/src/prototypes/chapter_two/dialogue.gd')
    three=lines_dictionary('game/src/prototypes/chapter_three/dialogue.gd')
    two['complete']=[line for line in two['complete'] if line[0]!='白盒验证结束']
    stages=[
      simple_stage('loop.arrival','dialogue','R1-01',0,230,'沿骨路接近前方补巢者',first['loop.arrival']),
      simple_stage('loop.warning','dialogue','R1-01',0,320,'先询问补巢者，辨认聚食区的危险',first['loop.warning']),
      simple_stage('loop.passage','battle','R1-01',5,650,'到下方宽骨台压退护食甲，再沿骨台向出口前进',enemy={'profile':0,'at':spot('R1-01',5,860),'room_id':'R1-01','lane':[400,1000],'arena':[380,430,650,520],'floor_y':950,'ending':'retreat','hp':10}),
      simple_stage('loop.aftermath','dialogue','R1-01',4,1475,'到出口菌灯旁，向补巢者询问下层入口',first['loop.aftermath'],reward_abilities=['dash']),
      simple_stage('ch01_sifting_route','explore','R1-02',4,1490,'沿须筛的真实台阶前进，到右侧通道前查看标记',tasks=[{'id':'ch01_route_seen','label':'F 查看下行路线标记','at':spot('R1-02',4,1490),'room_id':'R1-02','requires':[],'grant':[],'lines':[],'support':{'room_id':'R1-02','surface':4,'x':1490}}],required=['ch01_route_seen'],reward_abilities=['float']),
      simple_stage('ch01_foldwell_entry','exit','R1-03',8,1500,'沿舌台上方的通路向右进入折井上沿')]
    # explore task插入后补齐演员信息，不生成地图或对白占位。
    c1={'id':1,'chapter_id':IDS[1],'title':'须庭里的低鸣','room_id':'R1-01','stages':stages,'next':2}
    stages=[
      simple_stage('ch02_arrival','dialogue','R1-04',0,330,'到折井上沿，询问正在封路的守卫',two['arrival']),
      simple_stage('ch02_refusal','dialogue','R1-04',2,970,'接近警戒线，听清守卫封路的原因',two['refusal']),
      simple_stage('ch02_guard_conflict','battle','R1-04',3,1310,'守卫已举壳警告；读招、绕侧反击，解除封锁',enemy={'profile':2,'at':spot('R1-04',3,1750),'room_id':'R1-04','lane':[1130,2300],'arena':[1120,280,1220,520],'floor_y':800,'ending':'surrender','hp':18}),
      simple_stage('ch02_aftermath','dialogue','R1-04',3,1950,'先停手，查看守卫仍在保护的下层住户',two['aftermath']),
      simple_stage('ch02_rescue','observe','R1-05',0,280,'到折井下层观察住户撤离，F可结束这一段演出',duration=8,captions=['守卫已停止交锋。住户沿断口内侧的支撑，一户接一户撤到安全平台。','老守护者带人接住最后一户住巢，催还留在断口上的住户往内侧走。'],grant=['ch02_rescue_done']),
      simple_stage('ch02_permit','dialogue','R1-05',1,545,'居民撤离结束后，与老守护者交谈',two['permit'],reward_abilities=['fissure']),
      simple_stage('ch02_complete','dialogue','R1-05',3,1220,'跟随撤出的住户，前往胃室',two['complete']),
      simple_stage('ch02_exit','exit','R1-05',4,1510,'沿右侧已有通路前往胃室')]
    c2={'id':2,'chapter_id':IDS[2],'title':'折井的封路旧壳','room_id':'R1-04','stages':stages,'next':3}
    stages=[
      simple_stage('ch03_arrival','dialogue','R3-01',2,1050,'进入胃室，跟住户找补巢者',three['arrival']),
      simple_stage('ch03_meet','dialogue','R3-01',2,1350,'到菌床旁询问脏水的来源',three['meet']),
      simple_stage('ch03_mudback','battle','R3-01',3,2230,'大甲占住排水口；赶开大甲后再查看旧瓣',enemy={'profile':1,'at':spot('R3-01',3,2590),'room_id':'R3-01','lane':[2050,2830],'arena':[2040,1560,800,520],'floor_y':2080,'ending':'retreat','hp':18},optional_observations=[{'id':'ch03_basin','label':'F 查看回水（可选）','lines':three['basin'],**position('R3-01',2,1810)}]),
      simple_stage('ch03_valve','dialogue','R3-01',4,3120,'大甲退走后，到右侧排水口查看旧瓣',three['valve']),
      simple_stage('ch03_open_valve','explore','R3-01',4,3120,'确认旧瓣后，再按一次F主动撬开旧瓣',tasks=[{'id':'ch03_valve_opened','label':'F 撬开旧瓣，尝试排走积水','requires':[],'grant':['ch03_valve_opened'],'lines':[],**position('R3-01',4,3120)}],required=['ch03_valve_opened']),
      simple_stage('ch03_flood','observe','R3-01',4,3120,'回水冲向菌床；观察事故后沿原路返回住巢',duration=8,captions=['旧瓣刚被撬开，近处积水退下去。远侧槽口随即翻起浑水，回水绕过水道冲向菌床。','老守护者带守卫压住旧瓣，把住户接回高台。菌床上的细丝被冲散，巢片滑离原位。'],grant=['ch03_flood_settled']),
      simple_stage('ch03_after','dialogue','R3-01',2,1350,'沿已走过的骨台返回菌床，帮补巢者安置住户',three['after']),
      simple_stage('ch03_salvage','explore','R3-01',1,620,'到左侧浅滩捡回旧壳，再回菌床固定巢片',tasks=[{'id':'ch03_shell_recovered','label':'F 捡回浅滩旧壳','requires':[],'grant':[],'lines':[],**position('R3-01',1,620)}],required=['ch03_shell_recovered']),
      simple_stage('ch03_fixed','dialogue','R3-01',2,1350,'把旧壳带回住巢，和补巢者一起固定',three['fixed'],reward_abilities=['pressure']),
      simple_stage('ch03_exit','exit','R3-01',9,100,'沿左侧上行骨台前往脂库')]
    c3={'id':3,'chapter_id':IDS[3],'title':'胃室的回水','room_id':'R3-01','stages':stages,'next':4}
    return [c1,c2,c3]


def build():
    chapters=first_chapters()
    for number in range(4,13):
        src=SOURCE/f'ch{number:02}.json'
        source=json.loads(src.read_text(encoding='utf-8'))
        chapter={'id':number,'chapter_id':IDS[number],'title':source['title'],'summary':source['summary'],'room_id':BIND[source['stages'][0]['id']]['room_id'],'source_file':src.relative_to(ROOT).as_posix(),'source_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'next':source['next'],'stages':[annotate(copy.deepcopy(s)) for s in source['stages']]}
        # 正式入口不显示白盒快捷键文案；原目标完整存于source_objective供差异审计。
        for stage in chapter['stages']:
            stage['source_objective']=stage['objective']
            stage['objective']=stage['objective'].replace('白盒压缩过程','潮汐变化').replace('白盒压缩观察','潮汐观察').replace('白盒压缩过程','潮汐变化').replace('全线白盒。R可回访结尾，不再开战。','本次旅途；之后可回访，不再交战。')
            stage['objective']=re.sub(r'；?再按F可结束。?','；F可结束观察。',stage['objective'])
            stage['objective']=stage['objective'].replace('白盒', '').replace('R可回访结尾，不再开战。', '之后可回访，不再交战。')
        chapters.append(chapter)
    for chapter in chapters:
        n=chapter['id'];chapter['transition_route']=ROUTES[n]
        chapter['route_hint']=' → '.join(ROUTES[n])
        chapter['actors']=[]
    find=lambda key:next(s for c in chapters for s in c['stages'] if s['id']==key)
    find('ch04_07_exit')['route_hint']='沿上层骨台右侧通路，进入环居腔。'
    find('ch06_07_exit')['objective']='返回左侧入口，沿环居腔、脂库和胃室原路返程，再从胃室右上方通道去泵庭'
    find('ch06_07_exit')['reward_abilities']=['anchor']
    find('ch07_leave_pump')['min_seconds']=1.0
    find('ch07_exit')['objective']='执卫已收手；沿右侧已有骨台进入骨穹腔'
    find('ch09_exit')['reward_abilities']=['bone']
    find('ch11_exit')['objective']='从左侧回到旧歌腔，沿维护路前往尾根主闸'
    find('ch11_exit')['reward_abilities']=['silence']
    for chapter in chapters:
        for stage in chapter['stages']:
            for task in stage.get('tasks',[]):
                if task['id'] in ['ch03_valve_opened','ch04_open_slit','ch12_shift_narrow_cover']:
                    task['requires_fresh_press']=True
            if stage['id']=='ch03_flood':
                stage['props']=[{'id':'ch03_fungus','asset':'fungus-bed','height':90,**position('R3-01',2,1550)}]
    data={'schema_version':1,'mode':'existing-formal-map-fallback','source':'docs/现有地图章节保底接入.md','room_geometry_changed':False,'chapter_count':12,'chapters':chapters}
    OUT.parent.mkdir(parents=True,exist_ok=True);OUT.write_bytes((json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    print('wrote',OUT.relative_to(ROOT),'chapters',len(chapters),'stages',sum(len(c['stages']) for c in chapters))


if __name__=='__main__':build()
