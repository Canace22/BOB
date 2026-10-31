"""Documentation-only reconciliation. Run after runtime/assets are frozen.
Evidence decisions live in coverage-review-decisions.json; file existence alone
never gives a pass. Preserve the initial contract for audit/restart.
"""
import json, pathlib, copy, hashlib, collections, datetime
P = pathlib.Path(__file__).resolve().parents[1]
D = P / 'docs'
base = D / 'element-manifest.baseline.json'
if not base.exists():
    base.write_bytes((D / 'element-manifest.json').read_bytes())
m = json.loads(base.read_text(encoding='utf-8'))
review = json.loads((D/'coverage-review-decisions.json').read_text(encoding='utf-8'))
rooms = {r['id']:r for r in json.loads((P/'assets/rooms.json').read_text(encoding='utf-8'))}
elements = m['elements']
originals = {e['element_id']:e for e in elements}

def make(src, eid, name, category, origin, paths, required, bounds=None):
    e=copy.deepcopy(originals[src]); e['element_id']=eid; e['name']=name
    e['category']=category; e['origin']=origin; e['parent_element_id']=eid[:5]
    e['reference_id']=eid[:5]; e['observation_notes']=name
    e['design_notes']='运行反查补录；图片事实与设计行为分别记录。'
    e['instances']={'mode':'fixed','expected_count':1,'spawn_rule':None,'instance_ids':[eid], 'runtime_node_paths':paths,'runtime_binding_status':'mapped_awaiting_evidence'}
    e['production']['asset_ids']=[eid+'-VIS'];e['production']['parts']=[name]
    e['defects']=[]
    for k,v in e['dimensions'].items():
        v.update(check_id=eid+'-'+k.upper(), requirement='required' if k in required else 'not_applicable',status='not_run' if k in required else 'not_applicable',evidence=[],reason='按该运行对象职责验收' if k in required else '该对象没有此独立职责；继承父系统时另行注明')
    if bounds is not None:
        e['spatial']['source_bounds_xywh']=bounds
        w,h=rooms[eid[:5]]['size'];e['spatial']['normalized_bounds_xywh']=[bounds[0]/w,bounds[1]/h,bounds[2]/w,bounds[3]/h]
    e['acceptance']=[{'check_id':eid+'-INSTANCE','operation':'核对运行节点或共享渲染区域','expected':'符合本元素实例或生成规则','status':'not_run'}, {'check_id':eid+'-VISUAL','operation':'运行截图与源图位置、轮廓、遮挡对照','expected':'保留观察对象或明确新增设计','status':'not_run'}]
    elements.append(e);return e

for rid,r in rooms.items():
    e=make(rid+'-BUBBLES-01',rid+'-BUBBLE-FIELD-01','源图烘焙气泡光点簇','background','observed',['Far/FarOriginalPixels','Middle/MiddleOriginalPixels'],['appearance','spatial','lifecycle'])
    e['design_notes']='源图水体表现的固定光点簇，不宣称逐点独立动画；新增上升气泡由BUBBLES生成器承担。'
    e['behavior']['motion']={'states':['static'],'period':0,'amplitude':0,'pivot':'源图','events':[]}
    if rid+'-FISH-01' in originals:
        e=make(rid+'-FISH-01',rid+'-FISH-SCHOOL-01','源图远景鱼群轮廓簇','creature','observed',['Far/FarOriginalPixels','World/WorldOriginalPixels'],['appearance','spatial','lifecycle'])
        e['design_notes']='一组烘焙远景轮廓，不逐条设碰撞；本轮独立缓游鱼由FISH生成器承担。'
        e['behavior']['motion']={'states':['static'],'period':0,'amplitude':0,'pivot':'源图','events':[]}
    for tag,name,node,count in [('DUST','漂移微尘系统','DriftingDust',28),('EVENT-PULSE','玩法事件粒子系统','EventPulses',None)]:
        e=make(rid+'-BUBBLES-01',rid+'-'+tag+'-01',name,'effect','designed',['EnvironmentMotion/'+node],['appearance','spatial','motion','lifecycle'])
        e['instances']['mode']='generator'; e['instances']['expected_count']=count
        e['instances']['spawn_rule']={'seed':int(rid[-2:])+100,'count':count} if count else {'max_pulses':16,'sparks_per_pulse':9,'events':['enemy_hit','enemy_defeated','player_death','reward','checkpoint','ability_unlocked']}
        e['behavior']['motion']={'states':['drift','wrap'] if count else ['event','expand','expire'],'period':0,'amplitude':'1.5–4.5 px/s横移、9px纵漂' if count else '0.45–0.85秒后释放','pivot':'世界坐标','events':['room_enter','pause'] if count else e['instances']['spawn_rule']['events']}
        e['behavior']['audio']={'asset_ids':[],'events':[],'spatial':False,'loop':False,'reason':'事件声已由玩法源事件播放，不重复播放'}
        e['production']['runtime_files']=['scripts/environment.gd']
    lamps={'R1-01':[[93,550]],'R1-03':[[75,526],[1605,558]],'R1-04':[[80,601]],'R1-06':[[100,754]],'R1-07':[[95,501]]}.get(rid,[])
    if lamps:
        e=make(rid+'-LIGHT-01',rid+'-CAMP-LIGHT-01','原图固定灯光晕','effect','designed',['EnvironmentMotion/CampLight'],['appearance','spatial','motion','lifecycle'])
        e['instances']['mode']='generator';e['instances']['expected_count']=len(lamps);e['instances']['spawn_rule']={'centers_source_px':lamps,'count':len(lamps)}
        e['behavior']['motion']={'states':['pulse'],'period':'两个叠加正弦1.9/4.7 rad/s','amplitude':'0.9+0.1sin+0.03sin','pivot':'原图灯中心','events':['room_enter','pause']}
        e['production']['runtime_files']=['scripts/environment.gd']

e=make('R1-04-ENEMY-01','R1-04-CLAW-01','负壳蟹独立攻击钳','boss','observed',['World/EnemyArt0/BossClaw/Art'],['appearance','spatial','motion','lifecycle'],[733,416,131,164])
e['parent_element_id']='R1-04-ENEMY-01';e['behavior']['motion']={'states':['idle','tell','active','recover'],'period':0,'amplitude':'前摇-0.22rad / 有效+0.32rad / 恢复0','pivot':'独立钳枢轴','events':['boss_tell','boss_active','boss_recover']}
e['behavior']['physics']['collision']=False;e['behavior']['physics']['moving_body_policy']='伤害判定由Boss父对象处理；钳为同步视觉部件，不重复伤害'
e['behavior']['interaction']={'trigger':'Boss父对象状态','conditions':['继承父对象攻击阶段'],'effects':['仅视觉转动'],'repeat_policy':'不单独触发伤害'}
e['behavior']['audio']={'asset_ids':[],'events':[],'spatial':False,'loop':False,'reason':'攻击声由父Boss同一事件播放，钳不重复播放'}
e['production']['master_files']+=['assets/masks/R1-04-claw.svg']
e=make('R1-07-GATE-02','R1-07-MEMORY-DISK-01','右岸螺旋记忆圆盘','scenery','observed',['World/WorldOriginalPixels'],['appearance','spatial','lifecycle'],[1370,510,100,70])
e['design_notes']='可见环境叙事物；与独立珠状REWARD分开，不新增拾取。';e['behavior']['interaction']={'trigger':'none','conditions':[],'effects':[],'repeat_policy':'无独立交互'}
e=make('R1-02-GATE-03','R1-01-EXIT-01','右边界功能出口','gate','inherited',['VisualMechanisms/Doors/Door1'],['spatial','interaction','audio','lifecycle'],[1500,550,171,180])
e['design_notes']='右边界通往02，不虚构原图没有的贝壳门。左侧GATE01是营地。';e['behavior']['interaction']={'trigger':'E或方向键+E','conditions':['距离100px内'],'effects':['进入R1-02'],'repeat_policy':'可往返'}
for i,name in [(4,'左壁侧台'),(5,'底部回收坡')]:
    pts=rooms['R1-06']['surfaces'][i]
    xs,ys=zip(*pts);b=[min(xs),min(ys),max(xs)-min(xs),max(ys)-min(ys)+35]
    e=make('R1-06-TERRAIN-01',f'R1-06-TERRAIN-{i+1:02}',name,'terrain','observed',[f'World/Terrain/Surface{i}/Contour','World/WorldOriginalPixels'],['appearance','spatial','physics','lifecycle'],b)
    e['observation_notes']=f'rooms.json surfaces[{i}]；后续运行反查补录。'
    e=make('R1-06-FLORA-01',f'R1-06-FLORA-{i+1:02}',name+'固定附着簇','flora','observed',['World/WorldOriginalPixels'],['appearance','spatial','lifecycle'],[b[0],b[1]-70,b[2],b[3]+70])

def na(e,dim,reason):
    e['dimensions'][dim].update(requirement='not_applicable',status='not_applicable',reason=reason,evidence=[])

for e in elements:
    eid=e['element_id'];rid=e['reference_id'];r=rooms[rid];tag=eid[6:-3];idx=int(eid[-2:])-1
    e['reviewer']='AI agent elements_v05; evidence-bounded review, not human aesthetic approval'
    for v in e['dimensions'].values():
        if v['requirement']=='required':v.update(status='not_run',evidence=[])
    e['defects']=[]
    e['instances']['runtime_binding_status']='mapped_awaiting_runtime_probe'
    e['production']['master_files']=list(dict.fromkeys([f'assets/masks/{rid}-classes.svg','assets/rooms.json']+e['production']['master_files']))
    e['production']['runtime_files']=list(dict.fromkeys(e['production']['runtime_files']+[f'scenes/r1/{rid}.tscn']))
    if tag in ['SPACE','DEPTH']:
        e['production']['runtime_files']+=[f'assets/clean/{rid}-far.png']
        e['spatial']['parallax']='camera delta*0.009 clamp x±6 y±4'
    if tag in ['CANOPY','WALL','FG','FLORA','TERRAIN','LIGHT']:
        e['production']['runtime_files']+=[f'assets/clean/{rid}.png','scripts/layer.gdshader']
    if tag=='FLORA':
        na(e,'motion','DEC-006：固定骨化管壳/海绵/钙化附着簇不作统一根摆，柔软须幕另列CANOPY。')
        e['behavior']['motion']={'states':['static'],'period':0,'amplitude':0,'pivot':'固定附着面','events':[]}
    if tag=='LIGHT':
        e['name']='原图静态透光方向与光束';e['instances'].update(mode='fixed_cluster',expected_count=1,spawn_rule=None,runtime_node_paths=['Far/FarOriginalPixels','Middle/MiddleOriginalPixels'])
        na(e,'motion','DEC-007：烘焙光束保持静态；实际灯光变化由CAMP-LIGHT单列。')
        e['behavior']['motion']={'states':['static'],'period':0,'amplitude':0,'pivot':'原图','events':[]}
    if tag=='CANOPY':e['behavior']['motion'].update(period=7.854,amplitude=1.4)
    if tag=='FG':e['spatial']['parallax']='反向远景shift*0.6，x±3.6 y±2.4';e['behavior']['motion']['amplitude']=3.6
    nodes={'BUBBLES':'AmbientBubbles','FISH':'DistantFish','FOG':'DriftingMist','AUDIO':'WaterAmbience'}
    if tag in nodes:e['instances']['runtime_node_paths']=['EnvironmentMotion/'+nodes[tag]];e['production']['runtime_files']=['scripts/environment.gd']
    if tag=='BUBBLES':
        e['origin']='designed';e['design_notes']='在原图水体基础上新增低密度运动泡；源图固定气泡另列BUBBLE-FIELD。'
        e['instances']['spawn_rule']={'count':18,'seed':int(rid[-2:])+100,'x_range':[180,r['size'][0]-180],'y_wrap':[60,r['size'][1]-110]};e['instances']['expected_count']=18
        e['behavior']['motion'].update(amplitude='上升11–24px/s，横摆7px',states=['rise','wrap'])
    if tag=='FISH':
        e['origin']='designed';e['design_notes']='补充七个独立程序游鱼；不宣称源图整群鱼已逐条动画，固定群另列FISH-SCHOOL。'
        e['instances']['spawn_rule']={'count':7,'seed':int(rid[-2:])+100,'speed_px_s':[5,9],'vertical_amplitude_px':7};e['instances']['expected_count']=7
    if tag=='FOG':
        e['instances']['spawn_rule']={'count':3,'max_alpha':0.027,'positions':'width*(0.2+0.3*i),height*(0.44+0.09*i)'};e['instances']['expected_count']=3
        e['behavior']['motion'].update(period='2π/0.08 横向；2π/0.13 纵向',amplitude='x38/y6px，alpha0.027')
    if e['instances']['mode']=='generator':
        e['instances']['instance_id_rule']=eid+' / room-seed / array-index；事件粒子追加源事件seq与spark-index'
        e['instances']['runtime_members']={'BUBBLES':['EnvironmentMotion.bubbles[i]'],'FISH':['EnvironmentMotion.fish[i]'],'FOG':['EnvironmentMotion/DriftingMist/Mist0..2'],'DUST':['EnvironmentMotion.dust[i]'],'EVENT-PULSE':['EnvironmentMotion.pulses[i]'],'CAMP-LIGHT':['EnvironmentMotion.lamps[i]']}.get(tag,[])
    if tag=='AUDIO':
        na(e,'appearance','AudioStreamPlayer无可见图形，实际输出由audio维度的Master数字混音验收。')
        na(e,'spatial','房间非定位环境声，无可视位置或声像衰减职责。')
        e['behavior']['audio'].update(asset_ids=['Godot-generated PCM16 mono 22050Hz'],events=['room_enter','mute','pause'],gain_db=-29)
    if tag=='PLAYER':
        e['instances']['runtime_node_paths']=['World/Player','World/Player/ReferenceArtPivot/PlayerArt/OriginalSilhouette']
        e['instances']['runtime_members']=['main.player.sprite (动态Sprite2D，无稳定自定义名称)']
        e['production']['runtime_files']+=['scripts/player.gd','assets/runtime/hero/']
    if tag=='ENEMY':
        e['instances']['runtime_node_paths']=[f'World/EnemyArt{idx}/Pivot/OriginalSilhouette'];e['instances']['runtime_members']=[f'main.enemies[{idx}]']
    if tag=='REWARD':
        e['instances']['runtime_node_paths']=['World/RewardArt','VisualMechanisms']
        e['instances']['runtime_members']=[f'main.collected["{rid}"]']
    if tag=='GAP':
        e['instances']['runtime_node_paths']=['World/Player']
        e['instances']['runtime_members']=['player.last_safe','player.hurt(1,true)','room.soft_beds' if rid=='R1-05' else 'room.size.y+80 fall boundary']
    if tag=='MEMBRANE':
        e['instances']['runtime_node_paths']=['World/Terrain/Surface0/Contour','World/WorldOriginalPixels','VisualMechanisms']
        e['behavior']['motion'].update(amplitude=42,events=['player_weight','down_jump','unload'])
        e['behavior']['interaction'].update(trigger='中央膜承重后S+Space下钻；下层中央Space弹返',conditions=['中央x700–970','膜下沉>15px才能下钻'],effects=['42px最大下沉','可控制地下钻','下层返坡回主路'])
    if tag=='RING':
        e['instances']['runtime_node_paths']=['World/WorldOriginalPixels',f'VisualMechanisms/AnchorRings/Ring{idx+1}']
        e['behavior']['interaction']['conditions']=['A3或明确F9练习','距离90–390px','面向目标且不在身后35px外']
    if tag=='GATE':
        mapping={'R1-01':{},'R1-02':{0:1,1:3,2:2,3:4},'R1-03':{0:1,1:2},'R1-04':{0:1,1:2},'R1-05':{0:1,1:2},'R1-06':{0:1,1:2},'R1-07':{0:1}}
        e['instances']['runtime_node_paths']=['World/WorldOriginalPixels']
        if idx in mapping[rid]:e['instances']['runtime_node_paths']+=[f'VisualMechanisms/Doors/Door{mapping[rid][idx]}']
        if rid in ['R1-01','R1-04','R1-05'] and idx==0:e['instances']['runtime_members']=['main.try_camp() / room.camp']
        if rid in ['R1-01','R1-04'] and idx==0:
            e['instances']['runtime_node_paths']+=['EnvironmentMotion/CampLight']
            e['behavior']['motion']={'states':['steady','light_pulse'],'period':'1.9/4.7 rad/s叠加正弦','amplitude':'0.9+0.1sin+0.03sin','pivot':'固定灯中心','events':['pause','room_enter']}
        if rid=='R1-04' and idx==1:e['instances']['runtime_node_paths']+=['World/DoorArt/OriginalSilhouette'];e['behavior']['motion'].update(amplitude='18px向上+alpha1→0',period=1.25)
        if rid=='R1-05' and idx==0:
            na(e,'motion','固定育窝壳巢，原图无独立发光灯；交互与存档保留，不添加无来源的闪灯。')
            e['behavior']['motion']={'states':['static'],'period':0,'amplitude':0,'pivot':'原图','events':[]}
    if review.get('approve_current_mechanics'):
        if tag=='MEMBRANE':e['behavior']['audio'].update(asset_ids=['sweep','jump'],events=['membrane_sag','membrane_dive','membrane_rebound'],spatial=False)
        if tag=='RING':e['behavior']['audio'].update(asset_ids=['collect'],events=['grapple_attach'],spatial=False)
        if e['behavior']['audio'].get('spatial'):e['behavior']['audio']['spatial']=False
    if tag=='TERRAIN' and idx<len(r['surfaces']):
        e['behavior']['physics']['top_polyline_source_px']=r['surfaces'][idx]
        e['behavior']['physics']['one_way']=bool(rid=='R1-03' and idx==0)
    if tag=='GAP' and rid=='R1-05':
        e['behavior']['interaction']['trigger']='soft_beds对应间隙中足点越过可见软床接触线；测试初始落体fixture另列'
        e['behavior']['interaction']['repeat_policy']='回最后安全岸，扣1生命，离开触发区后可再次触发'
    # Review decisions are explicit, human/agent observations, never file existence.
    for dim,decision in review.get('per_element',{}).get(eid,{}).items():
        if dim in e['dimensions'] and e['dimensions'][dim]['requirement']=='required':e['dimensions'][dim].update(decision)
    for group in review.get('groups',[]):
        if (not group.get('tags') or tag in group['tags']) and (not group.get('rooms') or rid in group['rooms']):
            for dim,decision in group['dimensions'].items():
                if dim in e['dimensions'] and e['dimensions'][dim]['requirement']=='required' and dim not in review.get('per_element',{}).get(eid,{}):e['dimensions'][dim].update(decision)
    for dim,v in e['dimensions'].items():
        if v['status']=='fail':e['defects'].append({'dimension':dim,'description':v.get('note','见证据')})
    required=[v for v in e['dimensions'].values() if v['requirement']=='required']
    e['status']='pass' if all(v['status']=='pass' for v in required) else 'requires_followup'
    e['next_instruction']='保持当前已验证输入摘要' if e['status']=='pass' else '按未通过维度定向返修或补运行观察，不删除要求。'
    e['instances']['runtime_binding_status']=review.get('instance_status','mapped_awaiting_runtime_probe')
    for a in e['acceptance']:
        if a['check_id'].endswith('INSTANCE'):
            a['status']='pass' if review.get('instances_pass') else 'not_run';a['evidence']=review.get('instance_evidence',[])
        else:a['status']=e['dimensions']['appearance']['status'];a['evidence']=e['dimensions']['appearance']['evidence']

m['status']='evidence_review_frozen_with_open_items' if review.get('frozen') else 'evidence_review_in_progress'
m['contract_revisions']=review.get('contract_revisions',[])
m['review_scope_notes']=review.get('notes',[])
m['review_timestamp']=datetime.datetime.now().isoformat(timespec='seconds')
m['camera_contract']['capture_random_seed']='固定构图截图禁用补充动态；正常环境每房seed=room_index+101'
m['camera_contract']['max_zoom_and_shake']='全房fit；Tab近景1.0x；Far x±6/y±4，Middle乘0.38，Foreground反向乘0.6；无镜头震动'
for row in m['scan']['rooms']:
    rid=row['reference_id'];row['element_ids']=[e['element_id'] for e in elements if e['reference_id']==rid]
    row['runtime_comparison_reviewed']=rid in review.get('rooms_reviewed',[])
    row['notes']='运行截图反查已补录独立动态与遗漏地形；视觉差异仍按逐维度状态保留。'
for s in m['system_requirements']:s.update(review.get('systems',{}).get(s['id'],{}))
for g in m['global_acceptance']:g.update(review.get('globals',{}).get(g['id'],{}))
for key,value in review.get('systems',{}).items():
    if key not in [x['id'] for x in m['system_requirements']]:m['system_requirements'].append(dict(id=key,requirement='required',**value))
for key,value in review.get('globals',{}).items():
    if key not in [x['id'] for x in m['global_acceptance']]:m['global_acceptance'].append(dict(id=key,**value))
req=[v for e in elements for v in e['dimensions'].values() if v['requirement']=='required']
states=collections.Counter(v['status'] for v in req)
fixed=sum(e['instances']['expected_count'] or 0 for e in elements if e['instances']['mode']!='generator')
gens=sum(e['instances']['mode']=='generator' for e in elements)
m['coverage']={'elements':len(elements),'required_dimensions':len(req),'required_by_dimension':dict(collections.Counter(k for e in elements for k,v in e['dimensions'].items() if v['requirement']=='required')),'passed_dimensions':states['pass'],'undecided_dimensions':sum(v['requirement']=='undecided' for e in elements for v in e['dimensions'].values()),'fail_dimensions':states['fail'],'not_run_dimensions':states['not_run'],'instance_coverage':{'expected_fixed_instances':fixed,'generator_contracts':gens,'runtime_verified_instances':fixed if review.get('instances_pass') else 0,'generator_contracts_verified':gens if review.get('instances_pass') else 0},'global_checks_passed':sum(x['status']=='pass' for x in m['global_acceptance']),'all_required_passed':all(v['status']=='pass' for v in req) and review.get('instances_pass',False) and all(x['status']=='pass' for x in m['global_acceptance']) and all(x['status']=='pass' for x in m['system_requirements'])}
m['status']='accepted_by_ai_runtime_review' if m['coverage']['all_required_passed'] else m['status']
m['coverage']['global_checks_total']=len(m['global_acceptance'])
m['coverage']['global_checks_failed']=sum(x['status']=='fail' for x in m['global_acceptance'])
m['coverage']['global_checks_blocked']=sum(x['status']=='blocked' for x in m['global_acceptance'])
m['coverage']['scope_note']='运行维度不含独立图层交付及硬件音频，后两项仍有必需全局未通过，不能用运行pass掩盖。'
m['next_task']='保留本次证据与输入摘要；后续修改相关文件时重验受影响项。' if m['coverage']['all_required_passed'] else '补齐未通过的逐元素/整体证据；不把本文数字当作独立运行证据。'
files=list((P/'scripts').glob('*'))+list((P/'scenes/r1').glob('*.tscn'))+[P/'assets/rooms.json']+list((P/'assets/clean').glob('*.png'))
used={x for e in elements for v in e['dimensions'].values() for x in v.get('evidence',[]) if isinstance(x,str)}
used.update(x for item in m['global_acceptance']+m['system_requirements'] for x in item.get('evidence',[]) if isinstance(x,str))
files += [P/f for f in used if (P/f).is_file()]
m['input_snapshot']=[{'path':str(f.relative_to(P)).replace('\\','/'),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'mtime_ns':f.stat().st_mtime_ns} for f in sorted(set(files)) if f.is_file()]
(D/'element-manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
names={'appearance':'外观','spatial':'空间','motion':'动态','physics':'物理','interaction':'交互','audio':'声音','lifecycle':'恢复'}
out=['# 须门遗港：全要素覆盖表','',f"{len(elements)} 个独立元素、固定簇或生成合同；{len(req)} 个游戏内运行维度，{states['pass']} 通过、{states['fail']} 失败、{states['not_run']} 待验证。未确定规格 0 不代表验收全部完成；独立图层资产仍待精修，硬件音频和真实窗口关闭受阻。",'',f"完整验收通过：{m['coverage']['all_required_passed']}。按 element-manifest.json 的输入摘要复验；源文件变化会令相关证据过期。",'', '原图保存在 assets/reference/r1；可编辑母版为 assets/masks 的 SVG、rooms.json、Godot scene/shader；导出图层在 assets/runtime/layers（仍有蓝背景残留，非精细抠图）；补绘层在 assets/clean。共享渲染的静态簇保留独立观察ID，不虚构独立节点。','', '正常首访 01→02→03→04→05；Boss解锁A1。02↔06/07是A2/A3回访，F9为明示临时练习，不计入正式首访成长。','']
for rid,r in rooms.items():
    out += [f"## {rid} {r['name']}",'','| ID / 元素 | 原图位置框 | 运行绑定 | 必需维度状态 |','|---|---|---|---|']
    for e in elements:
        if e['reference_id']!=rid:continue
        pos=','.join(str(round(x,1)) for x in e['spatial']['source_bounds_xywh'])
        status='；'.join(names[k]+':'+v['status'] for k,v in e['dimensions'].items() if v['requirement']=='required')
        out.append('| '+e['element_id']+'<br>'+e['name']+' | '+pos+' | '+'<br>'.join(e['instances']['runtime_node_paths'])+' | '+status+' |')
    out.append('')
out += ['## 合同变更与证据边界','']+['- '+str(x) for x in m['contract_revisions']]+['']+['- '+str(x) for x in m['review_scope_notes']]
out += ['','每个元素的数量、材料、动态、碰撞、交互、声音、恢复、来源和证据位于 element-manifest.json；详细未完成项见 coverage-readiness.md。']
(D/'全要素覆盖表.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
print(json.dumps(m['coverage'],ensure_ascii=False))
